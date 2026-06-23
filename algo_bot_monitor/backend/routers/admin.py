from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from backend.deps import get_db, get_current_active_admin
from backend.models import User, Strategy, AuditLog
from backend.schemas import AdminDashboardResponse, PlatformMetrics, SystemMetrics, AuditLogResponse
from backend.utils.system import get_system_metrics

router = APIRouter(prefix="/api/admin", tags=["Admin Actions"])

@router.get("/dashboard", response_model=AdminDashboardResponse)
def get_admin_dashboard(
    current_admin: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    # Platform metrics
    active_users = db.query(func.count(User.id)).scalar() or 0
    running_strategies = db.query(func.count(Strategy.id)).filter(Strategy.enabled == True).scalar() or 0
    
    # System metrics
    sys_metrics = get_system_metrics()
    
    return AdminDashboardResponse(
        platform_metrics=PlatformMetrics(
            active_users_count=active_users,
            running_strategies_count=running_strategies
        ),
        system_metrics=SystemMetrics(
            cpu_utilization_percent=sys_metrics["cpu_utilization_percent"],
            memory_usage_percent=sys_metrics["memory_usage_percent"],
            disk_space_percent=sys_metrics["disk_space_percent"]
        )
    )

@router.get("/audit-logs", response_model=list[AuditLogResponse])
def get_audit_logs(
    current_admin: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    # Fetch all audit logs in descending chronological order
    logs = db.query(AuditLog).order_by(AuditLog.created_at.desc()).all()
    return logs
