# AI Assistant Service Menu

KDE Dolphin context menu that lets you right-click any folder and open an AI assistant (opencode) or terminal in that directory. Includes Ollama auto-start and a Zenity GUI for configuration.

**Terminal-agnostic** — automatically detects your terminal emulator (Konsole, GNOME Terminal, Alacritty, Kitty, foot, WezTerm, Tilix, xfce4-terminal, xterm, and more).

## What it does

Right-click any folder in Dolphin to get three actions, in order:

1. **Open Terminal Here** — open a terminal in the selected directory
2. **Open AI Assistant Here** — open a terminal and launch [opencode](https://github.com/anomalyco/opencode) in that directory
3. **Configure AI Assistant** — Zenity GUI to switch models, launch modes, and flags

Additional features:
- Auto-detects your terminal emulator — works on KDE, GNOME, or any desktop
- Auto-starts Ollama as a systemd user service (if installed)
- Falls back to on-demand Ollama start if the service isn't running
- Distro-agnostic — no hardcoded paths, works on any Linux

## Requirements

- KDE Plasma (Dolphin file manager)
- A terminal emulator (auto-detected)
- [opencode](https://github.com/anomalyco/opencode) installed and in PATH
- [Ollama](https://ollama.com) (optional — for local LLM support)
- zenity (for the configuration GUI — installed by default on most GNOME/KDE distros)

## Install

```bash
git clone https://github.com/UndeadBulwark/AI-Assistant-Service-Menu.git
cd AI-Assistant-Service-Menu
./install.sh
```

After installation, right-click any folder in Dolphin to see the three actions.

## Uninstall

```bash
cd AI-Assistant-Service-Menu
./uninstall.sh
```

Removes the context menu entries, launch scripts, icon, config, and Ollama systemd service. Ollama itself is not removed.

## Configuration

Settings are stored in `~/.config/ai-assistant-menu/config.conf` and can be edited via the Zenity GUI or manually.

### Config file

```conf
# Model to use
MODEL=glm-5.1:cloud

# Extra flags passed to opencode
EXTRA_FLAGS=

# Launch mode: "model" | "raw" | "default"
LAUNCH_MODE=model
```

### Launch modes

| Mode | Command | Description |
|------|---------|-------------|
| `model` | `opencode --model <MODEL>` | Default — passes model flag |
| `raw` | `opencode <EXTRA_FLAGS>` | Full custom — only extra flags |
| `default` | `opencode` | No flags — uses opencode's own defaults |

### Model selection

The Zenity config GUI offers:

- **Cloud models** — glm-5.1:cloud, GPT-4o, Claude Sonnet 4, Gemini 2.5, DeepSeek
- **Popular local models** — Llama 3.x, Mistral, Phi-3, Gemma 2, Qwen 2.5
- **Coding local models** — CodeLlama, DeepSeek Coder, StarCoder2, Qwen Coder
- **Installed Ollama models** — auto-detects whatever you've pulled locally
- **Custom model** — type any model name

### Env var override

The `OPENCODE_MODEL` env var overrides the config file model if set.

## Icon

The **Open AI Assistant Here** action uses a lambda (λ) icon (`lambda-ai.svg`) — a Catppuccin Mocha-styled lambda symbol on a dark background.

## Files

| File | Installed to |
|------|-------------|
| `terminal-launch.sh` | `~/.local/bin/terminal-launch.sh` |
| `opencode-launch.sh` | `~/.local/bin/opencode-launch.sh` |
| `zenity-config.sh` | `~/.local/bin/zenity-config.sh` |
| `opencode-context.desktop` | `~/.local/share/kio/servicemenus/opencode-context.desktop` |
| `icons/lambda-ai.svg` | `~/.local/share/icons/hicolor/scalable/apps/lambda-ai.svg` |
| `ollama.service` | `~/.config/systemd/user/ollama.service` |
| (auto-created) | `~/.config/ai-assistant-menu/config.conf` |

## Terminal detection

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

## opencode discovery

`opencode-launch.sh` searches for `opencode` in this order:

1. `~/.config/opencode/bin/opencode`
2. `~/.local/bin/opencode`
3. `~/.local/share/opencode/bin/opencode`
4. nvm node versions (`$NVM_DIR/versions/node/*/bin/opencode`)
5. Whatever `command -v opencode` returns

## Self-test

```bash
./test.sh
```

Validates that all files exist and scripts have valid bash syntax.

## License

[GPL-3.0-or-later](LICENSE)