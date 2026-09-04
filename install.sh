#!/usr/bin/env bash
# install.sh — link this repo into Claude Code, Codex, and Grok, and make sure the skills it depends on exist.
# Idempotent; re-run any time (after cloning, after `git pull`, after a CLI update).
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd -P)"

echo "== 1/3 prerequisites"
# superpowers plugin: the Claude Code execute loop (subagent-driven-development). Claude Code only.
if command -v claude >/dev/null 2>&1; then
  if claude plugins list 2>/dev/null | grep -q '^ *❯ *superpowers@'; then
    echo "ok    superpowers plugin (Claude Code)"
  else
    echo "..    installing superpowers plugin for Claude Code"
    claude plugins install superpowers && echo "ok    superpowers plugin installed" || echo "!!    could not install superpowers — run: claude plugins install superpowers"
  fi
else
  echo "--    claude not found; skipping superpowers (needed only for Claude Code)"
fi
# Matt Pocock's skills: grilling + domain-modeling run the interview; tdd/research/wayfinder are used by the plan and research steps.
need=""
for s in grilling domain-modeling; do
  [[ -f "$HOME/.agents/skills/$s/SKILL.md" || -f "$HOME/.claude/skills/$s/SKILL.md" ]] || need="$need $s"
done
if [[ -z "$need" ]]; then
  echo "ok    mattpocock skills (grilling, domain-modeling)"
else
  echo "..    missing:$need — starting the installer. Pick at least grilling, domain-modeling, tdd, research, wayfinder (or all), and install to ALL agents (*)."
  if command -v npx >/dev/null 2>&1; then
    npx skills@latest add mattpocock/skills -g -a '*' || echo "!!    installer failed — run manually: npx skills@latest add mattpocock/skills -g -a '*'"
  else
    echo "!!    npx not found — install Node.js, then run: npx skills@latest add mattpocock/skills -g -a '*'"
  fi
fi

echo "== 2/3 linking this repo into the CLIs"
mkdir -p ~/.claude/skills ~/.agents/skills ~/.grok/skills ~/.claude/agents ~/.codex/agents ~/.grok/agents
ln -sfn "$R/skills/mew-kickoff" ~/.claude/skills/mew-kickoff          # Claude Code (follows symlinked skill dirs — verified 2026-09-03)
ln -sfn "$R/skills/mew-kickoff" ~/.agents/skills/mew-kickoff          # Codex personal skills dir; Grok reads it too
ln -sfn ../../.agents/skills/mew-kickoff ~/.grok/skills/mew-kickoff   # Grok's own skills dir, same pattern as its other installs
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-critic; do
  ln -sfn "$R/agents/claude/$a.md"   ~/.claude/agents/$a.md
  ln -sfn "$R/agents/codex/$a.toml"  ~/.codex/agents/$a.toml
  ln -sfn "$R/agents/grok/$a.md"     ~/.grok/agents/$a.md
done
ln -sfn "$R/agents/codex/mew-reviewer-heavy.toml" ~/.codex/agents/mew-reviewer-heavy.toml
ln -sfn "$R/agents/grok/mew-reviewer-heavy.md" ~/.grok/agents/mew-reviewer-heavy.md
echo "ok    symlinks written (skill + 5 base agents × 3 CLIs + conditional heavy reviewers)"

echo "== 3/3 next"
echo "Open a NEW session in each CLI you use (skills and agents are read at session start), then verify:"
echo "  bash $R/skills/mew-kickoff/scripts/smoke.sh"
