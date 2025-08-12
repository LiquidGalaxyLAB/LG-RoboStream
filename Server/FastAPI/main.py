from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import asyncio
import json
import time
from typing import List
import uvicorn
import os

from models import (
    SensorData, ActuatorData, RGBCameraData, 
    OrbitRequest, OrbitStopRequest
)
from robot_simulator import RobotSimulator
from pydantic import BaseModel
import LG.lg_data as lg_data
from LG.lg_service import lg_service
from Orbit_Builder import OrbitBuilder

app = FastAPI(title="Robot Sensor API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class LGConfig(BaseModel):
    host: str
    username: str
    password: str
    total_screens: int

class LGLoginRequest(BaseModel):
    host: str
    username: str 
    password: str
    total_screens: int

class LGSensorRequest(BaseModel):
    selected_sensors: List[str]

class LGServerRequest(BaseModel):
    server_host: str

class RobotIPRequest(BaseModel):
    robot_ip: str

class RobotLocationRequest(BaseModel):
    latitude: float
    longitude: float
    altitude: float = 0.0

robot = RobotSimulator()
connected_clients: List[WebSocket] = []

ROBOT_IP = None

# Global orbit instance
_orbit_builder: OrbitBuilder = None

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
            "lg_disconnect": "/lg/disconnect",
            "lg_clean_placemark_files": "/lg/clean-placemark-files",
            "lg_show_robot_location": "/lg/show-robot-location",
            "lg_show_robot_location_manual": "/lg/show-robot-location-manual", 
            "lg_hide_robot_location": "/lg/hide-robot-location",
            "lg_robot_tracking_status": "/lg/robot-tracking-status",
            "lg_clear_logos": "/lg/clear-logos",
            "lg_clear_kml_and_logos": "/lg/clear-kml-logos",
            "lg_update_robot_location": "/lg/update-robot-location",
            "robot_reset_to_initial": "/robot/reset-to-initial",
            "robot_cycle_info": "/robot/cycle-info",
            "orbit_start": "/orbit/start",
            "orbit_start_robot": "/orbit/start-robot",
            "orbit_quick_start": "/orbit/quick-start",
            "orbit_default": "/orbit/default",
            "orbit_stop": "/orbit/stop",
            "orbit_status": "/orbit/status",
            "orbit_config": "/orbit/config",
            "set_robot_ip": "/set-robot-ip",
            "get_robot_ip": "/get-robot-ip"
        }
    }

@app.post("/lg-config")
async def set_lg_config(config: LGConfig):
    lg_data.LG_HOST = config.host
    lg_data.LG_USERNAME = config.username
    lg_data.LG_PASSWORD = config.password
    lg_data.LG_TOTAL_SCREENS = config.total_screens
    return {"message": "Liquid Galaxy configuration updated successfully"}

@app.get("/lg-config")
async def get_lg_config():
    return {
        "host": lg_data.LG_HOST,
        "username": lg_data.LG_USERNAME,
        "password": lg_data.LG_PASSWORD,
        "total_screens": lg_data.LG_TOTAL_SCREENS,
    }

@app.post("/lg/login")
async def lg_login(request: LGLoginRequest):
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
    print(f"Debug: lg_show_sensors endpoint called with sensors: {request.selected_sensors}")
    print(f"Debug: LG Config - Host: {lg_data.LG_HOST}, Username: {lg_data.LG_USERNAME}, Screens: {lg_data.LG_TOTAL_SCREENS}")
    
    robot.update_sensors()

    combined_data = robot.sensor_data.dict()
    combined_data['actuators'] = robot.actuator_data.dict()
    
    success = await lg_service.show_sensor_data(combined_data, request.selected_sensors)
    print(f"Debug: lg_service.show_sensor_data() returned: {success}")
    
    return {
        "success": success,
        "message": "Sensor data displayed successfully" if success else "Failed to display sensor data"
    }

@app.post("/lg/hide-sensors")
async def lg_hide_sensors():
    success = await lg_service.hide_sensor_data()
    return {
        "success": success,
        "message": "Sensor data hidden successfully" if success else "Failed to hide sensor data"
    }

@app.post("/lg/disconnect")
async def lg_disconnect():
    await lg_service.disconnect()
    return {
        "success": True,
        "message": "Disconnected from Liquid Galaxy"
    }

@app.post("/lg/clear-all-kml")
async def lg_clear_all_kml():
    success = await lg_service.clear_all_kml()
    return {
        "success": success,
        "message": "All KML content cleared successfully" if success else "Failed to clear all KML content"
    }

