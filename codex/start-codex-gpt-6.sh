#!/bin/bash
# OpenAI Codex on the GPT-6 family.
#   fast    -> gpt-6-luna  + low
#   default -> gpt-6-sol   + medium
#   deep    -> gpt-6-astra + high
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

require_codex

CODEX_PROFILE="${CODEX_PROFILE:-default}"
case "$CODEX_PROFILE" in
  fast)    MODEL="gpt-6-luna";  EFFORT="low" ;;
  default) MODEL="gpt-6-sol";   EFFORT="medium" ;;
  deep)    MODEL="gpt-6-astra"; EFFORT="high" ;;
  *)
    echo "❌ Invalid CODEX_PROFILE: $CODEX_PROFILE (use fast, default, or deep)." >&2
    exit 1
    ;;
esac
echo "⚙️  Codex GPT-6 | mode: $CODEX_PROFILE | model: $MODEL | reasoning: $EFFORT"

exec codex -m "$MODEL" -c model_reasoning_effort="$EFFORT" "$@"
