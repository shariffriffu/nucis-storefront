import uuid
import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func

from backend.deps import get_db, get_current_user
from backend.models import User, Order, SystemLog, AuditLog, Strategy
from backend.schemas import (
    OrderResponse,
    SystemLogResponse,
    OrderExecutionResponse,
    WatchlistResponse,
    WatchlistSymbol,
    StrategyConfigResponse
)
from backend.utils.logger import log_system_event
from backend.utils.ws_manager import manager

router = APIRouter(tags=["Trading Core"])

# Stock prices in Rupees
MOCK_STOCK_PRICES = {
    "RELIANCE": 2450.00,
    "TCS": 3200.00,
    "INFY": 1450.00,
    "HDFCBANK": 1600.00,
    "SBIN": 580.00,
}

def get_stock_price(symbol: str) -> float:
    # Capitalize symbol
    sym = symbol.upper().strip()
    return MOCK_STOCK_PRICES.get(sym, 100.00)

@router.post("/orders", response_model=OrderExecutionResponse)
async def execute_order(
    symbol: str = Query(..., min_length=1, max_length=20),
    qty: int = Query(..., gt=0),
    transaction_type: str = Query(..., pattern="^(BUY|SELL)$"),
    product_type: str = Query(..., pattern="^(INTRADAY|CNC)$"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    symbol = symbol.upper().strip()
    exec_price = get_stock_price(symbol)
    total_cost = qty * exec_price
    broker_order_id = f"BKR_{uuid.uuid4().hex[:10].upper()}"
    
    # 1. Verification of user holdings or balance
    if transaction_type == "BUY":
        if current_user.balance < total_cost:
            # Order fails due to insufficient balance
            failed_order = Order(
                user_id=current_user.id,
                symbol=symbol,
                qty=qty,
                transaction_type=transaction_type,
                product_type=product_type,
                broker_order_id=broker_order_id,
                execution_price=exec_price,
                status="FAILED",
                created_at=datetime.now(timezone.utc)
            )
            db.add(failed_order)
            db.commit()
            
            log_system_event("WARNING", "trading", f"Order {broker_order_id} failed: User {current_user.email} has insufficient balance. Required: {total_cost} INR, Available: {current_user.balance} INR")
            
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient balance. Required: {total_cost} INR, Available: {current_user.balance} INR"
            )
            
        # Deduct balance
        current_user.balance -= total_cost
        
    elif transaction_type == "SELL":
        # For CNC, check if user has enough shares to sell
        if product_type == "CNC":
            # Calculate executed buy shares
            buy_shares = db.query(func.sum(Order.qty)).filter(
                Order.user_id == current_user.id,
                Order.symbol == symbol,
                Order.transaction_type == "BUY",
                Order.status == "EXECUTED"
            ).scalar() or 0
            
            # Calculate executed sell shares
            sell_shares = db.query(func.sum(Order.qty)).filter(
                Order.user_id == current_user.id,
                Order.symbol == symbol,
                Order.transaction_type == "SELL",
                Order.status == "EXECUTED"
            ).scalar() or 0
            
            holdings = buy_shares - sell_shares
            if holdings < qty:
                # Order fails due to insufficient holdings
                failed_order = Order(
                    user_id=current_user.id,
                    symbol=symbol,
                    qty=qty,
                    transaction_type=transaction_type,
                    product_type=product_type,
                    broker_order_id=broker_order_id,
                    execution_price=exec_price,
                    status="FAILED",
                    created_at=datetime.now(timezone.utc)
                )
                db.add(failed_order)
                db.commit()
                
                log_system_event("WARNING", "trading", f"Order {broker_order_id} failed: User {current_user.email} has insufficient holdings for {symbol}. Required: {qty}, Available: {holdings}")
                
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Insufficient holdings to sell. Required: {qty}, Available: {holdings}"
                )
                
        # Add to balance
        current_user.balance += total_cost

    # 2. Save executed order
    new_order = Order(
        user_id=current_user.id,
        symbol=symbol,
        qty=qty,
        transaction_type=transaction_type,
        product_type=product_type,
        broker_order_id=broker_order_id,
        execution_price=exec_price,
        status="EXECUTED",
        created_at=datetime.now(timezone.utc)
    )
    db.add(new_order)
    db.commit()
    db.refresh(new_order)
    
    # 3. Write Audit Log
    audit_entry = AuditLog(
        event_type="ORDER_EXECUTION",
        user_id=current_user.id,
        detail=f"Executed {transaction_type} order for {qty} shares of {symbol} at {exec_price} INR (Product: {product_type}). Broker Order ID: {broker_order_id}"
    )
    db.add(audit_entry)
    db.commit()
    
    log_system_event("INFO", "trading", f"Order {broker_order_id} executed successfully for {current_user.email}. {transaction_type} {qty} {symbol} @ {exec_price} INR")
    
    # 4. Broadcast on WebSockets
    # Broadcast order update
    await manager.broadcast({
        "channel": "orders",
        "type": "order_update",
        "data": {
            "id": new_order.id,
            "symbol": new_order.symbol,
            "qty": new_order.qty,
            "transaction_type": new_order.transaction_type,
            "product_type": new_order.product_type,
            "broker_order_id": new_order.broker_order_id,
            "execution_price": new_order.execution_price,
            "status": new_order.status,
            "created_at": new_order.created_at.isoformat()
        }
    }, "orders")
    
    # Broadcast trade filled
    await manager.broadcast({
        "channel": "trades",
        "type": "trade_filled",
        "data": {
            "symbol": new_order.symbol,
            "qty": new_order.qty,
            "price": new_order.execution_price,
            "side": new_order.transaction_type,
            "timestamp": new_order.created_at.isoformat()
        }
    }, "trades")
    
    return {
        "message": "Order executed successfully",
        "broker_order_id": new_order.broker_order_id
    }


