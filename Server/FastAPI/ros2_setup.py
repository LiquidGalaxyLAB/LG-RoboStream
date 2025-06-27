import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Imu, NavSatFix
from geometry_msgs.msg import Vector3, Quaternion
from std_msgs.msg import Header
import threading
import time
from typing import Optional

class RobotROS2Node(Node):
    """
    ROS2 Node for Robot Sensor Data Publishing
    """
    
    def __init__(self):
        super().__init__('robot_sensor_node')
        
        # Create publishers
        self.imu_publisher = self.create_publisher(Imu, '/robot/imu', 10)
        self.gps_publisher = self.create_publisher(NavSatFix, '/robot/gps', 10)
        
        # Create timers for periodic publishing
        self.imu_timer = self.create_timer(0.1, self.publish_imu_data)  # 10Hz
        self.gps_timer = self.create_timer(1.0, self.publish_gps_data)  # 1Hz
        
        # Data storage
        self.current_imu_data = None
        self.current_gps_data = None
        
        self.get_logger().info('Robot ROS2 Node initialized')
    
    def update_imu_data(self, imu_data):
        """Update IMU data from FastAPI"""
        self.current_imu_data = imu_data
    
    def update_gps_data(self, gps_data):
        """Update GPS data from FastAPI"""
        self.current_gps_data = gps_data
    
    def publish_imu_data(self):
        """Publish IMU data to ROS2 topic"""
        if self.current_imu_data is None:
            return
            
        msg = Imu()
        msg.header = Header()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = "imu_link"
        
        # Linear acceleration
        msg.linear_acceleration.x = self.current_imu_data['accelerometer']['x']
        msg.linear_acceleration.y = self.current_imu_data['accelerometer']['y']
        msg.linear_acceleration.z = self.current_imu_data['accelerometer']['z']
        
        # Angular velocity
        msg.angular_velocity.x = self.current_imu_data['gyroscope']['x']
        msg.angular_velocity.y = self.current_imu_data['gyroscope']['y']
        msg.angular_velocity.z = self.current_imu_data['gyroscope']['z']
        
        # Orientation (quaternion) - simplified for now
        msg.orientation.x = 0.0
        msg.orientation.y = 0.0
        msg.orientation.z = 0.0
        msg.orientation.w = 1.0
        
        self.imu_publisher.publish(msg)
    
    def publish_gps_data(self):
        """Publish GPS data to ROS2 topic"""
        if self.current_gps_data is None:
            return
            
        msg = NavSatFix()
        msg.header = Header()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = "gps_link"
        
        msg.latitude = self.current_gps_data['latitude']
        msg.longitude = self.current_gps_data['longitude']
        msg.altitude = self.current_gps_data['altitude']
        
        # Set status
        msg.status.status = 0  # GPS fix
        msg.status.service = 1  # GPS service
        
        self.gps_publisher.publish(msg)

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

# Global ROS2 manager instance
ros2_manager = ROS2Manager()
