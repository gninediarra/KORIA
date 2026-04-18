import React, { useContext } from 'react';
import { ThemeContext } from '../App';

const AlertRow = ({ type, message, time, severity, isDark }) => (
  <div className={`flex items-center gap-6 p-6 border-b last:border-none transition-colors cursor-pointer ${
    isDark ? 'border-white/5 hover:bg-white/[0.02]' : 'border-gray-100 hover:bg-gray-50'
  }`}>
    <div className={`w-3 h-3 rounded-full ${severity === 'high' ? 'bg-red-500' : 'bg-amber-500'}`}></div>
    <div className="flex-grow">
      <div className={`font-semibold transition-colors ${isDark ? 'text-white' : 'text-gray-900'}`}>{message}</div>
      <div className={`text-sm font-medium uppercase tracking-wide transition-colors ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>{type}</div>
    </div>
    <div className={`font-medium text-sm transition-colors ${isDark ? 'text-blue-100/30' : 'text-gray-400'}`}>{time}</div>
  </div>
);

export default function Alerts() {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';

  return (
    <div className="max-w-7xl mx-auto px-8 py-12 transition-colors duration-700">
      <div className="mb-12">
        <h1 className={`text-4xl font-bold tracking-tight mb-2 transition-colors ${isDark ? 'text-white' : 'text-gray-900'}`}>Alertes</h1>
        <p className={`text-lg transition-colors ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>Suivi en temps réel des incidents environnementaux.</p>
      </div>

      <div className={`rounded-[40px] border overflow-hidden transition-all duration-700 ${
        isDark ? 'bg-[#0f172a]/50 border-white/5 shadow-2xl' : 'bg-white border-gray-200 shadow-sm'
      }`}>
        <div className={`p-8 border-b flex justify-between items-center transition-colors ${
          isDark ? 'bg-white/[0.02] border-white/5' : 'bg-gray-50/50 border-gray-100'
        }`}>
          <span className={`font-bold transition-colors ${isDark ? 'text-blue-100/60' : 'text-gray-700'}`}>Dernières Alertes</span>
          <button className="text-[#10b981] font-bold text-sm hover:text-[#059669] transition-colors">Tout marquer comme lu</button>
        </div>
        <div className="divide-y divide-transparent">
          <AlertRow isDark={isDark} type="Qualité Air" message="Pic de pollution détecté zone industrielle nord" time="Il y a 10 min" severity="high" />
          <AlertRow isDark={isDark} type="Système Eau" message="Fluctuation pH anormale - Secteur Chenini" time="Il y a 2h" severity="medium" />
          <AlertRow isDark={isDark} type="Capteurs" message="Maintenance requise station sol S-14" time="Il y a 5h" severity="medium" />
        </div>
      </div>
    </div>
  );
}