@app.post("/lg/clear-logos")
async def lg_clear_logos():
    success = await lg_service.clear_logos()
    return {
        "success": success,
        "message": "Logos cleared from leftmost screen" if success else "Failed to clear logos"
    }

@app.post("/lg/clear-kml-logos")
async def lg_clear_kml_and_logos():
    success = await lg_service.clean_kml_and_logos()
    return {
        "success": success,
        "message": "KML overlays and logos cleared" if success else "Failed to clear KML overlays + logos"
    }

@app.post("/lg/clean-placemark-files")
async def lg_clean_placemark_files():
    success = await lg_service.clean_all_placemark_files()
    return {
        "success": success,
        "message": "All placemark files cleaned successfully" if success else "Failed to clean placemark files"
    }

@app.post("/lg/relaunch")
async def lg_relaunch():
    success = await lg_service.relaunch_lg()
    return {
        "success": success,
        "message": "Liquid Galaxy relaunched successfully" if success else "Failed to relaunch Liquid Galaxy"
    }

@app.post("/lg/show-robot-location")
async def lg_show_robot_location():
    print("Debug: lg_show_robot_location endpoint called")
    
    robot.reset_to_initial_position()
    
    robot.update_sensors()
    gps_data = robot.sensor_data.gps
    
    print(f"Debug: Current GPS data - lat={gps_data.latitude}, lon={gps_data.longitude}, alt={gps_data.altitude}")
    
    success = await lg_service.show_robot_location(
        latitude=gps_data.latitude,
        longitude=gps_data.longitude,
        altitude=gps_data.altitude
    )
    
    return {
        "success": success,
        "message": f"Robot location displayed on LG at {gps_data.latitude:.6f}, {gps_data.longitude:.6f}" if success else "Failed to display robot location on LG",
        "location": {
            "latitude": gps_data.latitude,
            "longitude": gps_data.longitude,
            "altitude": gps_data.altitude
        }
    }

@app.post("/lg/show-robot-location-manual")
async def lg_show_robot_location_manual(request: RobotLocationRequest):
    print(f"Debug: lg_show_robot_location_manual endpoint called with lat={request.latitude}, lon={request.longitude}, alt={request.altitude}")
    
    success = await lg_service.show_robot_location(
        latitude=request.latitude,
        longitude=request.longitude,
        altitude=request.altitude
    )
    
    return {
        "success": success,
        "message": f"Robot location displayed on LG at {request.latitude:.6f}, {request.longitude:.6f}" if success else "Failed to display robot location on LG",
        "location": {
            "latitude": request.latitude,
            "longitude": request.longitude,
            "altitude": request.altitude
        }
    }

@app.post("/lg/hide-robot-location")
async def lg_hide_robot_location():
    print("Debug: lg_hide_robot_location endpoint called")
    
    success = await lg_service.hide_robot_location()
    
    return {
        "success": success,
        "message": "Robot location hidden from LG" if success else "Failed to hide robot location from LG"
    }

@app.get("/lg/robot-tracking-status")
async def lg_robot_tracking_status():
    is_active = lg_service.is_robot_tracking_active()
    
    return {
        "tracking_active": is_active,
        "message": "Robot tracking is active" if is_active else "Robot tracking is inactive"
    }

@app.post("/robot/reset-to-initial")
async def reset_robot_to_initial():
    
    robot.reset_to_initial_position()
    
    if lg_service.is_robot_tracking_active():
        try:
            gps_data = robot.sensor_data.gps
            await lg_service.show_robot_location(
                latitude=gps_data.latitude,
                longitude=gps_data.longitude,
                altitude=gps_data.altitude
            )
            print(f"Robot reset and placemark updated: {gps_data.latitude:.6f}, {gps_data.longitude:.6f}")
        except Exception as e:
            print(f"Error updating placemark after reset: {e}")
    
    return {
        "success": True,
        "message": "Robot reset to initial position",
        "location": {
            "latitude": robot.sensor_data.gps.latitude,
            "longitude": robot.sensor_data.gps.longitude,
            "altitude": robot.sensor_data.gps.altitude
        }
    }

@app.get("/robot/cycle-info")
async def get_robot_cycle_info():
    return {
        "total_positions": len(robot.gps_positions),
        "current_position_index": robot.current_gps_index,
        "positions": [
            {
                "index": i,
                "latitude": pos[0],
                "longitude": pos[1],
                "is_initial": i == 0,
                "is_current": i == robot.current_gps_index
            }
            for i, pos in enumerate(robot.gps_positions)
        ],
        "update_interval_seconds": robot.update_interval
    }

