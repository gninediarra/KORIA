"""GET /zones and GET /zones/{zone_id} — zone list from zones.json"""
from fastapi import APIRouter, HTTPException
from app.services.zone_analysis import get_zones_list, load_zones_config

router = APIRouter(tags=["Zones"])

_type_map = {"gct": "industriel", "ville": "urbain", "mer": "maritime", "oasis": "oasis"}


@router.get("/zones")
def list_zones():
    return get_zones_list()


@router.get("/zones/{zone_id}")
def get_zone(zone_id: str):
    config = load_zones_config()
    z = config["zones"].get(zone_id)
    if not z:
        raise HTTPException(status_code=404, detail=f"Zone '{zone_id}' introuvable")
    lat, lon = z["centre"][0], z["centre"][1]
    return {
        "id": zone_id,
        "name": z["nom_fr"],
        "type": _type_map.get(zone_id, "urbain"),
        "center": {"lat": lat, "lon": lon},
        "bbox": z["bbox"],
        "description": z.get("description", ""),
        "superficie_km2": z.get("superficie_km2", 0),
        "population": z.get("population", 0),
        "couleur": z.get("couleur", "#888888"),
    }
