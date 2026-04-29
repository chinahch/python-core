#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="python"
INSTALL_ROOT="/etc/python"
CONFIG_FILE="${INSTALL_ROOT}/config.yml"
BINARY_PATH="/usr/local/bin/python"
SERVICE_NAME="python.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
DOWNLOAD_BASE="https://raw.githubusercontent.com/chinahch/python-core/main"

log() {
    echo "[INFO] $*"
}

err() {
    echo "[ERROR] $*" >&2
}

detect_arch() {
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "amd64" ;;
    esac
}

write_service() {
    cat <<EOF2 > "$SERVICE_PATH"
[Unit]
Description=V2bX Python Backend
After=network.target

[Service]
ExecStart=${BINARY_PATH} -c ${CONFIG_FILE}
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF2
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
}

download_and_install_binary() {
    local arch tmp package_url
    arch=$(detect_arch)
    tmp=$(mktemp -d)
    package_url="${DOWNLOAD_BASE}/python-linux-${arch}.tar.gz"

    log "Downloading package: $package_url"
    curl -fsSL "$package_url" -o "${tmp}/package.tar.gz"

    log "Extracting package"
    tar -xzvf "${tmp}/package.tar.gz" -C "$tmp" >/dev/null

    log "Installing binary to $BINARY_PATH"
    install -m 755 "${tmp}/python-linux-${arch}" "$BINARY_PATH"

    mkdir -p "$INSTALL_ROOT"
    touch "$CONFIG_FILE"
}

start_service() {
    log "Starting ${SERVICE_NAME}"
    systemctl restart "$SERVICE_NAME"
}

main() {
    log "Installing ${APP_NAME}"
    download_and_install_binary
    write_service
    start_service
    log "Done"
    log "Service: ${SERVICE_NAME}"
    log "Config: ${CONFIG_FILE}"
}

main "$@"
