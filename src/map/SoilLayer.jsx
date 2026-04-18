import React from 'react';
import { CircleMarker, Popup } from 'react-leaflet';
import { soilData } from './fakeData';

export default function SoilLayer() {
  return (
    <>
      {soilData.map((point) => (
        <CircleMarker
          key={point.id}
          center={[point.lat, point.lng]}
          radius={8}
          pathOptions={{
            color: '#4ade80',
            fillColor: point.humidity > 60 ? '#16a34a' : '#f97316',
            fillOpacity: 0.7,
          }}
        >
          <Popup>
            <strong>🌱 Sensor de Suelo</strong><br />
            Humedad: {point.humidity}%<br />
            pH: {point.ph}<br />
            Temp: {point.temperature}°C
          </Popup>
        </CircleMarker>
      ))}
    </>
  );
}
