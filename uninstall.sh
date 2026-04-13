#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
SERVICE_MENU_DIR="${HOME}/.local/share/kio/servicemenus"
SYSTEMD_DIR="${HOME}/.config/systemd/user"

echo "=== AI Assistant Service Menu Uninstaller ==="
echo ""

echo "Removing launch script..."
rm -f "${INSTALL_DIR}/opencode-launch.sh"
echo "  -> Removed ${INSTALL_DIR}/opencode-launch.sh"

echo "Removing KDE service menu..."
rm -f "${SERVICE_MENU_DIR}/opencode-context.desktop"
echo "  -> Removed ${SERVICE_MENU_DIR}/opencode-context.desktop"

echo "Removing Ollama systemd user service..."
rm -f "${SYSTEMD_DIR}/ollama.service"
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user reset-failed ollama.service 2>/dev/null || true
echo "  -> Removed ${SYSTEMD_DIR}/ollama.service"

echo "Refreshing KDE service menu cache..."
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 &>/dev/null || true
elif command -v kbuildsycoca5 &>/dev/null; then
    kbuildsycoca5 &>/dev/null || true
fi

echo ""
echo "=== Uninstall complete! ==="
echo "The 'Open AI Assistant Here' context menu has been removed."
echo "Ollama itself was not removed — only the auto-start service was disabled."