import React, { useContext, useEffect, useRef, useState } from 'react';
import { Navigation, Cpu, Radio, Play, Square, Wifi, WifiOff, Loader, Brain, Flame, MapPin, Gauge, Battery, BatteryLow, BatteryWarning, ScrollText } from 'lucide-react';
import { ThemeContext } from '../App';
import { api, wsUrl } from '../services/api';

const PHASE_LABELS = {
  takeoff: 'Décollage', transit: 'Transit', scanning: 'Scan IA',
  return: 'Retour base', landing: 'Atterrissage', complete: 'Terminé', idle: 'En attente',
};

function* mockTelemetry() {
  const phases = [
    { phase: 'takeoff',  count: 8,  alt: (i) => Math.min(i * 6.5, 50) },
    { phase: 'transit',  count: 10, alt: () => 50 },
    { phase: 'scanning', count: 20, alt: () => 50 },
    { phase: 'return',   count: 10, alt: () => 50 },
    { phase: 'landing',  count: 8,  alt: (i) => Math.max(50 - i * 6.5, 0) },
  ];
  let elapsed = 0, bat = 100;
  for (const { phase, count, alt } of phases) {
    for (let i = 0; i < count; i++) {
      bat -= 0.4; elapsed++;
      const isScanning = phase === 'scanning';
      yield {
        type: 'telemetry', elapsed_s: elapsed, phase, battery_pct: +bat.toFixed(1),
        position: { lat: 33.852 + (Math.random() - 0.5) * 0.01, lon: 9.978 + (Math.random() - 0.5) * 0.01, altitude_m: +alt(i).toFixed(1) },
        sensors: { speed_m_s: +(6 + Math.random() * 4).toFixed(1), air: { so2_ug_m3: +(90 + Math.random() * 20).toFixed(1), pm10_ug_m3: +(80 + Math.random() * 15).toFixed(1), temperature_c: +(28 + Math.random()).toFixed(1), humidity_pct: +(55 + Math.random() * 3).toFixed(1) } },
        jetson_status: { cpu_pct: +(50 + Math.random() * 20).toFixed(1), gpu_pct: isScanning ? +(70 + Math.random() * 15).toFixed(1) : +(25 + Math.random() * 10).toFixed(1), temp_c: +(58 + Math.random() * 8).toFixed(1) },
        ...(isScanning ? { ai_results: { segmentation: { class_name: 'contamine_gct', confidence: +(0.85 + Math.random() * 0.1).toFixed(3), is_contaminated: true }, thermal: { anomaly_detected: true, anomaly_delta_c: +(12 + Math.random() * 4).toFixed(1) } } } : {}),
      };
    }
  }
}

function ThermalCanvas({ hotspotPct = 2.81, anomalyDelta = 14, tick = 0 }) {
  const canvasRef = useRef(null);
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const W = canvas.width, H = canvas.height;
    const img = ctx.createImageData(W, H);
    const stops = [[0,[0,0,0]],[0.12,[30,0,50]],[0.35,[140,0,60]],[0.59,[235,55,0]],[0.82,[255,175,0]],[1.0,[255,255,255]]];
    function ironColor(t) {
      for (let i = 1; i < stops.length; i++) {
        const [t0,c0] = stops[i-1], [t1,c1] = stops[i];
        if (t <= t1) { const f=(t-t0)/(t1-t0); return c0.map((v,j)=>Math.round(v+f*(c1[j]-v))); }
      }
      return stops[stops.length-1][1];
    }
    const pulse = 0.85 + 0.1 * Math.sin(tick * 0.8);
    const hotspots = [{ cx:0.42,cy:0.38,strength:0.9*pulse,sigma:0.14 },{ cx:0.60,cy:0.55,strength:0.6*pulse,sigma:0.09 },{ cx:0.28,cy:0.68,strength:0.5*pulse,sigma:0.08 }];
    for (let y = 0; y < H; y++) {
      for (let x = 0; x < W; x++) {
        let heat = 0.15 + Math.random() * 0.04;
        for (const h of hotspots) { const dx=x/W-h.cx,dy=y/H-h.cy; heat+=h.strength*Math.exp(-(dx*dx+dy*dy)/(2*h.sigma*h.sigma)); }
        heat = Math.min(1, heat);
        const [r,g,b] = ironColor(heat);
        const idx = (y*W+x)*4;
        img.data[idx]=r; img.data[idx+1]=g; img.data[idx+2]=b; img.data[idx+3]=255;
      }
    }
    ctx.putImageData(img, 0, 0);
  }, [hotspotPct, anomalyDelta, tick]);
  return <canvas ref={canvasRef} width={256} height={256} className="w-full rounded-2xl object-cover" style={{ maxHeight: 280, imageRendering: 'pixelated' }} />;
}

