#!/usr/bin/env bash
# Hermes HUD Web UI — Build & Push Script
# Run on compile machine, then pull on NAS
#
# Usage:
#   chmod +x build-and-push.sh
#   ./build-and-push.sh your-registry.com/hermes-hudui:latest

set -e

IMAGE="${1:-hermes-hudui:latest}"
REGISTRY="$(dirname "$IMAGE")"
TAG="$(basename "$IMAGE")"

echo "☤ Building hermes-hudui..."
docker build --platform linux/amd64 -t "${IMAGE}" .

echo "☤ Pushing to registry..."
docker push "${IMAGE}"

echo ""
echo "✔ Done. On your NAS, update docker-compose.yml image: and run:"
echo "   docker compose up -d"
echo ""
echo "   Then open http://<nas-ip>:3001"
