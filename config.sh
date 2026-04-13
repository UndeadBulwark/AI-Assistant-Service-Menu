#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ai-assistant-menu"
CONFIG_FILE="${CONFIG_DIR}/config.conf"

mkdir -p "${CONFIG_DIR}"

if [ ! -f "${CONFIG_FILE}" ]; then
    cat > "${CONFIG_FILE}" << 'DEFAULTS'
# AI Assistant Service Menu configuration
# Edited via config.sh or manually

# Model to use (e.g. "glm-5.1:cloud", "llama3.1:8b", "codellama:13b")
MODEL=glm-5.1:cloud

# Extra flags passed to opencode (e.g. "--no-stream", "--debug")
EXTRA_FLAGS=

# Launch mode: "model" = opencode --model <MODEL>, "raw" = opencode <EXTRA_FLAGS>, "default" = opencode with no flags
LAUNCH_MODE=model
DEFAULTS
fi

source "${CONFIG_FILE}"

if command -v kdialog &>/dev/null; then
    DIALOGBackend="kdialog"
elif command -v zenity &>/dev/null; then
    DIALOGBackend="zenity"
else
    echo "Error: kdialog or zenity required." >&2
    exit 1
fi

dialog_info() {
    local title="${1}" text="${2}"
    if [ "${DIALOGBackend}" = "kdialog" ]; then
        kdialog --title "${title}" --msgbox "${text}"
    else
        zenity --info --title "${title}" --text "${text}" 2>/dev/null
    fi
}

dialog_error() {
    local title="${1}" text="${2}"
    if [ "${DIALOGBackend}" = "kdialog" ]; then
        kdialog --title "${title}" --error "${text}"
    else
        zenity --error --title "${title}" --text "${text}" 2>/dev/null
    fi
}

dialog_yesno() {
    local title="${1}" text="${2}"
    if [ "${DIALOGBackend}" = "kdialog" ]; then
        kdialog --title "${title}" --yesno "${text}"
    else
        zenity --question --title "${title}" --text "${text}" 2>/dev/null
    fi
}

dialog_input() {
    local title="${1}" text="${2}" default="${3:-}"
    if [ "${DIALOGBackend}" = "kdialog" ]; then
        kdialog --title "${title}" --inputbox "${text}" "${default}" 2>/dev/null || echo "__CANCEL__"
    else
        zenity --entry --title "${title}" --text "${text}" --entry-text="${default}" 2>/dev/null || echo "__CANCEL__"
    fi
}

