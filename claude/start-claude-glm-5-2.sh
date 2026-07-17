#!/bin/bash
# Direct Z.ai Coding Plan launcher for GLM-5.2.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

require_claude
require_mcp_json

ENV_FILE=".env.local"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${ZAI_CODING_API_KEY:?ZAI_CODING_API_KEY must be set in the environment or local .env.local.}"

CLAUDE_PROFILE="${CLAUDE_PROFILE:-default}"
case "$CLAUDE_PROFILE" in
  fast)
    EFFORT_LEVEL="low"
    OUTPUT_TOKENS=16384
    ;;
  default)
    EFFORT_LEVEL="medium"
    OUTPUT_TOKENS=32768
    ;;
  deep)
    EFFORT_LEVEL="high"
    OUTPUT_TOKENS=32768
    ;;
  *)
    echo "❌ Invalid CLAUDE_PROFILE: $CLAUDE_PROFILE (use fast, default, or deep)." >&2
    exit 1
    ;;
esac

export_plumbing_env

export CLAUDE_CODE_MAX_OUTPUT_TOKENS="$OUTPUT_TOKENS"
# Cacheless proxied backend: keep the MCP cap tight. Unlike native (25000, absorbed
# by the 1h cache), a large tool return here re-injects into an uncached prefix
# every turn, inflating per-turn input cost on the Z.ai plan.
export MAX_MCP_OUTPUT_TOKENS=8000

CONTEXT_NAME=$(get_context_name)

# Z.ai's Coding Plan Anthropic-compatible endpoint.  Every Claude tier is
# deliberately pinned to GLM-5.2; do not cross-map a tier to another GLM model.
unset ANTHROPIC_API_KEY
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$ZAI_CODING_API_KEY"
export ANTHROPIC_MODEL="glm-5.2[1m]"
export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.2[1m]"
export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.2[1m]"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-5.2[1m]"

exec claude \
  --continue \
  --permission-mode=bypassPermissions \
  --mcp-config ./.mcp.json \
  --effort "$EFFORT_LEVEL" \
  --name="ZAI-GLM-5.2-${CONTEXT_NAME:-UnknownContext}"
