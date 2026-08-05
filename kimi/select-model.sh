#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    KIMI • MODEL SELECTOR                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo
echo "  [1] K3   stronger family"
echo "  [2] K2.7 leaner"
echo
echo "  [q] Quit"
echo
read -r -p "Choose family [1-2]: " choice

case "$choice" in
  1) LAUNCHER="start-kimi-k-3.sh" ;;
  2) LAUNCHER="start-kimi-k-2-7.sh" ;;
  q|Q) exit 0 ;;
  *)
    echo "❌ Invalid choice. Choose 1, 2, or q." >&2
    exit 1
    ;;
esac

exec "$SCRIPT_DIR/$LAUNCHER" "$@"
