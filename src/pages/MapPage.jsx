import React, { useContext, useEffect, useState } from 'react';
import { MapContainer, TileLayer, Polygon, Popup, CircleMarker } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { ThemeContext } from '../App';
import { api } from '../services/api';

// Fix default marker icons broken by webpack
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
});

const GABES_CENTER = [33.88, 10.0];
const GABES_ZOOM = 12;

const STATUS_COLOR = { vert: '#22c55e', orange: '#f97316', rouge: '#ef4444' };

function statusColor(status) {
  return STATUS_COLOR[status] || '#94a3b8';
}

function aqiLabel(aqi) {
  if (aqi <= 50) return { label: 'Bon', color: '#22c55e' };
  if (aqi <= 100) return { label: 'Modéré', color: '#eab308' };
  if (aqi <= 150) return { label: 'Mauvais', color: '#f97316' };
  return { label: 'Dangereux', color: '#ef4444' };
}

export default function MapPage() {
  const { theme } = useContext(ThemeContext);
  const isDark = theme === 'dark';
  const [mapData, setMapData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeLayer, setActiveLayer] = useState('sol');

  useEffect(() => {
    api.mapLiving().then(setMapData).finally(() => setLoading(false));
  }, []);

  const aqi = mapData?.air_quality;
  const aqiInfo = aqi ? aqiLabel(aqi.aqi) : null;

  return (
    <div className="max-w-7xl mx-auto px-8 py-12">
      <div className="mb-8 flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className={`text-4xl font-bold tracking-tight mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>
            Carte en Temps Réel
          </h1>
          <p className={`text-lg ${isDark ? 'text-blue-100/40' : 'text-gray-500'}`}>
            Visualisation géo-spatiale des données environnementales de Gabès.
          </p>
        </div>

        {/* Layer toggle */}
        <div className="flex gap-2">
          {['sol', 'eau', 'air'].map((l) => (
            <button
              key={l}
              onClick={() => setActiveLayer(l)}
              className={`px-4 py-2 rounded-2xl text-sm font-semibold uppercase tracking-wider transition-all border ${
                activeLayer === l
                  ? 'bg-[#00d4ff] text-[#080e1a] border-[#00d4ff]'
                  : isDark
                  ? 'bg-white/5 text-white/60 border-white/10 hover:border-[#00d4ff]'
                  : 'bg-white text-gray-500 border-gray-200 hover:border-[#00d4ff]'
              }`}
            >
              {l === 'sol' ? '🌱 Sol' : l === 'eau' ? '💧 Eau' : '💨 Air'}
            </button>
          ))}
        </div>
      </div>

      {/* AQI banner */}
      {aqiInfo && (
        <div
          className={`mb-4 px-6 py-3 rounded-2xl flex items-center gap-4 border text-sm font-medium ${
            isDark ? 'bg-white/5 border-white/10' : 'bg-white border-gray-200'
          }`}
        >
          <span className="w-3 h-3 rounded-full" style={{ background: aqiInfo.color }} />
          <span className={isDark ? 'text-white/80' : 'text-gray-700'}>
            Qualité de l'air (GCT) — AQI&nbsp;
            <strong style={{ color: aqiInfo.color }}>{aqi.aqi}</strong>
            &nbsp;({aqiInfo.label}) · SO₂&nbsp;{aqi.so2}&nbsp;µg/m³ · PM10&nbsp;{aqi.pm10}&nbsp;µg/m³
          </span>
          {mapData?.meteo && (
            <span className={`ml-auto ${isDark ? 'text-white/40' : 'text-gray-400'}`}>
              🌡️ {mapData.meteo.temperature}°C · 💨 {mapData.meteo.wind_speed} km/h
            </span>
          )}
        </div>
      )}

      {/* Map container */}
      <div
        className={`rounded-[32px] overflow-hidden border shadow-2xl transition-all duration-700 ${
          isDark ? 'border-white/10 shadow-black/30' : 'border-gray-200'
        }`}
        style={{ height: 560 }}
      >
        {loading && (
          <div className={`w-full h-full flex items-center justify-center ${isDark ? 'bg-[#0f172a]' : 'bg-gray-50'}`}>
            <span className={`text-lg font-medium animate-pulse ${isDark ? 'text-white/40' : 'text-gray-400'}`}>
              Chargement de la carte…
            </span>
          </div>
        )}
        {!loading && mapData && (
          <MapContainer center={GABES_CENTER} zoom={GABES_ZOOM} style={{ width: '100%', height: '100%' }}>
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/">OSM</a>'
              url={
                isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
              }
            />

            {/* Zone polygons */}
            {mapData.features.map((f) => {
              const p = f.properties;
              const color =
                activeLayer === 'sol'
                  ? statusColor(p.sol_status)
                  : activeLayer === 'eau'
                  ? statusColor(p.eau_status)
                  : p.couleur;

              // GeoJSON coords are [lon, lat]; Leaflet needs [lat, lon]
              const positions = f.geometry.coordinates[0].map(([lon, lat]) => [lat, lon]);

              return (
                <Polygon
                  key={p.zone_id}
                  positions={positions}
                  pathOptions={{ color, fillColor: color, fillOpacity: 0.35, weight: 2 }}
                >
                  <Popup>
                    <div style={{ minWidth: 180 }}>
                      <strong>{p.nom}</strong>
                      <br />
                      Sol : {p.sol_contamination_pct}% contaminé ({p.sol_status})
                      <br />
                      Eau : turbidité {p.eau_turbidite?.toFixed(2)} ({p.eau_status})
                      <br />
                      Score santé sol : {p.sol_health}/100
                    </div>
                  </Popup>
                </Polygon>
              );
            })}

            {/* Pollution sources */}
            {mapData.pollution_sources?.map((src) => (
              <CircleMarker
                key={src.id}
                center={[src.lat, src.lon]}
                radius={8}
                pathOptions={{ color: '#ef4444', fillColor: '#ef4444', fillOpacity: 0.8 }}
              >
                <Popup>
                  <strong>🏭 {src.nom}</strong>
                  <br />
                  Hauteur : {src.hauteur_m} m
                  <br />
                  SO₂ : {src.debit_so2_g_s} g/s
                </Popup>
              </CircleMarker>
            ))}
          </MapContainer>
        )}
      </div>

      {/* Legend */}
      {!loading && mapData && (
        <div className={`mt-4 flex flex-wrap gap-4 text-sm font-medium ${isDark ? 'text-white/50' : 'text-gray-500'}`}>
          {[
            { color: '#22c55e', label: 'Vert (sain)' },
            { color: '#f97316', label: 'Orange (dégradé)' },
            { color: '#ef4444', label: 'Rouge (critique)' },
            { color: '#ef4444', label: '● Source pollution' },
          ].map(({ color, label }) => (
            <span key={label} className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full inline-block" style={{ background: color }} />
              {label}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
