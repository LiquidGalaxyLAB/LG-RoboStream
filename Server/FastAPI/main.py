from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import asyncio
import json
import time
from typing import List
import uvicorn
import atexit
import os

from models import SensorData, ActuatorData, RGBCameraData
from robot_simulator import RobotSimulator, ROS2_AVAILABLE

#Here I try to import the ROS2 integration module.
try:
    from ros2_setup import ros2_manager
    ROS2_AVAILABLE = True
    print("ROS2 integration enabled")
except ImportError as e:
    ROS2_AVAILABLE = False
    print(f"ROS2 integration disabled: {e}")

#I import the FastAPI and other necessary modules.
app = FastAPI(title="Robot Sensor API with ROS2", version="1.0.0")

#I set up CORS middleware to allow cross-origin requests.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#I create the robot simulator instance and list for connected WebSocket clients.
robot = RobotSimulator()
connected_clients: List[WebSocket] = []

#I define the root endpoint with API information.
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

#I define the sensors endpoint to get current sensor data.
@app.get("/sensors", response_model=SensorData)
async def get_sensors():
    robot.update_sensors()
    return robot.sensor_data

#I define the actuators endpoint to get current actuator data.
@app.get("/actuators", response_model=ActuatorData)
async def get_actuators():
    robot.update_sensors()
    return robot.actuator_data

#I define the config endpoint to get server configuration.
@app.get("/config")
async def get_config():
    return {
        "server_info": {
            "name": "Robot Sensor API",
            "version": "1.0.0",
            "status": "running"
        },
        "update_schedule": robot.get_update_info()
    }

#I define the force update endpoint to manually trigger data updates.
@app.post("/force-update")
async def force_update():
    robot.force_update()
    return {
        "message": "Sensor data updated successfully",
        "timestamp": robot.sensor_data.timestamp,
        "update_info": robot.get_update_info()
    }

#I define the RGB camera endpoint to get camera sensor data.
@app.get("/rgb-camera", response_model=RGBCameraData)
async def get_rgb_camera():
    robot.update_sensors()
    return robot.sensor_data.rgb_camera

#I define the RGB camera image endpoint to serve the current image file.
@app.get("/rgb-camera/image")
async def get_rgb_camera_image():
    robot.update_sensors()
    image_path = robot.get_current_image_path()
    
    #I check if the image exists and return it or an error message.
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

#I define the RGB camera image data endpoint to get base64 encoded image with metadata.
@app.get("/rgb-camera/image-data")
async def get_rgb_camera_image_data():
    robot.update_sensors()
    
    #I get the image as base64 and calculate timing information.
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

#I define the ROS2 status endpoint to check ROS2 integration status.
@app.get("/ros2/status")
async def get_ros2_status():
    return {
        "ros2_available": ROS2_AVAILABLE,
        "ros2_initialized": ROS2_AVAILABLE and ros2_manager.node is not None,
        "topics": {
            "imu": "/robot/imu",
            "gps": "/robot/gps"
        } if ROS2_AVAILABLE else {},
        "message": "ROS2 integration active" if ROS2_AVAILABLE else "ROS2 integration disabled"
    }

#I define the health check endpoint for monitoring.
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "ros2_status": "available" if ROS2_AVAILABLE else "unavailable"
    }

#I define the WebSocket endpoint for real-time data streaming.
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_clients.append(websocket)
    try:
        #I continuously send updated sensor data to the client.
        while True:
            robot.update_sensors()
            
            data = {
                "sensors": robot.sensor_data.dict(),
                "actuators": robot.actuator_data.dict(),
                "update_info": robot.get_update_info()
            }
            await websocket.send_text(json.dumps(data))
            
            await asyncio.sleep(2)
    except WebSocketDisconnect:
        #I remove the client from the list when they disconnect.
        connected_clients.remove(websocket)
        print(f"Client disconnected. Active connections: {len(connected_clients)}")

#I run the server when this file is executed directly.
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
    
    #I initialize ROS2 if available.
    if ROS2_AVAILABLE:
        print("🤖 Initializing ROS2...")
        if ros2_manager.initialize():
            print("✅ ROS2 initialized successfully")
            print("📡 Publishing sensor data to ROS2 topics:")
            print("   - /robot/imu (sensor_msgs/Imu)")
            print("   - /robot/gps (sensor_msgs/NavSatFix)")
            
            #I register cleanup function for ROS2 shutdown.
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
    #I start the FastAPI server with uvicorn.
    uvicorn.run(app, host="0.0.0.0", port=8000)
