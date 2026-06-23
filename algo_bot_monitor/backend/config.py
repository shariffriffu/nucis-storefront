import os
from pydantic_settings import BaseSettings
from cryptography.fernet import Fernet

class Settings(BaseSettings):
    PROJECT_NAME: str = "Algo Trading Bot Monitor Backend"
    API_V1_STR: str = "/api"
    
    # Database
    DATABASE_URL: str = "sqlite:///./algo_bot.db"
    
    # JWT Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "705f4fa6e811bc0e5c54e3d36b856b3e248b6cbfb6028a30cf7f98bbf88b3941")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Broker Credentials Encryption Key (Fernet key)
    # Automatically generates a random secure Fernet key if not set in environment
    FERNET_KEY: str = os.getenv("FERNET_KEY", "")

    model_config = {
        "env_file": ".env",
        "case_sensitive": True
    }

# Instantiate settings
settings = Settings()

# Ensure Fernet Key is set and valid
if not settings.FERNET_KEY:
    settings.FERNET_KEY = Fernet.generate_key().decode()
