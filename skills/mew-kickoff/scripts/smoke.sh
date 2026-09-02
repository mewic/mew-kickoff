#!/usr/bin/env bash
# smoke.sh — verify every pointer mew-kickoff relies on still resolves, on every harness.
# Run after any Claude Code / Codex / Grok / plugin / agent-file update:  bash ~/.claude/skills/mew-kickoff/scripts/smoke.sh
set -u
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
SKILL="$SKILL_DIR/SKILL.md"
CLAUDE="${CLAUDE_HOME:-$HOME/.claude}"
PLUGINS="$CLAUDE/plugins/cache"
fail=0
ok()  { printf 'ok    %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1"; fail=1; }

find_skill() {  # user dir first, then any plugin ("plugin:skill" allowed)
  local ref="$1" name="${1##*:}" plugin=""
  [[ "$ref" == *:* ]] && plugin="${ref%%:*}"
  if [[ -z "$plugin" && -f "$CLAUDE/skills/$name/SKILL.md" ]]; then echo "$CLAUDE/skills/$name/SKILL.md"; return; fi
  local hit; hit=$(find "$PLUGINS" -path "*/${plugin:-*}/*/skills/$name/SKILL.md" 2>/dev/null | sort -V | tail -1)
  [[ -n "$hit" ]] && echo "$hit"
}

echo "# core"
for f in map.md ultracode.md adapters/claude.md adapters/codex.md adapters/grok.md adapters/loop.md agents/openai.yaml; do
  [[ -f "$SKILL_DIR/$f" ]] && ok "file $f" || bad "file $f missing"
done
# The core must stay harness-neutral: Claude-only tokens belong in adapters/claude.md.
for tok in 'Skill tool' 'subagent_type' 'superpowers:' '/effort' '/security-review' 'grill-with-docs' 'temporarily edit'; do
  grep -qF "$tok" "$SKILL" && bad "SKILL.md carries harness-specific token '$tok' — move it to an adapter" || ok "core free of '$tok'"
done
words=$(wc -w < "$SKILL" | tr -d ' ')
(( words <= 2200 )) && ok "SKILL.md $words words" || bad "SKILL.md is $words words (> 2200) — disclose reference to sibling files"

echo "# claude"
for ref in grilling domain-modeling superpowers:writing-plans superpowers:subagent-driven-development security-review; do
  f=$(find_skill "$ref")
  if [[ -z "$f" ]]; then [[ "$ref" == security-review ]] && ok "skill $ref (built-in, not on disk)" || bad "skill $ref not found"; continue; fi
  grep -q '^disable-model-invocation: *true' "$f" && bad "skill $ref is user-invoked; the Skill tool will refuse it" || ok "skill $ref"
done
SDD=$(dirname "$(find_skill superpowers:subagent-driven-development)")
for f in task-reviewer-prompt.md implementer-prompt.md scripts/review-package scripts/sdd-workspace ../requesting-code-review/code-reviewer.md; do
  [[ -e "$SDD/$f" ]] && ok "SDD $f" || bad "SDD $f missing — re-check adapters/claude.md against $SDD/SKILL.md"
done
grep -q 'Five rounds maximum' "$SDD/SKILL.md" && ok "SDD still uses a 5-round cap" || bad "SDD round cap changed — update adapters/claude.md"
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-critic code-reviewer; do
  f="$CLAUDE/agents/$a.md"
  [[ -f "$f" ]] || { bad "claude agent $a missing"; continue; }
  grep -q '^model:' "$f" && ok "claude agent $a (model: $(grep '^model:' "$f" | awk '{print $2}'))" || bad "claude agent $a has no model line"
done
grep -Eq '^tools:.*(Bash|Edit)' "$CLAUDE/agents/mew-critic.md" && bad "mew-critic has Bash or Edit; it may only Write its report" || ok "mew-critic has no shell and no Edit"
for a in mew-reviewer mew-critic; do
  grep -Eq '^tools:.*(Write|Bash)' "$CLAUDE/agents/$a.md" && ok "claude agent $a can write its report" || bad "claude agent $a has a tools list without Write or Bash — its report rule is inert"
done
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-critic; do
  grep -q '150 words' "$CLAUDE/agents/$a.md" && ok "claude agent $a report rule" || bad "claude agent $a lacks the 150-word report rule"
done

echo "# codex"
for s in grilling domain-modeling; do [[ -f "$HOME/.agents/skills/$s/SKILL.md" ]] && ok "cross-runtime skill $s in ~/.agents/skills" || bad "~/.agents/skills/$s missing — Codex/Grok cannot load it"; done
[[ "$(cd -P "$HOME/.agents/skills/mew-kickoff" 2>/dev/null && pwd -P)" == "$SKILL_DIR" ]] && ok "~/.agents/skills/mew-kickoff → skill dir" || bad "~/.agents/skills/mew-kickoff does not resolve to $SKILL_DIR"
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-critic; do
  f="$HOME/.codex/agents/$a.toml"
  [[ -f "$f" ]] || { bad "codex agent $a.toml missing"; continue; }
  grep -q '^model = ' "$f" && grep -q '150 words' "$f" && ok "codex agent $a ($(grep '^model = ' "$f" | cut -d'"' -f2))" || bad "codex agent $a lacks model or report rule"
done
if command -v codex >/dev/null; then
  codex features list 2>/dev/null | grep -Eq '^multi_agent\s+stable\s+true' && ok "codex multi_agent enabled" || bad "codex multi_agent flag not enabled — spawn_agent will be missing"
else ok "codex not installed here (skipped)"; fi

echo "# grok"
[[ "$(cd -P "$HOME/.grok/skills/mew-kickoff" 2>/dev/null && pwd -P)" == "$SKILL_DIR" ]] && ok "~/.grok/skills/mew-kickoff → skill dir" || bad "~/.grok/skills/mew-kickoff does not resolve to $SKILL_DIR"
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-critic; do
  f="$HOME/.grok/agents/$a.md"
  [[ -f "$f" ]] || { bad "grok agent $a.md missing"; continue; }
  grep -q '^model:' "$f" && grep -q '^effort:' "$f" && grep -q '150 words' "$f" && ok "grok agent $a ($(grep '^model:' "$f" | awk '{print $2}'), effort $(grep '^effort:' "$f" | awk '{print $2}'))" || bad "grok agent $a lacks model, effort, or report rule"
done

if (( fail )); then echo "SMOKE: FAIL"; exit 1; else echo "SMOKE: PASS"; fi
