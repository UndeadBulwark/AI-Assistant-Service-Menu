#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
SERVICE_MENU_DIR="${HOME}/.local/share/kio/servicemenus"
SYSTEMD_DIR="${HOME}/.config/systemd/user"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ai-assistant-menu"

echo "=== AI Assistant Service Menu Uninstaller ==="
echo ""

echo "Removing launch scripts..."
rm -f "${INSTALL_DIR}/opencode-launch.sh"
echo "  -> Removed ${INSTALL_DIR}/opencode-launch.sh"
rm -f "${INSTALL_DIR}/terminal-launch.sh"
echo "  -> Removed ${INSTALL_DIR}/terminal-launch.sh"
rm -f "${INSTALL_DIR}/ai-config.sh"
echo "  -> Removed ${INSTALL_DIR}/ai-config.sh"

echo "Removing KDE service menu..."
rm -f "${SERVICE_MENU_DIR}/opencode-context.desktop"
echo "  -> Removed ${SERVICE_MENU_DIR}/opencode-context.desktop"

echo "Removing Ollama systemd user service..."
rm -f "${SYSTEMD_DIR}/ollama.service"
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user reset-failed ollama.service 2>/dev/null || true
echo "  -> Removed ${SYSTEMD_DIR}/ollama.service"

echo "Removing config directory..."
if [ -d "${CONFIG_DIR}" ]; then
    rm -rf "${CONFIG_DIR}"
    echo "  -> Removed ${CONFIG_DIR}"
else
    echo "  -> Config dir already removed"
fi

echo "Refreshing KDE service menu cache..."
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 &>/dev/null || true
elif command -v kbuildsycoca5 &>/dev/null; then
    kbuildsycoca5 &>/dev/null || true
fi

echo ""
echo "=== Uninstall complete! ==="
echo "The 'Open AI Assistant Here' context menu and configuration have been removed."
echo "Ollama itself was not removed — only the auto-start service was disabled."