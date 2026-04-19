import React, { useContext, useEffect, useState } from 'react';
import { Wind, Thermometer, Droplets, AlertTriangle, AlertOctagon, ShieldCheck, ChevronRight } from 'lucide-react';
import { ThemeContext } from '../App';
import { api } from '../services/api';

const ZONES = ['gct', 'ville', 'mer', 'oasis'];
const ZONE_LABELS = { gct: 'Zone GCT', ville: 'Centre-Ville', mer: 'Littoral', oasis: 'Oasis' };

const LEVEL_STYLES = {
  vert:   { bg: 'bg-green-500/10',  border: 'border-green-500/30',  dot: 'bg-green-500',  text: 'text-green-400',  badge: 'Faible',  Icon: ShieldCheck },
  orange: { bg: 'bg-orange-500/10', border: 'border-orange-500/30', dot: 'bg-orange-400', text: 'text-orange-400', badge: 'Modéré',  Icon: AlertTriangle },
  rouge:  { bg: 'bg-red-500/10',    border: 'border-red-500/30',    dot: 'bg-red-500',    text: 'text-red-400',    badge: 'Élevé',   Icon: AlertOctagon },
};
function levelStyle(level) { return LEVEL_STYLES[level] || LEVEL_STYLES.orange; }

function AlertCard({ zoneId, data, isDark }) {
  const s = levelStyle(data.global_alert_level);
  const air = data.air_quality || {};
  const meteo = data.meteo || {};
  const { Icon } = s;

  return (
    <div className={`rounded-3xl border p-6 transition-all duration-700 ${s.bg} ${s.border} ${isDark ? '' : 'shadow-sm'}`}>
      <div className="flex items-start justify-between mb-4">
        <div>
          <div className={`font-bold text-lg ${isDark ? 'text-white' : 'text-gray-900'}`}>{ZONE_LABELS[zoneId] || zoneId}</div>
          <div className={`text-xs uppercase tracking-widest mt-0.5 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>Qualité de l'air</div>
        </div>
        <span className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${s.text} border ${s.border}`}>
          <Icon size={12} strokeWidth={2} />
          {s.badge}
        </span>
      </div>

      <div className="grid grid-cols-3 gap-3 mb-4">
        {[
          { label: 'AQI',  value: air.aqi },
          { label: 'SO₂',  value: air.so2  != null ? `${air.so2} µg/m³`  : '—' },
          { label: 'PM10', value: air.pm10 != null ? `${air.pm10} µg/m³` : '—' },
        ].map(({ label, value }) => (
          <div key={label} className={`rounded-2xl p-3 text-center ${isDark ? 'bg-white/5' : 'bg-white/60'}`}>
            <div className={`text-xs uppercase tracking-wider mb-1 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>{label}</div>
            <div className={`font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{value ?? '—'}</div>
          </div>
        ))}
      </div>

      {meteo.temperature != null && (
        <div className={`text-xs mb-3 flex items-center gap-3 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>
          <span className="flex items-center gap-1"><Thermometer size={11} strokeWidth={1.5} /> {meteo.temperature}°C</span>
          <span className="flex items-center gap-1"><Wind size={11} strokeWidth={1.5} /> {meteo.wind_speed} km/h</span>
          <span className="flex items-center gap-1"><Droplets size={11} strokeWidth={1.5} /> {meteo.humidity}%</span>
        </div>
      )}

      {data.cascade_alert?.active && (
        <div className="text-xs font-semibold text-red-400 mb-3 flex items-center gap-1.5">
          <AlertOctagon size={12} strokeWidth={2} /> Alerte cascade : {data.cascade_alert.message}
        </div>
      )}

      {data.recommendations?.length > 0 && (
        <ul className="space-y-1">
          {data.recommendations.slice(0, 2).map((rec, i) => (
            <li key={i} className={`text-xs flex gap-2 items-start ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>
              <ChevronRight size={11} className="text-[#00d4ff] mt-0.5 flex-none" strokeWidth={2} />
              {rec}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default function Alerts() {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';
  const [alerts, setAlerts] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all(ZONES.map((z) => api.airRealtime(z).then((d) => [z, d])))
      .then((entries) => setAlerts(Object.fromEntries(entries)))
      .finally(() => setLoading(false));
  }, []);

  const levels = Object.values(alerts).map((d) => d.global_alert_level);
  const globalLevel = levels.includes('rouge') ? 'rouge' : levels.includes('orange') ? 'orange' : 'vert';
  const gs = levelStyle(globalLevel);
  const { Icon: GlobalIcon } = gs;

  return (
    <div className="max-w-7xl mx-auto px-8 py-12 transition-colors duration-700">
      <div className="mb-10 flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className={`text-4xl font-bold tracking-tight mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>Alertes</h1>
          <p className={`text-lg ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>Suivi en temps réel des incidents environnementaux — Gabès.</p>
        </div>
        {!loading && (
          <span className={`flex items-center gap-2 px-4 py-2 rounded-2xl text-sm font-bold uppercase tracking-wider border ${gs.text} ${gs.border} ${gs.bg}`}>
            <GlobalIcon size={14} strokeWidth={2} />
            Niveau global : {gs.badge}
          </span>
        )}
      </div>

      {loading && <div className={`text-center py-24 text-lg font-medium animate-pulse ${isDark ? 'text-white/30' : 'text-gray-400'}`}>Chargement des alertes…</div>}

      {!loading && (
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {ZONES.map((z) =>
            alerts[z] ? (
              <AlertCard key={z} zoneId={z} data={alerts[z]} isDark={isDark} />
            ) : (
              <div key={z} className={`rounded-3xl border p-6 ${isDark ? 'border-white/5 bg-white/[0.02]' : 'border-gray-100 bg-white'}`}>
                <div className={`text-sm ${isDark ? 'text-white/30' : 'text-gray-400'}`}>Données indisponibles</div>
              </div>
            )
          )}
        </div>
      )}
    </div>
  );
}
