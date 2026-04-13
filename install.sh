#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="${HOME}/.local/bin"
SERVICE_MENU_DIR="${HOME}/.local/share/kio/servicemenus"
SYSTEMD_DIR="${HOME}/.config/systemd/user"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ai-assistant-menu"
ICON_DIR="${HOME}/.local/share/icons/hicolor/scalable/apps"
PLUGIN_DIR="${HOME}/.local/lib/qt6/plugins/plasma/kcms/systemsettings"
ENV_DIR="${HOME}/.config/environment.d"

echo "=== AI Assistant Service Menu Installer ==="
echo ""

check_build_deps() {
    local missing=()
    command -v cmake &>/dev/null || missing+=("cmake")
    command -v ninja &>/dev/null || missing+=("ninja-build")
    [ -f /usr/share/ECM/cmake/ECMConfig.cmake ] || missing+=("extra-cmake-modules")
    pkg-config --exists Qt6Widgets 2>/dev/null || missing+=("qt6-qtbase-devel")
    pkg-config --exists Qt6Network 2>/dev/null || missing+=("qt6-qtbase-devel")
    [ -f /usr/lib64/cmake/KF6KCMUtils/KCMUtilsConfig.cmake ] || missing+=("kf6-kcmutils-devel")
    [ -f /usr/lib64/cmake/KF6ConfigWidgets/KF6ConfigWidgetsConfig.cmake ] || missing+=("kf6-kcmutils-devel")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing build dependencies for KCM plugin:"
        for dep in "${missing[@]}"; do
            echo "  - ${dep}"
        done
        echo ""
        echo "Install with:"
        echo "  sudo dnf install ${missing[*]}"
        echo ""
        return 1
    fi
    return 0
}

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

KCM_BUILT=false
echo ""

if [ -f "${PLUGIN_DIR}/kcm_ai_assistant.so" ]; then
    echo "KCM plugin already installed at ${PLUGIN_DIR}/kcm_ai_assistant.so"
    KCM_BUILT=true
elif check_build_deps; then
    echo "Build deps satisfied. Building KCM plugin..."
    echo ""

    cmake -B "${SCRIPT_DIR}/build" -G Ninja \
        -S "${SCRIPT_DIR}/kcm" \
        -DCMAKE_INSTALL_PREFIX="${HOME}/.local" \
        -DCMAKE_BUILD_TYPE=Release && \
    cmake --build "${SCRIPT_DIR}/build"

    if [ $? -eq 0 ]; then
        mkdir -p "${PLUGIN_DIR}"
        cp "${SCRIPT_DIR}/build/bin/plasma/kcms/systemsettings/kcm_ai_assistant.so" "${PLUGIN_DIR}/kcm_ai_assistant.so" 2>/dev/null || true

        if [ -f "${PLUGIN_DIR}/kcm_ai_assistant.so" ]; then
            echo "  -> ${PLUGIN_DIR}/kcm_ai_assistant.so"
            KCM_BUILT=true

            if [ -f "${SCRIPT_DIR}/build/kcm_ai_assistant.desktop" ]; then
                mkdir -p "${HOME}/.local/share/applications"
                cp "${SCRIPT_DIR}/build/kcm_ai_assistant.desktop" "${HOME}/.local/share/applications/kcm_ai_assistant.desktop"
                echo "  -> ${HOME}/.local/share/applications/kcm_ai_assistant.desktop"
            fi
        else
            echo "Warning: KCM .so not found in build output. Falling back to shell config."
        fi
    else
        echo "Warning: KCM build failed. Falling back to shell config."
    fi
else
    echo "Skipping KCM build (missing deps). Shell config will be used instead."
    echo "Install deps and re-run to build the native KDE config panel."
fi

echo ""
echo "Setting up QT_PLUGIN_PATH..."
mkdir -p "${ENV_DIR}"
ENV_FILE="${ENV_DIR}/ai-assistant.conf"
if [ ! -f "${ENV_FILE}" ]; then
    echo "QT_PLUGIN_PATH=${HOME}/.local/lib/qt6/plugins:\${QT_PLUGIN_PATH}" > "${ENV_FILE}"
    echo "  -> Created ${ENV_FILE}"
