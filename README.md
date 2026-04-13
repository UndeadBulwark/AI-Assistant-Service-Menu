# AI Assistant Service Menu

KDE Dolphin context menu that lets you right-click any folder and open an AI assistant (opencode) in that directory. Includes a native KDE System Settings module (KCM) for configuration, Ollama auto-start, and terminal-agnostic launcher.

**Terminal-agnostic** — automatically detects your terminal emulator (Konsole, GNOME Terminal, Alacritty, Kitty, foot, WezTerm, Tilix, xfce4-terminal, xterm, and more).

## What it does

Right-click any folder in Dolphin to get two actions:

- **Open AI Assistant Here** — open a terminal and launch [opencode](https://github.com/anomalyco/opencode) in that directory
- **Configure AI Assistant** — native KDE config panel (or shell fallback) to change model, launch mode, and flags

Additional features:
- Auto-detects your terminal emulator — works on KDE, GNOME, or any desktop
- **Native KDE System Settings module** (KCM) for configuration — single window, no cascading popups
- Falls back to shell-based config if KCM isn't built
- Auto-starts Ollama as a systemd user service (if installed)
- Distro-agnostic — no hardcoded paths, works on any Linux
- **Immutable-distro friendly** — installs to `~/.local`, no `sudo` needed

## Requirements

- KDE Plasma (Dolphin file manager)
- A terminal emulator (auto-detected)
- [opencode](https://github.com/anomalyco/opencode) installed and in PATH
- [Ollama](https://ollama.com) (optional — for local LLM support)

### KCM build dependencies (optional — for native KDE config panel)

- cmake
- ninja-build
- extra-cmake-modules
- qt6-qtbase-devel
- kf6-kcmutils-devel

Install on Fedora/Nobara/Bazzite:
```bash
sudo dnf install cmake ninja-build extra-cmake-modules qt6-qtbase-devel kf6-kcmutils-devel
```

## Install

```bash
git clone https://github.com/UndeadBulwark/AI-Assistant-Service-Menu.git
cd AI-Assistant-Service-Menu
./install.sh
```

If KCM build deps are installed, `install.sh` will compile the native KDE config module automatically. Otherwise, it falls back to the shell-based config menu.

After installation, right-click any folder in Dolphin to see the actions.

## Uninstall

```bash
cd AI-Assistant-Service-Menu
./uninstall.sh
```

Removes the context menu entries, launch scripts, KCM plugin, config, and Ollama systemd service. Ollama itself is not removed.

## Configuration

Settings are stored in `~/.config/ai-assistant-menu/config.conf` and can be edited via the KCM, the shell config, or manually.

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

### Native KCM (KDE System Settings)

If built, the config panel appears in:
- **System Settings → Applications → AI Assistant**
- Standalone: `QT_PLUGIN_PATH=~/.local/lib/qt6/plugins kcmshell6 kcm_ai_assistant`
- Dolphin right-click → Configure AI Assistant

Features:
- Flat model dropdown (cloud, popular local, coding local — all in one list)
- "Custom..." option for typing any model name
- "Detect Installed Ollama Models" button
- Launch mode radio buttons
- Extra flags text entry
- Apply / Reset / Default buttons

### Env var override

The `OPENCODE_MODEL` env var overrides the config file model if set.

## Files

| File | Installed to |
|------|-------------|
| `terminal-launch.sh` | `~/.local/bin/terminal-launch.sh` |
| `opencode-launch.sh` | `~/.local/bin/opencode-launch.sh` |
| `config.sh` | `~/.local/bin/ai-config.sh` |
| `kcm-launch.sh` | `~/.local/bin/kcm-launch.sh` |
| `opencode-context.desktop` | `~/.local/share/kio/servicemenus/opencode-context.desktop` |
| `icons/lambda-ai.svg` | `~/.local/share/icons/hicolor/scalable/apps/lambda-ai.svg` |
| `ollama.service` | `~/.config/systemd/user/ollama.service` |
| (built) `kcm_ai_assistant.so` | `~/.local/lib/qt6/plugins/plasma/kcms/systemsettings/` |
| (auto-created) | `~/.config/ai-assistant-menu/config.conf` |
| (auto-created) | `~/.config/environment.d/ai-assistant.conf` |

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