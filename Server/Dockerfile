FROM ubuntu:22.04

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Set locale for ROS2
RUN apt-get update && apt-get install -y locales \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Install system dependencies and ROS2 requirements
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    gnupg2 \
    lsb-release \
    python3 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Add ROS2 repository
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Install ROS2 Humble
RUN apt-get update && apt-get install -y \
    ros-humble-desktop \
    python3-rosdep \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init && rosdep update

# Setup ROS2 environment
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
ENV ROS_DISTRO=humble
ENV ROS_VERSION=2
ENV ROS_PYTHON_VERSION=3

# Set work directory
WORKDIR /app

# Source ROS2 and install Python dependencies
COPY requirements.txt .
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && pip3 install --no-cache-dir -r requirements.txt"

# Copy application code
COPY FastAPI/ .

# Set up ROS2 Python path
ENV PYTHONPATH="${PYTHONPATH}:/opt/ros/humble/lib/python3.10/site-packages"

# Expose port
EXPOSE 8000

# Run the application with ROS2 environment
CMD ["/bin/bash", "-c", "source /opt/ros/humble/setup.bash && python3 main.py"]
