#!/bin/bash
set -e

echo "Starting BetterBird Docker Container..."
echo "======================================="

# Handle UID/GID changes at runtime
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "User Configuration:"
echo "  PUID: $PUID"
echo "  PGID: $PGID"

# Get current UID/GID of betterbird user
CURRENT_UID=$(id -u betterbird)
CURRENT_GID=$(id -g betterbird)

# Change UID/GID if different from current
if [ "$PUID" != "$CURRENT_UID" ] || [ "$PGID" != "$CURRENT_GID" ]; then
    echo "Updating betterbird user UID:GID from $CURRENT_UID:$CURRENT_GID to $PUID:$PGID..."
    
    # Change group ID
    groupmod -o -g "$PGID" betterbird
    
    # Change user ID
    usermod -o -u "$PUID" betterbird
    
    # Update ownership of home directory and important paths
    echo "Updating file ownership (this may take a moment)..."
    chown -R betterbird:betterbird /home/betterbird
    chown -R betterbird:betterbird /opt/noVNC
    
    echo "UID/GID update complete!"
else
    echo "UID/GID already correct, no changes needed."
fi

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

# Set profile directory if specified, otherwise let BetterBird use profiles.ini
if [ -z "$BETTERBIRD_PROFILE" ]; then
    echo "BETTERBIRD_PROFILE not set - BetterBird will use profiles.ini"
    # Set to empty to signal supervisord not to use --profile flag
    export BETTERBIRD_PROFILE=""
    export USE_PROFILE_FLAG="false"
else
    echo "Using custom profile directory: $BETTERBIRD_PROFILE"
    export USE_PROFILE_FLAG="true"
    # Ensure profile directory exists with proper permissions
    mkdir -p "$BETTERBIRD_PROFILE"
    chmod 755 "$BETTERBIRD_PROFILE"
    chown -R betterbird:betterbird "$BETTERBIRD_PROFILE"
fi

# Print configuration
echo "Configuration:"
echo "  Display: $DISPLAY"
echo "  VNC Port: $VNC_PORT"
echo "  noVNC Port: $NOVNC_PORT"
echo "  Resolution: $VNC_RESOLUTION"
echo "  Profile Mode: $([ "$USE_PROFILE_FLAG" = "true" ] && echo "Custom ($BETTERBIRD_PROFILE)" || echo "Default (profiles.ini)")"
echo "  Timezone: $TZ"
echo "======================================="

# Ensure Downloads directory exists
mkdir -p /home/betterbird/Downloads
chmod 755 /home/betterbird/Downloads
chown -R betterbird:betterbird /home/betterbird/Downloads

# Create X11 socket directory (fixes Xvfb warning)
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix
chown root:root /tmp/.X11-unix

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

# Start supervisord as root (it will drop to betterbird user per config)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
