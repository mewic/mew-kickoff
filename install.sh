#!/usr/bin/env bash
# install.sh — link this repo into Claude Code, Codex, and Grok. Idempotent; re-run after cloning on a new machine.
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd -P)"
mkdir -p ~/.claude/skills ~/.agents/skills ~/.grok/skills ~/.claude/agents ~/.codex/agents ~/.grok/agents
ln -sfn "$R/skills/mew-kickoff" ~/.claude/skills/mew-kickoff          # Claude Code (follows symlinked skill dirs — verified 2026-09-03)
ln -sfn "$R/skills/mew-kickoff" ~/.agents/skills/mew-kickoff          # Codex personal skills dir; Grok reads it too
ln -sfn ../../.agents/skills/mew-kickoff ~/.grok/skills/mew-kickoff   # Grok's own skills dir, same pattern as its other installs
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-critic; do
  ln -sfn "$R/agents/claude/$a.md"   ~/.claude/agents/$a.md
  ln -sfn "$R/agents/codex/$a.toml"  ~/.codex/agents/$a.toml
  ln -sfn "$R/agents/grok/$a.md"     ~/.grok/agents/$a.md
done
echo "linked. Open a NEW session in each CLI (agent and skill files are read at session start), then run:"
echo "  bash $R/skills/mew-kickoff/scripts/smoke.sh"
