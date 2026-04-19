import React, { useContext, useEffect, useState } from 'react';
import { Wind, CloudFog, Thermometer, AlertTriangle, Droplets, Layers, ChevronRight, Lightbulb } from 'lucide-react';
import { ThemeContext } from '../App';
import { api } from '../services/api';

const ZONE_LABELS = { gct: 'Zone GCT', ville: 'Centre-Ville', mer: 'Littoral', oasis: 'Oasis' };

const STATUS_STYLES = {
  vert:   { dot: 'bg-green-500',  text: 'text-green-400',  label: 'Sain' },
  orange: { dot: 'bg-orange-400', text: 'text-orange-400', label: 'Dégradé' },
  rouge:  { dot: 'bg-red-500',    text: 'text-red-400',    label: 'Critique' },
};
function statusStyle(s) { return STATUS_STYLES[s] || { dot: 'bg-gray-400', text: 'text-gray-400', label: s }; }

function aqiColor(aqi) {
  if (aqi <= 50) return 'text-green-400';
  if (aqi <= 100) return 'text-yellow-400';
  if (aqi <= 150) return 'text-orange-400';
  return 'text-red-400';
}

function StatCard({ Icon, iconColor, label, value, sub, isDark }) {
  return (
    <div className={`p-6 rounded-3xl border transition-all duration-700 ${isDark ? 'bg-white/[0.03] border-white/5' : 'bg-white border-gray-100 shadow-sm'}`}>
      <div className={`w-10 h-10 rounded-2xl flex items-center justify-center mb-4 ${isDark ? 'bg-white/5' : 'bg-gray-50'}`}>
        <Icon size={20} className={iconColor} strokeWidth={1.5} />
      </div>
      <div className={`text-xs font-semibold uppercase tracking-widest mb-1 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>{label}</div>
      <div className={`text-2xl font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{value}</div>
      {sub && <div className={`text-xs mt-1 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>{sub}</div>}
    </div>
  );
}

function ZoneCard({ zoneId, data, isDark }) {
  const sol = statusStyle(data.sol.status);
  const eau = statusStyle(data.eau.status);
  return (
    <div className={`p-6 rounded-3xl border transition-all duration-700 ${isDark ? 'bg-white/[0.03] border-white/5' : 'bg-white border-gray-100 shadow-sm'}`}>
      <div className={`font-bold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>{ZONE_LABELS[zoneId] || zoneId}</div>
      <div className="space-y-3">
        <div>
          <div className={`text-xs uppercase tracking-wider mb-1 flex items-center gap-1 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>
            <Layers size={11} strokeWidth={1.5} /> Sol
          </div>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className={`w-2 h-2 rounded-full ${sol.dot}`} />
              <span className={`text-sm font-medium ${sol.text}`}>{sol.label}</span>
            </div>
            <span className={`text-sm ${isDark ? 'text-white/60' : 'text-gray-600'}`}>{data.sol.health_score}/100</span>
          </div>
          <div className={`mt-1 h-1.5 rounded-full overflow-hidden ${isDark ? 'bg-white/10' : 'bg-gray-100'}`}>
            <div className="h-full rounded-full transition-all" style={{ width: `${data.sol.health_score}%`, background: data.sol.status === 'vert' ? '#22c55e' : data.sol.status === 'orange' ? '#f97316' : '#ef4444' }} />
          </div>
          <div className={`text-xs mt-1 ${isDark ? 'text-blue-100/20' : 'text-gray-400'}`}>Contamination : {data.sol.contamination_pct}%</div>
        </div>
        <div>
          <div className={`text-xs uppercase tracking-wider mb-1 flex items-center gap-1 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>
            <Droplets size={11} strokeWidth={1.5} /> Eau
          </div>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className={`w-2 h-2 rounded-full ${eau.dot}`} />
              <span className={`text-sm font-medium ${eau.text}`}>{eau.label}</span>
            </div>
            <span className={`text-sm ${isDark ? 'text-white/60' : 'text-gray-600'}`}>Turb. {data.eau.turbidite?.toFixed(2)}</span>
          </div>
          <div className={`text-xs mt-1 ${isDark ? 'text-blue-100/20' : 'text-gray-400'}`}>Contamination : {data.eau.contamination_pct}%</div>
        </div>
      </div>
    </div>
  );
}

export default function Dashboard() {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => { api.dashboard().then(setData).finally(() => setLoading(false)); }, []);

  return (
    <div className="max-w-7xl mx-auto px-8 py-12 transition-colors duration-700">
      <div className="mb-10">
        <h1 className={`text-4xl font-bold tracking-tight mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>Tableau de Bord</h1>
        <p className={`text-lg ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>Suivi des indicateurs environnementaux en temps réel — Gabès.</p>
      </div>

      {loading && <div className={`text-center py-24 text-lg font-medium animate-pulse ${isDark ? 'text-white/30' : 'text-gray-400'}`}>Chargement des données…</div>}

      {!loading && data && (
        <>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-10">
            <StatCard Icon={Wind}          iconColor="text-[#00d4ff]"  label="AQI (GCT)"      value={<span className={aqiColor(data.air_quality.aqi)}>{data.air_quality.aqi}</span>} sub={`Alerte : ${data.air_quality.alert_level}`} isDark={isDark} />
            <StatCard Icon={CloudFog}      iconColor="text-purple-400" label="SO₂"             value={`${data.air_quality.so2} µg/m³`} isDark={isDark} />
            <StatCard Icon={Thermometer}   iconColor="text-orange-400" label="Température"     value={data.meteo ? `${data.meteo.temperature}°C` : '—'} sub={data.meteo ? `Vent ${data.meteo.wind_speed} km/h` : ''} isDark={isDark} />
            <StatCard Icon={AlertTriangle} iconColor="text-red-400"    label="Alerte cascade"  value={data.cascade_alert?.active ? 'Active' : 'Inactive'} sub={data.cascade_alert?.message || ''} isDark={isDark} />
          </div>

          <h2 className={`text-xl font-bold mb-4 ${isDark ? 'text-white/70' : 'text-gray-700'}`}>Zones surveillées</h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-10">
            {Object.entries(data.zones).map(([zoneId, zoneData]) => (
              <ZoneCard key={zoneId} zoneId={zoneId} data={zoneData} isDark={isDark} />
            ))}
          </div>

          {data.recommendations?.length > 0 && (
            <div className={`rounded-3xl border p-6 transition-all duration-700 ${isDark ? 'bg-white/[0.03] border-white/5' : 'bg-white border-gray-100 shadow-sm'}`}>
              <h2 className={`font-bold mb-4 flex items-center gap-2 ${isDark ? 'text-white/70' : 'text-gray-700'}`}>
                <Lightbulb size={16} className="text-yellow-400" strokeWidth={1.5} /> Recommandations
              </h2>
              <ul className="space-y-2">
                {data.recommendations.map((rec, i) => (
                  <li key={i} className={`text-sm flex gap-3 items-start ${isDark ? 'text-blue-100/50' : 'text-gray-600'}`}>
                    <ChevronRight size={14} className="text-[#00d4ff] mt-0.5 flex-none" strokeWidth={2} />
                    {rec}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </>
      )}
    </div>
  );
}
