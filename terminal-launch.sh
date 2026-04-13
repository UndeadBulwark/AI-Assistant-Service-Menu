#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${1:-$HOME}"

find_terminal() {
    local terminals=(
        "konsole"
        "org.gnome.Terminal"
        "gnome-terminal"
        "alacritty"
        "kitty"
        "foot"
        "wezterm"
        "tilix"
        "xfce4-terminal"
        "mate-terminal"
        "lxterminal"
        "sakura"
        "st"
        "xterm"
    )

    for term in "${terminals[@]}"; do
        if command -v "${term}" &>/dev/null; then
            echo "${term}"
            return 0
        fi
    done

    local term_path
    if term_path="$(xdg-terminal 2>/dev/null)"; then
        [ -n "${term_path}" ] && echo "${term_path}" && return 0
    fi

    return 1
}

TERMINAL="$(find_terminal)" || {
    echo "Error: no terminal emulator found." >&2
    echo "Install one of: konsole, gnome-terminal, alacritty, kitty, foot, wezterm, tilix, xfce4-terminal, xterm" >&2
    read -r -p "Press Enter to exit..."
    exit 1
}

case "${TERMINAL}" in
    konsole)
        exec konsole --workdir "${WORKDIR}" -e "$HOME/.local/bin/opencode-launch.sh"
        ;;
    org.gnome.Terminal|gnome-terminal)
        exec gnome-terminal --working-directory="${WORKDIR}" -- "$HOME/.local/bin/opencode-launch.sh"
        ;;
    alacritty)
        exec alacritty --working-directory "${WORKDIR}" -e "$HOME/.local/bin/opencode-launch.sh"
        ;;
    kitty)
        exec kitty --directory "${WORKDIR}" "$HOME/.local/bin/opencode-launch.sh"
        ;;
    foot)
        exec foot --directory="${WORKDIR}" "$HOME/.local/bin/opencode-launch.sh"
        ;;
    wezterm)
        exec wezterm start --cwd "${WORKDIR}" -- "$HOME/.local/bin/opencode-launch.sh"
        ;;
    tilix)
        exec tilix --working-directory="${WORKDIR}" -e "$HOME/.local/bin/opencode-launch.sh"
        ;;
    xfce4-terminal)
        exec xfce4-terminal --working-directory="${WORKDIR}" -x "$HOME/.local/bin/opencode-launch.sh"
        ;;
    mate-terminal)
        exec mate-terminal --working-directory="${WORKDIR}" -x "$HOME/.local/bin/opencode-launch.sh"
        ;;
    lxterminal)
        exec lxterminal --working-directory="${WORKDIR}" -e "$HOME/.local/bin/opencode-launch.sh"
        ;;
    sakura)
        exec sakura --working-directory="${WORKDIR}" -x "$HOME/.local/bin/opencode-launch.sh"
        ;;
    st)
        exec st -d "${WORKDIR}" -e "$HOME/.local/bin/opencode-launch.sh"
        ;;
    xterm)
        exec xterm -e "cd '${WORKDIR}' && '$HOME/.local/bin/opencode-launch.sh'"
        ;;
    *)
        if [ -x "${TERMINAL}" ]; then
            exec "${TERMINAL}" -e "cd '${WORKDIR}' && '$HOME/.local/bin/opencode-launch.sh'"
        fi
        echo "Error: unknown terminal '${TERMINAL}'" >&2
        exit 1
        ;;
esac