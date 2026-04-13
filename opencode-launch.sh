#!/usr/bin/env bash
set -euo pipefail

OLLAMA_URL="http://localhost:11434"

if ! curl -sf "${OLLAMA_URL}/api/tags" > /dev/null 2>&1; then
    systemctl --user start ollama.service 2>/dev/null || true
    for i in {1..15}; do
        if curl -sf "${OLLAMA_URL}/api/tags" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
fi

find_opencode() {
    local candidates=(
        "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/bin/opencode"
        "${HOME}/.local/bin/opencode"
        "${XDG_DATA_HOME:-$HOME/.local/share}/opencode/bin/opencode"
    )

    if [ -n "${NVM_DIR:-}" ]; then
        local nvm_opencode
        nvm_opencode="$(find "${NVM_DIR}/versions/node" -name opencode -path '*/bin/opencode' 2>/dev/null | head -1 || true)"
        [ -n "${nvm_opencode}" ] && candidates+=("${nvm_opencode}")
    fi

    local path_opencode
    path_opencode="$(command -v opencode 2>/dev/null || true)"
    [ -n "${path_opencode}" ] && candidates+=("${path_opencode}")

    for candidate in "${candidates[@]}"; do
        if [ -x "${candidate}" ]; then
            echo "${candidate}"
            return 0
        fi
    done

    return 1
}

OPENCODE="$(find_opencode)" || {
    echo "Error: opencode not found. Install it first:" >&2
    echo "  https://github.com/anomalyco/opencode" >&2
    read -r -p "Press Enter to exit..."
    exit 1
}

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ai-assistant-menu"
CONFIG_FILE="${CONFIG_DIR}/config.conf"

MODEL="${OPENCODE_MODEL:-glm-5.1:cloud}"
EXTRA_FLAGS=""
LAUNCH_MODE="model"

if [ -f "${CONFIG_FILE}" ]; then
    source "${CONFIG_FILE}"
fi

PROMPT_FILE="${CONFIG_DIR}/system-prompt.md"
if [ -f "${PROMPT_FILE}" ] && [ -s "${PROMPT_FILE}" ]; then
    export OPENCODE_CONFIG_CONTENT="{\"instructions\":[\"${PROMPT_FILE}\"]}"
fi

if [ $# -gt 0 ]; then
    exec "${OPENCODE}" "$@"
fi

case "${LAUNCH_MODE}" in
    model)
        exec "${OPENCODE}" --model "${MODEL}" ${EXTRA_FLAGS}
        ;;
    raw)
        exec "${OPENCODE}" ${EXTRA_FLAGS}
        ;;
    default)
        exec "${OPENCODE}"
        ;;
    *)
        exec "${OPENCODE}" --model "${MODEL}"
        ;;
esac