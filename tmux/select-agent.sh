#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  CODING    AGENT    SELECTOR                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo
echo "  [1] Claude Family"
echo "  [2] Codex Family  [default: GPT-6 Sol, medium]"
echo "  [3] Kimi  Family"
echo "  [4] Gemini  Family"
echo
echo "  [q] Quit"
echo
read -r -p "Choose agent [1-4, Enter=Codex]: " choice

case "$choice" in
  1)
    echo "▶ Starting Claude Family ..."
    exec "$REPO_ROOT/claude/select-model.sh"
    ;;
  ""|2)
    echo "▶ Starting Codex Family ..."
    exec "$REPO_ROOT/codex/select-model.sh"
    ;;
  3)
    echo "▶ Starting Kimi Family ..."
    exec "$REPO_ROOT/kimi/select-model.sh"
    ;;
  4)
    echo "▶ Starting Gemini (Antigravity, native)..."
    exec agy
    ;;
  q|Q)
    exit 0
    ;;
  *)
    echo "❌ Invalid Agent Family. Choose 1-4, or q to quit." >&2
    exit 1
    ;;
esac