@router.get("/orders", response_model=list[OrderResponse])
def get_user_orders(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    orders = db.query(Order).filter(Order.user_id == current_user.id).order_by(Order.created_at.desc()).all()
    return orders


@router.get("/logs", response_model=list[SystemLogResponse])
def get_system_logs(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Fetch 100 most recent logs
    logs = db.query(SystemLog).order_by(SystemLog.created_at.desc()).limit(100).all()
    # Reverse to keep chronological order or keep newest first as requested (List of the 100 most recent system execution logs)
    return logs


@router.get("/watchlist", response_model=WatchlistResponse)
def get_watchlist(current_user: User = Depends(get_current_user)):
    symbols_data = [
        {"symbol": "RELIANCE", "price": 2450.00, "pct_change": 1.2, "rel_vol": 1.5, "scores": {"S1": 85, "S2": 90, "S3": 60, "S4": 70, "S5": 50}},
        {"symbol": "TCS", "price": 3200.00, "pct_change": -0.8, "rel_vol": 0.9, "scores": {"S1": 40, "S2": 30, "S3": 75, "S4": 80, "S5": 60}},
        {"symbol": "INFY", "price": 1450.00, "pct_change": 2.1, "rel_vol": 2.4, "scores": {"S1": 95, "S2": 95, "S3": 90, "S4": 85, "S5": 70}},
        {"symbol": "HDFCBANK", "price": 1600.00, "pct_change": 0.3, "rel_vol": 1.1, "scores": {"S1": 60, "S2": 55, "S3": 50, "S4": 40, "S5": 45}},
        {"symbol": "SBIN", "price": 580.00, "pct_change": -1.5, "rel_vol": 1.8, "scores": {"S1": 20, "S2": 30, "S3": 40, "S4": 50, "S5": 80}}
    ]
    return WatchlistResponse(watchlist=[WatchlistSymbol(**s) for s in symbols_data])


@router.post("/positions/{position_id}/close")
async def force_exit_position(
    position_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    symbol = position_id.upper().strip()
    
    orders = db.query(Order).filter(
        Order.user_id == current_user.id,
        Order.symbol == symbol,
        Order.status == "EXECUTED"
    ).all()
    
    buy_qty = sum(o.qty for o in orders if o.transaction_type == "BUY")
    sell_qty = sum(o.qty for o in orders if o.transaction_type == "SELL")
    net_qty = buy_qty - sell_qty
    
    if net_qty <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No active position to close for symbol {symbol}."
        )
    
    exec_price = get_stock_price(symbol)
    broker_order_id = f"BKR_CLS_{uuid.uuid4().hex[:10].upper()}"
    
    current_user.balance += net_qty * exec_price
    
    close_order = Order(
        user_id=current_user.id,
        symbol=symbol,
        qty=net_qty,
        transaction_type="SELL",
        product_type="INTRADAY",
        broker_order_id=broker_order_id,
        execution_price=exec_price,
        status="EXECUTED",
        created_at=datetime.now(timezone.utc)
    )
    db.add(close_order)
    
    audit_entry = AuditLog(
        event_type="FORCE_EXIT",
        user_id=current_user.id,
        detail=f"Force-closed position for {symbol}. Sold {net_qty} shares at {exec_price} INR. Broker Order ID: {broker_order_id}"
    )
    db.add(audit_entry)
    db.commit()
    
    log_system_event("WARNING", "trading", f"Manual force-exit triggered for {symbol} by {current_user.email}. Closed {net_qty} shares.")
    
    await manager.broadcast({
        "channel": "orders",
        "type": "order_update",
        "data": {
            "id": close_order.id,
            "symbol": close_order.symbol,
            "qty": close_order.qty,
            "transaction_type": close_order.transaction_type,
            "product_type": close_order.product_type,
            "broker_order_id": close_order.broker_order_id,
            "execution_price": close_order.execution_price,
            "status": close_order.status,
            "created_at": close_order.created_at.isoformat()
        }
    }, "orders")
    
    await manager.broadcast({
        "channel": "trades",
        "type": "trade_filled",
        "data": {
            "symbol": close_order.symbol,
            "qty": close_order.qty,
            "price": close_order.execution_price,
            "side": close_order.transaction_type,
            "timestamp": close_order.created_at.isoformat()
        }
    }, "trades")
    
    return {
        "message": f"Position for {symbol} force-closed successfully.",
        "broker_order_id": broker_order_id
    }


@router.get("/strategies", response_model=list[StrategyConfigResponse])
def get_strategies_configs(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    strategies = db.query(Strategy).filter(Strategy.user_id == current_user.id).all()
    configs = []
    for stg in strategies:
        configs.append(StrategyConfigResponse(
            name=stg.name,
            enabled=stg.enabled,
            parameters=json.loads(stg.parameters)
        ))
    return configs


@router.post("/strategies/{name}/toggle")
def toggle_strategy(
    name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    stg = db.query(Strategy).filter(
        Strategy.user_id == current_user.id,
        (Strategy.name == name) | (Strategy.strategy_id == name)
    ).first()
    
    if not stg:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Strategy '{name}' not found."
        )
    
    stg.enabled = not stg.enabled
    
    audit_entry = AuditLog(
        event_type="STRATEGY_TOGGLE",
        user_id=current_user.id,
        detail=f"Toggled strategy '{stg.name}' state to {stg.enabled}."
    )
    db.add(audit_entry)
    db.commit()
    
    log_system_event("INFO", "trading", f"Strategy '{stg.name}' toggled to {stg.enabled} by {current_user.email}.")
    
    return {
        "message": f"Strategy '{stg.name}' toggled successfully.",
        "name": stg.name,
        "enabled": stg.enabled
    }
