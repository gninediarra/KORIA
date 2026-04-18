"""
Generates personalized alerts from classified measurements.
Each user role receives tailored recommendations.
"""
from app.models.measurement import Classification, SensorType
from app.models.user import UserRole
from app.models.alert import AlertSeverity


SEVERITY_MAP = {
    Classification.rouge: AlertSeverity.critique,
    Classification.orange: AlertSeverity.avertissement,
    Classification.vert: AlertSeverity.info,
}

# Role-specific recommendation templates per sensor_type + classification
RECOMMENDATIONS: dict[str, dict[str, dict[str, list]]] = {
    "sol": {
        "rouge": {
            UserRole.agriculteur: [
                "Arrêtez immédiatement l'irrigation avec les eaux locales.",
                "Ne plantez aucune culture alimentaire dans cette parcelle.",
                "Contactez l'ANPE pour analyse détaillée du sol.",
            ],
            UserRole.autorite: [
                "Alerte rouge sol : contamination critique détectée.",
                "Déclencher une inspection industrielle dans la zone.",
                "Rapport détaillé disponible sur le dashboard.",
            ],
            UserRole.citoyen: [
                "Évitez tout contact avec le sol dans cette zone.",
                "Ne consommez pas de produits agricoles locaux sans vérification.",
            ],
        },
        "orange": {
            UserRole.agriculteur: [
                "Salinité ou stress hydrique détecté — vérifiez la source d'irrigation.",
                "Cultures résistantes au sel recommandées : henné, orge.",
                "Effectuez une analyse de sol complète cette semaine.",
            ],
            UserRole.autorite: [
                "Stress sol détecté — surveillance renforcée recommandée.",
            ],
            UserRole.citoyen: [
                "Qualité du sol dégradée dans votre quartier — restez informé.",
            ],
        },
    },
    "eau": {
        "rouge": {
            UserRole.pecheur: [
                "Zone de pêche dangereuse — rejet industriel probable.",
                "Évitez la pêche dans un rayon de 2 km du point détecté.",
                "Signalez tout poisson anormal à la direction des pêches.",
            ],
            UserRole.agriculteur: [
                "Ne pas utiliser l'eau de ce canal pour l'irrigation.",
                "Risque de contamination des cultures par les phosphates.",
            ],
            UserRole.autorite: [
                "Rejet industriel probable dans les eaux côtières.",
                "Intervention urgente recommandée — seuils réglementaires dépassés.",
            ],
            UserRole.citoyen: [
                "Évitez la baignade dans cette zone du golfe.",
                "Ne consommez pas de fruits de mer pêchés localement.",
            ],
        },
        "orange": {
            UserRole.pecheur: [
                "Turbidité anormale détectée — pêche déconseillée aujourd'hui.",
                "Préférez les zones plus au large du golfe.",
            ],
            UserRole.autorite: [
                "Dégradation de la qualité des eaux côtières — surveillance accrue.",
            ],
            UserRole.citoyen: [
                "Qualité de l'eau dégradée — prudence pour les activités côtières.",
            ],
        },
    },
    "air": {
        "rouge": {
            UserRole.citoyen: [
                "Qualité de l'air dangereuse — restez à l'intérieur.",
                "Fermez fenêtres et portes. Évitez tout effort physique extérieur.",
                "Personnes vulnérables (enfants, asthmatiques) : précautions maximales.",
            ],
            UserRole.autorite: [
                "Concentration SO₂/H₂S au-dessus du seuil réglementaire.",
                "Intervention urgente requise — source industrielle probable.",
                "Alerter la direction régionale de l'environnement.",
            ],
            UserRole.agriculteur: [
                "Pollution atmosphérique critique — risque pour les cultures.",
                "Protégez les serres et cultures sensibles.",
            ],
        },
        "orange": {
            UserRole.citoyen: [
                "Qualité de l'air dégradée dans votre secteur.",
                "Limitez les activités physiques en extérieur.",
                "Fenêtres fermées recommandées.",
            ],
            UserRole.autorite: [
                "Niveaux de pollution atmosphérique élevés — surveillance renforcée.",
            ],
        },
    },
}

ALERT_TITLES = {
    ("sol", "rouge"): "Contamination critique du sol",
    ("sol", "orange"): "Stress sol détecté",
    ("eau", "rouge"): "Rejet industriel dans les eaux",
    ("eau", "orange"): "Qualité eau dégradée",
    ("air", "rouge"): "Qualité de l'air dangereuse",
    ("air", "orange"): "Pollution atmosphérique élevée",
}


def generate_alerts(
    sensor_type: str,
    classification: Classification,
    zone_name: str,
    zone_id=None,
) -> list[dict] | None:
    """Returns a list of alert dicts (one per targeted role) or None if vert."""
    if classification == Classification.vert:
        return None

    level = "rouge" if classification == Classification.rouge else "orange"
    role_recs = RECOMMENDATIONS.get(sensor_type, {}).get(level, {})
    if not role_recs:
        return None

    severite = SEVERITY_MAP[classification]
    titre = ALERT_TITLES.get((sensor_type, level), f"Alerte {sensor_type} — {level}")
    roles_target = list(role_recs.keys())
    all_recs = []
    for recs in role_recs.values():
        all_recs.extend(recs)

    description = _build_description(sensor_type, level, zone_name)

    return [{
        "titre": titre,
        "description": description,
        "severite": severite,
        "roles_target": [r.value for r in roles_target],
        "zone_name": zone_name,
        "zone_id": zone_id,
        "recommandations": all_recs,
    }]


def _build_description(sensor_type: str, level: str, zone_name: str) -> str:
    labels = {
        ("sol", "rouge"): f"Contamination critique du sol détectée dans la zone {zone_name}.",
        ("sol", "orange"): f"Stress hydrique ou salinité élevée détectés — zone {zone_name}.",
        ("eau", "rouge"): f"Rejet industriel probable dans les eaux de la zone {zone_name}.",
        ("eau", "orange"): f"Turbidité anormale dans les eaux côtières — zone {zone_name}.",
        ("air", "rouge"): f"Concentration de gaz dangereux (SO₂/H₂S/NH₃) au-dessus des seuils dans la zone {zone_name}.",
        ("air", "orange"): f"Niveaux de pollution atmosphérique élevés — zone {zone_name}.",
    }
    return labels.get((sensor_type, level), f"Anomalie {sensor_type} détectée — zone {zone_name}.")