@app.post("/orbit/start")
async def start_orbit(orbit_request: OrbitRequest):

    global _orbit_builder
    
    lg_host = lg_data.LG_HOST or "lg1"
    lg_username = lg_data.LG_USERNAME or "lg"
    lg_password = lg_data.LG_PASSWORD or "1234asdfASDF"
    
    if not lg_data.LG_HOST:
        print("⚠️  Warning: Using default LG settings. Configure proper LG settings for production use.")

    if (_orbit_builder is None or 
        _orbit_builder.ip != lg_host or
        _orbit_builder.user != lg_username or
        _orbit_builder.password != lg_password):
        
        _orbit_builder = OrbitBuilder(
            ip=lg_host,
            port=22,  # Default SSH port
            user=lg_username,
            password=lg_password
        )
    
    print(2)
    
    # Check if orbit is already running
    if _orbit_builder.is_running():
        return {
            "success": False,
            "status": "already_running", 
            "message": "There is already an orbit running. Stop it first before starting a new one."
        }
    
    # Start the orbit
    print(orbit_request)
    print(type(orbit_request))
    started = _orbit_builder.start_orbit(
        lat=orbit_request.latitude,
        lon=orbit_request.longitude,
        zoom=orbit_request.zoom,
        tilt=orbit_request.tilt,
        steps=orbit_request.steps,
        step_ms=orbit_request.step_ms,
        start_heading=orbit_request.start_heading
    )
    
    print(3)
    
    if started:
    
        print(f"[{time.strftime('%H:%M:%S')}] Orbit started at {orbit_request.latitude:.6f}, {orbit_request.longitude:.6f}")
        return {
            "success": True,
            "status": "started", 
            "message": f"Orbit started around coordinates {orbit_request.latitude:.6f}, {orbit_request.longitude:.6f}",
            "parameters": orbit_request.dict()
        }
    else:
        return {
            "success": False,
            "status": "error", 
            "message": "Failed to start orbit"
        }

@app.post("/orbit/start-robot")
async def start_orbit_around_robot():
    global _orbit_builder
    
    if not all([lg_data.LG_HOST, lg_data.LG_USERNAME, lg_data.LG_PASSWORD]):
        raise HTTPException(
            status_code=400, 
            detail="Liquid Galaxy connection not configured. Please configure LG settings first."
        )

    robot.update_sensors()
    gps_data = robot.sensor_data.gps
    
    print(3)
    print(gps_data);
    
    # Create orbit request with robot's current position
    orbit_request = OrbitRequest(
        latitude=gps_data.latitude,
        longitude=gps_data.longitude,
        zoom=4000,
        tilt=60,
        steps=36,  # 10 degrees per step
        step_ms=300,  # Faster orbit
        start_heading=0.0
    )
    
    return await start_orbit(orbit_request)

@app.post("/orbit/stop")
async def stop_orbit(
    force: bool = Query(False, description="Force stop the orbit thread"),
    timeout: float = Query(2.0, ge=0.1, le=10.0, description="Timeout in seconds to wait for graceful stop")
):
    global _orbit_builder
    
    if _orbit_builder is None:
        return {
            "success": False,
            "status": "idle", 
            "message": "No orbit builder instance exists"
        }
    
    if not _orbit_builder.is_running():
        return {
            "success": False,
            "status": "idle", 
            "message": "There is no orbit currently running"
        }
    
    stopped = _orbit_builder.stop_orbit(timeout=timeout, force=force)
    
    if stopped:
        print(f"[{time.strftime('%H:%M:%S')}] Orbit stopped successfully")
        return {
            "success": True,
            "status": "stopped", 
            "message": "Orbit stopped successfully"
        }
    else:
        if force:
            return {
                "success": False,
                "status": "error", 
                "message": "Could not force stop the orbit thread"
            }
        else:
            return {
                "success": False,
                "status": "timeout", 
                "message": f"Orbit did not stop within {timeout} seconds. Try with force=true parameter."
            }

