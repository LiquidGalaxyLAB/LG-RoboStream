import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Imu, NavSatFix
from std_msgs.msg import Header

class RobotROS2Node(Node):
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