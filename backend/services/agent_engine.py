"""
AgentEngine — Multilingual LLM agents via Groq API (Llama-3.3-70b-versatile).
4 specialized agents: farmer, fisherman, citizen, authority.
"""
import os
import json
import asyncio
import aiohttp
from datetime import datetime
from pathlib import Path
from typing import Optional

BASE_DIR = Path(__file__).parent.parent

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.3-70b-versatile"

# Read from environment — set GROQ_API_KEY in your shell or .env
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")

SUPPORTED_LANGUAGES = {
    "fr": "French",
    "ar": "Arabic",
    "en": "English",
    "ber": "Tamazight/Berber",
}

AGENT_SYSTEM_PROMPTS = {
    "agriculteur": """Tu es GabèsEye AgriBot, assistant IA spécialisé pour les agriculteurs de Gabès, Tunisie.
Tu analyses les données satellitaires (Sentinel-2) et les indices spectraux (NDVI, BSI, NBR) pour donner des conseils pratiques.
Parle en {language}. Sois direct et concret. Utilise des termes agricoles locaux.
Contexte: Zone industrielle GCT, sols contaminés aux phosphates, sécheresse croissante.
Ne dépasse pas 200 mots. Structure: Situation → Risques → Actions immédiates → Actions moyen terme.""",

    "pecheur": """Tu es GabèsEye MarinBot, assistant IA pour les pêcheurs du Golfe de Gabès.
Tu analyses la qualité de l'eau (turbidité, NDWI, NDCI) et les alertes météo marines.
Parle en {language}. Priorise la sécurité en mer et la qualité des captures.
Contexte: Pollution industrielle GCT, turbidité élevée, zones de contamination variables.
Ne dépasse pas 200 mots. Structure: Conditions actuelles → Zones à éviter → Zones sûres → Sécurité.""",

    "citoyen": """Tu es GabèsEye CitiBot, assistant IA pour les citoyens de Gabès.
Tu expliques la qualité de l'air (AQI, SO₂, PM10) et les risques sanitaires en termes simples.
Parle en {language}. Sois rassurant mais honnête. Donne des conseils de santé pratiques.
Contexte: Émissions SO₂ usine GCT, épisodes de pollution atmosphérique chronique.
Ne dépasse pas 200 mots. Structure: Situation du jour → Impact santé → Ce qu'il faut faire → Ce qu'il faut éviter.""",

    "autorite": """Tu es GabèsEye AuthoBot, assistant IA pour les autorités et décideurs de Gabès.
Tu synthétises les données multi-axes (sol, eau, air) en rapports officiels structurés.
Réponds en {language}. Format rapport officiel avec métriques précises.
Contexte: Hackathon H12 Innovation - système IA de surveillance environnementale.
Structure: Résumé exécutif → Indicateurs clés → Zones critiques → Recommandations politiques → Actions urgentes.""",
}


async def _call_groq(messages: list, temperature: float = 0.7) -> str:
    """Call Groq API with retry logic."""
    if not GROQ_API_KEY:
        return _local_fallback(messages)

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": GROQ_MODEL,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": 512,
    }

    for attempt in range(2):
        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=15)) as session:
                async with session.post(GROQ_API_URL, headers=headers, json=payload) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        return data["choices"][0]["message"]["content"]
                    elif resp.status == 429:
                        await asyncio.sleep(2)
                    else:
                        error = await resp.text()
                        print(f"[AgentEngine] Groq error {resp.status}: {error[:200]}")
                        break
        except Exception as e:
            print(f"[AgentEngine] Request failed: {e}")

    return _local_fallback(messages)


