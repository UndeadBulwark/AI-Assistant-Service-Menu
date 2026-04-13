#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="${HOME}/.local/lib/qt6/plugins/plasma/kcms/systemsettings"

if [ -f "${PLUGIN_DIR}/kcm_ai_assistant.so" ] && command -v kcmshell6 &>/dev/null; then
    QT_PLUGIN_PATH="${HOME}/.local/lib/qt6/plugins:${QT_PLUGIN_PATH:-}" kcmshell6 kcm_ai_assistant
else
    exec "${HOME}/.local/bin/ai-config.sh"
fi