# GabèsEye — AI Environmental Monitoring Dashboard

> **H12 Innovation Hackathon — *AI Healing Gabès***
> Surveillance environnementale en temps réel de la région de Gabès, Tunisie.

---

## Présentation

**GabèsEye** est une plateforme d'intelligence artificielle pour surveiller et prédire la contamination environnementale autour du complexe chimique GCT (Groupe Chimique Tunisien) à Gabès.

Le projet couvre trois axes :

| Axe | Modèles | Données |
|-----|---------|---------|
| **Sol** | U-Net EfficientNet-B3 + BiLSTM + Mahalanobis | Sentinel-2 L2A (20 m), 5 bandes |
| **Eau** | U-Net EfficientNet-B3 + BiLSTM | Sentinel-2 L2A, 6 bandes |
| **Air** | XGBoost + BiLSTM + Plume Gaussienne | Open-Meteo API (temps réel) |

**LLM** : Groq Llama-3.3-70b-versatile — agents multilingues FR / AR / EN / Tamazight  
**Drone** : Digital Twin DJI Mini 3 Pro avec caméra thermique FLIR simulée (Jetson Nano)

---

## Architecture technique

```
GabèsEye/
├── backend/
│   ├── main.py                  # FastAPI — tous les endpoints (port 8002)
│   ├── requirements.txt
│   ├── .env                     # GROQ_API_KEY (non versionné)
│   ├── data/
│   │   └── zones.json           # Définition des 4 zones géographiques
│   ├── models/                  # Poids PyTorch + XGBoost
│   │   ├── unet_finetuned.pth   # U-Net Sol
│   │   ├── unet_eau_final.pth   # U-Net Eau
│   │   ├── lstm_best.pth        # BiLSTM Sol
│   │   ├── lstm_eau_best.pth    # BiLSTM Eau
│   │   ├── lstm_air_best.pth    # BiLSTM Air
│   │   └── xgb_air.pkl          # XGBoost Air
│   ├── services/
│   │   ├── zone_engine.py       # U-Net inference + Mahalanobis
│   │   ├── lstm_engine.py       # BiLSTM prédictions sol/eau/air
│   │   ├── alert_engine.py      # XGBoost + Plume Gaussienne + Open-Meteo
│   │   ├── agent_engine.py      # Agents Groq LLM multilingues
│   │   └── drone_engine.py      # Digital Twin + simulation thermique FLIR
│   └── static/
│       └── index.html           # Dashboard SPA (Vanilla JS + Leaflet)
```

---

## Endpoints API

### Santé
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/health` | Ping |
| `GET` | `/api/status` | Statut global |

### Sol
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/sol/{zone_id}` | U-Net segmentation + Mahalanobis |
| `GET` | `/sol/{zone_id}/timeline` | Historique contamination 2018→2025 |
| `GET` | `/sol/{zone_id}/predict?steps=12` | BiLSTM — 12 mois par défaut |
| `GET` | `/sol/{zone_id}/crop-yield` | Impact rendement agricole 2024-2030 |

### Eau
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/eau/{zone_id}` | Turbidité + anomalies |
| `GET` | `/eau/{zone_id}/predict?steps=12` | BiLSTM turbidité |

### Air
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/air/{zone_id}/realtime` | XGBoost + Open-Meteo temps réel |
| `GET` | `/air/{zone_id}/predict?steps=30` | BiLSTM AQI 30 jours |
| `GET` | `/air/plume/{zone_id}` | Plume Gaussienne SO₂ (Pasquill-Gifford) |

### Dashboard & Carte
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/dashboard` | Snapshot toutes zones + météo |
| `GET` | `/map/living` | GeoJSON Leaflet — statut en direct |

### Agents IA (Groq Llama-3.3-70b)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/agent/chat` | Chat multilingue multi-tour |
| `POST` | `/agent/agriculteur` | Recommandations sol + météo |
| `POST` | `/agent/pecheur` | Qualité eau + météo marine |
| `POST` | `/agent/citoyen` | Alerte qualité de l'air |
| `POST` | `/agent/autorite` | Rapport officiel multi-axes |
| `POST` | `/agent/health-risk` | Évaluation risque santé personnalisé |

