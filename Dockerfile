FROM debian:trixie-slim

# Build arguments
ARG BETTERBIRD_VERSION=140.5.0esr-bb14
ARG NOVNC_VERSION=1.7.0
ARG WEBSOCKIFY_VERSION=0.13.0
ARG DEBIAN_FRONTEND=noninteractive
ARG USER_UID=1000
ARG USER_GID=1000

# Environment variables
ENV DISPLAY=:0 \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    VNC_RESOLUTION=1280x720 \
    VNC_PASSWORD=betterbird \
    TZ=UTC

# Install dependencies
# dist-upgrade pulls in security fixes newer than the base image snapshot.
# --no-install-recommends keeps optional packages (and their CVEs) out of the image.
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
    # VNC and X11
    xvfb \
    x11vnc \
    fluxbox \
    xterm \
    # noVNC dependencies
    python3 \
    python3-numpy \
    # BetterBird dependencies
    libasound2t64 \
    libdbus-glib-1-2 \
    libdbus-1-3 \
    dbus-x11 \
    libgtk-3-0t64 \
    libx11-xcb1 \
    libxt6t64 \
    libpci3 \
    libxtst6 \
    # Graphics/OpenGL libraries
    libgl1 \
    libgl1-mesa-dri \
    libegl1 \
    libgbm1 \
    # Fonts
    fonts-liberation \
    fonts-dejavu \
    # MIME detection for GTK apps (normally a recommends)
    shared-mime-info \
    # Web browser
    firefox-esr \
    # XDG utilities for default applications
    xdg-utils \
    desktop-file-utils \
    # Utilities (curl is build-time only, purged below)
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

# Install noVNC and websockify from pinned release tarballs (avoids shipping git)
RUN mkdir -p /opt/noVNC/utils/websockify && \
    curl -fsSL "https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz" \
        | tar -xz --strip-components=1 -C /opt/noVNC && \
    curl -fsSL "https://github.com/novnc/websockify/archive/refs/tags/v${WEBSOCKIFY_VERSION}.tar.gz" \
        | tar -xz --strip-components=1 -C /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    chown -R betterbird:betterbird /opt/noVNC

# Download and install BetterBird
# Use the get.php script to always get the latest release
RUN mkdir -p /opt/betterbird && \
    curl -fsSL "https://www.betterbird.eu/downloads/get.php?os=linux&lang=en-US&version=release" \
    -o /tmp/betterbird.tar.xz && \
    tar -xJf /tmp/betterbird.tar.xz -C /opt/betterbird --strip-components=1 && \
    rm /tmp/betterbird.tar.xz && \
    chown -R betterbird:betterbird /opt/betterbird

# Remove build-time-only download tools so they don't show up in vulnerability scans
RUN apt-get purge -y curl && apt-get autoremove -y --purge && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p \
    /home/betterbird/.vnc \
    /home/betterbird/.thunderbird \
    /home/betterbird/Downloads && \
    chown -R betterbird:betterbird /home/betterbird

# Copy configuration files
COPY --chown=betterbird:betterbird scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --chown=betterbird:betterbird scripts/start.sh /usr/local/bin/start.sh
COPY --chown=betterbird:betterbird scripts/betterbird-wrapper.sh /usr/local/bin/betterbird-wrapper.sh
RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/betterbird-wrapper.sh

# Copy desktop entries for applications (as root)
COPY scripts/betterbird.desktop /usr/share/applications/betterbird.desktop
COPY scripts/firefox-esr.desktop /usr/share/applications/firefox-esr.desktop
RUN update-desktop-database /usr/share/applications || true

# Create VNC password file (x11vnc's own format; replaces tigervnc's vncpasswd)
USER betterbird
RUN mkdir -p /home/betterbird/.vnc && \
    x11vnc -storepasswd "${VNC_PASSWORD}" /home/betterbird/.vnc/passwd && \
    chmod 600 /home/betterbird/.vnc/passwd

# Configure default applications for http/https links
COPY --chown=betterbird:betterbird scripts/mimeapps.list /home/betterbird/.config/mimeapps.list

# Fluxbox config for minimal window manager
COPY --chown=betterbird:betterbird scripts/fluxbox-menu /home/betterbird/.fluxbox/menu
RUN mkdir -p /home/betterbird/.fluxbox && \
    echo "session.screen0.toolbar.visible: false" > /home/betterbird/.fluxbox/init && \
    echo "session.screen0.fullMaximization: true" >> /home/betterbird/.fluxbox/init && \
    echo "session.screen0.slit.placement: RightBottom" >> /home/betterbird/.fluxbox/init && \
    echo "session.screen0.slit.autoHide: true" >> /home/betterbird/.fluxbox/init && \
    echo "session.screen0.workspaces: 1" >> /home/betterbird/.fluxbox/init

USER root

# Expose ports
EXPOSE ${VNC_PORT} ${NOVNC_PORT}

# Volumes for persistent data
VOLUME ["/home/betterbird/.thunderbird", "/home/betterbird/Downloads"]

# Health check (python3 stdlib, so no curl/wget needed in the final image)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:${NOVNC_PORT}/', timeout=5)" || exit 1

# Start as root (entrypoint will handle switching to betterbird user)
WORKDIR /home/betterbird

ENTRYPOINT ["/usr/local/bin/start.sh"]
