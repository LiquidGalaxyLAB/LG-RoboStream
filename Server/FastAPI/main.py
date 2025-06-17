# c:\Users\alexb\Documents\GSOC-lg\RoboStreamApp\robot_api\main.py
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import asyncio
import json
import random
import time
from typing import Dict, List
import uvicorn

app = FastAPI(title="Robot Sensor API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ThreeAxisData(BaseModel):
    x: float
    y: float
    z: float

class IMUData(BaseModel):
    accelerometer: ThreeAxisData
    gyroscope: ThreeAxisData
    magnetometer: ThreeAxisData

class GPSData(BaseModel):
    latitude: float
    longitude: float
    altitude: float
    speed: float
    satellites: int

class SensorData(BaseModel):
    timestamp: float
    imu: IMUData
    gps: GPSData
    lidar: str
    camera: str

class ServoData(BaseModel):
    speed: int
    temperature: float
    consumption: float
    voltage: float
    status: str

class ActuatorData(BaseModel):
    front_left_wheel: ServoData
    front_right_wheel: ServoData
    back_left_wheel: ServoData
    back_right_wheel: ServoData

class RobotSimulator:
    def __init__(self):
        # Base GPS coordinates for Plaza de España, Madrid
        self.base_lat = 40.4238
        self.base_lon = -3.7123
        
        self.sensor_data = SensorData(
            timestamp=time.time(),
            imu=IMUData(
                accelerometer=ThreeAxisData(x=0.0, y=0.0, z=-9.8),
                gyroscope=ThreeAxisData(x=0.0, y=0.0, z=0.0),
                magnetometer=ThreeAxisData(x=0.0, y=0.0, z=0.0)
            ),
            gps=GPSData(
                latitude=self.base_lat,
                longitude=self.base_lon,
                altitude=655.0,
                speed=0.0,
                satellites=10
            ),
            lidar="Connected",
            camera="Streaming"
        )
        
        self.actuator_data = ActuatorData(
            front_left_wheel=self._create_servo_data(),
            front_right_wheel=self._create_servo_data(),
            back_left_wheel=self._create_servo_data(),
            back_right_wheel=self._create_servo_data()
        )
    
    def _create_servo_data(self) -> ServoData:
        """Create random servo data for a wheel"""
        return ServoData(
            speed=random.randint(0, 150),
            temperature=round(random.uniform(35.0, 75.5), 1),
            consumption=round(random.uniform(1.5, 5.0), 2),
            voltage=round(random.uniform(11.8, 12.5), 1),
            status="Operational" if random.random() > 0.05 else "Error"
        )
    
    def _create_three_axis_data(self, min_val: float = -9.8, max_val: float = 9.8) -> ThreeAxisData:
        """Create random three-axis data"""
        return ThreeAxisData(
            x=round(random.uniform(min_val, max_val), 2),
            y=round(random.uniform(min_val, max_val), 2),
            z=round(random.uniform(min_val, max_val), 2)
        )
    
    def update_sensors(self):
        """Simulate sensor data changes"""
        self.sensor_data.timestamp = time.time()
        
        # Update IMU data
        self.sensor_data.imu.accelerometer = self._create_three_axis_data()
        self.sensor_data.imu.gyroscope = self._create_three_axis_data()
        self.sensor_data.imu.magnetometer = self._create_three_axis_data()
        
        # Update GPS data with slight movement around base coordinates
        self.sensor_data.gps.latitude = self.base_lat + random.uniform(-0.0001, 0.0001)
        self.sensor_data.gps.longitude = self.base_lon + random.uniform(-0.0001, 0.0001)
        self.sensor_data.gps.altitude = round(random.uniform(650.0, 660.0), 1)
        self.sensor_data.gps.speed = round(random.uniform(0.0, 5.0), 1)
        self.sensor_data.gps.satellites = random.randint(8, 12)
        
        # LiDAR and Camera status remain constant
        self.sensor_data.lidar = "Connected"
        self.sensor_data.camera = "Streaming"
        
        # Update actuator data
        self.actuator_data.front_left_wheel = self._create_servo_data()
        self.actuator_data.front_right_wheel = self._create_servo_data()
        self.actuator_data.back_left_wheel = self._create_servo_data()
        self.actuator_data.back_right_wheel = self._create_servo_data()

robot = RobotSimulator()
connected_clients: List[WebSocket] = []

@app.get("/")
async def root():
    return {"message": "Robot Sensor API", "status": "running"}

@app.get("/sensors", response_model=SensorData)
async def get_sensors():
    robot.update_sensors()
    return robot.sensor_data

@app.get("/actuators", response_model=ActuatorData)
async def get_actuators():
    robot.update_sensors()
    return robot.actuator_data

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_clients.append(websocket)
    try:
        while True:
            robot.update_sensors()
            data = {
                "sensors": robot.sensor_data.dict(),
                "actuators": robot.actuator_data.dict()
            }
            await websocket.send_text(json.dumps(data))
            await asyncio.sleep(1)
    except WebSocketDisconnect:
        connected_clients.remove(websocket)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)