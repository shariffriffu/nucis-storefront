import logging
import traceback
from datetime import datetime, timezone
from backend.database import SessionLocal
from backend.models import SystemLog

# Configure basic logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("algo_bot")

def log_system_event(level: str, module: str, message: str, exception: Exception = None):
    # Log to standard console
    log_msg = f"[{module}] {message}"
    if level == "INFO":
        logger.info(log_msg)
    elif level == "WARNING":
        logger.warning(log_msg)
    elif level == "ERROR":
        logger.error(log_msg)
    
    # Format traceback if exception exists
    exc_trace = None
    if exception:
        exc_trace = "".join(traceback.format_exception(type(exception), exception, exception.__traceback__))
        if level == "ERROR":
            logger.error(f"Exception Trace: {exc_trace}")

    # Log to SQLite Database
    db = SessionLocal()
    try:
        db_log = SystemLog(
            level=level,
            module=module,
            message=message,
            exception_trace=exc_trace,
            created_at=datetime.now(timezone.utc)
        )
        db.add(db_log)
        db.commit()
    except Exception as db_err:
        logger.error(f"Failed to save system log to database: {db_err}")
    finally:
        db.close()
