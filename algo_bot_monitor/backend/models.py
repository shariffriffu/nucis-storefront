from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Boolean, Text
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from backend.database import Base

def utcnow():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="USER", nullable=False)  # "USER" or "ADMIN"
    balance = Column(Float, default=100000.0, nullable=False) # Current account balance in Indian Rupees (INR)
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships
    broker_credentials = relationship("BrokerCredentials", back_populates="user", uselist=False, cascade="all, delete-orphan")
    orders = relationship("Order", back_populates="user", cascade="all, delete-orphan")
    strategies = relationship("Strategy", back_populates="user", cascade="all, delete-orphan")


class BrokerCredentials(Base):
    __tablename__ = "broker_credentials"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    encrypted_api_key = Column(String, nullable=False)
    encrypted_client_id = Column(String, nullable=False)
    encrypted_password = Column(String, nullable=False)
    encrypted_totp_secret = Column(String, nullable=False)
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="broker_credentials")


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    symbol = Column(String, nullable=False)
    qty = Column(Integer, nullable=False)
    transaction_type = Column(String, nullable=False)  # "BUY" or "SELL"
    product_type = Column(String, nullable=False)      # "INTRADAY" or "CNC"
    broker_order_id = Column(String, unique=True, nullable=False)
    execution_price = Column(Float, nullable=False)     # Price in Indian Rupees (INR)
    status = Column(String, default="EXECUTED", nullable=False)  # "EXECUTED", "FAILED", "PENDING"
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="orders")


class SystemLog(Base):
    __tablename__ = "system_logs"

    id = Column(Integer, primary_key=True, index=True)
    level = Column(String, nullable=False)  # "INFO", "WARNING", "ERROR"
    module = Column(String, nullable=False)
    message = Column(String, nullable=False)
    exception_trace = Column(Text, nullable=True)
    created_at = Column(DateTime, default=utcnow, nullable=False)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    event_type = Column(String, nullable=False)  # e.g., "USER_REGISTER", "USER_LOGIN", "BROKER_CREDENTIALS_UPDATE"
    user_id = Column(Integer, nullable=True)     # ID of the user triggering the event (null if system level)
    detail = Column(Text, nullable=False)
    created_at = Column(DateTime, default=utcnow, nullable=False)


class Strategy(Base):
    __tablename__ = "strategies"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    strategy_id = Column(String, nullable=False)        # e.g. "STG_MOMENTUM"
    name = Column(String, nullable=False)               # Human readable name
    enabled = Column(Boolean, default=False, nullable=False)
    parameters = Column(Text, nullable=False)           # JSON string storing strategy parameters
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="strategies")
