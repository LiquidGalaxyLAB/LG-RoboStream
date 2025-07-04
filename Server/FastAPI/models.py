from pydantic import BaseModel

#I define the structure of the data that I am going to get from the robot's sensors, using Pydantic models.
class ThreeAxisData(BaseModel):
    x: float
    y: float
    z: float

# I define the structure of the IMU data, which includes accelerometer, gyroscope, and magnetometer readings.
class IMUData(BaseModel):
    accelerometer: ThreeAxisData
    gyroscope: ThreeAxisData
    magnetometer: ThreeAxisData

# I define the structure of the GPS data, which includes latitude, longitude, altitude, and speed.
class GPSData(BaseModel):
    latitude: float
    longitude: float
    altitude: float
    speed: float

#I define the RGB camera data structure with all its properties.
class RGBCameraData(BaseModel):
    camera_id: str
    resolution: str
    fps: int
    status: str
    current_image: str
    image_timestamp: float
    images_available: int
    rotation_interval: int

#I define the complete sensor data structure that includes all sensor readings.
class SensorData(BaseModel):
    timestamp: float
    imu: IMUData
    gps: GPSData
    lidar: str
    camera: str
    rgb_camera: RGBCameraData

#I define the servo motor data structure for each wheel.
class ServoData(BaseModel):
    speed: int
    temperature: float
    consumption: float
    voltage: float
    status: str

#I define the actuator data structure for all four wheels.
class ActuatorData(BaseModel):
    front_left_wheel: ServoData
    front_right_wheel: ServoData
    back_left_wheel: ServoData
    back_right_wheel: ServoData
