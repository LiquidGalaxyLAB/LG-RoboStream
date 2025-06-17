# Robot Sensor Simulation API

A FastAPI-based robot sensor and actuator simulation running on Ubuntu 22.04 LTS.

## Features

### Sensors
- **IMU Sensor**: 3-axis accelerometer, gyroscope, and magnetometer
- **GPS Sensor**: Location, altitude, speed, and satellite count
- **LiDAR**: Connection status
- **Camera**: Streaming status

### Actuators
- **Four Wheel Servomotors**: Speed, temperature, consumption, voltage, and status for each wheel

## Quick Start

### Using Docker Compose
```bash
docker-compose up --build
```

### Using Docker
```bash
docker build -t robot-api .
docker run -p 8000:8000 robot-api
```

### Local Development
```bash
pip install -r requirements.txt
cd FastAPI
python main.py
```

## API Endpoints

- `GET /` - API status
- `GET /sensors` - Get current sensor data
- `GET /actuators` - Get current actuator data
- `WebSocket /ws` - Real-time data stream

## API Documentation
Visit `http://localhost:8000/docs` for interactive API documentation.
