import rclpy
import threading
import time
from typing import Optional
from .node import RobotROS2Node

class ROS2Manager:
    """
    Manager class for ROS2 operations
    """
    
    def __init__(self):
        self.node: Optional[RobotROS2Node] = None
        self.executor = None
        self.ros_thread = None
        self.running = False
    
    def initialize(self):
        """Initialize ROS2"""
        try:
            rclpy.init()
            self.node = RobotROS2Node()
            self.executor = rclpy.executors.SingleThreadedExecutor()
            self.executor.add_node(self.node)
            
            # Start ROS2 in a separate thread
            self.running = True
            self.ros_thread = threading.Thread(target=self._run_ros2)
            self.ros_thread.daemon = True
            self.ros_thread.start()
            
            return True
        except Exception as e:
            print(f"Failed to initialize ROS2: {e}")
            return False
    
    def _run_ros2(self):
        """Run ROS2 executor in thread"""
        while self.running and rclpy.ok():
            try:
                self.executor.spin_once(timeout_sec=0.1)
            except Exception as e:
                print(f"ROS2 executor error: {e}")
                time.sleep(0.1)
    
    def update_sensor_data(self, sensor_data):
        """Update sensor data for ROS2 publishing"""
        if self.node is not None:
            imu_dict = {
                'accelerometer': {
                    'x': sensor_data.imu.accelerometer.x,
                    'y': sensor_data.imu.accelerometer.y,
                    'z': sensor_data.imu.accelerometer.z
                },
                'gyroscope': {
                    'x': sensor_data.imu.gyroscope.x,
                    'y': sensor_data.imu.gyroscope.y,
                    'z': sensor_data.imu.gyroscope.z
                }
            }
            
            gps_dict = {
                'latitude': sensor_data.gps.latitude,
                'longitude': sensor_data.gps.longitude,
                'altitude': sensor_data.gps.altitude
            }
            
            self.node.update_imu_data(imu_dict)
            self.node.update_gps_data(gps_dict)
    
    def shutdown(self):
        """Shutdown ROS2"""
        self.running = False
        if self.ros_thread:
            self.ros_thread.join(timeout=2.0)
        if self.executor:
            self.executor.shutdown()
        if self.node:
            self.node.destroy_node()
        rclpy.shutdown()