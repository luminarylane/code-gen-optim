#!/bin/bash
# Native Claude Code on Anthropic (claude.ai / firstParty).
# Tailored lever: PROMPT CACHING. On this backend the 1h ephemeral cache is real
# and measured (a warm prefix re-reads at ~10% price). Everything here protects
# that cache. Reasoning is tuned via --effort; MAX_THINKING_TOKENS is NOT set
# because adaptive-thinking models ignore it (verified: the outgoing request
# carries thinking:{type:adaptive} with no budget regardless).
#
# Browser: --chrome is OPT-IN (CLAUDE_CHROME=1). It streams live page DOM and
# screenshots into the main context and guzzles tokens. Default off — routine
# browser work should use the agent-browser CLI (compact ~200-400 token a11y
# snapshots, run via Bash: `agent-browser open <url>` / `snapshot -i` / `click @e2`).
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

require_claude
require_mcp_json

# Set the context var for use in remote
CONTEXT_NAME=$(get_context_name)
remote_control_args=()
if [[ -n "$CONTEXT_NAME" ]]; then
  remote_control_args=("--remote-control=$CONTEXT_NAME")
  echo "remote_control_args: $remote_control_args"
fi

# Chrome integration is opt-in — token-heavy, only for real logged-in / visual work.
# Chrome integration is opt-in — token-heavy, only for real logged-in / visual work.
chrome_args=()
if [[ "${CLAUDE_CHROME:-0}" == "1" ]]; then
  chrome_args=(--chrome)
  echo "chrome_args: $chrome_args"
fi

# Profile drives effort, model tier, AND advisor — tier is the biggest cost lever,
# so "fast" drops from Opus to Sonnet. Only the native backend gets a tier drop.
#
# Advisor (--advisor, native/API-only, experimental): the main model consults a
# stronger model as a server tool at decision points (before committing an
# approach, on a recurring error, before declaring done). It fires only at those
# points, so an Opus advisor costs far less than running Opus throughout, and
# toggling it does NOT invalidate the prompt cache. "fast" stays lean (no advisor)
# as the true-cheap profile; default + deep escalate hard calls to Opus.
# Override per launch: CLAUDE_ADVISOR=<model> to set, CLAUDE_ADVISOR=off to disable.
CLAUDE_PROFILE="${CLAUDE_PROFILE:-default}"
case "$CLAUDE_PROFILE" in
  fast)
    CLAUDE_MODEL="sonnet"
    EFFORT_LEVEL="low"
    OUTPUT_TOKENS=16384
    ADVISOR_MODEL=""
    ;;
  default)
    CLAUDE_MODEL="opusplan"
    EFFORT_LEVEL="medium"
    OUTPUT_TOKENS=32768
    ADVISOR_MODEL="opus"
    ;;
  deep)
    CLAUDE_MODEL="opus"
    EFFORT_LEVEL="high"
    OUTPUT_TOKENS=32768
    ADVISOR_MODEL="opus"
    ;;
  *)
    echo "❌ Invalid CLAUDE_PROFILE: $CLAUDE_PROFILE (use fast, default, or deep)." >&2
    exit 1
    ;;
esac

# Advisor override: CLAUDE_ADVISOR=off|none disables; any other value sets the
# advisor model (e.g. CLAUDE_ADVISOR=opus adds one to the lean "fast" profile).
if [[ -n "${CLAUDE_ADVISOR:-}" ]]; then
  case "$CLAUDE_ADVISOR" in
    off|none) ADVISOR_MODEL="" ;;
    *)        ADVISOR_MODEL="$CLAUDE_ADVISOR" ;;
  esac
fi
advisor_args=()
if [[ -n "$ADVISOR_MODEL" ]]; then
  advisor_args=(--advisor "$ADVISOR_MODEL")
fi
echo "⚙️  Profile: $CLAUDE_PROFILE | model: $CLAUDE_MODEL | effort: $EFFORT_LEVEL | advisor: ${ADVISOR_MODEL:-none} | output: $OUTPUT_TOKENS | chrome: ${CLAUDE_CHROME:-0}"

export_plumbing_env
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="$OUTPUT_TOKENS"
# Cap MCP output so a single tool return can't blow the cached prefix. Kept
# generous here — the cache absorbs most repeated context on this backend.
export MAX_MCP_OUTPUT_TOKENS=25000

# Cache protection, native-only:
#  - --exclude-dynamic-system-prompt-sections moves per-machine bits (cwd, env,
#    git status) out of the cached prefix, improving cross-session cache reuse.
#  - Autocompact is left at Claude's default ON PURPOSE. Forcing early compaction
#    rewrites the prefix and burns the warm 1h cache, which costs more than it
#    saves on this backend. Do NOT add CLAUDE_CODE_AUTO_COMPACT_WINDOW here.
# Session continuity: --continue by default; CLAUDE_FRESH=1 starts a clean
# session (escape hatch for a cross-provider transcript that won't resume, e.g.
# a leftover LiteLLM/GPT conversation that fails Anthropic thinking-block checks).
continue_args=(--continue)
if [[ "${CLAUDE_FRESH:-0}" == "1" ]]; then
  continue_args=()
fi

exec claude \
  ${continue_args[@]+"${continue_args[@]}"} \
  ${chrome_args[@]+"${chrome_args[@]}"} \
  --exclude-dynamic-system-prompt-sections \
  --permission-mode=bypassPermissions \
  --mcp-config ./.mcp.json \
  --model "$CLAUDE_MODEL" \
  --effort "$EFFORT_LEVEL" \
  ${advisor_args[@]+"${advisor_args[@]}"} \
  --name="Anthropic Claude" \
  ${remote_control_args[@]+"${remote_control_args[@]}"}