@app.get("/orbit/config")
async def get_orbit_config():
    global _orbit_builder
    
    return {
        "lg_config": {
            "host": lg_data.LG_HOST or "lg1 (default)",
            "username": lg_data.LG_USERNAME or "lg (default)",
            "password_set": bool(lg_data.LG_PASSWORD),
            "total_screens": lg_data.LG_TOTAL_SCREENS or "3 (default)",
            "using_defaults": not all([lg_data.LG_HOST, lg_data.LG_USERNAME, lg_data.LG_PASSWORD])
        },
        "orbit_builder": {
            "exists": _orbit_builder is not None,
            "is_running": _orbit_builder.is_running() if _orbit_builder else False,
            "connection_info": {
                "ip": _orbit_builder.ip if _orbit_builder else None,
                "user": _orbit_builder.user if _orbit_builder else None,
            } if _orbit_builder else None
        }
    }

@app.get("/orbit/status")
async def get_orbit_status():
    global _orbit_builder
    
    if _orbit_builder is None:
        return {
            "is_running": False,
            "status": "no_instance",
            "message": "No orbit builder instance"
        }
    
    status = _orbit_builder.get_status()
    return {
        "is_running": status["is_running"],
        "status": "running" if status["is_running"] else "idle",
        "message": "Orbit is running" if status["is_running"] else "No orbit running",
        "connection_info": status["connection_info"]
    }

@app.post("/orbit/quick-start")
async def quick_start_orbit(
    latitude: float = Query(41.605725, description="Latitude for orbit center"),
    longitude: float = Query(0.606787, description="Longitude for orbit center"),
    orbit_type: str = Query("normal", regex="^(slow|normal|fast)$", description="Orbit speed type")
):
    orbit_params = {
        "slow": {"steps": 72, "step_ms": 800, "zoom": 197, "tilt": 45},
        "normal": {"steps": 36, "step_ms": 500, "zoom": 197, "tilt": 60},
        "fast": {"steps": 24, "step_ms": 200, "zoom": 197, "tilt": 75}
    }
    
    params = orbit_params[orbit_type]
    
    orbit_request = OrbitRequest(
        latitude=latitude,
        longitude=longitude,
        zoom=params["zoom"],
        tilt=params["tilt"],
        steps=params["steps"],
        step_ms=params["step_ms"],
        start_heading=0.0
    )
    
    result = await start_orbit(orbit_request)
    result["orbit_type"] = orbit_type
    result["predefined_parameters"] = params
    
    return result

@app.post("/lg/update-robot-location")
async def lg_update_robot_location():
    if not lg_service.is_robot_tracking_active():
        return {
            "success": False,
            "message": "Robot tracking is not active"
        }
    
    # Get current robot GPS data
    robot.update_sensors()
    gps_data = robot.sensor_data.gps
    
    print(f"Debug: Updating robot location - lat={gps_data.latitude}, lon={gps_data.longitude}, alt={gps_data.altitude}")
    
    success = await lg_service.show_robot_location(
        latitude=gps_data.latitude,
        longitude=gps_data.longitude,
        altitude=gps_data.altitude
    )
    
    return {
        "success": success,
        "message": f"Robot location updated on LG at {gps_data.latitude:.6f}, {gps_data.longitude:.6f}" if success else "Failed to update robot location on LG",
        "location": {
            "latitude": gps_data.latitude,
            "longitude": gps_data.longitude,
            "altitude": gps_data.altitude
        }
    }

@app.post("/set-robot-ip")
async def set_robot_ip(request: RobotIPRequest):
    global ROBOT_IP
    ROBOT_IP = request.robot_ip
    
    try:
        with open("../ROS/robot_data.py", "w") as f:
            f.write(f"ROBOT_IP = '{request.robot_ip}'\n")
    except Exception as e:
        pass
    
    return {
        "success": True,
        "message": f"Robot IP set to {request.robot_ip}",
        "robot_ip": request.robot_ip
    }

@app.get("/get-robot-ip")
async def get_robot_ip():
    return {
        "robot_ip": ROBOT_IP,
        "is_set": ROBOT_IP is not None
    }

@app.post("/orbit/default")
async def start_default_orbit():
    return await quick_start_orbit(
        latitude=41.605725,
        longitude=0.606787,
        orbit_type="normal"
    )

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
    robot.force_update()
    return {
        "message": "Sensor data updated successfully",
        "timestamp": robot.sensor_data.timestamp,
        "update_info": robot.get_update_info()
    }

@app.get("/rgb-camera", response_model=RGBCameraData)
async def get_rgb_camera():
    robot.update_sensors()
    return robot.sensor_data.rgb_camera

