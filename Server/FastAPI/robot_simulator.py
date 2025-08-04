import os
import time
import random
import base64
from typing import List
from models import SensorData, IMUData, ThreeAxisData, GPSData, RGBCameraData, ActuatorData, ServoData

class RobotSimulator:
    def __init__(self):
        self.base_lat = 41.6175
        self.base_lon = 0.6200
        
        self.update_interval = 10.0
        self.last_update = 0.0
        
        self.images_folder = "images"
        self.image_files = self._load_image_files()
        self.current_image_index = 0
        self.last_image_update = time.time()
        self.image_rotation_interval = 5.0

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
                altitude=175.0,
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
        return ServoData(
            speed=random.randint(0, 150),
            temperature=round(random.uniform(35.0, 75.5), 1),
            consumption=round(random.uniform(1.5, 5.0), 2),
            voltage=round(random.uniform(11.8, 12.5), 1),
            status="Operational" if random.random() > 0.05 else "Error"
        )
    
    def _load_image_files(self) -> List[str]:
        try:
            if os.path.exists(self.images_folder):
                files = [f for f in os.listdir(self.images_folder) 
                        if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
                files.sort()
                return files
            return []
        except Exception as e:
            print(f"Error loading image files: {e}")
            return []
    
    def _create_rgb_camera_data(self) -> RGBCameraData:
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
        current_time = time.time()
        time_since_last_rotation = current_time - self.last_image_update

        if (time_since_last_rotation >= self.image_rotation_interval 
            and self.image_files):
            self.current_image_index = (self.current_image_index + 1) % len(self.image_files)
            self.last_image_update = current_time
            print(f"[{time.strftime('%H:%M:%S')}] RGB Camera: Rotated to image {self.current_image_index + 1}/{len(self.image_files)}: {self.image_files[self.current_image_index]} (after {time_since_last_rotation:.1f}s)")

        self.sensor_data.rgb_camera = self._create_rgb_camera_data()

    def get_current_image_path(self) -> str:
        if self.image_files and self.current_image_index < len(self.image_files):
            return os.path.join(self.images_folder, self.image_files[self.current_image_index])
        return ""

    def get_image_as_base64(self) -> str:
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
        return ThreeAxisData(
            x=round(random.uniform(min_val, max_val), 2),
            y=round(random.uniform(min_val, max_val), 2),
            z=round(random.uniform(min_val, max_val), 2)
        )

    def update_sensors(self):
        current_time = time.time()

        if current_time - self.last_update < self.update_interval:
            self._update_rgb_camera()
            return

        self.last_update = current_time
        self.sensor_data.timestamp = current_time

        self.sensor_data.imu.accelerometer = self._create_three_axis_data()
        self.sensor_data.imu.gyroscope = self._create_three_axis_data()
        self.sensor_data.imu.magnetometer = self._create_three_axis_data()
        
        self.sensor_data.gps.latitude = self.base_lat + random.uniform(-0.001, 0.001)
        self.sensor_data.gps.longitude = self.base_lon + random.uniform(-0.001, 0.001)
        self.sensor_data.gps.altitude = round(random.uniform(150.0, 200.0), 1)
        self.sensor_data.gps.speed = round(random.uniform(0.0, 8.0), 1)
        
        self.sensor_data.lidar = "Connected" if random.random() > 0.1 else "Disconnected"
        self.sensor_data.camera = "Streaming" if random.random() > 0.05 else "Offline"
        
        self._update_rgb_camera()
        
        self.actuator_data.front_left_wheel = self._create_servo_data()
        self.actuator_data.front_right_wheel = self._create_servo_data()
        self.actuator_data.back_left_wheel = self._create_servo_data()
        self.actuator_data.back_right_wheel = self._create_servo_data()
        
        print(f"[{time.strftime('%H:%M:%S')}] Sensor data updated - GPS: {self.sensor_data.gps.latitude:.6f}, {self.sensor_data.gps.longitude:.6f}")

    def force_update(self):
        self.last_update = 0.0
        self.update_sensors()

    def get_update_info(self):
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
