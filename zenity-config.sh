#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ai-assistant-menu"
CONFIG_FILE="${CONFIG_DIR}/config.conf"

mkdir -p "${CONFIG_DIR}"

if [ ! -f "${CONFIG_FILE}" ]; then
    cat > "${CONFIG_FILE}" << 'DEFAULTS'
# AI Assistant Service Menu configuration
# Edited via zenity-config.sh or manually

# Model to use (e.g. "glm-5.1:cloud", "llama3.1:8b", "codellama:13b")
MODEL=glm-5.1:cloud

# Extra flags passed to opencode (e.g. "--no-stream", "--debug")
EXTRA_FLAGS=

# Launch mode: "model" = opencode --model <MODEL>, "raw" = opencode <EXTRA_FLAGS>, "default" = opencode with no flags
LAUNCH_MODE=model
DEFAULTS
fi

source "${CONFIG_FILE}"

show_main_menu() {
    local current_info
    current_info="Current settings:\n"
    current_info+="  Model: ${MODEL}\n"
    current_info+="  Launch mode: ${LAUNCH_MODE}\n"
    current_info+="  Extra flags: ${EXTRA_FLAGS:-none}"

    local choice
    choice=$(zenity --list --title="AI Assistant — Configuration" \
        --width=450 --height=320 \
        --text="${current_info}" \
        --column="Action" --column="Description" \
        "Change Model" "Pick a model (local or cloud)" \
        "Custom Model" "Enter any model name manually" \
        "Launch Mode" "How opencode is launched (model/raw/default)" \
        "Extra Flags" "Add custom flags to opencode" \
        "View Config" "Open config file in editor" \
        "Reset" "Reset all settings to defaults" \
        2>/dev/null) || exit 0

    echo "${choice}"
}

pick_model_category() {
    zenity --list --title="Pick Model Category" \
        --width=350 --height=300 \
        --column="Category" --column="Description" \
        "Cloud" "Remote cloud models (OpenAI, Anthropic, etc.)" \
        "Ollama Popular" "Popular local Ollama models" \
        "Ollama Coding" "Code-focused Ollama models" \
        "Ollama All" "All locally installed Ollama models" \
        2>/dev/null || echo "__CANCEL__"
}

pick_cloud_model() {
    zenity --list --title="Cloud Models" \
        --width=400 --height=350 \
        --column="Model" --column="Provider" \
        "glm-5.1:cloud" "GLM (default)" \
        "gpt-4o" "OpenAI" \
        "gpt-4o-mini" "OpenAI" \
        "o1" "OpenAI" \
        "o3-mini" "OpenAI" \
        "claude-sonnet-4-20250514" "Anthropic" \
        "claude-haiku-4-20250514" "Anthropic" \
        "gemini-2.5-pro" "Google" \
        "gemini-2.5-flash" "Google" \
        "deepseek-chat" "DeepSeek" \
        "deepseek-reasoner" "DeepSeek" \
        2>/dev/null || echo "__CANCEL__"
}

pick_ollama_popular() {
    zenity --list --title="Popular Ollama Models" \
        --width=400 --height=380 \
        --column="Model" --column="Size" \
        "llama3.1:8b" "~4.7 GB" \
        "llama3.1:70b" "~40 GB" \
        "llama3.2:3b" "~2.0 GB" \
        "llama3.3:70b" "~40 GB" \
        "mistral:7b" "~4.1 GB" \
        "mistral-nemo:12b" "~7.2 GB" \
        "phi3:mini" "~2.3 GB" \
        "gemma2:9b" "~5.4 GB" \
        "qwen2.5:7b" "~4.4 GB" \
        "codestral:22b" "~12 GB" \
        2>/dev/null || echo "__CANCEL__"
}

pick_ollama_coding() {
    zenity --list --title="Coding Ollama Models" \
        --width=400 --height=320 \
        --column="Model" --column="Focus" \
        "codellama:13b" "General code" \
        "codellama:34b" "General code (large)" \
        "deepseek-coder-v2:16b" "DeepSeek code" \
        "starcoder2:7b" "StarCoder2" \
        "qwen2.5-coder:7b" "Qwen code" \
        "qwen2.5-coder:32b" "Qwen code (large)" \
        "codegemma:7b" "Gemma code" \
        2>/dev/null || echo "__CANCEL__"
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
        zenity --error --title="No Models Found" \
            --text="No Ollama models found. Is Ollama running?\n\nInstall models with: ollama pull <model>" \
            2>/dev/null
        echo "__CANCEL__"
        return
    fi

    local items=()
    while IFS= read -r model; do
        items+=("${model}" "${model}")
    done <<< "${models}"

    zenity --list --title="Installed Ollama Models" \
        --width=400 --height=350 \
        --column="Model" --column="Model" \
        "${items[@]}" \
        2>/dev/null || echo "__CANCEL__"
}

