import asyncio
import logging
from typing import Dict, Set
from fastapi import WebSocket

logger = logging.getLogger("algo_bot")

class ConnectionManager:
    def __init__(self):
        # Maps channel name to set of active WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {
            "pnl": set(),
            "trades": set(),
            "orders": set(),
            "system": set()
        }

    async def connect(self, websocket: WebSocket, channel: str):
        await websocket.accept()
        if channel in self.active_connections:
            self.active_connections[channel].add(websocket)
            logger.info(f"WebSocket client connected to channel: {channel}. Total: {len(self.active_connections[channel])}")
        else:
            # If a custom channel is used, initialize it
            self.active_connections[channel] = {websocket}
            logger.info(f"WebSocket client connected to custom channel: {channel}.")

    def disconnect(self, websocket: WebSocket, channel: str):
        if channel in self.active_connections and websocket in self.active_connections[channel]:
            self.active_connections[channel].remove(websocket)
            logger.info(f"WebSocket client disconnected from channel: {channel}. Total: {len(self.active_connections[channel])}")

    async def broadcast(self, message: dict, channel: str):
        # 1. Send to target channel
        if channel in self.active_connections:
            targets = list(self.active_connections[channel])
            for connection in targets:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.debug(f"Failed to send WS message on channel {channel}: {e}")
                    if connection in self.active_connections[channel]:
                        self.active_connections[channel].remove(connection)
                        
        # 2. Also forward to "all" channel if active
        if "all" in self.active_connections:
            targets_all = list(self.active_connections["all"])
            for connection in targets_all:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.debug(f"Failed to send WS message on multiplex channel 'all': {e}")
                    if connection in self.active_connections["all"]:
                        self.active_connections["all"].remove(connection)

# Global singleton connection manager
manager = ConnectionManager()
