# AI Assistant Service Menu

KDE Dolphin context menu that lets you right-click any folder and open an AI assistant (opencode) in that directory. Includes Ollama auto-start via systemd.

## What it does

- Adds **"Open AI Assistant Here"** to the KDE Dolphin right-click menu for folders
- Opens Konsole in the selected directory and launches [opencode](https://github.com/anomalyco/opencode)
- Auto-starts Ollama as a systemd user service (if installed)
- Falls back to on-demand Ollama start if the service isn't running
- Distro-agnostic — no hardcoded paths, works on any Linux with KDE Plasma

## Requirements

- KDE Plasma (Dolphin file manager)
- [opencode](https://github.com/anomalyco/opencode) installed and in PATH
- Konsole (KDE terminal)
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

Removes the context menu entry, launch script, and Ollama systemd service. Ollama itself is not removed.

## Files

| File | Installed to |
|------|-------------|
| `opencode-launch.sh` | `~/.local/bin/opencode-launch.sh` |
| `opencode-context.desktop` | `~/.local/share/kio/servicemenus/opencode-context.desktop` |
| `ollama.service` | `~/.config/systemd/user/ollama.service` |

## How the launch script works

`opencode-launch.sh` searches for `opencode` in this order:

1. `~/.config/opencode/bin/opencode`
2. `~/.local/bin/opencode`
3. `~/.local/share/opencode/bin/opencode`
4. nvm node versions (`$NVM_DIR/versions/node/*/bin/opencode`)
5. Whatever `command -v opencode` returns

If Ollama isn't running, it tries to start it via systemd, then falls back to `ollama serve`.

## Self-test

```bash
./test.sh
```

Validates that all files exist and scripts have valid bash syntax.

## License

[GPL-3.0-or-later](LICENSE)