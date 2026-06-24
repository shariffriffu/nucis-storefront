from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional, Dict, Any, List

class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
    role: str = Field("USER", pattern="^(USER|ADMIN)$")

class UserResponse(BaseModel):
    id: int
    email: str
    role: str
    balance: float
    created_at: datetime

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenRefreshRequest(BaseModel):
    refresh_token: str

class BrokerCredentialsCreate(BaseModel):
    api_key: str
    client_id: str
    password: str
    totp_secret: str

class OrderResponse(BaseModel):
    id: int
    symbol: str
    qty: int
    transaction_type: str
    product_type: str
    broker_order_id: str
    execution_price: float
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class OrderExecutionResponse(BaseModel):
    message: str
    broker_order_id: str

class SystemLogResponse(BaseModel):
    id: int
    level: str
    module: str
    message: str
    exception_trace: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class AuditLogResponse(BaseModel):
    id: int
    event_type: str
    user_id: Optional[int] = None
    detail: str
    created_at: datetime

    class Config:
        from_attributes = True

class StrategyResponse(BaseModel):
    strategy_id: str
    name: str
    enabled: bool
    parameters: Dict[str, Any]

    class Config:
        from_attributes = True

# Mobile Specific Schemas
class PnLPeriod(BaseModel):
    today: float
    weekly: float
    monthly: float
    total: float

class MobileDashboardResponse(BaseModel):
    balance: float
    pnl: PnLPeriod
    roi: float
    win_rate: float
    loss_rate: float
    engine_running_state: bool

class PositionState(BaseModel):
    symbol: str
    qty: int
    buy_price: float
    current_price: float
    pnl: float

class LivePnLResponse(BaseModel):
    total_unrealized_pnl: float
    positions: List[PositionState]

class SystemStatusResponse(BaseModel):
    engine_status: str
    broker_connection: str
    simulation_mode: bool

class WidgetPayloadResponse(BaseModel):
    pnl_today: float
    balance: float
    open_positions_count: int
    last_filled_trade_text: str

# Admin Dashboard
class PlatformMetrics(BaseModel):
    active_users_count: int
    running_strategies_count: int

class SystemMetrics(BaseModel):
    cpu_utilization_percent: float
    memory_usage_percent: float
    disk_space_percent: float

class AdminDashboardResponse(BaseModel):
    platform_metrics: PlatformMetrics
    system_metrics: SystemMetrics

# Synced Mobile API Response Schemas
class TradeHistoryResponse(BaseModel):
    symbol: str
    buy_price: float
    sell_price: float
    qty: int
    pnl: float
    exit_reason: str
    timestamp: datetime

    class Config:
        from_attributes = True

class OpenPositionResponse(BaseModel):
    symbol: str
    entry_price: float
    market_price: float
    qty: int
    stop_loss: float
    target: float
    pnl: float

    class Config:
        from_attributes = True

class ClosedPositionResponse(BaseModel):
    symbol: str
    entry_price: float
    exit_price: float
    qty: int
    pnl: float
    closed_at: datetime

    class Config:
        from_attributes = True

class WatchlistSymbol(BaseModel):
    symbol: str
    price: float
    pct_change: float
    rel_vol: float
    scores: Dict[str, int]

class WatchlistResponse(BaseModel):
    watchlist: List[WatchlistSymbol]

class StrategyConfigResponse(BaseModel):
    name: str
    enabled: bool
    parameters: Dict[str, Any]

