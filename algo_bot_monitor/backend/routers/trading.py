import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func

from backend.deps import get_db, get_current_user
from backend.models import User, Order, SystemLog, AuditLog
from backend.schemas import OrderResponse, SystemLogResponse, OrderExecutionResponse
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
