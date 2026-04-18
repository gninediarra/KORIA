// ── Datos simulados de sensores ambientales ──

export const soilData = [
  { id: 's1', lat: 40.4168, lng: -3.7038, humidity: 72, ph: 6.8, temperature: 18 },
  { id: 's2', lat: 41.3851, lng: 2.1734,  humidity: 45, ph: 7.2, temperature: 21 },
  { id: 's3', lat: 37.3891, lng: -5.9845, humidity: 63, ph: 6.5, temperature: 24 },
  { id: 's4', lat: 39.4699, lng: -0.3763, humidity: 38, ph: 7.8, temperature: 22 },
  { id: 's5', lat: 43.2630, lng: -2.9350, humidity: 80, ph: 6.1, temperature: 15 },
];

export const waterData = [
  { id: 'w1', lat: 40.4530, lng: -3.6883, quality: 'buena',  level: 3.2, turbidity: 12 },
  { id: 'w2', lat: 41.4000, lng: 2.1900,  quality: 'mala',   level: 1.8, turbidity: 85 },
  { id: 'w3', lat: 37.4000, lng: -5.9700, quality: 'buena',  level: 4.5, turbidity: 8 },
  { id: 'w4', lat: 39.4800, lng: -0.3600, quality: 'mala',   level: 2.1, turbidity: 67 },
  { id: 'w5', lat: 43.2700, lng: -2.9500, quality: 'buena',  level: 5.0, turbidity: 5 },
];

export const airData = [
  { id: 'a1', lat: 40.4300, lng: -3.7100, aqi: 42,  pm25: 12, co2: 410 },
  { id: 'a2', lat: 41.3900, lng: 2.1600,  aqi: 98,  pm25: 35, co2: 480 },
  { id: 'a3', lat: 37.3800, lng: -5.9900, aqi: 55,  pm25: 18, co2: 430 },
  { id: 'a4', lat: 39.4600, lng: -0.3800, aqi: 130, pm25: 55, co2: 520 },
  { id: 'a5', lat: 43.2500, lng: -2.9400, aqi: 30,  pm25: 8,  co2: 395 },
];
