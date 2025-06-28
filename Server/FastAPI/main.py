# c:\Users\alexb\Documents\GSOC-lg\RoboStreamApp\robot_api\main.py
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
import asyncio
import json
import random
import time
from typing import Dict, List
import uvicorn
import atexit
import os
import base64

# ROS2 Integration
try:
    from ros2_setup import ros2_manager
    ROS2_AVAILABLE = True
    print("ROS2 integration enabled")
except ImportError as e:
    ROS2_AVAILABLE = False
    print(f"ROS2 integration disabled: {e}")

app = FastAPI(title="Robot Sensor API with ROS2", version="1.0.0")

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

class RobotSimulator:
    def __init__(self):
        # Base GPS coordinates for Plaza de España, Madrid
        self.base_lat = 40.4238
        self.base_lon = -3.7123
        
        # Update interval in seconds
        self.update_interval = 5.0
        self.last_update = 0.0
        
        # RGB Camera configuration
        self.images_folder = "images"
        self.image_files = self._load_image_files()
        self.current_image_index = 0
        self.last_image_update = time.time()
        self.image_rotation_interval = 180.0  # 3 minutes (180 seconds)
        
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
                speed=0.0
            ),
            lidar="Connected",
            camera="Streaming",
            rgb_camera=self._create_rgb_camera_data()
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
    
    def _load_image_files(self) -> List[str]:
        """Load available image files from the images folder"""
        try:
            if os.path.exists(self.images_folder):
                files = [f for f in os.listdir(self.images_folder) 
                        if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
                files.sort()  # Sort for consistent order
                return files
            return []
        except Exception as e:
            print(f"Error loading image files: {e}")
            return []
    
    def _create_rgb_camera_data(self) -> RGBCameraData:
        """Create RGB camera data with current image"""
        current_image = ""
        if self.image_files:
            current_image = self.image_files[self.current_image_index]
        
        return RGBCameraData(
            camera_id="RGB_CAM_01",
            resolution="1920x1080",
            fps=30,
            status="Active" if self.image_files else "No Images",
            current_image=current_image,
            image_timestamp=self.last_image_update,
            images_available=len(self.image_files),
            rotation_interval=int(self.image_rotation_interval)
        )
    
    def _update_rgb_camera(self):
        """Update RGB camera image rotation"""
        current_time = time.time()
        
        # Check if it's time to rotate the image
        if (current_time - self.last_image_update >= self.image_rotation_interval 
            and self.image_files):
            self.current_image_index = (self.current_image_index + 1) % len(self.image_files)
            self.last_image_update = current_time
            print(f"[{time.strftime('%H:%M:%S')}] RGB Camera: Rotated to image {self.current_image_index + 1}/{len(self.image_files)}: {self.image_files[self.current_image_index]}")
        
        # Update RGB camera data
        self.sensor_data.rgb_camera = self._create_rgb_camera_data()
    
    def get_current_image_path(self) -> str:
        """Get the full path of the current image"""
        if self.image_files and self.current_image_index < len(self.image_files):
            return os.path.join(self.images_folder, self.image_files[self.current_image_index])
        return ""
    
    def get_image_as_base64(self) -> str:
        """Get current image as base64 encoded string"""
        try:
            image_path = self.get_current_image_path()
            if image_path and os.path.exists(image_path):
                with open(image_path, "rb") as img_file:
                    return base64.b64encode(img_file.read()).decode('utf-8')
            return ""
        except Exception as e:
            print(f"Error encoding image to base64: {e}")
            return ""
    
    def _create_three_axis_data(self, min_val: float = -9.8, max_val: float = 9.8) -> ThreeAxisData:
        """Create random three-axis data"""
        return ThreeAxisData(
            x=round(random.uniform(min_val, max_val), 2),
            y=round(random.uniform(min_val, max_val), 2),
            z=round(random.uniform(min_val, max_val), 2)
        )
    
    def update_sensors(self):
        """Simulate sensor data changes - only update every 5 seconds"""
        current_time = time.time()
        
        # Only update if 5 seconds have passed since last update
        if current_time - self.last_update < self.update_interval:
            # Still update RGB camera (it has its own timing)
            self._update_rgb_camera()
            return
        
        self.last_update = current_time
        self.sensor_data.timestamp = current_time
        
        # Update IMU data
        self.sensor_data.imu.accelerometer = self._create_three_axis_data()
        self.sensor_data.imu.gyroscope = self._create_three_axis_data()
        self.sensor_data.imu.magnetometer = self._create_three_axis_data()
        
        # Update GPS data with slight movement around base coordinates
        self.sensor_data.gps.latitude = self.base_lat + random.uniform(-0.0001, 0.0001)
        self.sensor_data.gps.longitude = self.base_lon + random.uniform(-0.0001, 0.0001)
        self.sensor_data.gps.altitude = round(random.uniform(650.0, 660.0), 1)
        self.sensor_data.gps.speed = round(random.uniform(0.0, 5.0), 1)
        
        # LiDAR and Camera status with occasional changes
        self.sensor_data.lidar = "Connected" if random.random() > 0.1 else "Disconnected"
        self.sensor_data.camera = "Streaming" if random.random() > 0.05 else "Offline"
        
        # Update RGB camera
        self._update_rgb_camera()
        
        # Update actuator data
        self.actuator_data.front_left_wheel = self._create_servo_data()
        self.actuator_data.front_right_wheel = self._create_servo_data()
        self.actuator_data.back_left_wheel = self._create_servo_data()
        self.actuator_data.back_right_wheel = self._create_servo_data()
        
        # Publish to ROS2 if available
        if ROS2_AVAILABLE:
            try:
                ros2_manager.update_sensor_data(self.sensor_data)
            except Exception as e:
                print(f"Error publishing to ROS2: {e}")
        
        print(f"[{time.strftime('%H:%M:%S')}] Sensor data updated - GPS: {self.sensor_data.gps.latitude:.6f}, {self.sensor_data.gps.longitude:.6f}")
        if ROS2_AVAILABLE:
            print(f"[{time.strftime('%H:%M:%S')}] Data published to ROS2 topics")

    def force_update(self):
        """Force an immediate sensor data update"""
        self.last_update = 0.0  # Reset last update time to force update
        self.update_sensors()

    def get_update_info(self):
        """Get information about the update schedule"""
        current_time = time.time()
        time_since_last = current_time - self.last_update
        time_until_next = max(0, self.update_interval - time_since_last)
        
        return {
            "update_interval_seconds": self.update_interval,
            "last_update_timestamp": self.last_update,
            "time_since_last_update": round(time_since_last, 1),
            "time_until_next_update": round(time_until_next, 1),
            "current_timestamp": current_time
        }

robot = RobotSimulator()
connected_clients: List[WebSocket] = []

@app.get("/")
async def root():
    return {
        "message": "Robot Sensor API", 
        "status": "running",
        "version": "1.0.0",
        "update_interval_seconds": robot.update_interval,
        "endpoints": {
            "sensors": "/sensors",
            "actuators": "/actuators", 
            "config": "/config",
            "force_update": "/force-update",
            "rgb_camera": "/rgb-camera",
            "rgb_camera_image": "/rgb-camera/image",
            "rgb_camera_image_data": "/rgb-camera/image-data",
            "websocket": "/ws"
        }
    }

@app.get("/sensors", response_model=SensorData)
async def get_sensors():
    robot.update_sensors()
    return robot.sensor_data

@app.get("/actuators", response_model=ActuatorData)
async def get_actuators():
    robot.update_sensors()
    return robot.actuator_data

@app.get("/config")
async def get_config():
    """Get server configuration and update information"""
    return {
        "server_info": {
            "name": "Robot Sensor API",
            "version": "1.0.0",
            "status": "running"
        },
        "update_schedule": robot.get_update_info()
    }

@app.post("/force-update")
async def force_update():
    """Force an immediate sensor data update"""
    robot.force_update()
    return {
        "message": "Sensor data updated successfully",
        "timestamp": robot.sensor_data.timestamp,
        "update_info": robot.get_update_info()
    }

@app.get("/rgb-camera", response_model=RGBCameraData)
async def get_rgb_camera():
    """Get RGB camera sensor data"""
    robot.update_sensors()  # This will update camera if needed
    return robot.sensor_data.rgb_camera

@app.get("/rgb-camera/image")
async def get_rgb_camera_image():
    """Get the current RGB camera image file"""
    robot.update_sensors()  # Update camera if needed
    image_path = robot.get_current_image_path()
    
    if image_path and os.path.exists(image_path):
        return FileResponse(
            image_path,
            media_type="image/png",
            headers={
                "Cache-Control": "no-cache",
                "X-Image-Index": str(robot.current_image_index),
                "X-Total-Images": str(len(robot.image_files)),
                "X-Current-Image": robot.image_files[robot.current_image_index] if robot.image_files else ""
            }
        )
    else:
        return {"error": "No image available", "message": "No images found in the images folder"}

@app.get("/rgb-camera/image-data")
async def get_rgb_camera_image_data():
    """Get RGB camera image as base64 encoded data with metadata"""
    robot.update_sensors()  # Update camera if needed
    
    image_base64 = robot.get_image_as_base64()
    current_time = time.time()
    time_since_last_rotation = current_time - robot.last_image_update
    time_until_next_rotation = max(0, robot.image_rotation_interval - time_since_last_rotation)
    
    return {
        "camera_info": robot.sensor_data.rgb_camera.dict(),
        "image_data": image_base64,
        "timing": {
            "current_timestamp": current_time,
            "last_rotation_timestamp": robot.last_image_update,
            "time_since_last_rotation": round(time_since_last_rotation, 1),
            "time_until_next_rotation": round(time_until_next_rotation, 1),
            "rotation_interval_seconds": robot.image_rotation_interval
        },
        "image_metadata": {
            "current_index": robot.current_image_index,
            "total_images": len(robot.image_files),
            "current_filename": robot.image_files[robot.current_image_index] if robot.image_files else "",
            "all_images": robot.image_files
        }
    }

@app.get("/ros2/status")
async def get_ros2_status():
    """Get ROS2 integration status"""
    return {
        "ros2_available": ROS2_AVAILABLE,
        "ros2_initialized": ROS2_AVAILABLE and ros2_manager.node is not None,
        "topics": {
            "imu": "/robot/imu",
            "gps": "/robot/gps"
        } if ROS2_AVAILABLE else {},
        "message": "ROS2 integration active" if ROS2_AVAILABLE else "ROS2 integration disabled"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint for Docker healthcheck"""
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "ros2_status": "available" if ROS2_AVAILABLE else "unavailable"
    }

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_clients.append(websocket)
    try:
        while True:
            # Check for updates (will only update if 5 seconds have passed)
            robot.update_sensors()
            
            # Send current data regardless of whether it was updated
            data = {
                "sensors": robot.sensor_data.dict(),
                "actuators": robot.actuator_data.dict(),
                "update_info": robot.get_update_info()
            }
            await websocket.send_text(json.dumps(data))
            
            # Send data every 2 seconds via WebSocket, but data only updates every 5 seconds
            await asyncio.sleep(2)
    except WebSocketDisconnect:
        connected_clients.remove(websocket)
        print(f"Client disconnected. Active connections: {len(connected_clients)}")

if __name__ == "__main__":
    print("🤖 Robot Sensor API Server with ROS2")
    print("=" * 50)
    print(f"📡 Data update interval: {robot.update_interval} seconds")
    print(f"📷 RGB Camera rotation interval: {robot.image_rotation_interval} seconds")
    print(f"🖼️  Available images: {len(robot.image_files)}")
    if robot.image_files:
        print(f"   Images: {', '.join(robot.image_files)}")
    print(f"🌐 Server running on: http://0.0.0.0:8000")
    print(f"📊 Available endpoints:")
    print(f"   GET  /sensors           - Current sensor data")
    print(f"   GET  /actuators         - Current actuator data")
    print(f"   GET  /config            - Server configuration")
    print(f"   POST /force-update      - Force data update")
    print(f"   GET  /rgb-camera        - RGB camera sensor data")
    print(f"   GET  /rgb-camera/image  - Current camera image file")
    print(f"   GET  /rgb-camera/image-data - Camera image as base64 + metadata")
    print(f"   WS   /ws                - WebSocket real-time data")
    print(f"   GET  /ros2/status       - ROS2 integration status")
    
    # Initialize ROS2 if available
    if ROS2_AVAILABLE:
        print("🤖 Initializing ROS2...")
        if ros2_manager.initialize():
            print("✅ ROS2 initialized successfully")
            print("📡 Publishing sensor data to ROS2 topics:")
            print("   - /robot/imu (sensor_msgs/Imu)")
            print("   - /robot/gps (sensor_msgs/NavSatFix)")
            
            # Setup cleanup on exit
            def cleanup_ros2():
                print("🔄 Shutting down ROS2...")
                ros2_manager.shutdown()
                print("✅ ROS2 shutdown complete")
                
            atexit.register(cleanup_ros2)
        else:
            print("❌ Failed to initialize ROS2")
    else:
        print("⚠️  ROS2 integration disabled")
    
    print("=" * 50)
    uvicorn.run(app, host="0.0.0.0", port=8000)