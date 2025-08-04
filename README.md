# 🤖 RoboStream v1.00

<div align="center">
  <img src="https://github.com/user-attachments/assets/40783f94-63f8-4798-b599-3dece36d66a7" width="400" alt="RoboStream Logo">
  <h3>Real-time Robot Sensor Data Streaming for Liquid Galaxy</h3>
  <p>A comprehensive solution for visualizing robot sensor data on Liquid Galaxy displays</p>
</div>
---


## 📋 Table of Contents
- [🚀 Server Setup](#-server-setup)
- [📲 App Installation](#-app-installation)
- [🔌 Server Configuration](#-server-configuration)
- [🌌 Liquid Galaxy Setup](#-liquid-galaxy-setup)
- [🏠 Home Screen](#-home-screen)
- [⚙️ Settings & Configuration](#️-settings--configuration)
- [📊 Sensor Data](#-sensor-data)
- [📡 Data Streaming](#-data-streaming)
- [⏹️ Stop Streaming](#️-stop-streaming)
- [🙏 Acknowledgements](#-acknowledgements)

---

## 🚀 Server Setup

First, initialize the server environment. Navigate to the server directory and run:

```bash
docker-compose up -d --build
```

This command uses Docker to build the project's required environment and start all necessary services in the background.

<div align="center">
  <img src="https://github.com/user-attachments/assets/ce3605da-4f5f-458c-bd9d-7468db23b7fb" width="600" alt="RoboStream Logo">
  <h3>Real-time Robot Sensor Data Streaming for Liquid Galaxy</h3>
  <p>A comprehensive solution for visualizing robot sensor data on Liquid Galaxy displays</p>
</div>

---

## 📲 App Installation

1. **Install the APK**: Download and install the provided APK file on your Android device
2. **Enable Unknown Sources**: You may need to enable "Install from unknown sources" in your device's settings
3. **Launch the App**: Open RoboStream after installation

<div align="center">
  <img src="https://github.com/user-attachments/assets/8636efdf-8e61-4e00-a363-f22da4a4bb1d" width="300" alt="App Installation">
  <img src="https://github.com/user-attachments/assets/c8035bb7-0fdd-49c0-94dd-ea3985aa60cf" width="400" alt="Installation Process">
</div>

---

## 🔌 Server Configuration

When you first open the app, you'll see the server configuration screen:

- **Enter Server IP**: Input the IP address of the device running the server
- **Port Handling**: Don't include the port number - the app automatically uses port 8000
- **Android Emulator**: If using the Android Emulator on the same machine, use `10.0.2.2`

<div align="center">
  <img src="https://github.com/user-attachments/assets/406d0f3b-53d9-465f-84fb-2314790f79dd" width="300" alt="Server Configuration">
</div>

---

## 🤖 Robot Configuration (Not implemented yet, just visual)

Configure the IP Address from the Robot:

- **Robot IP Address**: Input the IP address of the robot device
- **Development Status**: Currently in development - ROS and robot implementation on the server is still in progress
- **Current State**: This is a visual demo showing how it will work when fully implemented

<div align="center">
  <img src="https://github.com/user-attachments/assets/898e08d0-6858-4885-bc12-3a5a9d86c77d" width="300" alt="Robot Configuration">
</div>

---
## 🌌 Liquid Galaxy Setup

Configure your Liquid Galaxy connection:

**Required Information:**
- 🌐 Main LG IP Address
- 👤 Username
- 🔒 Password
- 📺 Total number of screens

**QR Code Configuration:**
- 📱 **QR Scanner Button**: Tap the QR code button to automatically fill all connection details
- 🔍 **Quick Setup**: Scan a QR code containing all Liquid Galaxy configuration data

**QR Code JSON Format Example:**
```json
{
  "ip": "192.168.1.100",
  "username": "lg",
  "password": "lglg",
  "screens": "5"
}
```

**Purpose**: The QR code scanner allows for quick and error-free configuration by scanning a code that contains all necessary Liquid Galaxy connection parameters, eliminating manual data entry.

**Connection Confirmation**: When successful, the RoboStream logo will appear on the leftmost screen of the Liquid Galaxy.

<div align="center">
  <img src="https://github.com/user-attachments/assets/bef763b5-337d-4476-ae3d-8429aa513fba" width="300" alt="Liquid Galaxy Configuration">
  <img src="https://github.com/user-attachments/assets/bea62792-cae8-4649-82bf-578ea3177182" width="300" alt="Liquid Galaxy QR Scanner">
</div>
---


## 🏠 Home Screen

The home screen provides easy access to all main features:

**Key Elements:**
- ⚙️ Settings button for configuration menu
- 📊 Sensor cards displaying real-time data
- 🎮 "Start Streaming" button to begin data transmission
- 🔴🟢 Connection indicators (Server, Robot & Liquid Galaxy)

<div align="center">
  <img src="https://github.com/user-attachments/assets/165dafc5-6cbf-4a73-bdca-300ab6a495b0" width="500" alt="Home Screen">
</div>

---

## ⚙️ Settings & Configuration

Access the settings menu to modify your connections:

**Available Options:**
- 🔧 Change server IP address
- 🧪 Test server connection
- 🌌 Update Liquid Galaxy details
- 🔄 Relaunch Button
- 🧹 Clear all KMLs from display
- 🤖 Configure robot IP address

<div align="center">
  <img src="https://github.com/user-attachments/assets/98c75486-b939-4520-9dbf-8a2d8062874f" width="250" alt="Settings Menu">
  <img src="https://github.com/user-attachments/assets/a5c4b6be-0a48-493e-af64-0e6400c9f927" width="250" alt="Server Settings">
  <img src="https://github.com/user-attachments/assets/a5e9cd19-d8c4-480d-a2e5-cfb32477462a" width="250" alt="LG Settings">
  <img src="https://github.com/user-attachments/assets/9b773d62-1693-44da-8b62-61917a889188" width="250" alt="Robot Settings">
</div>

---

## 📊 Sensor Data

View detailed information from individual sensors:

- **Real-time Data**: All sensor information is displayed and updated every 2 seconds
- **Live Detail Views**: Tap any sensor card to see comprehensive data that updates in real-time
- **Live Indicator**: Cards show a "LIVE" indicator to confirm real-time updates
- **Server Sync**: Data comes directly from the server and matches what's shown on Liquid Galaxy
- **Streaming**: When streaming to Liquid Galaxy, data is sent every 5 seconds automatically

<div align="center">
  <img src="https://github.com/user-attachments/assets/a80293f6-32e6-47dd-ac08-befa373fefa8" width="300" alt="Sensor Data 1">
  <img src="https://github.com/user-attachments/assets/da0f94b4-a8c2-422b-9833-02d4a56bb917" width="300" alt="Sensor Data 2">
</div>

---

## 📡 Data Streaming

Start streaming data to Liquid Galaxy:

**Streaming Options:**
- 📷 **RGB Camera**: Immediate streaming when selected
- 🔬 **Other Sensors**: Select one or more sensors, then press "Start Streaming"
- ✅ **Multiple Selection**: You can select several sensors simultaneously for concurrent data streaming
- ⏱️ **Update Frequency**: Data updates every 5 seconds during streaming

<div align="center">
  <img src="https://github.com/user-attachments/assets/030606d9-2666-478a-9ae4-662e546085bf" width="300" alt="Streaming Options">
  <img src="https://github.com/user-attachments/assets/0c2a7357-613a-4506-af3c-cc91b2dd9dc5" width="300" alt="Streaming Active">
</div>

### 🖥️ Liquid Galaxy Display

How the streaming data appears on Liquid Galaxy screens:

<div align="center">
  <img src="https://github.com/user-attachments/assets/199a16d4-610a-4afe-9fa4-4a9cdb579244" width="400" alt="LG Display 1">
  <img src="https://github.com/user-attachments/assets/53fd4e14-2949-4780-88ee-a84eec6030ff" width="400" alt="LG Display 2">
</div>

---

## ⏹️ Stop Streaming

To end the streaming session:

Simply press the **"Stop Streaming"** button to immediately stop all data transmission to Liquid Galaxy.

<div align="center">
  <img src="https://github.com/user-attachments/assets/c3dd09b4-a6b6-40db-878b-b96fca375ba8" width="300" alt="Stop Streaming">
</div>

---

<div align="center">
  <p><strong>🚀 Ready to explore robot data visualization with RoboStream!</strong></p>
</div>

---

<div align="center">
  <h3>🙏 Acknowledgements</h3>
  <p>
    Thanks to my main mentor <strong>Moisés Martínez</strong> and secondary mentors <strong>Andreu Ibañez</strong> and <strong>kamalimiquel</strong>.<br>
    And thanks to the team of the <strong>Liquid Galaxy LAB Lleida</strong>, Headquarters of the Liquid Galaxy project:<br>
    <strong>Alba, Paula, Josep, Jordi, Oriol, Sharon, Alejandro, Marc</strong>, and admin <strong>Andreu</strong>, for their continuous support on my project.<br>
    Info at <a href="https://www.liquidgalaxy.eu" target="_blank">www.liquidgalaxy.eu</a>
  </p>
</div>
