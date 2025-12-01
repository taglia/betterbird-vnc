# Quick Start Guide

Get BetterBird running in 3 minutes!

## Step 1: Pull the Image

Choose your registry:

```bash
# From GitHub Container Registry (recommended)
docker pull ghcr.io/taglia/betterbird-vnc:latest

# Or from Docker Hub
docker pull tagliasteel/betterbird-vnc:latest
```

## Step 2: Run the Container

```bash
docker run -d \
  --name betterbird \
  -p 6080:6080 \
  -v betterbird-profile:/home/betterbird/.thunderbird \
  -v betterbird-downloads:/home/betterbird/Downloads \
  -e PUID=1000 \
  -e PGID=1000 \
  -e VNC_PASSWORD=your-secure-password \
  -e VNC_RESOLUTION=1920x1080 \
  -e TZ=America/New_York \
  --shm-size 2g \
  ghcr.io/taglia/betterbird-vnc:latest
```

**Important:** Change `your-secure-password` and `America/New_York` to your values!

## Step 3: Access BetterBird

Open your browser and go to:
```
http://localhost:6080
```

That's it! You should see BetterBird running in your browser.

## Next Steps

- 🔒 **Secure your setup** - See the [Security section](README.md#security-considerations)
- 📚 **Read the full README** - [README.md](README.md)
- ⚙️ **Customize settings** - Add more environment variables
- 🔄 **Use Docker Compose** - See [docker-compose.yml](docker-compose.yml)

## Using Docker Compose

1. **Download docker-compose.yml:**
   ```bash
   curl -O https://raw.githubusercontent.com/taglia/docker-betterbird/main/docker-compose.yml
   ```

2. **Edit the file** to set your password and timezone

3. **Start the container:**
   ```bash
   docker compose up -d
   ```

4. **Access:** http://localhost:6080

## Troubleshooting

### Black screen?
Wait 10-15 seconds for services to start, then refresh.

### Can't connect?
Check that port 6080 isn't already in use:
```bash
netstat -an | grep 6080
```

### Container keeps restarting?
Check the logs:
```bash
docker logs betterbird
```

For more help, see the [full README](README.md).
