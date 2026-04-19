"""
GabèsEye — Multilingual LLM agents via Groq API (Llama-3.3-70b-versatile).
Adapted from KORIA/H12 — 4 specialized agents: farmer, fisherman, citizen, authority.
"""
import os
import asyncio
import aiohttp
from datetime import datetime

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL   = "llama-3.3-70b-versatile"
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")

SUPPORTED_LANGUAGES = {"fr": "French", "ar": "Arabic", "en": "English", "ber": "Tamazight/Berber"}

AGENT_SYSTEM_PROMPTS = {
    "agriculteur": """Tu es GabèsEye AgriBot, assistant IA spécialisé pour les agriculteurs de Gabès, Tunisie.
Tu analyses les données sol (salinité, contamination, humidité) et donnes des conseils pratiques.
Réponds en {language}. Sois direct et concret. Termes agricoles locaux.
Contexte: Zone industrielle GCT, sols contaminés aux phosphates, sécheresse.
Max 200 mots. Structure: Situation → Risques → Actions immédiates → Moyen terme.""",

    "pecheur": """Tu es GabèsEye MarinBot, assistant IA pour les pêcheurs du Golfe de Gabès.
Tu analyses la qualité de l'eau (turbidité, phosphates, pH) et les conditions marines.
Réponds en {language}. Priorise la sécurité en mer et la qualité des captures.
Contexte: Pollution GCT, turbidité variable, zones de contamination.
Max 200 mots. Structure: Conditions actuelles → Zones à éviter → Zones sûres → Sécurité.""",

    "citoyen": """Tu es GabèsEye CitiBot, assistant IA pour les citoyens de Gabès.
Tu expliques la qualité de l'air (AQI, SO₂, H₂S, PM2.5) en termes simples et accessibles.
Réponds en {language}. Sois rassurant mais honnête. Conseils santé pratiques.
Contexte: Émissions GCT, pollution atmosphérique chronique.
Max 200 mots. Structure: Situation du jour → Impact santé → Ce qu'il faut faire → À éviter.""",

    "autorite": """Tu es GabèsEye AuthoBot, assistant IA pour les autorités et décideurs de Gabès.
Tu synthétises les données multi-axes en rapports officiels structurés.
Réponds en {language}. Format rapport officiel avec métriques précises.
Contexte: Surveillance environnementale réglementaire — ANPE / CRDA.
Max 250 mots. Structure: Résumé exécutif → Indicateurs → Zones critiques → Recommandations → Urgences.""",
}


def _format_context(zone_data: dict) -> str:
    parts = []
    if sol := zone_data.get("sol"):
        parts.append(
            f"SOL: salinité={sol.get('salinite','N/A')} dS/m, "
            f"contamination={sol.get('contamination','N/A')}, "
            f"humidité={sol.get('humidite','N/A')}%, "
            f"état={sol.get('etat','N/A')}"
        )
    if eau := zone_data.get("eau"):
        parts.append(
            f"EAU: turbidité={eau.get('turbidite','N/A')} NTU, "
            f"phosphates={eau.get('phosphates','N/A')} mg/L, "
            f"pH={eau.get('ph','N/A')}, "
            f"état={eau.get('etat','N/A')}"
        )
    if air := zone_data.get("air"):
        parts.append(
            f"AIR: AQI={air.get('aqi','N/A')}, "
            f"SO₂={air.get('so2','N/A')} µg/m³, "
            f"H₂S={air.get('h2s','N/A')} µg/m³, "
            f"PM2.5={air.get('pm25','N/A')} µg/m³, "
            f"état={air.get('etat','N/A')}"
        )
    return " | ".join(parts) if parts else "Aucune donnée capteur disponible"


async def _call_groq(messages: list, temperature: float = 0.7) -> str:
    if not GROQ_API_KEY:
        return _fallback(messages)

    headers = {"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"}
    payload  = {"model": GROQ_MODEL, "messages": messages, "temperature": temperature, "max_tokens": 512}

    for attempt in range(2):
        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=15)) as s:
                async with s.post(GROQ_API_URL, headers=headers, json=payload) as r:
                    if r.status == 200:
                        data = await r.json()
                        return data["choices"][0]["message"]["content"]
                    if r.status == 429:
                        await asyncio.sleep(2)
                    else:
                        break
        except Exception as e:
            print(f"[AgentEngine] Groq error: {e}")

    return _fallback(messages)