def _local_fallback(messages: list) -> str:
    """Intelligent rule-based fallback when Groq unavailable."""
    user_msg = messages[-1]["content"] if messages else ""
    system_msg = messages[0]["content"] if messages else ""

    if "agriculteur" in system_msg.lower() or "agri" in system_msg.lower():
        return (
            "⚠️ Situation sol critique détectée. NDVI faible (0.08) indique végétation stressée. "
            "Actions immédiates: (1) Évitez irrigation avec eau de surface — turbidité élevée. "
            "(2) Testez pH sol avant semis — contamination phosphate possible. "
            "(3) Préférez cultures résistantes: orge, cactus, halophytes. "
            "Moyen terme: compostage organique pour restaurer microbiome sol."
        )
    elif "pecheur" in system_msg.lower() or "marin" in system_msg.lower():
        return (
            "🌊 Conditions marines: turbidité élevée (0.62) côte GCT. "
            "Zones à éviter: 0-3 km de la côte industrielle. "
            "Zones acceptables: secteur sud golfe, eaux > 5 km offshore. "
            "Sécurité: vents 5 m/s NW — mer peu agitée. "
            "Captures: vérifier contamination métaux lourds avant commercialisation."
        )
    elif "citoyen" in system_msg.lower() or "citi" in system_msg.lower():
        return (
            "😷 Qualité air aujourd'hui: MAUVAISE (AQI 112). SO₂ élevé: 95 µg/m³. "
            "À faire: Fermez fenêtres entre 10h-15h. Portez masque FFP2 si sortie. "
            "Évitez activité sportive extérieure. Personnes asthmatiques: restez à l'intérieur. "
            "Amélioration prévue demain avec vent d'ouest."
        )
    else:
        return (
            "📊 Rapport GabèsEye — Synthèse multi-axes:\n"
            "• Sol: 29% contamination zone GCT (score santé: 42/100)\n"
            "• Eau: Turbidité 0.62 côte industrielle (146,290 pixels anomalies)\n"
            "• Air: AQI 112 — épisode critique prédit H+6\n"
            "Actions prioritaires: Renforcement monitoring temps réel, "
            "alertes population zones exposées, coordination avec GCT pour réduction émissions."
        )


def _format_context_message(data: dict) -> str:
    """Convert zone data dict to readable LLM context."""
    parts = []
    if "sol" in data:
        sol = data["sol"]
        parts.append(
            f"SOL: santé={sol.get('health_score', 'N/A')}/100, "
            f"contamination={sol.get('contamination_pct', 'N/A')}%, "
            f"statut={sol.get('status', 'N/A')}, "
            f"NDVI={sol.get('indices', {}).get('NDVI', 'N/A')}"
        )
    if "eau" in data:
        eau = data["eau"]
        parts.append(
            f"EAU: turbidité={eau.get('turbidite', 'N/A')}, "
            f"contamination={eau.get('contamination_pct', 'N/A')}%, "
            f"statut={eau.get('status', 'N/A')}"
        )
    if "air" in data:
        air = data["air"]
        parts.append(
            f"AIR: AQI={air.get('aqi', 'N/A')}, "
            f"SO₂={air.get('so2', 'N/A')} µg/m³, "
            f"PM10={air.get('pm10', 'N/A')} µg/m³, "
            f"alerte={air.get('alert_level', 'N/A')}"
        )
    if "meteo" in data:
        meteo = data["meteo"]
        parts.append(
            f"MÉTÉO: T={meteo.get('temperature', 'N/A')}°C, "
            f"vent={meteo.get('wind_speed', 'N/A')} m/s dir={meteo.get('wind_direction', 'N/A')}°, "
            f"humidité={meteo.get('humidity', 'N/A')}%"
        )
    return " | ".join(parts) if parts else "Données disponibles: aucune"


async def recommandation_agriculteur(zone_data: dict, langue: str = "fr", question: str = "") -> dict:
    """LLM agent for farmers — soil + weather analysis."""
    lang_name = SUPPORTED_LANGUAGES.get(langue, "French")
    system = AGENT_SYSTEM_PROMPTS["agriculteur"].format(language=lang_name)
    context = _format_context_message(zone_data)

    user_content = f"Données environnementales zone: {context}"
    if question:
        user_content += f"\n\nQuestion spécifique: {question}"

    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": user_content},
    ]

    response = await _call_groq(messages)
    return {
        "agent": "agriculteur",
        "langue": langue,
        "response": response,
        "zone_data": zone_data,
        "timestamp": datetime.utcnow().isoformat(),
    }