function Pill({ label, value, isDark }) {
  return (
    <div className={`rounded-2xl px-4 py-3 ${isDark ? 'bg-white/5' : 'bg-gray-50 border border-gray-100'}`}>
      <div className={`text-xs uppercase tracking-widest mb-1 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>{label}</div>
      <div className={`font-bold text-sm ${isDark ? 'text-white' : 'text-gray-900'}`}>{value ?? '—'}</div>
    </div>
  );
}

function SectionTitle({ icon: Icon, label, isDark }) {
  return (
    <div className={`font-bold mb-4 flex items-center gap-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>
      <Icon size={16} strokeWidth={1.5} className="text-[#00d4ff]" />
      {label}
    </div>
  );
}

export default function DronePage() {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';

  const [status, setStatus]           = useState(null);
  const [telemetry, setTelemetry]     = useState(null);
  const [thermal, setThermal]         = useState(null);
  const [running, setRunning]         = useState(false);
  const [backendOnline, setBackendOnline] = useState(null);
  const [log, setLog]                 = useState([]);
  const wsRef        = useRef(null);
  const mockTimerRef = useRef(null);
  const logRef       = useRef(null);

  const addLog = (msg) => setLog((p) => [...p.slice(-49), msg]);

  useEffect(() => {
    api.health().then(() => setBackendOnline(true)).catch(() => setBackendOnline(false));
    api.droneStatus().then(setStatus);
    api.droneThermal(33.852, 9.978, 'gct').then(setThermal);
    return () => { wsRef.current?.close(); clearTimeout(mockTimerRef.current); };
  }, []);

  useEffect(() => { if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight; }, [log]);

  function startMockMission() {
    const gen = mockTelemetry();
    addLog('Mode simulation locale activé');
    function tick() {
      const { value, done } = gen.next();
      if (done) { setRunning(false); addLog('Mission simulée terminée'); return; }
      setTelemetry(value);
      if (value.ai_results?.thermal) setThermal((p) => ({ ...p, ...value.ai_results.thermal, _tick: (p?._tick || 0) + 1 }));
      addLog(`[${value.elapsed_s}s] ${PHASE_LABELS[value.phase]} · Bat ${value.battery_pct}% · Alt ${value.position.altitude_m}m`);
      mockTimerRef.current = setTimeout(tick, 600);
    }
    tick();
  }

  function startMission() {
    if (running) return;
    setRunning(true); setLog([]);
    if (!backendOnline) { startMockMission(); return; }
    const missionId = `mission_${Date.now()}`;
    const url = wsUrl(`/ws/drone/${missionId}?zone_id=gct`);
    addLog(`Connexion → ${url}`);
    let ws;
    try { ws = new WebSocket(url); } catch { addLog('WebSocket non supporté — simulation'); startMockMission(); return; }
    wsRef.current = ws;
    const timeout = setTimeout(() => { if (ws.readyState !== WebSocket.OPEN) { ws.close(); addLog('Timeout — simulation locale'); startMockMission(); } }, 4000);
    ws.onopen = () => { clearTimeout(timeout); addLog('WebSocket connecté'); };
    ws.onmessage = (e) => {
      const pkt = JSON.parse(e.data);
      if (pkt.type === 'telemetry') {
        setTelemetry(pkt);
        if (pkt.ai_results?.thermal) setThermal((p) => ({ ...p, ...pkt.ai_results.thermal }));
        addLog(`[${pkt.elapsed_s}s] ${PHASE_LABELS[pkt.phase]} · Bat ${pkt.battery_pct}% · Alt ${pkt.position?.altitude_m}m`);
      }
      if (pkt.type === 'mission_end' || pkt.event === 'mission_complete') { setRunning(false); addLog('Mission terminée'); ws.close(); }
    };
    ws.onerror = () => clearTimeout(timeout);
    ws.onclose = (e) => { clearTimeout(timeout); if (e.code !== 1000 && running) { addLog('WebSocket fermé — simulation'); startMockMission(); } else setRunning(false); };
  }

  function stopMission() { wsRef.current?.close(); clearTimeout(mockTimerRef.current); setRunning(false); addLog('Mission arrêtée'); }

  const t = telemetry;
  const batPct = t?.battery_pct ?? 100;
  const batteryColor = batPct > 50 ? '#22c55e' : batPct > 20 ? '#f97316' : '#ef4444';
  const BatIcon = batPct > 50 ? Battery : batPct > 20 ? BatteryWarning : BatteryLow;

  const card = `rounded-3xl border p-6 ${isDark ? 'bg-white/[0.03] border-white/5' : 'bg-white border-gray-100 shadow-sm'}`;

  return (
    <div className="max-w-7xl mx-auto px-8 py-12">
      {/* Page header */}
      <div className="mb-8 flex items-start justify-between flex-wrap gap-4">
        <div>
          <h1 className={`text-4xl font-bold tracking-tight mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>Drone Digital Twin</h1>
          <p className={`text-lg ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>Surveillance aérienne IA — DJI Mini 3 Pro · FLIR · MicaSense · Jetson Nano</p>
        </div>
        <div className={`flex items-center gap-2 px-4 py-2 rounded-2xl text-sm font-semibold border ${
          backendOnline === null ? (isDark ? 'border-white/10 text-white/30' : 'border-gray-200 text-gray-400') :
          backendOnline ? 'border-green-500/30 text-green-400 bg-green-500/10' : 'border-orange-500/30 text-orange-400 bg-orange-500/10'
        }`}>
          {backendOnline === null ? <Loader size={14} className="animate-spin" /> : backendOnline ? <Wifi size={14} /> : <WifiOff size={14} />}
          {backendOnline === null ? 'Vérification…' : backendOnline ? 'Backend connecté' : 'Mode simulation'}
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Left column */}
        <div className="lg:col-span-1 flex flex-col gap-4">
          {/* Drone status */}
          <div className={card}>
            <SectionTitle icon={Navigation} label="Statut Drone" isDark={isDark} />
            {status ? (
              <div className="space-y-2 text-sm">
                {[['Modèle', status.drone_model], ['Autonomie', `${status.max_flight_time_min} min`], ['Portée', `${status.max_range_km} km`]].map(([k, v]) => (
                  <div key={k} className={`flex justify-between ${isDark ? 'text-blue-100/60' : 'text-gray-600'}`}>
                    <span>{k}</span><span className="font-medium text-right max-w-[60%]">{v}</span>
                  </div>
                ))}
                <div className={`flex justify-between ${isDark ? 'text-blue-100/60' : 'text-gray-600'}`}>
                  <span>Statut</span>
                  <span className={`font-bold flex items-center gap-1 ${running ? 'text-[#00d4ff]' : 'text-green-400'}`}>
                    {running ? <><Radio size={12} className="animate-pulse" /> En vol</> : <><Wifi size={12} /> Disponible</>}
                  </span>
                </div>
                <div className="pt-2">
                  <div className={`text-xs uppercase tracking-widest mb-1 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>Payload IA</div>
                  {status.payload?.map((p) => <div key={p} className={`text-xs py-0.5 flex items-center gap-1.5 ${isDark ? 'text-blue-100/50' : 'text-gray-500'}`}><Cpu size={10} strokeWidth={1.5} />{p}</div>)}
                </div>
              </div>
            ) : <div className={`text-sm animate-pulse ${isDark ? 'text-white/30' : 'text-gray-400'}`}>Chargement…</div>}
          </div>

          {/* Mission control */}
          <div className={card}>
            <SectionTitle icon={Gauge} label="Contrôle Mission" isDark={isDark} />
            <p className={`text-xs mb-4 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>
              Zone GCT · 4 waypoints · Altitude 50 m{!backendOnline && backendOnline !== null ? ' · Simulation' : ''}
            </p>
            <div className="flex gap-3">
              <button onClick={startMission} disabled={running}
                className={`flex-1 py-2.5 rounded-2xl text-sm font-bold transition-all flex items-center justify-center gap-2 ${running ? 'bg-white/10 text-white/30 cursor-not-allowed' : 'bg-[#00d4ff] text-[#080e1a] hover:bg-[#00b8d9]'}`}>
                <Play size={14} strokeWidth={2} /> {running ? 'En vol…' : 'Lancer'}
              </button>
              <button onClick={stopMission} disabled={!running}
                className={`flex-1 py-2.5 rounded-2xl text-sm font-bold transition-all border flex items-center justify-center gap-2 ${!running ? (isDark ? 'border-white/5 text-white/20 cursor-not-allowed' : 'border-gray-100 text-gray-300 cursor-not-allowed') : 'border-red-500/50 text-red-400 hover:bg-red-500/10'}`}>
                <Square size={14} strokeWidth={2} /> Arrêter
              </button>
            </div>
          </div>

          {/* Log */}
          <div className={card + ' flex-1'}>
            <SectionTitle icon={ScrollText} label="Journal de vol" isDark={isDark} />
            <div ref={logRef} className="overflow-y-auto space-y-1 scrollbar-thin" style={{ maxHeight: 200 }}>
              {log.length === 0
                ? <div className={`text-xs ${isDark ? 'text-white/20' : 'text-gray-300'}`}>En attente de mission…</div>
                : log.map((l, i) => <div key={i} className={`text-xs font-mono ${isDark ? 'text-blue-100/50' : 'text-gray-500'}`}>{l}</div>)}
            </div>
          </div>
        </div>

        {/* Right column */}
        <div className="lg:col-span-2 flex flex-col gap-4">
          {/* Telemetry */}
          <div className={card}>
            <SectionTitle icon={Radio} label="Télémétrie Temps Réel" isDark={isDark} />
            {t ? (
              <>
                <div className="mb-4">
                  <div className="flex justify-between text-xs mb-1">
                    <span className={`flex items-center gap-1 ${isDark ? 'text-blue-100/40' : 'text-gray-400'}`}><BatIcon size={12} strokeWidth={1.5} /> Batterie</span>
                    <span style={{ color: batteryColor }} className="font-bold">{t.battery_pct}%</span>
                  </div>
                  <div className={`h-2 rounded-full overflow-hidden ${isDark ? 'bg-white/10' : 'bg-gray-100'}`}>
                    <div className="h-full rounded-full transition-all duration-500" style={{ width: `${t.battery_pct}%`, background: batteryColor }} />
                  </div>
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-4">
                  <Pill label="Phase"    value={PHASE_LABELS[t.phase] || t.phase} isDark={isDark} />
                  <Pill label="Altitude" value={`${t.position?.altitude_m} m`} isDark={isDark} />
                  <Pill label="Position" value={`${t.position?.lat?.toFixed(4)}, ${t.position?.lon?.toFixed(4)}`} isDark={isDark} />
                  <Pill label="Vitesse"  value={`${t.sensors?.speed_m_s} m/s`} isDark={isDark} />
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-4">
                  <Pill label="SO₂"     value={`${t.sensors?.air?.so2_ug_m3} µg/m³`} isDark={isDark} />
                  <Pill label="PM10"    value={`${t.sensors?.air?.pm10_ug_m3} µg/m³`} isDark={isDark} />
                  <Pill label="Temp"    value={`${t.sensors?.air?.temperature_c}°C`} isDark={isDark} />
                  <Pill label="Humidité" value={`${t.sensors?.air?.humidity_pct}%`} isDark={isDark} />
                </div>
                {t.ai_results && (
                  <div className={`rounded-2xl p-4 border ${isDark ? 'bg-[#00d4ff]/5 border-[#00d4ff]/20' : 'bg-blue-50 border-blue-100'}`}>
                    <div className={`text-xs font-bold uppercase tracking-widest mb-2 flex items-center gap-1.5 ${isDark ? 'text-[#00d4ff]' : 'text-blue-600'}`}>
                      <Brain size={12} strokeWidth={2} /> Inférence IA Jetson Nano
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-sm">
                      <div className={isDark ? 'text-blue-100/60' : 'text-gray-600'}>
                        Classe : <strong>{t.ai_results.segmentation?.class_name}</strong> ({(t.ai_results.segmentation?.confidence * 100).toFixed(0)}%)
                      </div>
                      <div className={isDark ? 'text-blue-100/60' : 'text-gray-600'}>
                        Anomalie : <strong className={t.ai_results.thermal?.anomaly_detected ? 'text-red-400' : 'text-green-400'}>
                          {t.ai_results.thermal?.anomaly_detected ? `+${t.ai_results.thermal?.anomaly_delta_c}°C` : 'Non'}
                        </strong>
                      </div>
                    </div>
                  </div>
                )}
              </>
            ) : (
              <div className={`text-sm flex items-center gap-2 ${isDark ? 'text-white/20' : 'text-gray-300'}`}>
                <MapPin size={14} strokeWidth={1.5} /> Lancez une mission pour voir la télémétrie en direct.
              </div>
            )}
          </div>

          {/* Thermal */}
          <div className={card}>
            <SectionTitle icon={Flame} label="Image Thermique FLIR" isDark={isDark} />
            <p className={`text-xs mb-4 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>Zone GCT · Colormap Iron · 512×512</p>
            {thermal ? (
              <>
                {thermal.image_b64
                  ? <img src={`data:image/png;base64,${thermal.image_b64}`} alt="Thermal FLIR" className="w-full rounded-2xl object-cover mb-4" style={{ maxHeight: 280 }} />
                  : <div className="mb-4"><ThermalCanvas hotspotPct={thermal.hotspot_pct} anomalyDelta={thermal.anomaly_delta_c} tick={thermal._tick} /></div>
                }
                <div className="grid grid-cols-4 gap-3">
                  <Pill label="T° min"     value={`${thermal.temp_min_c}°C`} isDark={isDark} />
                  <Pill label="T° max"     value={`${thermal.temp_max_c}°C`} isDark={isDark} />
                  <Pill label="Δ anomalie" value={`+${thermal.anomaly_delta_c}°C`} isDark={isDark} />
                  <Pill label="Hotspots"   value={`${thermal.hotspot_pct}%`} isDark={isDark} />
                </div>
              </>
            ) : <div className={`text-sm animate-pulse ${isDark ? 'text-white/20' : 'text-gray-300'}`}>Chargement…</div>}
          </div>
        </div>
      </div>
    </div>
  );
}
