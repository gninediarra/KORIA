// HTTP: CRA proxy (package.json "proxy") → http://localhost:8002
// WS:  CRA proxy does NOT proxy WebSockets — direct connection
const WS_BASE  = process.env.REACT_APP_WS_URL || 'ws://localhost:8002';
const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8002';

export const wsUrl = (path) => `${WS_BASE}${path}`;

async function get(path) {
  const res = await fetch(path);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

async function post(path, body) {
  const res = await fetch(path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

// ── Mock data ────────────────────────────────────────────────────────────────

const MOCK_ZONE = (id) => ({
  sol: { health_score: 62, contamination_pct: 38, status: 'orange' },
  eau: { turbidite: 0.34, contamination_pct: 22, status: 'orange' },
  zone_info: { nom: id },
});

const MOCK_DASHBOARD = {
  timestamp: new Date().toISOString(),
  zones: { gct: MOCK_ZONE('gct'), ville: MOCK_ZONE('ville'), mer: MOCK_ZONE('mer'), oasis: MOCK_ZONE('oasis') },
  air_quality: { aqi: 112, alert_level: 'orange', so2: 48, pm10: 67 },
  meteo: { temperature: 24, wind_speed: 14, humidity: 58 },
  cascade_alert: { active: false, message: '' },
  recommendations: [
    "Éviter les activités en plein air près de la zone GCT.",
    "Surveiller la qualité de l'eau du littoral.",
  ],
};

const MOCK_AIR = {
  global_alert_level: 'orange',
  air_quality: { aqi: 112, so2: 48, pm10: 67 },
  meteo: { temperature: 24, wind_speed: 14, humidity: 58 },
  cascade_alert: { active: false, message: '' },
  recommendations: ['Données de démonstration — backend hors ligne.'],
};

const MOCK_MAP = {
  type: 'FeatureCollection',
  features: [
    { type: 'Feature', geometry: { type: 'Polygon', coordinates: [[[9.85,33.78],[10.05,33.78],[10.05,33.92],[9.85,33.92],[9.85,33.78]]] }, properties: { zone_id: 'gct',   nom: 'Zone GCT',    couleur: '#e74c3c', sol_status: 'rouge',  sol_health: 42, sol_contamination_pct: 58, eau_status: 'rouge',  eau_turbidite: 0.72 } },
    { type: 'Feature', geometry: { type: 'Polygon', coordinates: [[[9.95,33.85],[10.10,33.85],[10.10,33.98],[9.95,33.98],[9.95,33.85]]] }, properties: { zone_id: 'ville', nom: 'Centre-Ville', couleur: '#f39c12', sol_status: 'orange', sol_health: 61, sol_contamination_pct: 39, eau_status: 'orange', eau_turbidite: 0.31 } },
    { type: 'Feature', geometry: { type: 'Polygon', coordinates: [[[10.05,33.75],[10.25,33.75],[10.25,34.05],[10.05,34.05],[10.05,33.75]]] }, properties: { zone_id: 'mer',   nom: 'Littoral',    couleur: '#3498db', sol_status: 'orange', sol_health: 55, sol_contamination_pct: 45, eau_status: 'rouge',  eau_turbidite: 0.65 } },
    { type: 'Feature', geometry: { type: 'Polygon', coordinates: [[[9.88,33.87],[10.00,33.87],[10.00,33.95],[9.88,33.95],[9.88,33.87]]] }, properties: { zone_id: 'oasis', nom: 'Oasis',        couleur: '#27ae60', sol_status: 'vert',   sol_health: 74, sol_contamination_pct: 26, eau_status: 'orange', eau_turbidite: 0.28 } },
  ],
  air_quality: { aqi: 112, so2: 48, pm10: 67 },
  meteo: { temperature: 24, wind_speed: 14 },
  pollution_sources: [
    { id: 'cheminee_gct_1', nom: 'Cheminée GCT Principale', lat: 33.852, lon: 9.978, hauteur_m: 120, debit_so2_g_s: 85 },
    { id: 'cheminee_gct_2', nom: 'Cheminée GCT Secondaire', lat: 33.848, lon: 9.965, hauteur_m: 80,  debit_so2_g_s: 45 },
  ],
  timestamp: new Date().toISOString(),
};

const MOCK_DRONE_STATUS = {
  status: 'available',
  drone_model: 'DJI Mini 3 Pro (Digital Twin)',
  payload: ['Caméra thermique FLIR', 'Caméra multispectrale MicaSense', 'NVIDIA Jetson Nano'],
  max_flight_time_min: 38,
  max_range_km: 12,
};

const MOCK_THERMAL = {
  temp_min_c: 28.4, temp_max_c: 51.2, temp_mean_c: 34.7,
  anomaly_detected: true, anomaly_delta_c: 14.3, hotspot_pct: 2.81, image_b64: null,
};

// Offline fallback responses — proper UTF-8
const MOCK_CHAT = {
  fr: "Je suis désolé, le serveur est temporairement indisponible. Veuillez réessayer dans quelques instants.",
  en: "Sorry, the server is temporarily unavailable. Please try again in a moment.",
  ar: "عذراً، الخادم غير متاح مؤقتاً. يرجى المحاولة مرة أخرى بعد قليل.",
};

// ── Public API ───────────────────────────────────────────────────────────────

export const api = {
  health:       () => get('/health'),
  dashboard:    () => get('/dashboard').catch(() => MOCK_DASHBOARD),
  mapLiving:    () => get('/map/living').catch(() => MOCK_MAP),
  airRealtime:  (zoneId) => get(`/air/${zoneId}/realtime`).catch(() => MOCK_AIR),
  droneStatus:  () => get('/drone/status').catch(() => MOCK_DRONE_STATUS),
  droneThermal: (lat, lon, zoneId) =>
    get(`/drone/thermal?lat=${lat}&lon=${lon}&zone_id=${zoneId}`).catch(() => MOCK_THERMAL),
  chat: (body) =>
    post('/agent/chat', body).catch(() => ({
      response: MOCK_CHAT[body.langue] || MOCK_CHAT.fr,
    })),
  ttsUrl: (text, lang = 'fr') =>
    `${API_BASE}/api/tts?text=${encodeURIComponent(text)}&lang=${lang}`,
};
