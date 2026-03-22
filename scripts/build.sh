#!/bin/bash
#
# Build and push Docker image for hetzner-to-eks documentation site
#

set -e

REGISTRY="${REGISTRY:-docker.io}"
IMAGE_NAME="${IMAGE_NAME:-durianlab/hetzner-to-eks}"
TAG="${TAG:-latest}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build     Build Docker image"
    echo "  push      Push Docker image to registry"
    echo "  all       Build and push"
    echo "  local     Build for local testing (no registry)"
    echo ""
    echo "Options (environment variables):"
    echo "  REGISTRY=$REGISTRY"
    echo "  IMAGE_NAME=$IMAGE_NAME"
    echo "  TAG=$TAG"
    exit 1
}

CMD="${1:-all}"

FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"
LATEST_IMAGE="${REGISTRY}/${IMAGE_NAME}:latest"

log_info "Building image: $FULL_IMAGE"

case $CMD in
    build)
        docker build -t "$FULL_IMAGE" .
        log_info "Image built: $FULL_IMAGE"
        ;;
    push)
        log_info "Pushing $FULL_IMAGE..."
        docker push "$FULL_IMAGE"
        if [ "$TAG" != "latest" ]; then
            docker tag "$FULL_IMAGE" "$LATEST_IMAGE"
            log_info "Pushing $LATEST_IMAGE..."
            docker push "$LATEST_IMAGE"
        fi
        log_info "Push complete!"
        ;;
    all)
        docker build -t "$FULL_IMAGE" .
        log_info "Image built: $FULL_IMAGE"
        log_info "Pushing $FULL_IMAGE..."
        docker push "$FULL_IMAGE"
        if [ "$TAG" != "latest" ]; then
            docker tag "$FULL_IMAGE" "$LATEST_IMAGE"
            log_info "Pushing $LATEST_IMAGE..."
            docker push "$LATEST_IMAGE"
        fi
        log_info "Done!"
        ;;
    local)
        docker build -t hetzner-to-eks:local .
        log_info "Image built: hetzner-to-eks:local"
        log_info "Run locally with:"
        echo "  docker run -p 8080:80 hetzner-to-eks:local"
        ;;
    *)
        log_info "Unknown command: $CMD"
        usage
        ;;
esac
