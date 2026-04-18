import React, { useContext } from 'react';
import { ThemeContext } from '../App';

const StatCard = ({ label, value, color, icon, isDark }) => (
  <div className={`p-8 rounded-3xl border transition-all duration-700 ${
    isDark ? 'bg-white/[0.03] border-white/5 shadow-2xl' : 'bg-white border-gray-100 shadow-sm hover:shadow-md'
  }`}>
    <div className="flex justify-between items-start mb-4">
      <div className={`w-12 h-12 rounded-2xl flex items-center justify-center text-2xl transition-colors ${
        isDark ? 'bg-white/5' : `bg-${color}-50 text-${color}-600`
      }`}>
        {icon}
      </div>
    </div>
    <div className={`text-sm font-semibold uppercase tracking-wider mb-1 ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>{label}</div>
    <div className={`text-3xl font-bold transition-colors ${isDark ? 'text-white' : 'text-gray-900'}`}>{value}</div>
  </div>
);

export default function Dashboard() {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';

  return (
    <div className="max-w-7xl mx-auto px-8 py-12 transition-colors duration-700">
      <div className="mb-12">
        <h1 className={`text-4xl font-bold tracking-tight mb-2 transition-colors ${isDark ? 'text-white' : 'text-gray-900'}`}>Tableau de Bord</h1>
        <p className={`text-lg transition-colors ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>Suivi des indicateurs de performance environnementale.</p>
      </div>

      <div className="grid md:grid-cols-4 gap-6 mb-12">
        <StatCard label="Air Quality" value="98.2 AQI" color="green" icon="💨" isDark={isDark} />
        <StatCard label="Water pH" value="7.4" color="blue" icon="💧" isDark={isDark} />
        <StatCard label="Soil Health" value="85%" color="amber" icon="🌱" isDark={isDark} />
        <StatCard label="Active Sensors" value="124" color="purple" icon="🛰️" isDark={isDark} />
      </div>

      <div className={`rounded-[40px] border p-10 h-96 flex items-center justify-center transition-all duration-700 ${
        isDark ? 'bg-[#0f172a]/50 border-white/5 shadow-2xl' : 'bg-white border-gray-200 shadow-sm'
      }`}>
        <div className="text-center">
          <p className={`font-medium transition-colors ${isDark ? 'text-blue-100/20' : 'text-gray-400'}`}>Graphiques et statistiques en cours de chargement...</p>
        </div>
      </div>
    </div>
  );
}
