FROM debian:bookworm-slim

# Build arguments
ARG BETTERBIRD_VERSION=140.5.0esr-bb14
ARG DEBIAN_FRONTEND=noninteractive
ARG USER_UID=1000
ARG USER_GID=1000

# Environment variables
ENV DISPLAY=:0 \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    VNC_RESOLUTION=1280x720 \
    VNC_PASSWORD=betterbird \
    BETTERBIRD_PROFILE=/home/betterbird/.thunderbird \
    TZ=UTC

# Install dependencies
RUN apt-get update && apt-get install -y \
    # VNC and X11
    tigervnc-standalone-server \
    tigervnc-common \
    xvfb \
    x11vnc \
    fluxbox \
    xterm \
    # noVNC dependencies
    python3 \
    python3-numpy \
    git \
    net-tools \
    # BetterBird dependencies
    libasound2 \
    libdbus-glib-1-2 \
    libdbus-1-3 \
    dbus-x11 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxt6 \
    libpci3 \
    libxtst6 \
    # Graphics/OpenGL libraries
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libegl1-mesa \
    libgbm1 \
    # Fonts
    fonts-liberation \
    fonts-dejavu \
    # Web browser
    firefox-esr \
    # Utilities
    wget \
    bzip2 \
    xz-utils \
    ca-certificates \
    supervisor \
    procps \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN groupadd -g ${USER_GID} betterbird && \
    useradd -m -u ${USER_UID} -g betterbird -s /bin/bash betterbird

# Set Firefox as default browser
RUN update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/firefox-esr 100 && \
    update-alternatives --set x-www-browser /usr/bin/firefox-esr

# Install noVNC
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone --depth 1 https://github.com/novnc/websockify /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    chown -R betterbird:betterbird /opt/noVNC

# Download and install BetterBird
# Use the get.php script to always get the latest release
RUN mkdir -p /opt/betterbird && \
    wget -q "https://www.betterbird.eu/downloads/get.php?os=linux&lang=en-US&version=release" \
    -O /tmp/betterbird.tar.xz && \
    tar -xJf /tmp/betterbird.tar.xz -C /opt/betterbird --strip-components=1 && \
    rm /tmp/betterbird.tar.xz && \
    chown -R betterbird:betterbird /opt/betterbird

# Create necessary directories
RUN mkdir -p \
    /home/betterbird/.vnc \
    /home/betterbird/.thunderbird \
    /home/betterbird/Downloads && \
    chown -R betterbird:betterbird /home/betterbird

# Copy configuration files
COPY --chown=betterbird:betterbird scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --chown=betterbird:betterbird scripts/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Create VNC password file
USER betterbird
RUN mkdir -p /home/betterbird/.vnc && \
    echo "${VNC_PASSWORD}" | vncpasswd -f > /home/betterbird/.vnc/passwd && \
    chmod 600 /home/betterbird/.vnc/passwd

# Fluxbox config for minimal window manager
RUN mkdir -p /home/betterbird/.fluxbox && \
    echo "session.screen0.toolbar.visible: false" > /home/betterbird/.fluxbox/init && \
    echo "session.screen0.fullMaximization: true" >> /home/betterbird/.fluxbox/init && \
    echo "session.screen0.slit.placement: RightBottom" >> /home/betterbird/.fluxbox/init && \
    echo "session.screen0.slit.autoHide: true" >> /home/betterbird/.fluxbox/init && \
    fluxbox-generate_menu -o /home/betterbird/.fluxbox/menu || true

USER root

# Expose ports
EXPOSE ${VNC_PORT} ${NOVNC_PORT}

# Volumes for persistent data
VOLUME ["/home/betterbird/.thunderbird", "/home/betterbird/Downloads"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:${NOVNC_PORT}/ || exit 1

# Start as root (entrypoint will handle switching to betterbird user)
WORKDIR /home/betterbird

ENTRYPOINT ["/usr/local/bin/start.sh"]
