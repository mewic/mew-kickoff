#!/usr/bin/env bash
# install.sh — link this repo into Claude Code, Codex, Grok, and Cursor, and make sure the skills it depends on exist.
# Idempotent; re-run any time (after cloning, after `git pull`, after a CLI update).
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd -P)"

echo "== 1/3 prerequisites"
# Matt Pocock's skills: grilling + domain-modeling run the interview; tdd/research/wayfinder are used by the plan and research steps.
need=""
for s in grilling domain-modeling; do
  [[ -f "$HOME/.agents/skills/$s/SKILL.md" || -f "$HOME/.claude/skills/$s/SKILL.md" ]] || need="$need $s"
done
# Non-interactive: -s names the skills, -a '*' targets every agent, -y skips the confirmation; npx --yes skips npx's own download prompt.
add="npx --yes skills@latest add mattpocock/skills -s grilling domain-modeling tdd research wayfinder -g -a '*' -y"
if [[ -z "$need" ]]; then
  echo "ok    mattpocock skills (grilling, domain-modeling)"
else
  echo "..    missing:$need — installing grilling, domain-modeling, tdd, research, wayfinder for all agents (no prompts)"
  if command -v npx >/dev/null 2>&1; then
    npx --yes skills@latest add mattpocock/skills -s grilling domain-modeling tdd research wayfinder -g -a '*' -y </dev/null || echo "!!    installer failed — run manually: $add"
  else
    echo "!!    npx not found — install Node.js, then run: $add"
  fi
fi

echo "== 2/3 linking this repo into the CLIs"
mkdir -p "$HOME/.claude/skills" "$HOME/.agents/skills" "$HOME/.grok/skills" "$HOME/.cursor/skills" "$HOME/.claude/agents" "$HOME/.codex/agents" "$HOME/.grok/agents" "$HOME/.cursor/agents"
ln -sfn "$R/skills/mew-kickoff" "$HOME/.claude/skills/mew-kickoff"          # Claude Code (follows symlinked skill dirs — verified 2026-09-03)
ln -sfn "$R/skills/mew-kickoff" "$HOME/.agents/skills/mew-kickoff"          # Codex personal skills dir; Grok reads it too
ln -sfn ../../.agents/skills/mew-kickoff "$HOME/.grok/skills/mew-kickoff"   # Grok's own skills dir, same pattern as its other installs
ln -sfn "$R/skills/mew-kickoff" "$HOME/.cursor/skills/mew-kickoff"          # Cursor personal skills dir
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-critic; do
  ln -sfn "$R/agents/claude/$a.md"   "$HOME/.claude/agents/$a.md"
  ln -sfn "$R/agents/codex/$a.toml"  "$HOME/.codex/agents/$a.toml"
  ln -sfn "$R/agents/grok/$a.md"     "$HOME/.grok/agents/$a.md"
  ln -sfn "$R/agents/cursor/$a.md"   "$HOME/.cursor/agents/$a.md"
done
ln -sfn "$R/agents/codex/mew-reviewer-heavy.toml" "$HOME/.codex/agents/mew-reviewer-heavy.toml"
ln -sfn "$R/agents/grok/mew-reviewer-heavy.md" "$HOME/.grok/agents/mew-reviewer-heavy.md"
ln -sfn "$R/agents/cursor/mew-reviewer-heavy.md" "$HOME/.cursor/agents/mew-reviewer-heavy.md"
echo "ok    symlinks written (skill + agents for Claude/Codex/Grok/Cursor + conditional heavy reviewers)"

echo "== 3/3 next"
echo "Open a NEW session in each CLI you use (skills and agents are read at session start), then verify:"
echo "  bash \"$R/skills/mew-kickoff/scripts/smoke.sh\""
