# BetterBird Docker with Web-VNC

Run [BetterBird](https://www.betterbird.eu/) email client in a Docker container with web-based VNC access via noVNC. Access your email client through your web browser without installing anything locally!

[![Docker Hub](https://img.shields.io/docker/v/tagliasteel/betterbird-vnc?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/tagliasteel/betterbird-vnc)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-betterbird--vnc-blue?logo=github)](https://ghcr.io/tagliasteel/betterbird-vnc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> 🚀 **New here?** Check out the [Quick Start Guide](QUICKSTART.md) to get running in 3 minutes!

## Features

- **Web-based access**: Access BetterBird through your browser via noVNC
- **Traditional VNC support**: Connect using any VNC client
- **Persistent data**: Email profiles and downloads are persisted using Docker volumes
- **Debian-based**: Built on Debian Bookworm for stability and compatibility
- **Easy updates**: Simple scripts to update BetterBird and publish new images
- **Configurable**: Customize resolution, timezone, VNC password, and more
- **Multi-registry**: Published to Docker Hub and GitHub Container Registry

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Clone or download this repository
cd docker-betterbird

# Start the container
docker-compose up -d

# Access via web browser
# Open http://localhost:6080 in your browser
```

### Using Docker Run

**From Docker Hub:**
```bash
docker run -d \
  --name betterbird \
  -p 6080:6080 \
  -p 5900:5900 \
  -v betterbird-profile:/home/betterbird/.thunderbird \
  -v betterbird-downloads:/home/betterbird/Downloads \
  -e PUID=1000 \
  -e PGID=1000 \
  -e VNC_PASSWORD=betterbird \
  -e VNC_RESOLUTION=1280x720 \
  -e TZ=UTC \
  --shm-size 2g \
  tagliasteel/betterbird-vnc:latest
```

**From GitHub Container Registry:**
```bash
docker run -d \
  --name betterbird \
  -p 6080:6080 \
  -p 5900:5900 \
  -v betterbird-profile:/home/betterbird/.thunderbird \
  -v betterbird-downloads:/home/betterbird/Downloads \
  -e PUID=1000 \
  -e PGID=1000 \
  -e VNC_PASSWORD=betterbird \
  -e VNC_RESOLUTION=1280x720 \
  -e TZ=UTC \
  --shm-size 2g \
  ghcr.io/taglia/betterbird-vnc:latest
```

## Access Methods

### Web Browser (noVNC)
- URL: `http://localhost:6080`
- No client installation required
- Works on any device with a modern web browser

### VNC Client
- Host: `localhost`
- Port: `5900`
- Password: `betterbird` (or your configured password)

Use any VNC client like:
- TigerVNC Viewer
- RealVNC
- TightVNC
- macOS Screen Sharing

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for file permissions (set to match host user) |
| `PGID` | `1000` | Group ID for file permissions (set to match host user) |
| `VNC_PASSWORD` | `betterbird` | Password for VNC access |
| `VNC_RESOLUTION` | `1280x720` | Screen resolution (e.g., 1920x1080) |
| `TZ` | `UTC` | Timezone (e.g., America/New_York, Europe/London) |
| `DISPLAY` | `:0` | X11 display number |
| `VNC_PORT` | `5900` | VNC server port |
| `NOVNC_PORT` | `6080` | noVNC web interface port |

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `BETTERBIRD_VERSION` | `140.5.0esr-bb14` | BetterBird version to install |
| `USER_UID` | `1000` | User ID for the betterbird user |
| `USER_GID` | `1000` | Group ID for the betterbird user |

### Customizing Configuration

Edit `docker-compose.yml` to change environment variables:

```yaml
environment:
  - PUID=1000  # Change to your user ID
  - PGID=1000  # Change to your group ID
  - VNC_PASSWORD=my-secure-password
  - VNC_RESOLUTION=1920x1080
  - TZ=America/New_York
```

**Matching your host user's UID/GID** (recommended for proper file permissions):

```bash
# Find your UID/GID
id

# Output example: uid=1000(username) gid=1000(username)
# Use these values for PUID and PGID in docker-compose.yml
```

**Or set at runtime without editing files:**

```bash
# Using environment variables
PUID=$(id -u) PGID=$(id -g) docker-compose up -d

# Or create a .env file
echo "PUID=$(id -u)" > .env
echo "PGID=$(id -g)" >> .env
docker-compose up -d
```

## Data Persistence

Two volumes are used for persistent data:

- **BetterBird Profile**: `/home/betterbird/.thunderbird`
  - Contains all email accounts, settings, and local mail
- **Downloads**: `/home/betterbird/Downloads`
  - Email attachments and downloaded files

### Backup Your Data

```bash
# Backup profile
docker run --rm \
  -v betterbird-profile:/data \
  -v $(pwd):/backup \
  debian:bookworm-slim \
  tar czf /backup/betterbird-profile-backup.tar.gz /data

# Restore profile
docker run --rm \
  -v betterbird-profile:/data \
  -v $(pwd):/backup \
  debian:bookworm-slim \
  tar xzf /backup/betterbird-profile-backup.tar.gz -C /
```

## Building the Image

### Prerequisites

- Docker installed and running
- Docker Hub account (optional, for publishing)
- GitHub account (optional, for GHCR publishing)

### Build Locally

```bash
# Build with default version
docker build -t betterbird-vnc:latest .

# Build with specific version
docker build \
  --build-arg BETTERBIRD_VERSION=140.5.0esr-bb14 \
  -t betterbird-vnc:140.5.0esr-bb14 \
  .
```

### Using Build Script

The build script supports publishing to multiple registries.

**Build only (no publishing):**
```bash
scripts/build-and-publish.sh --build \
  --docker-username tagliasteel \
  --github-username taglia
```

**Build and publish to both registries:**
```bash
scripts/build-and-publish.sh --build-and-publish \
  --docker-username tagliasteel \
  --github-username taglia
```

**Publish to specific registry only:**
```bash
# GitHub Container Registry only
scripts/build-and-publish.sh --build-and-publish \
  --registries ghcr \
  --github-username taglia

# Docker Hub only
scripts/build-and-publish.sh --build-and-publish \
  --registries dockerhub \
  --docker-username tagliasteel
```

**Using environment variables:**
```bash
export DOCKER_USERNAME=tagliasteel
export GITHUB_USERNAME=taglia
scripts/build-and-publish.sh --build-and-publish
```

## Updating BetterBird

### Update to Latest Version

```bash
# Check for and update to latest version
scripts/update-betterbird.sh

# This will:
# 1. Fetch the latest BetterBird version
# 2. Update VERSION file
# 3. Update Dockerfile and docker-compose.yml
```

### Build and Publish Updated Image

```bash
# Method 1: Step by step
scripts/build-and-publish.sh --build \
  --docker-username tagliasteel \
  --github-username taglia
# Test the image...
scripts/build-and-publish.sh --publish \
  --docker-username tagliasteel \
  --github-username taglia

# Method 2: All at once
scripts/build-and-publish.sh --build-and-publish \
  --docker-username tagliasteel \
  --github-username taglia
```

The script will:
1. Build the image with the version from `VERSION` file
2. Tag it with both the version number and `latest`
3. Push both tags to Docker Hub and GitHub Container Registry

## Publishing Images

### Manual Publishing

#### One-Time Setup

**Docker Hub:**
```bash
docker login
```

**GitHub Container Registry:**
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u taglia --password-stdin
```

#### Publishing Process

1. **Update BetterBird version**:
   ```bash
   scripts/update-betterbird.sh
   ```

2. **Build the image**:
   ```bash
   scripts/build-and-publish.sh --build \
     --docker-username tagliasteel \
     --github-username taglia
   ```

3. **Test the image locally**:
   ```bash
   docker-compose up -d
   # Access http://localhost:6080 and verify it works
   ```

4. **Publish to registries**:
   ```bash
   scripts/build-and-publish.sh --publish \
     --docker-username tagliasteel \
     --github-username taglia
   ```

Or do it all at once:
```bash
scripts/update-betterbird.sh
scripts/build-and-publish.sh --build-and-publish \
  --docker-username tagliasteel \
  --github-username taglia
```

### Automated Publishing with GitHub Actions

This repository includes a GitHub Actions workflow for automated builds and publishing.

**Features:**
- ✅ Automatic builds on push to main
- ✅ Publishes to both Docker Hub and GHCR
- ✅ Weekly checks for BetterBird updates
- ✅ Automatic Docker Hub README sync
- ✅ Creates PRs for version updates

**Setup:**
1. See [.github/SETUP.md](.github/SETUP.md) for detailed instructions
2. Add required secrets to your GitHub repository:
   - `DOCKER_HUB_USERNAME`
   - `DOCKER_HUB_TOKEN`
3. Push to main branch or create a tag to trigger a build

**Triggers:**
- Push to `main` branch
- Git tags (e.g., `v1.0.0`)
- Manual dispatch from Actions tab
- Weekly schedule (Sundays at 2 AM UTC) - checks for updates

## Troubleshooting

### Container Won't Start

Check logs:
```bash
docker-compose logs -f
```

### Can't Connect to noVNC

1. Ensure port 6080 is not in use:
   ```bash
   netstat -an | grep 6080
   ```

2. Check container is running:
   ```bash
   docker ps | grep betterbird
   ```

3. Verify port mapping:
   ```bash
   docker port betterbird
   ```

### Black Screen or Display Issues

1. Check if Xvfb is running:
   ```bash
   docker exec betterbird ps aux | grep Xvfb
   ```

2. Restart the container:
   ```bash
   docker-compose restart
   ```

### BetterBird Won't Start

1. Check shared memory size (increase if needed):
   ```yaml
   shm_size: '4gb'
   ```

2. Check logs:
   ```bash
   docker-compose logs betterbird
   ```

### Permission Issues with Volumes

If you encounter permission issues:

```bash
# Build with your user ID
docker-compose build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)
docker-compose up -d
```

## Advanced Usage

### Custom BetterBird Version

Edit `docker-compose.yml`:
```yaml
build:
  args:
    BETTERBIRD_VERSION: 140.4.0esr-bb13
```

### Different Window Manager

The image uses Fluxbox by default. You can modify the Dockerfile to use a different window manager if needed.

### Running Multiple Instances

```bash
# Instance 1
docker run -d --name betterbird-1 -p 6081:6080 -p 5901:5900 ...

# Instance 2
docker run -d --name betterbird-2 -p 6082:6080 -p 5902:5900 ...
```

## Security Considerations

⚠️ **IMPORTANT SECURITY WARNINGS** ⚠️

This container runs a full email client accessible via VNC. **Improper deployment can expose your email accounts and data to the internet.**

### Critical Security Measures

1. **🔒 NEVER expose VNC ports (5900, 6080) directly to the internet**
   - These ports are **unencrypted by default**
   - Anyone who can access them can see your email, even with a VNC password

2. **🔑 Change the default VNC password immediately**
   - Default password: `betterbird`
   - Set via environment variable: `VNC_PASSWORD=your-strong-password`
   - Use a strong, unique password (minimum 16 characters)

3. **🌐 Use HTTPS/TLS for external access**
   - Always use a reverse proxy with SSL/TLS certificates
   - Options: Caddy (automatic HTTPS), nginx, Traefik
   - Never use HTTP for external access

4. **🔐 Use strong passwords for your email accounts**
   - Enable 2FA where possible
   - Use app-specific passwords for email accounts

5. **🧱 Firewall rules**
   - Block ports 5900 and 6080 from external networks
   - Only allow access from your reverse proxy or VPN

### Recommended Access Methods

Choose ONE of these secure access methods:

#### Option 1: Reverse Proxy with HTTPS (Recommended for Web Access)

**Using Caddy (Automatic HTTPS):**
```caddy
betterbird.yourdomain.com {
    reverse_proxy localhost:6080
}
```

**Using nginx with Let's Encrypt:**
```nginx
server {
    listen 443 ssl http2;
    server_name betterbird.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/betterbird.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/betterbird.yourdomain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:6080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Using Traefik:**
```yaml
services:
  betterbird:
    image: ghcr.io/tagliasteel/betterbird-vnc:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.betterbird.rule=Host(`betterbird.yourdomain.com`)"
      - "traefik.http.routers.betterbird.entrypoints=websecure"
      - "traefik.http.routers.betterbird.tls.certresolver=letsencrypt"
      - "traefik.http.services.betterbird.loadbalancer.server.port=6080"
```

#### Option 2: Tailscale VPN (Recommended for Personal Use)

[Tailscale](https://tailscale.com/) provides zero-configuration VPN access.

1. **Install Tailscale on your server:**
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```

2. **Access BetterBird via Tailscale IP:**
   ```
   http://100.x.x.x:6080
   ```

3. **Benefits:**
   - Encrypted peer-to-peer connection
   - No port forwarding needed
   - Access from anywhere on your Tailscale network
   - No reverse proxy configuration needed

#### Option 3: Cloudflare Tunnel (Zero-Trust Access)

[Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/) provides secure access without opening ports.

1. **Install cloudflared:**
   ```bash
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   sudo dpkg -i cloudflared-linux-amd64.deb
   ```

2. **Create tunnel:**
   ```bash
   cloudflared tunnel login
   cloudflared tunnel create betterbird
   cloudflared tunnel route dns betterbird betterbird.yourdomain.com
   ```

3. **Configure tunnel (config.yml):**
   ```yaml
   tunnel: <tunnel-id>
   credentials-file: /root/.cloudflared/<tunnel-id>.json
   
   ingress:
     - hostname: betterbird.yourdomain.com
       service: http://localhost:6080
     - service: http_status:404
   ```

4. **Run tunnel:**
   ```bash
   cloudflared tunnel run betterbird
   ```

5. **Benefits:**
   - Zero-trust access control
   - No exposed ports
   - DDoS protection
   - Free for personal use

#### Option 4: Local Network Only

**Safest option for home use:**
- Only access via `http://localhost:6080` or `http://192.168.x.x:6080`
- No external access
- Use VPN (like Tailscale) when away from home

### Additional Security Best Practices

- 📱 **Enable 2FA** on your email accounts
- 🔄 **Keep the image updated** - run `docker pull` regularly
- 📊 **Monitor access logs** - check `docker logs betterbird`
- 🚫 **Don't store sensitive data** in the container
- 💾 **Backup your profile** regularly (see Data Persistence section)
- 🔍 **Review running processes** - `docker exec betterbird ps aux`
- 🌐 **Use a dedicated VLAN** for container isolation (advanced)

### What NOT to Do

❌ **DO NOT** expose ports 5900 or 6080 to the internet without HTTPS  
❌ **DO NOT** use the default VNC password in production  
❌ **DO NOT** run as root on your host (Docker already provides isolation)  
❌ **DO NOT** disable firewall rules for convenience  
❌ **DO NOT** use this for untrusted users (single-user application)

## Project Structure

```
.
├── .github/
│   ├── workflows/
│   │   └── build-and-publish.yml  # GitHub Actions workflow
│   └── SETUP.md                   # GitHub Actions setup guide
├── scripts/
│   ├── start.sh                   # Container entrypoint script
│   ├── supervisord.conf           # Supervisor process manager config
│   ├── build-and-publish.sh       # Multi-registry build/publish script
│   └── update-betterbird.sh       # Version update script
├── Dockerfile                      # Main Docker image definition
├── docker-compose.yml              # Docker Compose configuration
├── DOCKER_HUB_README.md            # Docker Hub/GHCR description
├── VERSION                         # Current BetterBird version
├── LICENSE                         # MIT License
├── .dockerignore                   # Docker build ignore rules
├── .gitignore                      # Git ignore rules
└── README.md                       # This file
```

## Contributing

Contributions are welcome! Here's how you can help:

- 🐛 **Report bugs** - Open an issue describing the problem
- 💡 **Suggest features** - Share your ideas for improvements
- 📝 **Improve documentation** - Fix typos, add examples, clarify instructions
- 🔧 **Submit pull requests** - Fix bugs or add features
- ⭐ **Star the repository** - Show your support!

### Development Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes thoroughly
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Reporting Security Issues

If you discover a security vulnerability, please **DO NOT** open a public issue. Instead, email the maintainer directly or use GitHub's private security advisory feature.

## License & Attribution

### Docker Configuration

The Docker configuration files, scripts, and documentation in this repository are licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

This includes:
- Dockerfile
- docker-compose.yml
- Shell scripts (start.sh, build-and-publish.sh, update-betterbird.sh)
- Documentation files (README.md, QUICKSTART.md, etc.)

### Packaged Software

This Docker image packages the following third-party software components, each licensed under its respective open source license:

| Component | License | Website |
|-----------|---------|---------|
| **BetterBird** | Mozilla Public License 2.0 | [betterbird.eu](https://www.betterbird.eu/) |
| **noVNC** | MPL 2.0, BSD-2-Clause, SIL OFL 1.1, others | [novnc.com](https://novnc.com/) |
| **TigerVNC** | GNU General Public License v2.0 | [tigervnc.org](https://tigervnc.org/) |
| **Fluxbox** | MIT License | [fluxbox.org](http://fluxbox.org/) |
| **Debian packages** | Various DFSG-compliant licenses | [debian.org](https://www.debian.org/) |

See [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md) for complete license information and attributions.

### Source Code Availability

As required by the licenses of included software, source code is freely available:

- **BetterBird source**: https://github.com/Betterbird/thunderbird-patches
- **BetterBird releases**: https://www.betterbird.eu/downloads/
- **noVNC source**: https://github.com/novnc/noVNC
- **TigerVNC source**: https://github.com/TigerVNC/tigervnc
- **Fluxbox source**: https://github.com/fluxbox/fluxbox
- **Debian sources**: https://www.debian.org/distrib/packages

All packaged software is used in unmodified form from official sources.

### Important Notes

- This is a distribution/packaging project. No modifications have been made to the source code of any included software.
- Each component retains its original license and copyright.
- The Docker image is an aggregation of separately-licensed components, not a derivative work.
- GPL and MPL components remain under their respective licenses; only the Docker configuration is MIT-licensed.

## Acknowledgments

- [BetterBird](https://www.betterbird.eu/) - The fine-tuned email client based on Thunderbird
- [noVNC](https://novnc.com/) - Web-based VNC client enabling browser access
- [TigerVNC](https://tigervnc.org/) - High-performance VNC server
- [Fluxbox](http://fluxbox.org/) - Lightweight window manager
- [Debian](https://www.debian.org/) - The stable and reliable base distribution
