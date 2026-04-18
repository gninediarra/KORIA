import React, { useState } from 'react';
import { MapContainer, TileLayer } from 'react-leaflet';
import SoilLayer from './SoilLayer';
import WaterLayer from './WaterLayer';
import AirLayer from './AirLayer';
import 'leaflet/dist/leaflet.css';

const DEFAULT_CENTER = [40.4168, -3.7038]; // Madrid
const DEFAULT_ZOOM = 6;

export default function MapView() {
  const [activeLayers, setActiveLayers] = useState({
    soil: true,
    water: true,
    air: true,
  });

  const toggleLayer = (layer) => {
    setActiveLayers((prev) => ({ ...prev, [layer]: !prev[layer] }));
  };

  return (
    <div className="map-view" style={{ position: 'relative', width: '100%', height: '100%' }}>
      <MapContainer
        center={DEFAULT_CENTER}
        zoom={DEFAULT_ZOOM}
        style={{ width: '100%', height: '100%' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/">OSM</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {activeLayers.soil && <SoilLayer />}
        {activeLayers.water && <WaterLayer />}
        {activeLayers.air && <AirLayer />}
      </MapContainer>

      {/* Controles de capas */}
      <div className="layer-controls" style={{
        position: 'absolute', top: 10, right: 10, zIndex: 1000,
        background: 'rgba(0,0,0,0.7)', borderRadius: 8, padding: '8px 12px',
        display: 'flex', flexDirection: 'column', gap: 6,
      }}>
        {['soil', 'water', 'air'].map((layer) => (
          <label key={layer} style={{ color: '#fff', fontSize: 13, cursor: 'pointer' }}>
            <input
              type="checkbox"
              checked={activeLayers[layer]}
              onChange={() => toggleLayer(layer)}
              style={{ marginRight: 6 }}
            />
            {layer === 'soil' ? '🌱 Suelo' : layer === 'water' ? '💧 Agua' : '🌫️ Aire'}
          </label>
        ))}
      </div>
    </div>
  );
}
