#!/bin/bash
set -e

# Configurar el entorno ROS
source "/opt/ros/noetic/setup.bash"

# Si existe el workspace, configurarlo
if [ -f "/root/catkin_ws/devel/setup.bash" ]; then
    source "/root/catkin_ws/devel/setup.bash"
fi

# Ejecutar el comando especificado
exec "$@"
