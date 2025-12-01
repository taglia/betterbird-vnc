# BetterBird with Web-VNC

Run BetterBird email client in Docker with browser-based access via noVNC.

## Quick Start

```bash
docker run -d \
  --name betterbird \
  -p 6080:6080 \
  -p 5900:5900 \
  -v betterbird-profile:/home/betterbird/.thunderbird \
  -v betterbird-downloads:/home/betterbird/Downloads \
  -e VNC_PASSWORD=betterbird \
  --shm-size 2g \
  tagliasteel/betterbird-vnc:latest
```

Then open **http://localhost:6080** in your browser!

## What is BetterBird?

[BetterBird](https://www.betterbird.eu/) is a fine-tuned version of Mozilla Thunderbird with additional features, bug fixes, and UI improvements. This Docker image packages BetterBird with VNC and noVNC for easy browser-based access.

## Features

- 🌐 **Web-based access** - Use BetterBird in your browser via noVNC
- 🖥️ **VNC support** - Connect with traditional VNC clients
- 💾 **Persistent data** - Email profiles and downloads saved in Docker volumes
- 🔧 **Configurable** - Customize resolution, timezone, VNC password
- 🐧 **Debian-based** - Built on stable Debian Bookworm

## Access Methods

### Web Browser (noVNC) - Recommended
- Open `http://localhost:6080` in any modern browser
- No VNC client installation needed
- Works on any device

### VNC Client
- Connect to `localhost:5900`
- Default password: `betterbird`
- Use any VNC client (TigerVNC, RealVNC, etc.)

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | `betterbird` | VNC access password |
| `VNC_RESOLUTION` | `1280x720` | Screen resolution |
| `TZ` | `UTC` | Timezone (e.g., America/New_York) |

### Example with Custom Settings

```bash
docker run -d \
  --name betterbird \
  -p 6080:6080 \
  -p 5900:5900 \
  -v betterbird-profile:/home/betterbird/.thunderbird \
  -v betterbird-downloads:/home/betterbird/Downloads \
  -e VNC_PASSWORD=my-secure-password \
  -e VNC_RESOLUTION=1920x1080 \
  -e TZ=America/New_York \
  --shm-size 2g \
  tagliasteel/betterbird-vnc:latest
```

## Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  betterbird:
    image: tagliasteel/betterbird-vnc:latest
    container_name: betterbird
    ports:
      - "6080:6080"  # noVNC web interface
      - "5900:5900"  # VNC port
    environment:
      - VNC_PASSWORD=betterbird
      - VNC_RESOLUTION=1280x720
      - TZ=UTC
    volumes:
      - betterbird-profile:/home/betterbird/.thunderbird
      - betterbird-downloads:/home/betterbird/Downloads
    restart: unless-stopped
    shm_size: '2gb'

volumes:
  betterbird-profile:
  betterbird-downloads:
```

Start with:
```bash
docker-compose up -d
```

## Data Persistence

### Email Profile
Your BetterBird profile (accounts, settings, local mail) is stored in:
- **Volume:** `betterbird-profile`
- **Path:** `/home/betterbird/.thunderbird`

### Downloads
Email attachments and downloads are stored in:
- **Volume:** `betterbird-downloads`
- **Path:** `/home/betterbird/Downloads`

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

## Available Tags

- `latest` - Latest stable BetterBird version
- `140.5.0esr-bb14` - Specific BetterBird version

## Ports

| Port | Description |
|------|-------------|
| 6080 | noVNC web interface (HTTP) |
| 5900 | VNC server |

## Security Recommendations

⚠️ **CRITICAL SECURITY WARNINGS** ⚠️

**This container exposes your email client via VNC. Improper deployment can expose your email and personal data!**

### Must-Do Security Steps

1. 🔒 **NEVER expose ports 5900 or 6080 directly to the internet** - they are unencrypted!
2. 🔑 **Change the default VNC password** - set `VNC_PASSWORD` to a strong password (16+ characters)
3. 🌐 **Always use HTTPS** - use a reverse proxy (Caddy, nginx, Traefik) with SSL certificates
4. 🔐 **Enable 2FA** on your email accounts
5. 🧱 **Use firewall rules** - block VNC ports from external access

### Secure Access Options

**For External Access:**
- Use a reverse proxy with HTTPS (Caddy, nginx, Traefik)
- Use Tailscale VPN for encrypted peer-to-peer access
- Use Cloudflare Tunnel for zero-trust access

**For Home/Local Use:**
- Access only via local network (192.168.x.x:6080)
- Use VPN when accessing remotely

### Reverse Proxy Examples

**Caddy (Automatic HTTPS):**
```caddy
betterbird.yourdomain.com {
    reverse_proxy localhost:6080
}
```

**nginx with HTTPS:**
```nginx
server {
    listen 443 ssl http2;
    server_name betterbird.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:6080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

**See full README for Tailscale and Cloudflare Tunnel setup.**

## Troubleshooting

### Container restarts repeatedly
- Check logs: `docker logs betterbird`
- Ensure sufficient shared memory: `--shm-size 2g`

### Black screen in noVNC
- Wait 10-15 seconds for services to start
- Refresh the browser
- Check logs: `docker logs betterbird`

### Can't connect to VNC
- Verify port mapping: `docker port betterbird`
- Check firewall settings
- Ensure VNC port 5900 is not already in use

### Performance issues
- Increase shared memory: `--shm-size 4g`
- Allocate more CPU/RAM to Docker

## Source Code & Issues

- **GitHub:** https://github.com/taglia/docker-betterbird
- **Issues:** https://github.com/taglia/docker-betterbird/issues
- **BetterBird:** https://www.betterbird.eu/

## License & Attribution

### Docker Configuration

**Docker files and scripts**: MIT License

See the [GitHub repository](https://github.com/taglia/docker-betterbird) for complete source code and documentation.

### Packaged Software

This Docker image includes third-party software components, each under its own open source license:

| Component | License |
|-----------|---------|
| **BetterBird** | Mozilla Public License 2.0 |
| **noVNC** | MPL 2.0 (core), BSD-2-Clause, SIL OFL 1.1, others |
| **TigerVNC** | GNU General Public License v2.0 |
| **Fluxbox** | MIT License |
| **Debian packages** | Various DFSG-compliant licenses |

### Source Code Availability

Source code for all components is freely available:
- **BetterBird**: https://www.betterbird.eu/downloads/ and https://github.com/Betterbird/thunderbird-patches
- **noVNC**: https://github.com/novnc/noVNC
- **TigerVNC**: https://github.com/TigerVNC/tigervnc
- **Fluxbox**: https://github.com/fluxbox/fluxbox
- **Debian**: https://www.debian.org/distrib/packages

All packaged software is used in unmodified form. For complete license information, see [THIRD-PARTY-LICENSES.md](https://github.com/taglia/docker-betterbird/blob/main/THIRD-PARTY-LICENSES.md) in the source repository.

## Support

If you find this image useful, please ⭐ star the repository!

For issues or questions:
- Open an issue on [GitHub](https://github.com/taglia/docker-betterbird/issues)
- Check BetterBird documentation: https://www.betterbird.eu/support/
