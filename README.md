# AI Assistant Service Menu

KDE Dolphin context menu that lets you right-click any folder and open an AI assistant (opencode) in that directory. Includes Ollama auto-start via systemd.

**Terminal-agnostic** — automatically detects your terminal emulator (Konsole, GNOME Terminal, Alacritty, Kitty, foot, WezTerm, Tilix, xfce4-terminal, xterm, and more).

## What it does

- Adds **"Open AI Assistant Here"** to the KDE Dolphin right-click menu for folders
- Opens your terminal in the selected directory and launches [opencode](https://github.com/anomalyco/opencode)
- Auto-detects your terminal emulator — works on KDE, GNOME, or any desktop
- Auto-starts Ollama as a systemd user service (if installed)
- Falls back to on-demand Ollama start if the service isn't running
- Distro-agnostic — no hardcoded paths, works on any Linux

## Requirements

- KDE Plasma (Dolphin file manager)
- A terminal emulator (auto-detected)
- [opencode](https://github.com/anomalyco/opencode) installed and in PATH
- [Ollama](https://ollama.com) (optional — for local LLM support)

## Install

```bash
git clone https://github.com/UndeadBulwark/AI-Assistant-Service-Menu.git
cd AI-Assistant-Service-Menu
./install.sh
```

After installation, right-click any folder in Dolphin → **"Open AI Assistant Here"**.

## Uninstall

```bash
cd AI-Assistant-Service-Menu
./uninstall.sh
```

Removes the context menu entry, launch scripts, and Ollama systemd service. Ollama itself is not removed.

## Files

| File | Installed to |
|------|-------------|
| `terminal-launch.sh` | `~/.local/bin/terminal-launch.sh` |
| `opencode-launch.sh` | `~/.local/bin/opencode-launch.sh` |
| `opencode-context.desktop` | `~/.local/share/kio/servicemenus/opencode-context.desktop` |
| `ollama.service` | `~/.config/systemd/user/ollama.service` |

## How it works

### Terminal detection

`terminal-launch.sh` searches for a terminal emulator in this order:

1. konsole (KDE)
2. gnome-terminal (GNOME)
3. alacritty
4. kitty
5. foot (Wayland)
6. wezterm
7. tilix
8. xfce4-terminal
9. mate-terminal
10. lxterminal
11. sakura
12. st
13. xterm (fallback)

Each terminal has its own `--working-directory` and `-e` syntax handled correctly.

### opencode discovery

`opencode-launch.sh` searches for `opencode` in this order:

1. `~/.config/opencode/bin/opencode`
2. `~/.local/bin/opencode`
3. `~/.local/share/opencode/bin/opencode`
4. nvm node versions (`$NVM_DIR/versions/node/*/bin/opencode`)
5. Whatever `command -v opencode` returns

If Ollama isn't running, it tries to start it via systemd, then falls back to `ollama serve`.

### Default model

opencode is launched with `--model glm-5.1:cloud` by default. Override with the `OPENCODE_MODEL` env var:

```bash
export OPENCODE_MODEL="llama3.1:8b"
```

Or pass arguments directly — if you pass any args to the service menu, they replace the default model flag entirely.

## Self-test

```bash
./test.sh
```

Validates that all files exist and scripts have valid bash syntax.

## License

[GPL-3.0-or-later](LICENSE)