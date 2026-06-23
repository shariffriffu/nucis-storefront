import json
import random
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.deps import get_db, get_current_user
from backend.models import User, Order, Strategy
from backend.schemas import (
    MobileDashboardResponse,
    LivePnLResponse,
    SystemStatusResponse,
    WidgetPayloadResponse,
    StrategyResponse,
    PositionState,
    PnLPeriod
)
from backend.utils.engine_state import state
from backend.routers.trading import get_stock_price

router = APIRouter(prefix="/api/mobile", tags=["Mobile Specific"])

def calculate_pnl_stats(db: Session, user: User):
    # 1. Fetch all executed orders for the user
    orders = db.query(Order).filter(
        Order.user_id == user.id,
        Order.status == "EXECUTED"
    ).order_by(Order.created_at.asc()).all()
    
    # Check if live-connected
    is_live = (state.broker_connection == "CONNECTED")
    
    # 2. Group by symbol to compute net quantity and average buy price
    symbol_data = {}
    for order in orders:
        sym = order.symbol
        if sym not in symbol_data:
            symbol_data[sym] = {
                "buys": [],
                "sells": [],
                "total_buy_qty": 0,
                "total_sell_qty": 0,
                "total_buy_val": 0.0,
                "total_sell_val": 0.0,
            }
        
        if order.transaction_type == "BUY":
            symbol_data[sym]["buys"].append(order)
            symbol_data[sym]["total_buy_qty"] += order.qty
            symbol_data[sym]["total_buy_val"] += order.qty * order.execution_price
        else:
            symbol_data[sym]["sells"].append(order)
            symbol_data[sym]["total_sell_qty"] += order.qty
            symbol_data[sym]["total_sell_val"] += order.qty * order.execution_price
            
    # Calculate positions, realized/unrealized PnLs, wins, losses
    total_realized_pnl = 0.0
    total_unrealized_pnl = 0.0
    today_realized_pnl = 0.0
    weekly_realized_pnl = 0.0
    monthly_realized_pnl = 0.0
    
    wins = 0
    losses = 0
    total_trades = 0
    
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = now - timedelta(days=7)
    month_start = now - timedelta(days=30)
    
    positions = []
    
    for symbol, data in symbol_data.items():
        net_qty = data["total_buy_qty"] - data["total_sell_qty"]
        
        # Calculate avg buy price
        avg_buy_price = 0.0
        if data["total_buy_qty"] > 0:
            avg_buy_price = data["total_buy_val"] / data["total_buy_qty"]
            
        # Realized PnL is based on sells matching the average buy price
        realized_pnl = 0.0
        if data["total_sell_qty"] > 0:
            realized_pnl = data["total_sell_val"] - (data["total_sell_qty"] * avg_buy_price)
            total_realized_pnl += realized_pnl
            
            # Period distributions for realized PnL based on Sell order execution times
            for sell_order in data["sells"]:
                sell_pnl = sell_order.qty * (sell_order.execution_price - avg_buy_price)
                created_at = sell_order.created_at.replace(tzinfo=timezone.utc)
                if created_at >= today_start:
                    today_realized_pnl += sell_pnl
                if created_at >= week_start:
                    weekly_realized_pnl += sell_pnl
                if created_at >= month_start:
                    monthly_realized_pnl += sell_pnl
                
                # Check win/loss
                total_trades += 1
                if sell_pnl > 0:
                    wins += 1
                elif sell_pnl < 0:
                    losses += 1
                    
        # Unrealized PnL (for open positions)
        if net_qty > 0:
            if is_live:
                # Live fluctuations: slightly fluctuate the price around the base mock price
                # but keep it clean and in Rupees
                base_price = get_stock_price(symbol)
                # Introduce a small deterministic fluctuation based on seconds to simulate ticks
                fluc = (hash(symbol + str(now.second // 5)) % 11 - 5) / 1000.0  # -0.5% to +0.5%
                current_price = base_price * (1 + fluc)
                unrealized_pnl = (current_price - avg_buy_price) * net_qty
            else:
                # If NOT connected to live, don't show dummy live pricing/pnl
                current_price = avg_buy_price
                unrealized_pnl = 0.0
                
            total_unrealized_pnl += unrealized_pnl
            
            positions.append(PositionState(
                symbol=symbol,
                qty=net_qty,
                buy_price=avg_buy_price,
                current_price=current_price,
                pnl=unrealized_pnl
            ))
            
    # Calculate final periods PnL
    # Periodic PnL includes realized pnl in that period + current unrealized pnl
    pnl_today = today_realized_pnl + total_unrealized_pnl
    pnl_weekly = weekly_realized_pnl + total_unrealized_pnl
    pnl_monthly = monthly_realized_pnl + total_unrealized_pnl
    pnl_total = total_realized_pnl + total_unrealized_pnl
    
    # Rates
    win_rate = 0.0
    loss_rate = 0.0
    if total_trades > 0:
        win_rate = wins / total_trades
        loss_rate = losses / total_trades
        
    # ROI based on standard initial simulated account of 100,000 INR
    roi = (pnl_total / 100000.0) * 100.0
    
    return {
        "balance": user.balance,
        "pnl_today": pnl_today,
        "pnl_weekly": pnl_weekly,
        "pnl_monthly": pnl_monthly,
        "pnl_total": pnl_total,
        "roi": roi,
        "win_rate": win_rate,
        "loss_rate": loss_rate,
        "positions": positions,
        "total_unrealized_pnl": total_unrealized_pnl
    }


@router.get("/dashboard", response_model=MobileDashboardResponse)
def get_mobile_dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    stats = calculate_pnl_stats(db, current_user)
    
    return MobileDashboardResponse(
        balance=stats["balance"],
        pnl=PnLPeriod(
            today=stats["pnl_today"],
            weekly=stats["pnl_weekly"],
            monthly=stats["pnl_monthly"],
            total=stats["pnl_total"]
        ),
        roi=stats["roi"],
        win_rate=stats["win_rate"],
        loss_rate=stats["loss_rate"],
        engine_running_state=(state.engine_status == "RUNNING")
    )


@router.get("/live-pnl", response_model=LivePnLResponse)
def get_mobile_live_pnl(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    stats = calculate_pnl_stats(db, current_user)
    return LivePnLResponse(
        total_unrealized_pnl=stats["total_unrealized_pnl"],
        positions=stats["positions"]
    )


@router.get("/active-strategies", response_model=list[StrategyResponse])
def get_active_strategies(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    strategies = db.query(Strategy).filter(Strategy.user_id == current_user.id).all()
    
    resp_list = []
    for stg in strategies:
        resp_list.append(StrategyResponse(
            strategy_id=stg.strategy_id,
            name=stg.name,
            enabled=stg.enabled,
            parameters=json.loads(stg.parameters)
        ))
    return resp_list


@router.get("/system-status", response_model=SystemStatusResponse)
def get_system_status(
    current_user: User = Depends(get_current_user)
):
    return SystemStatusResponse(
        engine_status=state.engine_status,
        broker_connection=state.broker_connection,
        simulation_mode=state.simulation_mode
    )


@router.get("/widget", response_model=WidgetPayloadResponse)
def get_widget_payload(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    stats = calculate_pnl_stats(db, current_user)
    
    # Fetch last executed trade
    last_order = db.query(Order).filter(
        Order.user_id == current_user.id,
        Order.status == "EXECUTED"
    ).order_by(Order.created_at.desc()).first()
    
    if last_order:
        last_filled_text = f"{last_order.transaction_type} {last_order.qty} {last_order.symbol} @ {last_order.execution_price:.2f} INR"
    else:
        last_filled_text = "No trades executed yet"
        
    return WidgetPayloadResponse(
        pnl_today=stats["pnl_today"],
        balance=stats["balance"],
        open_positions_count=len(stats["positions"]),
        last_filled_trade_text=last_filled_text
    )