def _fallback(messages: list) -> str:
    system = messages[0]["content"] if messages else ""
    if "agri" in system.lower():
        return (
            "⚠️ Situation sol sous surveillance. Actions immédiates:\n"
            "① Évitez l'irrigation avec eau de surface — turbidité élevée.\n"
            "② Testez le pH sol avant tout semis — contamination phosphate possible.\n"
            "③ Préférez cultures résistantes: orge, cactus, halophytes.\n"
            "Moyen terme: compostage organique pour restaurer le microbiome."
        )
    if "marin" in system.lower() or "pecheur" in system.lower():
        return (
            "🌊 Conditions marines: turbidité élevée côte GCT.\n"
            "Zones à éviter: 0–3 km de la côte industrielle.\n"
            "Zones acceptables: secteur sud golfe, > 5 km offshore.\n"
            "Sécurité: vérifiez contamination métaux lourds avant commercialisation."
        )
    if "citi" in system.lower():
        return (
            "😷 Qualité air: surveillance requise. SO₂ en hausse détectée.\n"
            "① Fermez les fenêtres entre 10h–15h.\n"
            "② Portez un masque FFP2 si sortie prolongée.\n"
            "③ Évitez activité sportive extérieure.\n"
            "Personnes asthmatiques: restez à l'intérieur jusqu'à amélioration."
        )
    return (
        "📊 Rapport GabèsEye — Synthèse multi-axes:\n"
        "• Sol: surveillance contamination phosphates zone GCT\n"
        "• Eau: turbidité littorale — alertes pêcheurs actives\n"
        "• Air: AQI variable — épisodes SO₂ possibles\n"
        "Actions prioritaires: monitoring renforcé + coordination ANPE."
    )


async def conversational_agent(
    message: str,
    history: list,
    role: str = "citoyen",
    langue: str = "fr",
    zone_data: dict = None,
) -> dict:
    lang = SUPPORTED_LANGUAGES.get(langue, "French")
    system = AGENT_SYSTEM_PROMPTS.get(role, AGENT_SYSTEM_PROMPTS["citoyen"]).format(language=lang)

    if zone_data:
        system += f"\n\nDonnées capteurs en temps réel (GabèsEye): {_format_context(zone_data)}"

    msgs = [{"role": "system", "content": system}]
    for h in history[-6:]:
        msgs.append({"role": h["role"], "content": h["content"]})
    msgs.append({"role": "user", "content": message})

    response = await _call_groq(msgs, temperature=0.8)
    return {
        "role": role,
        "langue": langue,
        "response": response,
        "timestamp": datetime.utcnow().isoformat(),
    }


async def role_agent(
    role: str,
    zone_data: dict,
    langue: str = "fr",
    question: str = "",
) -> dict:
    lang = SUPPORTED_LANGUAGES.get(langue, "French")
    system = AGENT_SYSTEM_PROMPTS.get(role, AGENT_SYSTEM_PROMPTS["citoyen"]).format(language=lang)
    context = _format_context(zone_data)

    content = f"Données zone GabèsEye: {context}"
    if question:
        content += f"\n\nQuestion: {question}"

    msgs = [{"role": "system", "content": system}, {"role": "user", "content": content}]
    temp = 0.3 if role == "autorite" else 0.7
    response = await _call_groq(msgs, temperature=temp)

    return {
        "agent": role,
        "langue": langue,
        "response": response,
        "zone_data": zone_data,
        "timestamp": datetime.utcnow().isoformat(),
    }


async def health_risk(zone_data: dict, profil: dict) -> dict:
    langue = profil.get("langue", "fr")
    lang   = SUPPORTED_LANGUAGES.get(langue, "French")
    age    = profil.get("age", 35)
    conds  = profil.get("conditions", [])
    activite = profil.get("activite", "bureau")

    vuln = "élevée" if (age > 65 or age < 5) else ("modérée" if conds else "faible")

    system = (
        f"Tu es GabèsEye HealthBot. Évalue le risque santé personnalisé en {lang}.\n"
        f"Profil: {age} ans, vulnérabilité {vuln}, "
        f"conditions: {', '.join(conds) or 'aucune'}, activité: {activite}.\n"
        "Sois précis et personnalisé. Max 150 mots."
    )
    context = _format_context(zone_data)
    msgs = [
        {"role": "system", "content": system},
        {"role": "user", "content": f"Données environnementales: {context}"},
    ]

    response = await _call_groq(msgs)
    return {
        "agent": "health_risk",
        "profil": profil,
        "vulnerability": vuln,
        "response": response,
        "timestamp": datetime.utcnow().isoformat(),
    }
