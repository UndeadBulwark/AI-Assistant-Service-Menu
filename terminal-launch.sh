#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${1:-$HOME}"
MODE="${2:-opencode}"

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

launch_terminal_only() {
    local term="${1}"
    local dir="${2}"
    case "${term}" in
        konsole)          exec konsole --workdir "${dir}" ;;
        org.gnome.Terminal|gnome-terminal) exec gnome-terminal --working-directory="${dir}" ;;
        alacritty)        exec alacritty --working-directory "${dir}" ;;
        kitty)            exec kitty --directory "${dir}" ;;
        foot)             exec foot --directory="${dir}" ;;
        wezterm)          exec wezterm start --cwd "${dir}" ;;
        tilix)            exec tilix --working-directory "${dir}" ;;
        xfce4-terminal)   exec xfce4-terminal --working-directory "${dir}" ;;
        mate-terminal)    exec mate-terminal --working-directory "${dir}" ;;
        lxterminal)       exec lxterminal --working-directory "${dir}" ;;
        sakura)           exec sakura --working-directory "${dir}" ;;
        st)               exec st -d "${dir}" ;;
        xterm)            exec xterm ;;
        *)                exec "${term}" ;;
    esac
}

launch_with_opencode() {
    local term="${1}"
    local dir="${2}"
    case "${term}" in
        konsole)
            exec konsole --workdir "${dir}" -e "$HOME/.local/bin/opencode-launch.sh"
            ;;
        org.gnome.Terminal|gnome-terminal)
            exec gnome-terminal --working-directory="${dir}" -- "$HOME/.local/bin/opencode-launch.sh"
            ;;
        alacritty)
            exec alacritty --working-directory "${dir}" -e "$HOME/.local/bin/opencode-launch.sh"
            ;;
        kitty)
            exec kitty --directory "${dir}" "$HOME/.local/bin/opencode-launch.sh"
            ;;
        foot)
            exec foot --directory="${dir}" "$HOME/.local/bin/opencode-launch.sh"
            ;;
        wezterm)
            exec wezterm start --cwd "${dir}" -- "$HOME/.local/bin/opencode-launch.sh"
            ;;
        tilix)
            exec tilix --working-directory "${dir}" -e "$HOME/.local/bin/opencode-launch.sh"
            ;;
        xfce4-terminal)
            exec xfce4-terminal --working-directory "${dir}" -x "$HOME/.local/bin/opencode-launch.sh"
            ;;
        mate-terminal)
            exec mate-terminal --working-directory="${dir}" -x "$HOME/.local/bin/opencode-launch.sh"
            ;;
        lxterminal)
            exec lxterminal --working-directory "${dir}" -e "$HOME/.local/bin/opencode-launch.sh"
            ;;
        sakura)
            exec sakura --working-directory "${dir}" -x "$HOME/.local/bin/opencode-launch.sh"
            ;;
        st)
            exec st -d "${dir}" -e "$HOME/.local/bin/opencode-launch.sh"
            ;;
        xterm)
            exec xterm -e "cd '${dir}' && '$HOME/.local/bin/opencode-launch.sh'"
            ;;
        *)
            if [ -x "${term}" ]; then
                exec "${term}" -e "cd '${dir}' && '$HOME/.local/bin/opencode-launch.sh'"
            fi
            echo "Error: unknown terminal '${term}'" >&2
            exit 1
            ;;
    esac
}

TERMINAL="$(find_terminal)" || {
    echo "Error: no terminal emulator found." >&2
    echo "Install one of: konsole, gnome-terminal, alacritty, kitty, foot, wezterm, tilix, xfce4-terminal, xterm" >&2
    read -r -p "Press Enter to exit..."
    exit 1
}

case "${MODE}" in
    terminal)
        launch_terminal_only "${TERMINAL}" "${WORKDIR}"
        ;;
    opencode)
        launch_with_opencode "${TERMINAL}" "${WORKDIR}"
        ;;
    *)
        launch_with_opencode "${TERMINAL}" "${WORKDIR}"
        ;;
esac