import json
from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from backend.deps import get_db, get_current_user
from backend.models import User, AuditLog, BrokerCredentials, Strategy
from backend.schemas import UserRegister, UserResponse, TokenResponse, TokenRefreshRequest, BrokerCredentialsCreate
from backend.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    encrypt_data
)
from backend.utils.logger import log_system_event

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_in: UserRegister, db: Session = Depends(get_db)):
    # Check if user already exists
    user = db.query(User).filter(User.email == user_in.email).first()
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The user with this email already exists in the system.",
        )
    
    # Hash password and create User
    hashed_pwd = get_password_hash(user_in.password)
    new_user = User(
        email=user_in.email,
        hashed_password=hashed_pwd,
        role=user_in.role,
        balance=100000.0  # Initial account balance in INR
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Audit log
    audit_entry = AuditLog(
        event_type="USER_REGISTER",
        user_id=new_user.id,
        detail=f"User {new_user.email} registered successfully with role {new_user.role}."
    )
    db.add(audit_entry)
    
    # Seed default strategies for this user
    default_strategies = [
        {
            "strategy_id": "STG_MOMENTUM",
            "name": "Intraday Momentum",
            "enabled": True,
            "parameters": {"rsi_period": 14, "rsi_overbought": 70, "rsi_oversold": 30}
        },
        {
            "strategy_id": "STG_MEAN_REVERSION",
            "name": "Mean Reversion Bollinger Bands",
            "enabled": False,
            "parameters": {"bb_period": 20, "bb_std_dev": 2.0}
        },
        {
            "strategy_id": "STG_EMA_CROSS",
            "name": "EMA Crossover",
            "enabled": True,
            "parameters": {"fast_period": 9, "slow_period": 21}
        }
    ]
    
    for stg in default_strategies:
        strategy_entry = Strategy(
            user_id=new_user.id,
            strategy_id=stg["strategy_id"],
            name=stg["name"],
            enabled=stg["enabled"],
            parameters=json.dumps(stg["parameters"])
        )
        db.add(strategy_entry)
        
    db.commit()
    log_system_event("INFO", "auth", f"User {new_user.email} registered and default strategies seeded.")
    return new_user


@router.post("/login", response_model=TokenResponse)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    # Form data username is our email
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect email or password"
        )
    
    # Tokens
    access_token = create_access_token(data={"sub": user.email})
    refresh_token = create_refresh_token(data={"sub": user.email})
    
    # Audit log
    audit_entry = AuditLog(
        event_type="USER_LOGIN",
        user_id=user.id,
        detail=f"User {user.email} logged in successfully."
    )
    db.add(audit_entry)
    db.commit()
    
    log_system_event("INFO", "auth", f"User {user.email} logged in successfully.")
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


@router.post("/refresh", response_model=TokenResponse)
def refresh(
    body: TokenRefreshRequest,
    db: Session = Depends(get_db)
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(body.refresh_token)
        email: str = payload.get("sub")
        token_type: str = payload.get("type")
        if email is None or token_type != "refresh":
            raise credentials_exception
    except ValueError as e:
        raise credentials_exception from e
        
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    
    # Rotate tokens
    access_token = create_access_token(data={"sub": user.email})
    refresh_token = create_refresh_token(data={"sub": user.email})
    
    # Audit log
    audit_entry = AuditLog(
        event_type="TOKEN_REFRESH",
        user_id=user.id,
        detail=f"User {user.email} rotated access and refresh tokens."
    )
    db.add(audit_entry)
    db.commit()
    
    log_system_event("INFO", "auth", f"Tokens rotated for user {user.email}.")
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


@router.post("/broker-credentials")
def store_broker_credentials(
    credentials_in: BrokerCredentialsCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Encrypt inputs prior to storing in database
    enc_api_key = encrypt_data(credentials_in.api_key)
    enc_client_id = encrypt_data(credentials_in.client_id)
    enc_password = encrypt_data(credentials_in.password)
    enc_totp_secret = encrypt_data(credentials_in.totp_secret)
    
    # Check if credentials already exist
    broker_creds = db.query(BrokerCredentials).filter(BrokerCredentials.user_id == current_user.id).first()
    if broker_creds:
        broker_creds.encrypted_api_key = enc_api_key
        broker_creds.encrypted_client_id = enc_client_id
        broker_creds.encrypted_password = enc_password
        broker_creds.encrypted_totp_secret = enc_totp_secret
    else:
        broker_creds = BrokerCredentials(
            user_id=current_user.id,
            encrypted_api_key=enc_api_key,
            encrypted_client_id=enc_client_id,
            encrypted_password=enc_password,
            encrypted_totp_secret=enc_totp_secret
        )
        db.add(broker_creds)
        
    # Audit log
    audit_entry = AuditLog(
        event_type="BROKER_CREDENTIALS_UPDATE",
        user_id=current_user.id,
        detail=f"User {current_user.email} updated broker credentials."
    )
    db.add(audit_entry)
    db.commit()
    
    log_system_event("INFO", "auth", f"Broker credentials encrypted and stored for user {current_user.email}.")
    
    return {"message": "Broker credentials encrypted and stored successfully."}
