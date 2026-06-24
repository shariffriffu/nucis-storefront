import os
import pytest

# Override database URL for testing BEFORE imports
os.environ["DATABASE_URL"] = "sqlite:///./test_algo_bot.db"

from backend.config import settings
settings.DATABASE_URL = "sqlite:///./test_algo_bot.db"

from fastapi.testclient import TestClient
from backend.database import Base, engine, SessionLocal
from backend.main import app
from backend.models import User, BrokerCredentials, Order, Strategy, AuditLog
from backend.security import decrypt_data
from backend.utils.engine_state import state

client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def setup_database():
    # Setup tables
    Base.metadata.create_all(bind=engine)
    yield
    # Teardown
    Base.metadata.drop_all(bind=engine)
    # Remove test DB file if it exists
    if os.path.exists("./test_algo_bot.db"):
        try:
            os.remove("./test_algo_bot.db")
        except Exception:
            pass


def test_auth_flow():
    # 1. Test register USER
    reg_response = client.post("/api/auth/register", json={
        "email": "user@example.com",
        "password": "userpassword",
        "role": "USER"
    })
    assert reg_response.status_code == 201
    assert reg_response.json()["email"] == "user@example.com"
    assert reg_response.json()["role"] == "USER"
    assert reg_response.json()["balance"] == 100000.0  # Balance in Rupees
    
    # 2. Test register ADMIN
    reg_admin = client.post("/api/auth/register", json={
        "email": "admin@example.com",
        "password": "adminpassword",
        "role": "ADMIN"
    })
    assert reg_admin.status_code == 201
    assert reg_admin.json()["role"] == "ADMIN"

    # 3. Test register duplicate
    dup_response = client.post("/api/auth/register", json={
        "email": "user@example.com",
        "password": "anotherpassword",
        "role": "USER"
    })
    assert dup_response.status_code == 400
    assert "already exists" in dup_response.json()["detail"]

    # 4. Test login USER
    login_response = client.post("/api/auth/login", data={
        "username": "user@example.com",
        "password": "userpassword"
    })
    assert login_response.status_code == 200
    tokens = login_response.json()
    assert "access_token" in tokens
    assert "refresh_token" in tokens
    assert tokens["token_type"] == "bearer"

    # 5. Test login ADMIN
    login_admin = client.post("/api/auth/login", data={
        "username": "admin@example.com",
        "password": "adminpassword"
    })
    assert login_admin.status_code == 200
    admin_tokens = login_admin.json()

    # 6. Test login fail
    fail_login = client.post("/api/auth/login", data={
        "username": "user@example.com",
        "password": "wrongpassword"
    })
    assert fail_login.status_code == 400

    # 7. Test token refresh
    refresh_resp = client.post("/api/auth/refresh", json={
        "refresh_token": tokens["refresh_token"]
    })
    assert refresh_resp.status_code == 200
    rotated_tokens = refresh_resp.json()
    assert "access_token" in rotated_tokens
    assert "refresh_token" in rotated_tokens


