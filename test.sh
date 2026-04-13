#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=0

check_file() {
    if [ -f "${SCRIPT_DIR}/$1" ]; then
        echo "  [OK] $1"
    else
        echo "  [MISSING] $1"
        ERRORS=$((ERRORS + 1))
    fi
}

check_executable() {
    if [ -f "${SCRIPT_DIR}/$1" ] && bash -n "${SCRIPT_DIR}/$1" 2>/dev/null; then
        echo "  [OK] $1 (valid bash)"
    else
        echo "  [FAIL] $1 (syntax error or missing)"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "=== AI Assistant Service Menu — Self-Test ==="
echo ""
echo "Checking files..."
check_file "opencode-context.desktop"
check_file "ollama.service"
check_file "LICENSE"
check_file "README.md"
echo ""
echo "Checking scripts..."
check_executable "terminal-launch.sh"
check_executable "opencode-launch.sh"
check_executable "install.sh"
check_executable "uninstall.sh"
echo ""

if [ "${ERRORS}" -eq 0 ]; then
    echo "All checks passed!"
    exit 0
else
    echo "${ERRORS} check(s) failed!"
    exit 1
fi