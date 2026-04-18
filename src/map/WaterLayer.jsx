import React from 'react';
import { CircleMarker, Popup } from 'react-leaflet';
import { waterData } from './fakeData';

export default function WaterLayer() {
  return (
    <>
      {waterData.map((point) => (
        <CircleMarker
          key={point.id}
          center={[point.lat, point.lng]}
          radius={8}
          pathOptions={{
            color: '#38bdf8',
            fillColor: point.quality === 'buena' ? '#0ea5e9' : '#ef4444',
            fillOpacity: 0.7,
          }}
        >
          <Popup>
            <strong>💧 Sensor de Agua</strong><br />
            Calidad: {point.quality}<br />
            Nivel: {point.level} m<br />
            Turbidez: {point.turbidity} NTU
          </Popup>
        </CircleMarker>
      ))}
    </>
  );
}
