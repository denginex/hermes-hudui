# Hermes HUD Web UI — Docker Build & Deploy Guide

## Architecture

```
Compile Machine (build)          NAS (run)
─────────────────────            ─────────────────────
docker build ──────────────────→ Image
         ↓                              ↓
    Push to registry              docker compose up
    (docker push)                        ↓
                                   Container listens :3001
```

## Step 1: Build on Compile Machine

```bash
cd /path/to/hermes-hudui-docker

# Login to your registry (example with Docker Hub)
docker login

# Build and push
chmod +x build-and-push.sh
./build-and-push.sh your-registry.com/hermes-hudui:latest
```

Supported registry examples:
- Docker Hub:   `your-dockerhub-username/hermes-hudui:latest`
- GHCR:         `ghcr.io/your-org/hermes-hudui:latest`
- Self-hosted:  `your-nas:5000/hermes-hudui:latest`

## Step 2: Deploy on NAS

SSH into your NAS, then:

```bash
# Create directory
mkdir -p ~/docker/hermes-hudui
cd ~/docker/hermes-hudui

# Copy docker-compose.yml from compile machine
# (or create it manually — see docker-compose.yml in this folder)

# Edit image: line to point to your registry

# Start
docker compose up -d

# Check logs
docker compose logs -f
```

## Configuration

Edit `docker-compose.yml` to configure:

| Setting | Default | Description |
|---------|---------|-------------|
| `HERMES_HOME` | `/data/.hermes` | Path inside container |
| `ports` | `3001:3001` | External:Internal port |
| `volumes` | `~/.hermes:/data/.hermes:ro` | Mount your Hermes data (read-only) |

### If your Hermes data is at a custom location on NAS:

```yaml
volumes:
  /your/custom/path/.hermes:/data/.hermes:ro
```

### If Hermes Agent runs as another container (share network):

```yaml
services:
  hermes-hudui:
    # ... existing config ...
    network_mode: container:hermes-agent  # share network with Hermes container
```

Or put both in same `docker-compose.yml` with shared network.

## Access

Open `http://<your-nas-ip>:3001` in browser.

## Troubleshooting

```bash
# Check if container is running
docker ps | grep hermes-hudui

# View logs
docker compose logs -f

# Restart
docker compose restart

# Rebuild after update
docker compose pull && docker compose up -d
```