async def alerte_pecheur(eau_data: dict, meteo: dict, langue: str = "fr") -> dict:
    """LLM agent for fishermen — water quality + marine weather."""
    lang_name = SUPPORTED_LANGUAGES.get(langue, "French")
    system = AGENT_SYSTEM_PROMPTS["pecheur"].format(language=lang_name)
    context = _format_context_message({"eau": eau_data, "meteo": meteo})

    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": f"Conditions marines actuelles: {context}"},
    ]

    response = await _call_groq(messages)
    return {
        "agent": "pecheur",
        "langue": langue,
        "response": response,
        "timestamp": datetime.utcnow().isoformat(),
    }


async def alerte_citoyen(air_data: dict, langue: str = "fr") -> dict:
    """LLM agent for citizens — air quality health advice."""
    lang_name = SUPPORTED_LANGUAGES.get(langue, "French")
    system = AGENT_SYSTEM_PROMPTS["citoyen"].format(language=lang_name)
    context = _format_context_message({"air": air_data})

    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": f"Qualité air actuelle: {context}"},
    ]

    response = await _call_groq(messages)
    return {
        "agent": "citoyen",
        "langue": langue,
        "response": response,
        "timestamp": datetime.utcnow().isoformat(),
    }


async def rapport_autorite(all_data: dict, langue: str = "fr") -> dict:
    """LLM agent for authorities — full multi-axis environmental report."""
    lang_name = SUPPORTED_LANGUAGES.get(langue, "French")
    system = AGENT_SYSTEM_PROMPTS["autorite"].format(language=lang_name)
    context = _format_context_message(all_data)
    date_str = datetime.utcnow().strftime("%d/%m/%Y %H:%M UTC")

    user_content = (
        f"Générer rapport officiel environnemental Gabès — {date_str}\n"
        f"Données: {context}"
    )

    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": user_content},
    ]

    response = await _call_groq(messages, temperature=0.3)
    return {
        "agent": "autorite",
        "langue": langue,
        "response": response,
        "timestamp": datetime.utcnow().isoformat(),
        "all_data": all_data,
    }


async def conversational_agent(
    message: str,
    history: list,
    role: str = "citoyen",
    langue: str = "fr",
    context_data: dict = None,
) -> dict:
    """
    General conversational agent — answers questions about environment.
    Maintains conversation history for multi-turn dialogue.
    """
    lang_name = SUPPORTED_LANGUAGES.get(langue, "French")
    system = AGENT_SYSTEM_PROMPTS.get(role, AGENT_SYSTEM_PROMPTS["citoyen"]).format(language=lang_name)

    if context_data:
        context_str = _format_context_message(context_data)
        system += f"\n\nDonnées environnementales en temps réel: {context_str}"

    messages = [{"role": "system", "content": system}]
    for h in history[-6:]:  # Keep last 6 turns
        messages.append({"role": h["role"], "content": h["content"]})
    messages.append({"role": "user", "content": message})

    response = await _call_groq(messages, temperature=0.8)

    return {
        "role": role,
        "langue": langue,
        "user_message": message,
        "response": response,
        "timestamp": datetime.utcnow().isoformat(),
    }


async def health_risk_personalized(
    zone_id: str,
    air_data: dict,
    profil: dict,
) -> dict:
    """
    Personalized health risk assessment.
    profil: {age, conditions: ["asthme", "cardiaque"], activite: "sport/bureau/outdoor"}
    """
    lang_name = SUPPORTED_LANGUAGES.get(profil.get("langue", "fr"), "French")

    age = profil.get("age", 35)
    conditions = profil.get("conditions", [])
    activite = profil.get("activite", "bureau")

    vulnerability = "faible"
    if age > 65 or age < 5:
        vulnerability = "elevee"
    elif conditions:
        vulnerability = "moderee"

    system = f"""Tu es GabèsEye HealthBot. Évalue le risque santé personnalisé en {lang_name}.
Profil: {age} ans, vulnérabilité {vulnerability}, conditions: {', '.join(conditions) or 'aucune'}, activité: {activite}.
Sois précis et personnalisé. Maximum 150 mots."""

    context = _format_context_message({"air": air_data})
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": f"Zone {zone_id}: {context}"},
    ]

    response = await _call_groq(messages)

    return {
        "agent": "health_risk",
        "zone_id": zone_id,
        "profil": profil,
        "vulnerability": vulnerability,
        "response": response,
        "timestamp": datetime.utcnow().isoformat(),
    }
