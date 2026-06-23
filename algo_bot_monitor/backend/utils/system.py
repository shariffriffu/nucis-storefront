import psutil

def get_system_metrics():
    try:
        cpu_percent = psutil.cpu_percent(interval=None)
        # In case the first call is 0.0, we just ensure a sensible reading or return it
        memory_percent = psutil.virtual_memory().percent
        # Retrieve disk info for current workspace drive or default root
        disk_percent = psutil.disk_usage('/').percent
        return {
            "cpu_utilization_percent": cpu_percent,
            "memory_usage_percent": memory_percent,
            "disk_space_percent": disk_percent
        }
    except Exception:
        # Fallbacks in case environment doesn't allow parsing resource paths
        return {
            "cpu_utilization_percent": 0.0,
            "memory_usage_percent": 0.0,
            "disk_space_percent": 0.0
        }
