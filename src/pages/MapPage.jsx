import React, { useContext } from 'react';
import { ThemeContext } from '../App';

export default function MapPage() {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';

  return (
    <div className="max-w-7xl mx-auto px-8 py-12 transition-colors duration-700">
      <div className={`rounded-[40px] shadow-2xl border p-10 min-h-[600px] flex flex-col transition-all duration-700 ${
        isDark ? 'bg-[#0f172a]/50 border-white/5 shadow-black/20' : 'bg-white border-gray-200 shadow-gray-200/50'
      }`}>
        <div className="mb-8">
          <h1 className={`text-4xl font-bold tracking-tight mb-2 transition-colors duration-700 ${isDark ? 'text-white' : 'text-gray-900'}`}>Carte en Temps Réel</h1>
          <p className={`text-lg transition-colors duration-700 ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>Visualisation geo-spatiale des données environnementales de Gabès.</p>
        </div>
        
        {/* Placeholder para el Mapa */}
        <div className={`flex-grow rounded-3xl border-2 border-dashed flex items-center justify-center relative overflow-hidden group transition-all duration-700 ${
          isDark ? 'bg-white/5 border-white/10' : 'bg-gray-50 border-gray-200'
        }`}>
          <div className={`absolute inset-0 group-hover:bg-[#10b981]/5 transition-colors ${isDark ? 'bg-black/20' : 'bg-[#1e3a8a]/5'}`}></div>
          <div className="text-center z-10">
            <div className="text-6xl mb-4">🗺️</div>
            <p className={`font-medium transition-colors duration-700 ${isDark ? 'text-blue-100/20' : 'text-gray-400'}`}>L'intégration de Leaflet sera ici</p>
          </div>
        </div>
      </div>
    </div>
  );
}
