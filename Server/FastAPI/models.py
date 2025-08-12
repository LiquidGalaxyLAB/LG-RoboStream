from pydantic import BaseModel
from typing import Optional

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

class RGBCameraData(BaseModel):
    camera_id: str
    resolution: str
    fps: int
    status: str
    current_image: str
    image_timestamp: float
    images_available: int
    rotation_interval: int

class SensorData(BaseModel):
    timestamp: float
    imu: IMUData
    gps: GPSData
    lidar: str
    camera: str
    rgb_camera: RGBCameraData

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

# Orbit models
class OrbitRequest(BaseModel):
    latitude: float
    longitude: float
    zoom: Optional[int] = 4000
    tilt: Optional[int] = 60
    steps: Optional[int] = 30
    step_ms: Optional[int] = 500
    start_heading: Optional[float] = 0.0

class OrbitStopRequest(BaseModel):
    force: Optional[bool] = False
    timeout: Optional[float] = 2.0
