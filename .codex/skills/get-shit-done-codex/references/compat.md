# Compatibility: Claude → Codex for get-shit-done

## Tool mapping
- `Task(...)` → `spawn_agent` + `wait` + `close_agent`.
- `AskUserQuestion` → direct user interaction in chat.
- Bash-style shell helpers → PowerShell commands.

## Path mapping
- `C:/Users/Ahmed/.claude/get-shit-done/...` → `.claude/get-shit-done/...`
- `C:/Users/Ahmed/.claude/agents/...` → `.claude/agents/...`

## CLI mapping
- Use `node .claude/get-shit-done/bin/gsd-tools.js ...`.
- Keep `--raw` when upstream workflow uses it.
- Parse JSON by `ConvertFrom-Json`.
- Do not assign `node <path> <args>` into a single PowerShell string and invoke `& $cmd`.
- Use direct invocation: `node <path> ...` or `& node <path> ...`.

## Subagent mapping
- `subagent_type=gsd-*` maps to equivalent role contract in `.claude/agents/gsd-*.md`.
- Unspecified `subagent_type` values default to command-context Codex agent behavior.
- Do not pass `agent_type=gsd-*` to `spawn_agent`. Codex only accepts `default`, `explorer`, or `worker` (or omit `agent_type`).

## Required GSD subagents
- `gsd-project-researcher`
- `gsd-research-synthesizer`
- `gsd-roadmapper`
- `gsd-phase-researcher`
- `gsd-planner`
- `gsd-plan-checker`
- `gsd-executor`
- `gsd-verifier`
- `gsd-debugger`
- `gsd-integration-checker`
- `gsd-codebase-mapper`
