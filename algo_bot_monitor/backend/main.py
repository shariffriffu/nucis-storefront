import asyncio
import logging
from datetime import datetime, timezone
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST
from starlette.middleware.base import BaseHTTPMiddleware
from sqlalchemy.orm import Session

from sqlalchemy import text
from backend.database import engine, Base
from backend.deps import get_db
from backend.utils.ws_manager import manager
from backend.utils.engine_state import state
from backend.utils.system import get_system_metrics
from backend.utils.logger import log_system_event
from backend.routers import auth, trading, mobile, admin

# Create database tables automatically
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Algo Trading Bot Monitor",
    description="FastAPI Backend for real-time algorithmic trading monitoring and execution.",
    version="1.0.0"
)

# Enable CORS for frontend clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. Prometheus Metrics Configuration
HTTP_REQUESTS_TOTAL = Counter(
    "http_requests_total",
    "Total HTTP Requests Count",
    ["method", "path", "status_code"]
)

ACTIVE_WEBSOCKET_CONNECTIONS = Gauge(
    "active_websocket_connections",
    "Current active WebSocket connections count",
    ["channel"]
)

class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Proceed with request
        response = await call_next(request)
        # Avoid counting /metrics requests
        if request.url.path != "/metrics":
            HTTP_REQUESTS_TOTAL.labels(
                method=request.method,
                path=request.url.path,
                status_code=response.status_code
            ).inc()
        return response

app.add_middleware(PrometheusMiddleware)

# 2. Expose Prometheus Metrics Endpoint
@app.get("/metrics", tags=["Monitoring"])
def get_metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

# 3. Heartbeat Health Audit Endpoint
@app.get("/health", tags=["Monitoring"])
def health_check(db: Session = Depends(get_db)):
    db_status = "available"
    try:
        # Perform simple query to verify database is active
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unavailable: {str(e)}"
        
    sys_metrics = get_system_metrics()
    
    overall_status = "healthy"
    if db_status != "available":
        overall_status = "unhealthy"
        
    return {
        "status": overall_status,
        "database": db_status,
        "strategy_engine": state.engine_status.lower(),
        "system": {
            "cpu_percent": sys_metrics["cpu_utilization_percent"],
            "memory_percent": sys_metrics["memory_usage_percent"]
        }
    }

# 4. Include Routers
app.include_router(auth.router)
app.include_router(trading.router, prefix="/api")
app.include_router(mobile.router)
app.include_router(admin.router)

# 5. Streaming WebSockets Endpoint
@app.websocket("/ws/{channel}")
async def websocket_endpoint(websocket: WebSocket, channel: str):
    valid_channels = ["pnl", "trades", "orders", "system"]
    if channel not in valid_channels:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
        
    # Connect
    await manager.connect(websocket, channel)
    ACTIVE_WEBSOCKET_CONNECTIONS.labels(channel=channel).inc()
    
    try:
        while True:
            # Handle messages from client (e.g. Ping messages)
            data = await websocket.receive_json()
            if isinstance(data, dict) and data.get("type") == "ping":
                await websocket.send_json({"type": "pong"})
    except WebSocketDisconnect:
        manager.disconnect(websocket, channel)
        ACTIVE_WEBSOCKET_CONNECTIONS.labels(channel=channel).dec()
    except Exception as e:
        log_system_event("ERROR", "websocket", f"WebSocket connection error on channel {channel}", e)
        manager.disconnect(websocket, channel)
        ACTIVE_WEBSOCKET_CONNECTIONS.labels(channel=channel).dec()

# 6. Background Broadcast Loop to Simulate Live Market Feeds (connected mode)
async def websocket_broadcast_loop():
    while True:
        try:
            # Broadcast metrics periodically to system channel
            if state.broker_connection == "CONNECTED" and state.engine_status == "RUNNING":
                sys_metrics = get_system_metrics()
                # Broadcast on system channel
                await manager.broadcast({
                    "channel": "system",
                    "type": "system_status_update",
                    "data": {
                        "engine_status": state.engine_status,
                        "broker_connection": state.broker_connection,
                        "simulation_mode": state.simulation_mode,
                        "cpu_percent": sys_metrics["cpu_utilization_percent"],
                        "memory_percent": sys_metrics["memory_usage_percent"],
                        "timestamp": datetime.now(timezone.utc).isoformat()
                    }
                }, "system")
                
                # Broadcast ticking values on PnL channel to simulate active feeds
                # In standard live, clients see their specific updates. We broadcast index/market ticks
                # or general alerts.
                await manager.broadcast({
                    "channel": "pnl",
                    "type": "live_market_tick",
                    "data": {
                        "nifty_pnl_change_percent": round(0.01 * (hash(datetime.now().second) % 21 - 10), 3),
                        "timestamp": datetime.now(timezone.utc).isoformat()
                    }
                }, "pnl")
                
        except Exception as e:
            logging.error(f"Error in websocket broadcast loop: {e}")
            
        # Sleep for 3 seconds before next broadcast
        await asyncio.sleep(3)

# Hook background task into FastAPI startup event
@app.on_event("startup")
async def startup_event():
    log_system_event("INFO", "main", "FastAPI App starting up. Creating system background loops.")
    asyncio.create_task(websocket_broadcast_loop())
