#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="${HOME}/.local/bin"
SERVICE_MENU_DIR="${HOME}/.local/share/kio/servicemenus"
SYSTEMD_DIR="${HOME}/.config/systemd/user"

echo "=== AI Assistant Service Menu Installer ==="
echo ""

find_ollama() {
    local candidates=(
        "/usr/local/bin/ollama"
        "/usr/bin/ollama"
    )
    local path_ollama
    path_ollama="$(command -v ollama 2>/dev/null || true)"
    [ -n "${path_ollama}" ] && candidates+=("${path_ollama}")

    for candidate in "${candidates[@]}"; do
        if [ -x "${candidate}" ]; then
            echo "${candidate}"
            return 0
        fi
    done

    return 1
}

if ! OLLAMA_BIN="$(find_ollama)"; then
    echo "Warning: ollama not found. Install it from https://ollama.com"
    echo "The service menu will still be installed but Ollama auto-start will be skipped."
    echo ""
    INSTALL_OLLAMA_SERVICE=false
else
    echo "Found ollama: ${OLLAMA_BIN}"
    INSTALL_OLLAMA_SERVICE=true
fi

echo ""
echo "Installing launch script..."
mkdir -p "${INSTALL_DIR}"
cp "${SCRIPT_DIR}/opencode-launch.sh" "${INSTALL_DIR}/opencode-launch.sh"
chmod +x "${INSTALL_DIR}/opencode-launch.sh"
echo "  -> ${INSTALL_DIR}/opencode-launch.sh"

echo "Installing KDE service menu..."
mkdir -p "${SERVICE_MENU_DIR}"

if [ "${INSTALL_OLLAMA_SERVICE}" = true ]; then
    mkdir -p "${HOME}/.local/bin"
    if [ "${OLLAMA_BIN}" != "${HOME}/.local/bin/ollama" ]; then
        ln -sf "${OLLAMA_BIN}" "${HOME}/.local/bin/ollama"
    fi
fi

sed "s|%h/.local/bin/opencode-launch.sh|${HOME}/.local/bin/opencode-launch.sh|g" \
    "${SCRIPT_DIR}/opencode-context.desktop" > "${SERVICE_MENU_DIR}/opencode-context.desktop"
echo "  -> ${SERVICE_MENU_DIR}/opencode-context.desktop"

if [ "${INSTALL_OLLAMA_SERVICE}" = true ]; then
    echo "Installing Ollama systemd user service..."
    mkdir -p "${SYSTEMD_DIR}"

    sed "s|%h/.local/bin/ollama|${OLLAMA_BIN}|g" \
        "${SCRIPT_DIR}/ollama.service" > "${SYSTEMD_DIR}/ollama.service"
    echo "  -> ${SYSTEMD_DIR}/ollama.service"

    systemctl --user daemon-reload
    systemctl --user enable ollama.service
    systemctl --user start ollama.service
    echo "  -> Ollama service enabled and started"
else
    echo "Skipping Ollama systemd service (ollama not installed)"
fi

echo ""
echo "Refreshing KDE service menu cache..."
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 &>/dev/null || true
elif command -v kbuildsycoca5 &>/dev/null; then
    kbuildsycoca5 &>/dev/null || true
fi

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Right-click any folder in Dolphin → 'Open AI Assistant Here'"
echo ""
if [ "${INSTALL_OLLAMA_SERVICE}" = true ]; then
    echo "Ollama will auto-start on login."
    echo "Manage with: systemctl --user start/stop/status ollama.service"
else
    echo "Note: Install Ollama from https://ollama.com for LLM support."
fi