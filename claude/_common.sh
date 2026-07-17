#!/bin/bash
# Shared PLUMBING for the Claude Code launchers — checks + backend-agnostic env.
# Deliberately holds NO cost levers (caching, compaction, effort, model tier):
# those differ per backend and live in each launcher. Sourced, not executed.

require_claude() {
  if ! command -v claude &>/dev/null; then
    echo "❌ claude is not installed." >&2
    echo "please install it and try again." >&2
    exit 2
  fi
  echo "✅ claude is installed."
}

require_mcp_json() {
  if [[ ! -f .mcp.json ]]; then
    echo "❌ .mcp.json is missing in current directory." >&2
    echo "run this launcher from the repository you want Claude Code to work in." >&2
    exit 1
  fi
  echo "✅ .mcp.json found"
}

get_context_name() {
    # 1. Try tmux
    if [ -n "${TMUX:-}" ]; then
        # 2>/dev/null || true: a stale/forwarded $TMUX (dead server, SSH, detached)
        # makes tmux exit non-zero; without this guard `CONTEXT_NAME=$(get_context_name)`
        # trips set -e in the launchers and aborts before exec claude.
        tmux display-message -p '#S' 2>/dev/null || true
    # 2. If not tmux, try git
    elif git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        basename "$(git rev-parse --show-toplevel)"
    fi
}


# export_plumbing_env — backend-agnostic env only. Cost-neutral or universally
# safe. NOTE: MAX_MCP_OUTPUT_TOKENS is intentionally NOT set here — each launcher
# picks its own cap (tighter on cacheless proxied backends).
export_plumbing_env() {
  # Umbrella flag: covers telemetry, bug-report, error-report, autoupdater, and
  # feature-flag fetches. This is NON-INFERENCE traffic only — it costs zero model
  # tokens, so it does NOT protect the 5h/7d usage runway. Left ON it can starve
  # Remote Control's eligibility check, so default it OFF. Opt back in for a
  # locked-down / offline run with CLAUDE_LEAN_TRAFFIC=1.
  # (The real token saver is DISABLE_NON_ESSENTIAL_MODEL_CALLS below, kept on.)
  if [[ "${CLAUDE_LEAN_TRAFFIC:-0}" == "1" ]]; then
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
  fi
  # Suppress billed side model calls (flavor text, auto summaries) — a real,
  # small token saver, distinct from the traffic umbrella above.
  export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
  # Defer MCP tool schemas, load on demand (version-dependent; safe if ignored).
  export ENABLE_TOOL_SEARCH=true
  export BASH_MAX_OUTPUT_LENGTH=12000
  export BASH_DEFAULT_TIMEOUT_MS=180000
  export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1
  export CLAUDE_CODE_NO_FLICKER=1
  export MCP_CONNECTION_NONBLOCKING=true
  export CLAUDE_PROJECT_DIR="$(pwd)"
}
