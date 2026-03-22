#!/bin/bash
#
# Deploy hetzner-to-eks documentation site to Kubernetes
#

set -e

NAMESPACE="${NAMESPACE:-docs}"
RELEASE_NAME="${RELEASE_NAME:-hetzner-to-eks}"
CHART_PATH="${CHART_PATH:-./helm/hetzner-to-eks}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  install     Install the chart"
    echo "  upgrade     Upgrade the release"
    echo "  uninstall   Uninstall the release"
    echo "  status      Show release status"
    echo "  template    Render templates without installing"
    echo "  values      Show all values"
    echo ""
    echo "Options:"
    echo "  -n, --namespace    Kubernetes namespace (default: docs)"
    echo "  -r, --release      Release name (default: hetzner-to-eks)"
    echo "  -f, --values       Custom values file"
    echo "  --dry-run          Dry run mode"
    echo "  --help             Show this help"
    echo ""
    exit 1
}

CMD="${1:-install}"
shift || true

# Parse options
VALUES_FILE=""
DRY_RUN=""
NAMESPACE_FLAG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            NAMESPACE_FLAG="-n $NAMESPACE"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -f|--values)
            VALUES_FILE="-f $2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Ensure namespace exists
log_info "Ensuring namespace '$NAMESPACE' exists..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

case $CMD in
    install)
        log_info "Installing $RELEASE_NAME to $NAMESPACE..."
        helm install "$RELEASE_NAME" "$CHART_PATH" \
            $NAMESPACE_FLAG \
            $VALUES_FILE \
            $DRY_RUN \
            --wait --timeout 5m
        log_info "Done! Get the status with: $0 status -n $NAMESPACE"
        ;;
    upgrade)
        log_info "Upgrading $RELEASE_NAME in $NAMESPACE..."
        helm upgrade "$RELEASE_NAME" "$CHART_PATH" \
            $NAMESPACE_FLAG \
            $VALUES_FILE \
            $DRY_RUN \
            --wait --timeout 5m
        log_info "Upgrade complete!"
        ;;
    uninstall)
        log_warn "Uninstalling $RELEASE_NAME from $NAMESPACE..."
        helm uninstall "$RELEASE_NAME" $NAMESPACE_FLAG
        log_info "Uninstall complete!"
        ;;
    status)
        helm status "$RELEASE_NAME" $NAMESPACE_FLAG
        ;;
    template)
        log_info "Rendering templates..."
        helm template "$RELEASE_NAME" "$CHART_PATH" \
            $VALUES_FILE \
            $DRY_RUN
        ;;
    values)
        log_info "Current values..."
        helm show values "$CHART_PATH"
        ;;
    *)
        log_error "Unknown command: $CMD"
        usage
        ;;
esac