### Drone & Voix
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/drone/status` | Statut Digital Twin |
| `GET` | `/drone/thermal?zone_id=gct` | Image thermique FLIR 512×512 PNG base64 |
| `WS` | `/ws/drone/{mission_id}` | Télémétrie temps réel (1 paquet/s) |
| `WS` | `/ws/live/{role}` | Mises à jour environnementales 30s |
| `GET` | `/api/tts?text=...&lang=fr` | Text-to-speech gTTS (FR/EN/AR) |
| `POST` | `/api/transcribe?lang=ar` | Transcription Groq Whisper large-v3-turbo |

---

## Modèles IA

### U-Net Sol — `unet_finetuned.pth`
- Architecture : U-Net + EfficientNet-B3 encoder
- Entrée : 5 canaux (B2, B3, B4, B8, B11 Sentinel-2)
- Sortie : 5 classes — `vegetation`, `sol_agricole`, `sol_nu`, `sol_degrade`, `contamine_gct`
- Val accuracy : **88.8%**

### U-Net Eau — `unet_eau_final.pth`
- Architecture : U-Net + EfficientNet-B3 encoder
- Entrée : 6 canaux (B2, B3, B4, B8, B11, B12)
- Sortie : 5 classes — turbidité, sédiments, contamination
- Val accuracy : **77.2%**

### BiLSTM Sol/Eau — `lstm_best.pth` / `lstm_eau_best.pth`
- Architecture : BiLSTM, hidden=64, layers=2, dropout=0.2
- Entrée : séquence de 24 pas, 4 features
- Sortie : prédiction 1-60 pas (mensuel/journalier/horaire)
- MSE ≈ **0.019 / 0.032**

### BiLSTM Air — `lstm_air_best.pth`
- Architecture : BiLSTM, hidden=128, layers=2
- Entrée : séquence 24 pas, 4 features météo
- Sortie : AQI prédit 1-90 jours
- MSE : **0.012**

### XGBoost Air — `xgb_air.pkl`
- 7 features : température, humidité, vitesse vent, direction, pression, SO₂ estimé, PM10
- Classes : bon / modéré / mauvais / très_mauvais / dangereux
- Accuracy : **86.9%**

### Plume Gaussienne (Pasquill-Gifford)
- Modèle analytique SO₂ — classes A (très instable) → F (très stable)
- Paramètres : Q=85 kg/h, H=120 m cheminée GCT
- Retourne grille de concentration + isocontours

---

## Simulation Thermique FLIR

Rendu haute fidélité sur le backend :
- **Sources industrielles** : 5 hotspots Gaussiens calibrés sur GCT (cheminées, bassins, rejets)
- **Végétation** : patches de refroidissement aléatoires selon la zone
- **Bruit corrélé spatialement** : block noise 16×16
- **Traitement** : `scipy.ndimage.gaussian_filter(σ=3.0)` → **colormap FLIR Iron** (10 stops) → `PIL LANCZOS 512×512` → PNG base64

### Zones disponibles
| zone_id | Description |
|---------|-------------|
| `gct` | Zone industrielle GCT — 5 hotspots phosphates/cheminées |
| `mer` | Littoral Gabès — turbidité thermique marine |
| `oasis` | Oasis Chott el-Fejij — végétation cooling |
| `ville` | Centre-ville — chaleur urbaine + industrie périphérique |

---

## Digital Twin Drone

Simulation d'un **DJI Mini 3 Pro** équipé NVIDIA Jetson Nano :

**Phases de mission** : `idle → takeoff → transit → scanning → return → landing → complete`

**Waypoints GCT** (4 points de scan) :
- GCT_Nord : 33.852°N, 9.978°E
- GCT_Centre : 33.848°N, 9.990°E
- GCT_Sud : 33.840°N, 9.975°E
- GCT_Ouest : 33.855°N, 9.965°E

**Chaque paquet télémétrié** contient : position GPS, batterie, capteurs air (SO₂, PM10, T°, humidité), statut Jetson (CPU/GPU/°C), résultats inférence IA (segmentation + thermique), alertes batterie.

---

## Installation

```bash
# 1. Cloner
git clone https://github.com/gninediarra/KORIA.git
cd KORIA
git checkout Mané

# 2. Environnement Python
python -m venv venv
source venv/bin/activate          # Linux/Mac
venv\Scripts\activate             # Windows

# 3. Dépendances
pip install -r backend/requirements.txt

# 4. Variables d'environnement
echo "GROQ_API_KEY=gsk_your_key_here" > backend/.env

# 5. Lancer le serveur
cd backend
python main.py
# → http://localhost:8002
```

### Dépendances principales
```
fastapi>=0.111.0        # Framework API
uvicorn[standard]       # Serveur ASGI
torch>=2.0.0            # PyTorch — U-Net + BiLSTM
segmentation-models-pytorch  # EfficientNet-B3 backbone
xgboost>=2.0.0          # Classificateur air
numpy==1.26.4
scipy>=1.11.0           # Gaussian filter thermal
Pillow>=10.0.0          # FLIR Iron PNG rendering
gtts>=2.3.0             # Text-to-speech (FR/EN/AR)
aiohttp>=3.9.0          # Groq API + Open-Meteo
python-multipart        # Upload audio (transcription)
```

---

## Chatbot Vocal Multilingue

Le dashboard intègre un assistant IA flottant :

- **3 langues** : Français 🇫🇷 · English 🇬🇧 · عربي 🇹🇳
- **TTS** : gTTS backend (`/api/tts`) — arabe natif sans bug navigateur
- **STT** : MediaRecorder API → Groq Whisper `whisper-large-v3-turbo` (`/api/transcribe`)
- **Message de bienvenue** : données réelles `/dashboard` injectées dans le prompt Llama
- **Historique** : 8 derniers échanges transmis à Groq pour contexte multi-tour

---

## Zones surveillées

| Zone | Coordonnées | Problématique |
|------|-------------|---------------|
| **GCT** | 33.85°N, 9.98°E | Contamination phosphates, SO₂, rejets industriels |
| **Mer** | 33.88°N, 10.05°E | Turbidité, rejets liquides, perturbation écosystème marin |
| **Oasis** | 33.92°N, 9.87°E | Impact irrigation, salinisation, dégradation végétation |
| **Ville** | 33.88°N, 10.10°E | Pollution urbaine, chaleur, poussières phosphatées |

---

## Équipe

**M10-3** — H12 Innovation Hackathon  
Contact : [onanamiguel1234@gmail.com](mailto:onanamiguel1234@gmail.com)

---

## Licence

Projet développé dans le cadre du hackathon H12 — *AI Healing Gabès*.  
Usage académique et de recherche.