dialog_menu() {
    local title="${1}" text="${2}"
    shift 2
    if [ "${DIALOGBackend}" = "kdialog" ]; then
        kdialog --title "${title}" --menu "${text}" "$@"
    else
        local columns=()
        while [ $# -ge 2 ]; do
            columns+=("$1" "$2")
            shift 2
        done
        zenity --list --title "${title}" --width=450 --height=320 \
            --text "${text}" --column="Action" --column="Description" \
            "${columns[@]}" 2>/dev/null || echo "__CANCEL__"
    fi
}

dialog_radiolist() {
    local title="${1}" text="${2}"
    shift 2
    if [ "${DIALOGBackend}" = "kdialog" ]; then
        kdialog --title "${title}" --radiolist "${text}" "$@"
    else
        local columns=()
        local items=("$@")
        local i
        for (( i=0; i<${#items[@]}; i+=3 )); do
            local key="${items[$i]}"
            local desc="${items[$((i+1))]}"
            local on="${items[$((i+2))]}"
            if [ "${on}" = "on" ]; then
                columns+=("TRUE" "${key}" "${desc}")
            else
                columns+=("FALSE" "${key}" "${desc}")
            fi
        done
        zenity --list --title "${title}" --width=450 --height=300 \
            --text "${text}" --column="Select" --column="Mode" --column="Description" \
            --radiolist "${columns[@]}" 2>/dev/null || echo "__CANCEL__"
    fi
}

dialog_combolist() {
    local title="${1}" text="${2}"
    shift 2
    if [ "${DIALOGBackend}" = "kdialog" ]; then
        kdialog --title "${title}" --combobox "${text}" "$@"
    else
        local columns=()
        for item in "$@"; do
            columns+=("${item}" "${item}")
        done
        zenity --list --title "${title}" --width=400 --height=350 \
            --text "${text}" --column="Model" --column="Model" \
            "${columns[@]}" 2>/dev/null || echo "__CANCEL__"
    fi
}

show_main_menu() {
    local current="Current: Model=${MODEL}  Mode=${LAUNCH_MODE}  Flags=${EXTRA_FLAGS:-none}"
    dialog_menu "AI Assistant Configuration" "${current}" \
        "change-model" "Change Model (cloud or local)" \
        "custom-model" "Enter custom model name" \
        "launch-mode"  "Change launch mode" \
        "extra-flags" "Set extra opencode flags" \
        "view-config" "Open config file in editor" \
        "reset"       "Reset all settings to defaults"
}

pick_model_category() {
    dialog_menu "Pick Model Category" "Choose a model category:" \
        "cloud"          "Cloud models (OpenAI, Anthropic, Google...)" \
        "ollama-popular" "Popular local Ollama models" \
        "ollama-coding"  "Code-focused Ollama models" \
        "ollama-all"     "All locally installed Ollama models"
}

pick_cloud_model() {
    dialog_combolist "Cloud Models" "Select a cloud model:" \
        "glm-5.1:cloud" \
        "gpt-4o" \
        "gpt-4o-mini" \
        "o1" \
        "o3-mini" \
        "claude-sonnet-4-20250514" \
        "claude-haiku-4-20250514" \
        "gemini-2.5-pro" \
        "gemini-2.5-flash" \
        "deepseek-chat" \
        "deepseek-reasoner"
}

pick_ollama_popular() {
    dialog_combolist "Popular Ollama Models" "Select a model:" \
        "llama3.1:8b" \
        "llama3.1:70b" \
        "llama3.2:3b" \
        "llama3.3:70b" \
        "mistral:7b" \
        "mistral-nemo:12b" \
        "phi3:mini" \
        "gemma2:9b" \
        "qwen2.5:7b" \
        "codestral:22b"
}

pick_ollama_coding() {
    dialog_combolist "Coding Ollama Models" "Select a model:" \
        "codellama:13b" \
        "codellama:34b" \
        "deepseek-coder-v2:16b" \
        "starcoder2:7b" \
        "qwen2.5-coder:7b" \
        "qwen2.5-coder:32b" \
        "codegemma:7b"
}

pick_ollama_installed() {
    local models
    models=$(curl -sf http://localhost:11434/api/tags 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for m in data.get('models', []):
        print(m['name'])
except: pass
" 2>/dev/null) || true

    if [ -z "${models}" ]; then
        dialog_error "No Models Found" "No Ollama models found. Is Ollama running?\n\nInstall models with: ollama pull <model>"
        echo "__CANCEL__"
        return
    fi

    local items=()
    while IFS= read -r model; do
        items+=("${model}")
    done <<< "${models}"

    dialog_combolist "Installed Ollama Models" "Select an installed model:" "${items[@]}"
}

pick_launch_mode() {
    local model_on="off" raw_on="off" default_on="off"
    case "${LAUNCH_MODE}" in
        model)   model_on="on" ;;
        raw)     raw_on="on" ;;
        default) default_on="on" ;;
    esac

    dialog_radiolist "Launch Mode" "How should opencode be launched?" \
        "model"   "opencode --model <MODEL> (default)" "${model_on}" \
        "raw"     "opencode <EXTRA_FLAGS> (full custom)" "${raw_on}" \
        "default" "opencode (no flags, uses opencode defaults)" "${default_on}"
}

save_config() {
    local model="${1}"
    local launch_mode="${2}"
    local extra_flags="${3}"

    cat > "${CONFIG_FILE}" << EOF
# AI Assistant Service Menu configuration
# Edited via config.sh or manually

# Model to use (e.g. "glm-5.1:cloud", "llama3.1:8b", "codellama:13b")
MODEL=${model}

# Extra flags passed to opencode (e.g. "--no-stream", "--debug")
EXTRA_FLAGS=${extra_flags}

# Launch mode: "model" = opencode --model <MODEL>, "raw" = opencode <EXTRA_FLAGS>, "default" = opencode with no flags
LAUNCH_MODE=${launch_mode}
EOF

    dialog_info "Saved" "Configuration saved:\n\n  Model: ${model}\n  Launch mode: ${launch_mode}\n  Extra flags: ${extra_flags:-none}"
}

while true; do
    ACTION="$(show_main_menu)"

    case "${ACTION}" in
        "change-model"|__CANCEL__)
            [ "${ACTION}" = "__CANCEL__" ] && exit 0
            CATEGORY="$(pick_model_category)"
            case "${CATEGORY}" in
                cloud)          NEW_MODEL="$(pick_cloud_model)" ;;
                ollama-popular) NEW_MODEL="$(pick_ollama_popular)" ;;
                ollama-coding)  NEW_MODEL="$(pick_ollama_coding)" ;;
                ollama-all)     NEW_MODEL="$(pick_ollama_installed)" ;;
                *)              continue ;;
            esac
            [ "${NEW_MODEL}" = "__CANCEL__" ] && continue
            save_config "${NEW_MODEL}" "${LAUNCH_MODE}" "${EXTRA_FLAGS}"
            source "${CONFIG_FILE}"
            ;;
        "custom-model")
            NEW_MODEL="$(dialog_input "Custom Model" "Enter model name (e.g. glm-5.1:cloud, llama3.1:8b):" "${MODEL}")"
            [ "${NEW_MODEL}" = "__CANCEL__" ] && continue
            [ -z "${NEW_MODEL}" ] && continue
            save_config "${NEW_MODEL}" "${LAUNCH_MODE}" "${EXTRA_FLAGS}"
            source "${CONFIG_FILE}"
            ;;
        "launch-mode")
            NEW_MODE="$(pick_launch_mode)"
            [ "${NEW_MODE}" = "__CANCEL__" ] && continue
            [ -z "${NEW_MODE}" ] && continue
            save_config "${MODEL}" "${NEW_MODE}" "${EXTRA_FLAGS}"
            source "${CONFIG_FILE}"
            ;;
        "extra-flags")
            NEW_FLAGS="$(dialog_input "Extra Flags" "Extra flags passed to opencode (e.g. --no-stream --debug):" "${EXTRA_FLAGS}")"
            [ "${NEW_FLAGS}" = "__CANCEL__" ] && continue
            save_config "${MODEL}" "${LAUNCH_MODE}" "${NEW_FLAGS}"
            source "${CONFIG_FILE}"
            ;;
        "view-config")
            if command -v kate &>/dev/null; then
                kate "${CONFIG_FILE}" 2>/dev/null &
            elif command -v xdg-open &>/dev/null; then
                xdg-open "${CONFIG_FILE}" 2>/dev/null || true
            elif command -v nano &>/dev/null; then
                if command -v konsole &>/dev/null; then
                    konsole -e nano "${CONFIG_FILE}" 2>/dev/null &
                elif command -v xterm &>/dev/null; then
                    xterm -e nano "${CONFIG_FILE}" 2>/dev/null &
                fi
            fi
            source "${CONFIG_FILE}"
            ;;
        "reset")
            dialog_yesno "Reset" "Reset all settings to defaults?" || continue
            cat > "${CONFIG_FILE}" << 'DEFAULTS'
# AI Assistant Service Menu configuration
# Edited via config.sh or manually

# Model to use (e.g. "glm-5.1:cloud", "llama3.1:8b", "codellama:13b")
MODEL=glm-5.1:cloud

# Extra flags passed to opencode (e.g. "--no-stream", "--debug")
EXTRA_FLAGS=

# Launch mode: "model" = opencode --model <MODEL>, "raw" = opencode <EXTRA_FLAGS>, "default" = opencode with no flags
LAUNCH_MODE=model
DEFAULTS
            source "${CONFIG_FILE}"
            dialog_info "Reset" "Settings reset to defaults."
            ;;
        "")
            exit 0
            ;;
    esac
done