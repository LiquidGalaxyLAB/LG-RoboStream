# Usar Ubuntu 20.04 como base
FROM ubuntu:20.04

# Evitar preguntas interactivas durante la instalación
ARG DEBIAN_FRONTEND=noninteractive

# Configurar timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Actualizar el sistema e instalar dependencias básicas
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    wget \
    git \
    vim \
    nano \
    build-essential \
    python3-pip \
    python3-dev \
    locales \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Configurar locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Agregar el repositorio de ROS
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# Agregar las claves de ROS
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

# Actualizar la lista de paquetes
RUN apt-get update

# Instalar ROS Noetic Desktop Full
RUN apt-get install -y \
    ros-noetic-desktop-full \
    && rm -rf /var/lib/apt/lists/*

# Instalar herramientas adicionales de ROS
RUN apt-get update && apt-get install -y \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    python3-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

# Inicializar rosdep
RUN rosdep init && rosdep update

# Configurar el entorno ROS
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

# Crear un workspace de catkin
RUN mkdir -p /root/catkin_ws/src
WORKDIR /root/catkin_ws

# Inicializar el workspace
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin_make"

# Configurar el workspace en bashrc
RUN echo "source /root/catkin_ws/devel/setup.bash" >> ~/.bashrc

# Variables de entorno
ENV ROS_DISTRO=noetic
ENV ROS_PYTHON_VERSION=3
ENV PYTHONPATH="/opt/ros/noetic/lib/python3/dist-packages:$PYTHONPATH"

# Crear script de entrada
COPY ros_entrypoint.sh /
RUN chmod +x /ros_entrypoint.sh

# Configurar el punto de entrada
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
