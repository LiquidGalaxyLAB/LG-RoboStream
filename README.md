# RoboStream: Real-Time Telemetry & Streaming System for Liquid Galaxy

<p align="center"><em>A modern solution for immersive telemetry and live video streaming from a robot simulator, powered by Flutter and FastAPI, built for the Liquid Galaxy ecosystem.</em></p>

## 📑 Table of Contents

1. [About the Project](#about-the-project)
2. [Features](#features)
3. [Technology Stack](#technology-stack)
4. [Getting Started](#getting-started)
   * [Prerequisites](#prerequisites)
   * [Installation](#installation)
   * [Configuration](#configuration)
5. [Usage](#usage)
6. [Roadmap](#roadmap)
7. [License](#license)
8. [Contact](#contact)

---

## 🔍 About the Project

**RoboStream** is designed for real-time monitoring of robotic telemetry in immersive, multi-screen environments like Liquid Galaxy. It consists of two main components:

1. **Simulation Backend (Python & FastAPI)**

   * Simulates robot telemetry (IMU, GPS, odometry) and actuator data in real time.
   * Exposes data via REST API and WebSocket streams.
2. **Flutter Mobile Client**

   * Cross-platform control panel for configuring connections and visualizing streamed data.
   * Integrates SSH service to issue commands to a Liquid Galaxy cluster.

The goal is to bridge the gap between remote robot monitoring and intuitive, collaborative data visualization.

---

## ✨ Features

* **Simulated Robot Telemetry**

  * IMU (accelerometer, gyroscope, magnetometer) and GPS data streams
  * Actuator simulation: wheel speed, temperature, power consumption
  * WebSocket streaming for low-latency updates
  * REST endpoints for on-demand data retrieval
* **Mobile Control App**

  * Login and connection setup screens
  * Secure SSH connection management (LGService)
  * Interactive telemetry dashboards with animated cards
  * Direct service-based login functionality integrated into LGService
* **Standalone Mode**

  * Operate without actual Liquid Galaxy hardware using simulated data

---

## 🏗️ Technology Stack

| Layer          | Technology & Version                                   |
| -------------- | ------------------------------------------------------ |
| **Backend**    | Python 3.9+, FastAPI, Uvicorn, Pydantic, WebSockets    |
| **Simulation** | ROS 2 (rosbridge\_suite), Ignition Gazebo              |
| **Frontend**   | Flutter 3.x, Dart, flutter\_bloc, go\_router, dartssh2 |
| **DevOps**     | Docker, Docker Compose, GitHub Actions, GitHub Pages   |

---

## 🚀 Getting Started

Follow these steps to set up the project locally.

### Prerequisites

* **Git** (>= 2.30)
* **Docker & Docker Compose** (optional, recommended)
* **Python 3.9+** and **pip**
* **Flutter SDK 3.x+**

### Installation

> Installation instructions will be provided once development progresses.

### Configuration

> Configuration details will be provided once development progresses.

---

## ⚙️ Usage

> Usage instructions will be provided once development progresses.

---

## 🛣️ Roadmap

---

## 📜 License


---

## 📞 Contact

**Alejandro Bernaldo de Quirós Gómez**
Email: [alejandrobernaldog@gmail.com](mailto:alejandrobernaldog@gmail.com)
Universidad Francisco de Vitoria, Madrid, Spain

> *This README is designed following best practices for clarity, structure, and community engagement.*