@app.get("/rgb-camera/image")
async def get_rgb_camera_image(t: int = None):
    robot.update_sensors()
    image_path = robot.get_current_image_path()

    if image_path and os.path.exists(image_path):
        return FileResponse(
            image_path,
            media_type="image/png",
            headers={
                "Cache-Control": "no-cache, no-store, must-revalidate",
                "Pragma": "no-cache",
                "Expires": "0",
                "X-Image-Index": str(robot.current_image_index),
                "X-Total-Images": str(len(robot.image_files)),
                "X-Current-Image": robot.image_files[robot.current_image_index] if robot.image_files else "",
                "X-Timestamp": str(t) if t else "none"
            }
        )
    else:
        return {"error": "No image available", "message": "No images found in the images folder"}

@app.get("/rgb-camera/image-data")
async def get_rgb_camera_image_data():
    robot.update_sensors()

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

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": time.time()
    }

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_clients.append(websocket)
    try:
        while True:
            robot.update_sensors()
            
            # Actualizar placemark inmediatamente si las coordenadas GPS han cambiado
            # y el tracking está activo
            if lg_service.is_robot_tracking_active() and robot.has_gps_changed():
                try:
                    gps_data = robot.sensor_data.gps
                    await lg_service.show_robot_location(
                        latitude=gps_data.latitude,
                        longitude=gps_data.longitude,
                        altitude=gps_data.altitude
                    )
                    print(f"[{time.strftime('%H:%M:%S')}] IMMEDIATE placemark update: {gps_data.latitude:.6f}, {gps_data.longitude:.6f}")
                except Exception as e:
                    print(f"Error auto-updating robot location: {e}")
            
            data = {
                "sensors": robot.sensor_data.dict(),
                "actuators": robot.actuator_data.dict(),
                "update_info": robot.get_update_info(),
                "lg_robot_tracking": lg_service.is_robot_tracking_active()
            }
            await websocket.send_text(json.dumps(data))
            
            await asyncio.sleep(2)
    except WebSocketDisconnect:
        connected_clients.remove(websocket)
        print(f"Client disconnected. Active connections: {len(connected_clients)}")

if __name__ == "__main__":
    print("🤖 Robot Sensor API Server")
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
    print(f"   POST /lg-config         - Set Liquid Galaxy configuration")
    print(f"   GET  /lg-config         - Get Liquid Galaxy configuration")
    print(f"   POST /lg/login          - Login to Liquid Galaxy")
    print(f"   POST /lg/show-logo      - Show logo on Liquid Galaxy")
    print(f"   POST /lg/show-camera    - Show camera feed on Liquid Galaxy")
    print(f"   POST /lg/show-sensors   - Show sensor data on Liquid Galaxy")
    print(f"   POST /lg/hide-sensors   - Hide sensor data from Liquid Galaxy")
    print(f"   POST /lg/disconnect     - Disconnect from Liquid Galaxy")
    print(f"   POST /lg/clear-all-kml  - Clear all KML content from Liquid Galaxy")
    print(f"   POST /lg/show-robot-location - Show robot location on Liquid Galaxy (using current GPS)")
    print(f"   POST /lg/show-robot-location-manual - Show robot location with manual coordinates")
    print(f"   POST /lg/hide-robot-location - Hide robot location from Liquid Galaxy")
    print(f"   POST /robot/reset-to-initial - Reset robot to initial coordinate position")
    print(f"   GET  /robot/cycle-info - Get robot coordinate cycle information")
    print(f"   POST /orbit/start - Start orbit around specified coordinates")
    print(f"   POST /orbit/start-robot - Start orbit around current robot position")
    print(f"   POST /orbit/quick-start - Quick start orbit with predefined parameters")
    print(f"   POST /orbit/default - Start orbit with default coordinates (41.605725, 0.606787) at altitude 197.92m")
    print(f"   POST /orbit/stop - Stop running orbit")
    print(f"   GET  /orbit/status - Get current orbit status")
    print(f"   GET  /orbit/config - Get orbit and LG configuration")
    print(f"   GET  /lg/robot-tracking-status - Get robot tracking status")
    print("=" * 50)

@app.on_event("shutdown")
async def shutdown_event():
    global _orbit_builder
    
    print("Server shutting down, cleaning up resources...")
    
    if _orbit_builder and _orbit_builder.is_running():
        print("Stopping orbit before server shutdown...")
        _orbit_builder.stop_orbit(timeout=1.0, force=True)

    try:
        await lg_service.disconnect()
        print("Disconnected from Liquid Galaxy")
    except Exception as e:
        print(f"Error disconnecting from LG: {e}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