else
    if ! grep -q "ai-assistant" "${ENV_FILE}" 2>/dev/null; then
        echo "QT_PLUGIN_PATH=${HOME}/.local/lib/qt6/plugins:\${QT_PLUGIN_PATH}" >> "${ENV_FILE}"
        echo "  -> Updated ${ENV_FILE}"
    else
        echo "  -> ${ENV_FILE} already configured"
    fi
fi

echo ""
echo "Installing launch scripts..."
mkdir -p "${INSTALL_DIR}"
cp "${SCRIPT_DIR}/opencode-launch.sh" "${INSTALL_DIR}/opencode-launch.sh"
chmod +x "${INSTALL_DIR}/opencode-launch.sh"
echo "  -> ${INSTALL_DIR}/opencode-launch.sh"
cp "${SCRIPT_DIR}/terminal-launch.sh" "${INSTALL_DIR}/terminal-launch.sh"
chmod +x "${INSTALL_DIR}/terminal-launch.sh"
echo "  -> ${INSTALL_DIR}/terminal-launch.sh"
cp "${SCRIPT_DIR}/config.sh" "${INSTALL_DIR}/ai-config.sh"
chmod +x "${INSTALL_DIR}/ai-config.sh"
echo "  -> ${INSTALL_DIR}/ai-config.sh"
cp "${SCRIPT_DIR}/kcm-launch.sh" "${INSTALL_DIR}/kcm-launch.sh"
chmod +x "${INSTALL_DIR}/kcm-launch.sh"
echo "  -> ${INSTALL_DIR}/kcm-launch.sh"

echo "Installing config directory..."
mkdir -p "${CONFIG_DIR}"
if [ ! -f "${CONFIG_DIR}/config.conf" ]; then
    cat > "${CONFIG_DIR}/config.conf" << 'DEFAULTS'
# AI Assistant Service Menu configuration
# Edited via KCM or manually

# Model to use (e.g. "glm-5.1:cloud", "llama3.1:8b")
MODEL=glm-5.1:cloud

# Model source: "cloud" or "local"
MODEL_SOURCE=cloud

# Extra flags passed to opencode (e.g. "--no-stream", "--debug")
EXTRA_FLAGS=

# Launch mode: "model" = opencode --model <MODEL>, "raw" = opencode <EXTRA_FLAGS>, "default" = opencode with no flags
LAUNCH_MODE=model

# System prompt: custom instructions for opencode sessions (edit via system-prompt.md)
# See ~/.config/ai-assistant-menu/system-prompt.md
DEFAULTS
    echo "  -> ${CONFIG_DIR}/config.conf (created with defaults)"
else
    echo "  -> ${CONFIG_DIR}/config.conf (already exists, kept)"
fi

echo "Installing lambda icon..."
mkdir -p "${ICON_DIR}"
cp "${SCRIPT_DIR}/icons/lambda-ai.svg" "${ICON_DIR}/lambda-ai.svg"
echo "  -> ${ICON_DIR}/lambda-ai.svg"

if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f "${HOME}/.local/share/icons/hicolor" &>/dev/null || true
fi

echo "Installing KDE service menu..."
mkdir -p "${SERVICE_MENU_DIR}"

if [ "${INSTALL_OLLAMA_SERVICE}" = true ]; then
    mkdir -p "${HOME}/.local/bin"
    if [ "${OLLAMA_BIN}" != "${HOME}/.local/bin/ollama" ]; then
        ln -sf "${OLLAMA_BIN}" "${HOME}/.local/bin/ollama"
    fi
fi

sed "s|%h|${HOME}|g" \
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
echo "Right-click any folder in Dolphin:"
echo "  'Open AI Assistant Here'  — launch opencode in that directory"
echo "  'Configure AI Assistant' — change model, launch mode, flags"
echo ""
if [ "${KCM_BUILT}" = true ]; then
    echo "Config UI: Native KDE module (kcmshell6 kcm_ai_assistant)"
    echo "Also available in System Settings under Applications"
else
    echo "Config UI: Shell fallback (ai-config.sh)"
    echo "Install build deps and re-run for native KDE config panel"
fi
echo ""
if [ "${INSTALL_OLLAMA_SERVICE}" = true ]; then
    echo "Ollama will auto-start on login."
    echo "Manage with: systemctl --user start/stop/status ollama.service"
else
    echo "Note: Install Ollama from https://ollama.com for LLM support."
fi