"""
Seed script — zones Gabès + comptes démo avec portefeuilles blockchain.
Run: python seed.py
"""
from app.database import SessionLocal, engine, Base
import app.models  # noqa
from app.models.zone import Zone, ZoneType
from app.models.user import User, UserRole
from app.models.token import TokenTransaction, ActionType
from app.services.security import hash_password
from app.services.blockchain import create_wallet, encrypt_private_key

Base.metadata.create_all(bind=engine)

ZONES = [
    {
        "name": "Zone Industrielle Ghannouch",
        "type": ZoneType.industriel,
        "center_lat": 33.9167, "center_lng": 10.0833,
        "status": "rouge",
        "sol_salinite": 9.2, "sol_ph": 5.1, "sol_humidite": 6.0, "sol_contamination": 0.72, "sol_etat": "Contaminé",
        "eau_turbidite": 65.0, "eau_ph": 5.8, "eau_phosphates": 3.1, "eau_temperature": 28.5, "eau_etat": "Pollué",
        "air_so2": 420.0, "air_h2s": 18.5, "air_nh3": 350.0, "air_pm25": 89.0, "air_aqi": 175, "air_etat": "Dangereux",
        "recommandations": [
            "Évitez tout séjour prolongé dans cette zone.",
            "Inspection industrielle urgente du GCT recommandée.",
            "Alerte émise aux autorités régionales.",
        ],
    },
    {
        "name": "Oasis de Chenini",
        "type": ZoneType.agricole,
        "center_lat": 33.8833, "center_lng": 10.1167,
        "status": "orange",
        "sol_salinite": 5.1, "sol_ph": 6.8, "sol_humidite": 22.0, "sol_contamination": 0.35, "sol_etat": "Stress détecté",
        "eau_turbidite": 8.0, "eau_ph": 7.1, "eau_phosphates": 0.4, "eau_temperature": 22.0, "eau_etat": "Acceptable",
        "air_so2": 45.0, "air_h2s": 3.2, "air_nh3": 85.0, "air_pm25": 28.0, "air_aqi": 72, "air_etat": "Modéré",
        "recommandations": [
            "Salinité élevée — cultures résistantes recommandées (henné, orge).",
            "Vérifiez la source d'irrigation : évitez le canal Est.",
            "Surveillance hebdomadaire du sol conseillée.",
        ],
    },
    {
        "name": "Port de Gabès",
        "type": ZoneType.portuaire,
        "center_lat": 33.8833, "center_lng": 10.1000,
        "status": "orange",
        "sol_salinite": 3.0, "sol_ph": 7.2, "sol_humidite": 35.0, "sol_contamination": 0.2, "sol_etat": "Normal",
        "eau_turbidite": 22.0, "eau_ph": 7.5, "eau_phosphates": 0.9, "eau_temperature": 24.0, "eau_etat": "Turbide",
        "air_so2": 80.0, "air_h2s": 5.5, "air_nh3": 120.0, "air_pm25": 42.0, "air_aqi": 98, "air_etat": "Modéré",
        "recommandations": [
            "Pêche déconseillée dans un rayon de 1 km du port.",
            "Turbidité anormale — rejet industriel probable.",
            "Signaler tout poisson anormal à la direction des pêches.",
        ],
    },
    {
        "name": "Golfe de Gabès Nord",
        "type": ZoneType.maritime,
        "center_lat": 34.0, "center_lng": 10.2,
        "status": "vert",
        "sol_salinite": 1.5, "sol_ph": 8.1, "sol_humidite": 100.0, "sol_contamination": 0.05, "sol_etat": "Normal",
        "eau_turbidite": 3.5, "eau_ph": 8.2, "eau_phosphates": 0.15, "eau_temperature": 21.0, "eau_etat": "Propre",
        "air_so2": 12.0, "air_h2s": 0.8, "air_nh3": 18.0, "air_pm25": 10.0, "air_aqi": 32, "air_etat": "Bon",
        "recommandations": [
            "Zone de pêche sûre — qualité eau normale.",
            "Surveillance continue recommandée.",
        ],
    },
    {
        "name": "Centre-ville Gabès",
        "type": ZoneType.urbain,
        "center_lat": 33.8833, "center_lng": 10.1167,
        "status": "orange",
        "sol_salinite": 2.5, "sol_ph": 7.0, "sol_humidite": 18.0, "sol_contamination": 0.22, "sol_etat": "Acceptable",
        "eau_turbidite": 5.0, "eau_ph": 7.3, "eau_phosphates": 0.3, "eau_temperature": 20.0, "eau_etat": "Normal",
        "air_so2": 95.0, "air_h2s": 6.1, "air_nh3": 155.0, "air_pm25": 38.0, "air_aqi": 108, "air_etat": "Mauvais",
        "recommandations": [
            "Qualité de l'air mauvaise aujourd'hui — évitez les activités extérieures.",
            "Fenêtres fermées recommandées.",
            "Personnes asthmatiques et enfants : précautions maximales.",
        ],
    },
    {
        "name": "Côte de Chott el-Jerid",
        "type": ZoneType.cotier,
        "center_lat": 33.75, "center_lng": 9.95,
        "status": "vert",
        "sol_salinite": 2.0, "sol_ph": 7.5, "sol_humidite": 28.0, "sol_contamination": 0.08, "sol_etat": "Normal",
        "eau_turbidite": 4.0, "eau_ph": 7.8, "eau_phosphates": 0.2, "eau_temperature": 22.0, "eau_etat": "Propre",
        "air_so2": 15.0, "air_h2s": 1.2, "air_nh3": 22.0, "air_pm25": 12.0, "air_aqi": 40, "air_etat": "Bon",
        "recommandations": ["Zone en bon état — maintenir la surveillance."],
    },
]

