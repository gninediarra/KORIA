import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
import app.models  # noqa: F401 — registers all models with Base

from app.routers import auth, users, drone, alerts, map as map_router
from app.routers import tokens, gamification, ai as ai_router
from app.routers import zones_router, analysis, agent, voice, drone_ws, dashboard
from app.services.alert_monitor import run_alert_monitor

_monitor_task = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create DB tables
    Base.metadata.create_all(bind=engine)

    # Start background alert monitoring task
    global _monitor_task
    _monitor_task = asyncio.create_task(run_alert_monitor())

    yield

    # Cleanup on shutdown
    if _monitor_task and not _monitor_task.done():
        _monitor_task.cancel()
        try:
            await _monitor_task
        except asyncio.CancelledError:
            pass


app = FastAPI(
    title="GabèsEye API",
    description="Backend IA de surveillance environnementale — Gabès, Tunisie",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(drone.router)
app.include_router(alerts.router)
app.include_router(map_router.router)
app.include_router(tokens.router)
app.include_router(gamification.router)
app.include_router(ai_router.router)

# ── Mané — environmental analysis + AI agents + voice + drone WS ─────────────
app.include_router(zones_router.router)
app.include_router(analysis.router)
app.include_router(agent.router)
app.include_router(voice.router)
app.include_router(drone_ws.router)
app.include_router(dashboard.router)


@app.get("/")
def root():
    return {"status": "ok", "project": "GabèsEye", "docs": "/docs"}
