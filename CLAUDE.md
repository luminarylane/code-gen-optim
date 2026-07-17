# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Relocatable shell launcher bundles for Claude Code and OpenAI Codex, tuned per backend for cost/quality. There is no application code and no LiteLLM/proxy dependency — each launcher points its agent directly at a provider. The only artifacts are `*.sh` scripts.

## Commands

There are no tests; syntax-checking is the full validation:

```bash
bash -n claude/*.sh
bash -n codex/*.sh
```

Launchers are not run from this repo — they are copied into a target repository and run there (they require a `.mcp.json` in the working directory).

## Architecture

### Per-backend, not one config — driven by prompt caching

The dominant input-cost lever is prompt caching, and it differs by backend. Do **not** unify cost levers across launchers:

- **Native Anthropic** (`claude/start-claude-claude.sh`): 1h ephemeral cache works. Protect it — `--exclude-dynamic-system-prompt-sections`, leave auto-compaction at default (early compaction rewrites and burns the warm prefix). Profile drives model tier + `--effort`; `default` uses `opusplan` (Opus plans, Sonnet executes).
- **Native OpenAI** (`codex/`): OpenAI prefix caching applies automatically; keep the prefix stable. Profile drives model tier + `model_reasoning_effort`.
- **Direct Anthropic-compatible** (Kimi, Z.ai GLM): `unset ANTHROPIC_API_KEY`, set `ANTHROPIC_AUTH_TOKEN` to the provider key, point `ANTHROPIC_BASE_URL` at the provider. These are cacheless/proxied, so keep the MCP cap tight (`MAX_MCP_OUTPUT_TOKENS` well below the native `25000` — a large tool return re-injects into an uncached prefix every turn). Launcher shape is **not uniform** across this class: `start-claude-glm-5-2.sh` carries a fast/default/deep profile (drives `--effort` + output-token cap, pins `glm-5.2[1m]` for 1M context), while `start-claude-glm-4-7.sh` and `start-claude-kimi.sh` stay minimal (no profile). Caveat: `--effort` is likely a no-op on non-Claude GLM/Kimi models, so on those the profile effectively only sets the output-token cap.

`MAX_THINKING_TOKENS` is never set (ignored by adaptive-thinking models — verified via the outgoing request body). `--effort` / `CLAUDE_CODE_EFFORT_LEVEL` is the live reasoning dial and propagates as `output_config.effort`.

### `_common.sh` is plumbing only

Each bundle's `_common.sh` holds backend-agnostic checks and env (telemetry umbrella, tool-search, bash limits, project dir). It carries **no** caching/compaction/effort/tier logic — those live in the launcher that knows its backend.

### Launchers exec their agent

Launchers end in `exec claude ...` / `exec codex ...`, so `_common.sh` can only export vars and define functions. Optional flags are passed via arrays guarded with `${arr[@]+"${arr[@]}"}` — required because macOS `/bin/bash` is 3.2, which errors on empty `"${arr[@]}"` under `set -u`. Always test launcher changes with real `/bin/bash`, not a newer bash.

## Constraints

- **bash 3.2 compatibility** is mandatory (macOS default). Guard every optional-array expansion.
- Keep model IDs in the Codex launchers aligned with what `codex models` reports; they are OpenAI-served aliases.
- Skills use the same `SKILL.md` format in Claude (`.claude/skills/`) and Codex (`~/.codex/skills/`); slash commands have no Codex equivalent and port to skills.