DEMO_USERS = [
    {"name": "Ahmed Ben Ali",    "email": "ahmed@gabeseye.tn", "password": "demo1234", "role": UserRole.agriculteur, "parcelle": "Bahria Nord"},
    {"name": "Fatma Trabelsi",   "email": "fatma@gabeseye.tn", "password": "demo1234", "role": UserRole.pecheur,     "quartier": "Port"},
    {"name": "Inspecteur Samir", "email": "samir@gabeseye.tn", "password": "demo1234", "role": UserRole.autorite},
    {"name": "Manel Gharbi",     "email": "manel@gabeseye.tn", "password": "demo1234", "role": UserRole.citoyen,     "quartier": "Centre-ville"},
]

WELCOME_TOKENS = 10


def run():
    db = SessionLocal()
    try:
        # ── Zones ─────────────────────────────────────────────────────────────
        if db.query(Zone).count() == 0:
            for z in ZONES:
                db.add(Zone(**z))
            db.commit()
            print(f"✓ {len(ZONES)} zones créées")
        else:
            print("Zones déjà présentes — skip")

        # ── Comptes démo — force la mise à jour si wallet manquant ────────────
        for u in DEMO_USERS:
            existing = db.query(User).filter(User.email == u["email"]).first()

            if existing and existing.wallet_address:
                print(f"  ✓ {u['email']} — déjà à jour (wallet: {existing.wallet_address[:12]}…)")
                continue

            wallet_address, private_key = create_wallet()
            encrypted_pk = encrypt_private_key(private_key)

            if existing:
                # Mise à jour de l'ancien compte
                existing.password_hash       = hash_password(u["password"])
                existing.wallet_address      = wallet_address
                existing.encrypted_private_key = encrypted_pk
                existing.eco_tokens          = WELCOME_TOKENS
                user = existing
                print(f"  ↻ {u['email']} — portefeuille assigné ({wallet_address[:12]}…)")
            else:
                user = User(
                    name=u["name"],
                    email=u["email"],
                    password_hash=hash_password(u["password"]),
                    role=u["role"],
                    quartier=u.get("quartier"),
                    parcelle=u.get("parcelle"),
                    wallet_address=wallet_address,
                    encrypted_private_key=encrypted_pk,
                    eco_tokens=WELCOME_TOKENS,
                )
                db.add(user)
                print(f"  + {u['email']} — créé ({wallet_address[:12]}…)")

            db.flush()

            tx = TokenTransaction(
                user_id=user.id,
                amount=WELCOME_TOKENS,
                action_type=ActionType.welcome_bonus,
                description="Bonus de bienvenue GabèsEye",
                tx_hash=None,
            )
            db.add(tx)

        db.commit()
        print("\n✓ Base de données prête.")
        print("─" * 42)
        for u in DEMO_USERS:
            print(f"  {u['role'].value:<14} {u['email']}  /  {u['password']}")

    finally:
        db.close()


if __name__ == "__main__":
    run()
