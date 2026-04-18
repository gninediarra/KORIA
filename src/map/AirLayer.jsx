import React from 'react';
import { CircleMarker, Popup } from 'react-leaflet';
import { airData } from './fakeData';

function getAqiColor(aqi) {
  if (aqi <= 50) return '#22c55e';   // Bueno
  if (aqi <= 100) return '#eab308';  // Moderado
  if (aqi <= 150) return '#f97316';  // Insalubre para sensibles
  return '#ef4444';                   // Insalubre
}

export default function AirLayer() {
  return (
    <>
      {airData.map((point) => (
        <CircleMarker
          key={point.id}
          center={[point.lat, point.lng]}
          radius={10}
          pathOptions={{
            color: getAqiColor(point.aqi),
            fillColor: getAqiColor(point.aqi),
            fillOpacity: 0.6,
          }}
        >
          <Popup>
            <strong>🌫️ Sensor de Aire</strong><br />
            AQI: {point.aqi}<br />
            PM2.5: {point.pm25} µg/m³<br />
            CO₂: {point.co2} ppm
          </Popup>
        </CircleMarker>
      ))}
    </>
  );
}
