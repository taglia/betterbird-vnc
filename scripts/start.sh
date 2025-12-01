#!/bin/bash
set -e

echo "Starting BetterBird Docker Container..."
echo "======================================="

# Set timezone
if [ ! -z "$TZ" ]; then
    echo "Setting timezone to $TZ"
    export TZ
fi

# Create VNC password if VNC_PASSWORD is provided and different
if [ ! -z "$VNC_PASSWORD" ]; then
    echo "Configuring VNC password..."
    mkdir -p /home/betterbird/.vnc
    echo "$VNC_PASSWORD" | vncpasswd -f > /home/betterbird/.vnc/passwd
    chmod 600 /home/betterbird/.vnc/passwd
fi

# Print configuration
echo "Configuration:"
echo "  Display: $DISPLAY"
echo "  VNC Port: $VNC_PORT"
echo "  noVNC Port: $NOVNC_PORT"
echo "  Resolution: $VNC_RESOLUTION"
echo "  Timezone: $TZ"
echo "======================================="

# Ensure proper permissions
mkdir -p /home/betterbird/.thunderbird /home/betterbird/Downloads
chmod 755 /home/betterbird/.thunderbird /home/betterbird/Downloads

# Start D-Bus session bus
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    echo "Starting D-Bus session..."
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
    export DBUS_SESSION_BUS_PID
fi

# Wait a moment for environment to be ready
sleep 1

echo "Starting services via supervisord..."
echo ""
echo "Access the application at:"
echo "  noVNC (web browser): http://localhost:$NOVNC_PORT"
echo "  VNC client: localhost:$VNC_PORT"
echo "======================================="

# Start supervisord (it will manage all processes)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
