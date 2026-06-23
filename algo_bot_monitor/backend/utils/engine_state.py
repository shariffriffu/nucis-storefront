class EngineState:
    def __init__(self):
        self.engine_status: str = "RUNNING"          # "RUNNING" or "STOPPED"
        self.broker_connection: str = "CONNECTED"     # "CONNECTED" or "DISCONNECTED"
        self.simulation_mode: bool = True

state = EngineState()
