# code-gen-optim

Relocatable launcher bundles for AI coding agents — **Claude Code** and **OpenAI Codex** — tuned per backend for cost and quality. No LiteLLM, no proxy: each launcher points its agent at the provider directly.

The guiding principle is **right tool, right job, no wasted tokens redoing work**: spend model capability where it prevents redo (planning, hard execution) and save only where saving is free (dead knobs, telemetry, verbose prose).

## Bundles

- `claude/` — Claude Code launchers:
  - `start-claude-claude.sh` — native Anthropic (claude.ai). Prompt caching works here, so the launcher **protects the cache** and drives cost via model tier + reasoning effort.
  - `start-claude-kimi.sh`, `start-claude-glm-5-2.sh`, `start-claude-glm-4-7.sh` — direct Kimi / Z.ai Coding Plan endpoints (Anthropic-compatible), not metered through any proxy.
  - `select-claude-model.sh`, `start-tmux.sh` — model/work-mode picker and a tmux workspace.
- `codex/` — OpenAI Codex launchers:
  - `start-codex-gpt-5-6.sh`, `start-codex-gpt-5-4.sh` — GPT families, native caching, no bridge.
  - `select-codex-model.sh` — family + work-mode picker.
- `_common.sh` (one per bundle) — shared checks and plumbing only; no cost levers (those differ per backend and live in each launcher).

## Work modes

Each bundle's selector prompts for a work mode; `CLAUDE_PROFILE` / `CODEX_PROFILE` (`fast` / `default` / `deep`) maps to model tier + reasoning effort:

- **Claude native** — `fast`: Sonnet + low effort · `default`: **Opus Plan Mode** (`opusplan` — Opus plans, Sonnet executes) + medium · `deep`: flat Opus + high. Cache protected via `--exclude-dynamic-system-prompt-sections`; auto-compaction left at default (forcing early compaction burns the warm cache).
- **Codex** — `fast`: cheapest tier + low · `default`: mid tier + medium · `deep`: flagship + high. Native OpenAI prompt caching applies automatically.

`MAX_THINKING_TOKENS` is deliberately never set — adaptive-thinking models (Opus 4.8+) ignore it; `--effort` / `CLAUDE_CODE_EFFORT_LEVEL` is the live reasoning dial.

## Why per-backend, not one config

Prompt caching is the dominant input-cost lever and it behaves differently by backend (measured):

- **Native Anthropic** — 1-hour ephemeral cache; a warm prefix re-reads at ~10% of input price. Protect it.
- **Native OpenAI (Codex)** — server-side prefix caching applies automatically (~99% of input cached on warm turns in practice); keep the prefix stable.
- **A proxy routing Claude Code to a non-Anthropic model** — Anthropic `cache_control` is dropped in translation, so caching is lost and input is billed full price every turn. This is why GPT/Gemini are launched via their **own** native agents (Codex / Antigravity), not bridged into Claude Code.

## Install into a target repository

Copy the bundle you want next to (not over) the target repo's own `scripts/`:

```bash
cd ~/Developer/my-project
mkdir -p .claude
cp -R ~/Developer/code-gen-optim/claude .claude/litellm-launchers   # or wherever you keep tools

# start the model selector in a tmux workspace
.claude/litellm-launchers/start-tmux.sh my-project
```

The target repo must provide `.mcp.json`. Launchers resolve sibling scripts from their own directory while keeping the target repo as the working directory, so `.mcp.json` and `CLAUDE_PROJECT_DIR` stay scoped correctly.

Environment toggles for the native Claude launcher:

- `CLAUDE_PROFILE=fast|default|deep` — work mode (default `default`).
- `CLAUDE_CHROME=1` — enable the Chrome integration (opt-in; token-heavy). Default off; use the `agent-browser` CLI for routine browser work (compact accessibility snapshots).
- `CLAUDE_FRESH=1` — skip `--continue` and start a clean session (escape hatch for a transcript that won't resume, e.g. a cross-provider conversation that fails Anthropic thinking-block validation).

## Browser automation

Browser work uses the [agent-browser](https://agent-browser.dev/) CLI (compact ~200–400 token accessibility snapshots vs ~3–5k for full DOM), wired as an auto-triggering skill. Skills use the same `SKILL.md` format in Claude (`.claude/skills/`) and Codex (`~/.codex/skills/`), so they port 1:1.

## Validation

```bash
bash -n claude/*.sh
bash -n codex/*.sh
```

Launchers target macOS `/bin/bash` (3.2), so empty-array expansions use the `${arr[@]+"${arr[@]}"}` guard.

## License

MIT