pick_launch_mode() {
    zenity --list --title="Launch Mode" \
        --width=450 --height=280 \
        --text="How should opencode be launched?" \
        --column="Mode" --column="Description" \
        "model" "opencode --model <MODEL> (default)" \
        "raw" "opencode <EXTRA_FLAGS> (full custom)" \
        "default" "opencode (no flags, uses opencode defaults)" \
        2>/dev/null || echo "__CANCEL__"
}

enter_custom_model() {
    zenity --entry --title="Custom Model" \
        --text="Enter model name (e.g. glm-5.1:cloud, llama3.1:8b):" \
        --entry-text="${MODEL}" \
        2>/dev/null || echo "__CANCEL__"
}

enter_extra_flags() {
    zenity --entry --title="Extra Flags" \
        --text="Extra flags passed to opencode (e.g. --no-stream --debug):" \
        --entry-text="${EXTRA_FLAGS}" \
        2>/dev/null || echo "__CANCEL__"
}

save_config() {
    local model="${1}"
    local launch_mode="${2}"
    local extra_flags="${3}"

    cat > "${CONFIG_FILE}" << EOF
# AI Assistant Service Menu configuration
# Edited via zenity-config.sh or manually

# Model to use (e.g. "glm-5.1:cloud", "llama3.1:8b", "codellama:13b")
MODEL=${model}

# Extra flags passed to opencode (e.g. "--no-stream", "--debug")
EXTRA_FLAGS=${extra_flags}

# Launch mode: "model" = opencode --model <MODEL>, "raw" = opencode <EXTRA_FLAGS>, "default" = opencode with no flags
LAUNCH_MODE=${launch_mode}
EOF

    zenity --info --title="Saved" \
        --text="Configuration saved:\n\n  Model: ${model}\n  Launch mode: ${launch_mode}\n  Extra flags: ${extra_flags:-none}" \
        2>/dev/null
}

while true; do
    ACTION="$(show_main_menu)"

    case "${ACTION}" in
        "Change Model")
            CATEGORY="$(pick_model_category)"
            case "${CATEGORY}" in
                Cloud)        NEW_MODEL="$(pick_cloud_model)" ;;
                "Ollama Popular") NEW_MODEL="$(pick_ollama_popular)" ;;
                "Ollama Coding")  NEW_MODEL="$(pick_ollama_coding)" ;;
                "Ollama All")     NEW_MODEL="$(pick_ollama_installed)" ;;
                *)               continue ;;
            esac
            [ "${NEW_MODEL}" = "__CANCEL__" ] && continue
            save_config "${NEW_MODEL}" "${LAUNCH_MODE}" "${EXTRA_FLAGS}"
            source "${CONFIG_FILE}"
            ;;
        "Custom Model")
            NEW_MODEL="$(enter_custom_model)"
            [ "${NEW_MODEL}" = "__CANCEL__" ] && continue
            save_config "${NEW_MODEL}" "${LAUNCH_MODE}" "${EXTRA_FLAGS}"
            source "${CONFIG_FILE}"
            ;;
        "Launch Mode")
            NEW_MODE="$(pick_launch_mode)"
            [ "${NEW_MODE}" = "__CANCEL__" ] && continue
            save_config "${MODEL}" "${NEW_MODE}" "${EXTRA_FLAGS}"
            source "${CONFIG_FILE}"
            ;;
        "Extra Flags")
            NEW_FLAGS="$(enter_extra_flags)"
            [ "${NEW_FLAGS}" = "__CANCEL__" ] && continue
            save_config "${MODEL}" "${LAUNCH_MODE}" "${NEW_FLAGS}"
            source "${CONFIG_FILE}"
            ;;
        "View Config")
            if command -v xdg-open &>/dev/null; then
                xdg-open "${CONFIG_FILE}" 2>/dev/null || true
            elif command -v kate &>/dev/null; then
                kate "${CONFIG_FILE}" &>/dev/null &
            elif command -v nano &>/dev/null; then
                konsole -e nano "${CONFIG_FILE}" 2>/dev/null || \
                xterm -e nano "${CONFIG_FILE}" 2>/dev/null || true
            fi
            source "${CONFIG_FILE}"
            ;;
        "Reset")
            zenity --question --title="Reset" \
                --text="Reset all settings to defaults?" \
                2>/dev/null || continue
            rm -f "${CONFIG_FILE}"
            cat > "${CONFIG_FILE}" << 'DEFAULTS'
# AI Assistant Service Menu configuration
# Edited via zenity-config.sh or manually

# Model to use (e.g. "glm-5.1:cloud", "llama3.1:8b", "codellama:13b")
MODEL=glm-5.1:cloud

# Extra flags passed to opencode (e.g. "--no-stream", "--debug")
EXTRA_FLAGS=

# Launch mode: "model" = opencode --model <MODEL>, "raw" = opencode <EXTRA_FLAGS>, "default" = opencode with no flags
LAUNCH_MODE=model
DEFAULTS
            source "${CONFIG_FILE}"
            zenity --info --title="Reset" --text="Settings reset to defaults." 2>/dev/null
            ;;
        "")
            exit 0
            ;;
    esac
done