def test_broker_credentials_encryption():
    # Login to get token
    login_resp = client.post("/api/auth/login", data={
        "username": "user@example.com",
        "password": "userpassword"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Store credentials
    creds_payload = {
        "api_key": "my_api_key_123",
        "client_id": "client_abc",
        "password": "brokerpassword",
        "totp_secret": "totpsecret123"
    }
    resp = client.post("/api/auth/broker-credentials", json=creds_payload, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["message"] == "Broker credentials encrypted and stored successfully."

    # Direct query of the test database to assert that credentials are encrypted in DB
    db = SessionLocal()
    db_user = db.query(User).filter(User.email == "user@example.com").first()
    db_creds = db.query(BrokerCredentials).filter(BrokerCredentials.user_id == db_user.id).first()
    
    assert db_creds is not None
    # Database columns should hold encrypted strings, not plaintext
    assert db_creds.encrypted_api_key != creds_payload["api_key"]
    assert db_creds.encrypted_client_id != creds_payload["client_id"]
    assert db_creds.encrypted_password != creds_payload["password"]
    assert db_creds.encrypted_totp_secret != creds_payload["totp_secret"]

    # Assert that decrypting them returns the original plain text
    assert decrypt_data(db_creds.encrypted_api_key) == creds_payload["api_key"]
    assert decrypt_data(db_creds.encrypted_client_id) == creds_payload["client_id"]
    assert decrypt_data(db_creds.encrypted_password) == creds_payload["password"]
    assert decrypt_data(db_creds.encrypted_totp_secret) == creds_payload["totp_secret"]
    db.close()


def test_trading_core_and_orders():
    # Login user
    login_resp = client.post("/api/auth/login", data={
        "username": "user@example.com",
        "password": "userpassword"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Place valid BUY order
    buy_resp = client.post(
        "/api/orders?symbol=RELIANCE&qty=10&transaction_type=BUY&product_type=CNC",
        headers=headers
    )
    assert buy_resp.status_code == 200
    assert buy_resp.json()["message"] == "Order executed successfully"
    assert "broker_order_id" in buy_resp.json()
    
    # Verify user balance deducted in database (RELIANCE price is 2450.00 * 10 = 24500.0)
    # Start balance was 100000.0, should now be 75500.0
    db = SessionLocal()
    db_user = db.query(User).filter(User.email == "user@example.com").first()
    assert db_user.balance == 75500.0
    
    # 2. Place SELL order with enough holdings
    sell_resp = client.post(
        "/api/orders?symbol=RELIANCE&qty=4&transaction_type=SELL&product_type=CNC",
        headers=headers
    )
    assert sell_resp.status_code == 200
    # Balance should increase by (2450.00 * 4 = 9800.0) -> 85300.0
    db.refresh(db_user)
    assert db_user.balance == 85300.0

    # 3. Place SELL order with insufficient holdings (exceeds holdings of 6 RELIANCE left)
    sell_fail = client.post(
        "/api/orders?symbol=RELIANCE&qty=10&transaction_type=SELL&product_type=CNC",
        headers=headers
    )
    assert sell_fail.status_code == 400
    assert "Insufficient holdings to sell" in sell_fail.json()["detail"]

    # 4. Place BUY order with insufficient balance (85300.0 / 2450.00 = ~34 max shares)
    buy_fail = client.post(
        "/api/orders?symbol=RELIANCE&qty=50&transaction_type=BUY&product_type=CNC",
        headers=headers
    )
    assert buy_fail.status_code == 400
    assert "Insufficient balance" in buy_fail.json()["detail"]

    # 5. Get user orders list
    orders_list = client.get("/api/orders", headers=headers)
    assert orders_list.status_code == 200
    assert len(orders_list.json()) >= 2  # The executing ones and failing ones are stored

    # 6. Fetch logs
    logs_resp = client.get("/api/logs", headers=headers)
    assert logs_resp.status_code == 200
    assert len(logs_resp.json()) > 0
    db.close()


def test_mobile_endpoints():
    login_resp = client.post("/api/auth/login", data={
        "username": "user@example.com",
        "password": "userpassword"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. System status
    status_resp = client.get("/api/mobile/system-status", headers=headers)
    assert status_resp.status_code == 200
    assert status_resp.json()["engine_status"] == "RUNNING"
    assert status_resp.json()["broker_connection"] == "CONNECTED"

    # 2. Live PnL (in connected state: should fluctuate / show active status)
    pnl_resp = client.get("/api/mobile/live-pnl", headers=headers)
    assert pnl_resp.status_code == 200
    assert "total_unrealized_pnl" in pnl_resp.json()
    positions = pnl_resp.json()["positions"]
    assert len(positions) == 1  # We have 6 net shares of RELIANCE
    assert positions[0]["symbol"] == "RELIANCE"
    assert positions[0]["qty"] == 6

    # Test "no-dummy-data when disconnected" constraint
    # Change broker connection state to DISCONNECTED
    state.broker_connection = "DISCONNECTED"
    pnl_disconnected = client.get("/api/mobile/live-pnl", headers=headers)
    assert pnl_disconnected.status_code == 200
    assert pnl_disconnected.json()["total_unrealized_pnl"] == 0.0
    assert pnl_disconnected.json()["positions"][0]["pnl"] == 0.0
    assert pnl_disconnected.json()["positions"][0]["current_price"] == pnl_disconnected.json()["positions"][0]["buy_price"]
    
    # Restore connection state
    state.broker_connection = "CONNECTED"

    # 3. Active strategies
    strategies_resp = client.get("/api/mobile/active-strategies", headers=headers)
    assert strategies_resp.status_code == 200
    assert len(strategies_resp.json()) == 3
    assert strategies_resp.json()[0]["strategy_id"] == "STG_MOMENTUM"

    # 4. Dashboard
    dash_resp = client.get("/api/mobile/dashboard", headers=headers)
    assert dash_resp.status_code == 200
    assert dash_resp.json()["balance"] == 85300.0
    assert "pnl" in dash_resp.json()

    # 5. Widget payload
    widget_resp = client.get("/api/mobile/widget", headers=headers)
    assert widget_resp.status_code == 200
    assert widget_resp.json()["balance"] == 85300.0
    assert "SELL 4 RELIANCE" in widget_resp.json()["last_filled_trade_text"]


def test_admin_only_endpoints():
    # Login simple user
    login_user = client.post("/api/auth/login", data={
        "username": "user@example.com",
        "password": "userpassword"
    })
    user_token = login_user.json()["access_token"]
    user_headers = {"Authorization": f"Bearer {user_token}"}

    # Login admin
    login_admin = client.post("/api/auth/login", data={
        "username": "admin@example.com",
        "password": "adminpassword"
    })
    admin_token = login_admin.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. Attempt admin dashboard with USER token -> Expect 403
    dash_user_fail = client.get("/api/admin/dashboard", headers=user_headers)
    assert dash_user_fail.status_code == 403

    # 2. Attempt admin dashboard with ADMIN token -> Expect 200
    dash_admin_success = client.get("/api/admin/dashboard", headers=admin_headers)
    assert dash_admin_success.status_code == 200
    assert "platform_metrics" in dash_admin_success.json()
    assert "system_metrics" in dash_admin_success.json()

    # 3. Attempt audit logs with USER token -> Expect 403
    audit_user_fail = client.get("/api/admin/audit-logs", headers=user_headers)
    assert audit_user_fail.status_code == 403

    # 4. Attempt audit logs with ADMIN token -> Expect 200
    audit_admin_success = client.get("/api/admin/audit-logs", headers=admin_headers)
    assert audit_admin_success.status_code == 200
    assert len(audit_admin_success.json()) > 0


def test_health_and_metrics_endpoints():
    # Health check
    health_resp = client.get("/health")
    assert health_resp.status_code == 200
    assert health_resp.json()["status"] == "healthy"
    assert health_resp.json()["database"] == "available"

    # Prometheus metrics scraping
    metrics_resp = client.get("/metrics")
    assert metrics_resp.status_code == 200
    assert "http_requests_total" in metrics_resp.text


def test_new_synced_endpoints():
    login_resp = client.post("/api/auth/login", data={
        "username": "user@example.com",
        "password": "userpassword"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Trade history
    history_resp = client.get("/api/mobile/trade-history", headers=headers)
    assert history_resp.status_code == 200
    assert isinstance(history_resp.json(), list)

    # 2. Open positions
    open_pos_resp = client.get("/api/mobile/open-positions", headers=headers)
    assert open_pos_resp.status_code == 200
    assert isinstance(open_pos_resp.json(), list)

    # 3. Closed positions
    closed_pos_resp = client.get("/api/mobile/closed-positions", headers=headers)
    assert closed_pos_resp.status_code == 200
    assert isinstance(closed_pos_resp.json(), list)

    # 4. Watchlist
    watchlist_resp = client.get("/api/watchlist", headers=headers)
    assert watchlist_resp.status_code == 200
    assert "watchlist" in watchlist_resp.json()

    # 5. Strategies configurations
    strat_resp = client.get("/api/strategies", headers=headers)
    assert strat_resp.status_code == 200
    assert isinstance(strat_resp.json(), list)

    # 6. Toggle strategy
    toggle_resp = client.post("/api/strategies/STG_MOMENTUM/toggle", headers=headers)
    assert toggle_resp.status_code == 200
    assert toggle_resp.json()["enabled"] is False # toggled from true to false

