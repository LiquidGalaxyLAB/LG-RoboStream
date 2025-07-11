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
from pydantic import BaseModel
import LG.lg_data as lg_data
from LG.lg_service import lg_service

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

# Pydantic model for LG configuration
class LGConfig(BaseModel):
    host: str
    username: str
    password: str
    total_screens: int

# Pydantic model for LG login
class LGLoginRequest(BaseModel):
    host: str
    username: str 
    password: str
    total_screens: int

# Pydantic model for sensor data streaming
class LGSensorRequest(BaseModel):
    selected_sensors: List[str]

# Pydantic model for server host
class LGServerRequest(BaseModel):
    server_host: str

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
            "websocket": "/ws",
            "lg_config": "/lg-config",
            "lg_login": "/lg/login",
            "lg_show_logo": "/lg/show-logo",
            "lg_show_camera": "/lg/show-camera",
            "lg_show_sensors": "/lg/show-sensors",
            "lg_hide_sensors": "/lg/hide-sensors",
            "lg_disconnect": "/lg/disconnect"
        }
    }

#I define the endpoint to set LG configuration
@app.post("/lg-config")
async def set_lg_config(config: LGConfig):
    lg_data.LG_HOST = config.host
    lg_data.LG_USERNAME = config.username
    lg_data.LG_PASSWORD = config.password
    lg_data.LG_TOTAL_SCREENS = config.total_screens
    return {"message": "Liquid Galaxy configuration updated successfully"}

#I define the endpoint to get LG configuration
@app.get("/lg-config")
async def get_lg_config():
    return {
        "host": lg_data.LG_HOST,
        "username": lg_data.LG_USERNAME,
        "password": lg_data.LG_PASSWORD,
        "total_screens": lg_data.LG_TOTAL_SCREENS,
    }

# LG Service Endpoints
@app.post("/lg/login")
async def lg_login(request: LGLoginRequest):
    """Login to Liquid Galaxy and test connection"""
    result = await lg_service.login(
        request.host, 
        request.username, 
        request.password, 
        request.total_screens
    )
    return {
        "success": result.success,
        "message": result.message
    }

@app.post("/lg/show-logo")
async def lg_show_logo():
    """Show RoboStream logo on Liquid Galaxy"""
    print("Debug: lg_show_logo endpoint called")
    print(f"Debug: LG Config - Host: {lg_data.LG_HOST}, Username: {lg_data.LG_USERNAME}, Screens: {lg_data.LG_TOTAL_SCREENS}")
    
    success = await lg_service.show_logo()
    print(f"Debug: lg_service.show_logo() returned: {success}")
    
    return {
        "success": success,
        "message": "Logo displayed successfully" if success else "Failed to display logo"
    }

@app.post("/lg/show-camera")
async def lg_show_camera(request: LGServerRequest):
    """Show RGB camera feed on Liquid Galaxy"""
    print(f"Debug: lg_show_camera endpoint called with server_host: {request.server_host}")
    print(f"Debug: LG Config - Host: {lg_data.LG_HOST}, Username: {lg_data.LG_USERNAME}, Screens: {lg_data.LG_TOTAL_SCREENS}")
    
    success = await lg_service.show_rgb_camera(request.server_host)
    print(f"Debug: lg_service.show_rgb_camera() returned: {success}")
    
    return {
        "success": success,
        "message": "Camera feed displayed successfully" if success else "Failed to display camera feed"
    }

@app.post("/lg/show-sensors")
async def lg_show_sensors(request: LGSensorRequest):
    """Show sensor data on Liquid Galaxy"""
    print(f"Debug: lg_show_sensors endpoint called with sensors: {request.selected_sensors}")
    print(f"Debug: LG Config - Host: {lg_data.LG_HOST}, Username: {lg_data.LG_USERNAME}, Screens: {lg_data.LG_TOTAL_SCREENS}")
    
    robot.update_sensors()
    sensor_data_dict = robot.sensor_data.dict()
    
    success = await lg_service.show_sensor_data(sensor_data_dict, request.selected_sensors)
    print(f"Debug: lg_service.show_sensor_data() returned: {success}")
    
    return {
        "success": success,
        "message": "Sensor data displayed successfully" if success else "Failed to display sensor data"
    }
    return {
        "success": success,
        "message": "Sensor data displayed successfully" if success else "Failed to display sensor data"
    }

@app.post("/lg/hide-sensors")
async def lg_hide_sensors():
    """Hide sensor data from Liquid Galaxy"""
    success = await lg_service.hide_sensor_data()
    return {
        "success": success,
        "message": "Sensor data hidden successfully" if success else "Failed to hide sensor data"
    }

@app.post("/lg/disconnect")
async def lg_disconnect():
    """Disconnect from Liquid Galaxy"""
    await lg_service.disconnect()
    return {
        "success": True,
        "message": "Disconnected from Liquid Galaxy"
    }

@app.post("/lg/clear-all-kml")
async def lg_clear_all_kml():
    """Clear ALL KML content from ALL Liquid Galaxy screens"""
    success = await lg_service.clear_all_kml()
    return {
        "success": success,
        "message": "All KML content cleared successfully" if success else "Failed to clear all KML content"
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
    print(f"   POST /lg-config         - Set Liquid Galaxy configuration")
    print(f"   GET  /lg-config         - Get Liquid Galaxy configuration")
    print(f"   POST /lg/login          - Login to Liquid Galaxy")
    print(f"   POST /lg/show-logo      - Show logo on Liquid Galaxy")
    print(f"   POST /lg/show-camera    - Show camera feed on Liquid Galaxy")
    print(f"   POST /lg/show-sensors   - Show sensor data on Liquid Galaxy")
    print(f"   POST /lg/hide-sensors   - Hide sensor data from Liquid Galaxy")
    print(f"   POST /lg/disconnect     - Disconnect from Liquid Galaxy")
    print(f"   POST /lg/clear-all-kml  - Clear all KML content from Liquid Galaxy")
    
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
