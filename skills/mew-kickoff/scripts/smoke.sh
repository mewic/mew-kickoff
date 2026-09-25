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
for f in map.md ultracode.md execute.md adapters/claude.md adapters/codex.md adapters/grok.md adapters/cursor.md adapters/loop.md agents/openai.yaml; do
  [[ -f "$SKILL_DIR/$f" ]] && ok "file $f" || bad "file $f missing"
done
# The core must stay harness-neutral: harness tokens belong in adapters.
for core in "$SKILL" "$SKILL_DIR/execute.md"; do
  label=$(basename "$core")
  for tok in 'Skill tool' 'subagent_type' 'superpowers:' 'SDD' '/effort' '/security-review' 'grill-with-docs' 'temporarily edit' 'spawn_subagent' 'spawn_agent' 'Task tool' 'fork_turns'; do
    grep -qF "$tok" "$core" && bad "$label carries harness-specific token '$tok' — move it to an adapter" || ok "$label free of '$tok'"
  done
done
grep -q 'continue here' "$SKILL" && bad "SKILL.md still allows continue-here execute" || ok "SKILL.md forbids continue-here execute"
grep -q 'whole frontier' "$SKILL" && ok "SKILL.md uses grilling frontier rounds" || bad "SKILL.md must use grilling frontier rounds"
grep -q -- '-U3' "$SKILL_DIR/adapters/loop.md" && bad "loop.md still dumps unified diffs" || ok "loop.md omits full unified diffs"
words=$(wc -w < "$SKILL" | tr -d ' ')
(( words <= 1600 )) && ok "SKILL.md $words words" || bad "SKILL.md is $words words (> 1600) — disclose reference to sibling files"
ewords=$(wc -w < "$SKILL_DIR/execute.md" | tr -d ' ')
(( ewords <= 1200 )) && ok "execute.md $ewords words" || bad "execute.md is $ewords words (> 1200)"

echo "# claude"
for ref in grilling domain-modeling security-review; do
  f=$(find_skill "$ref")
  if [[ -z "$f" ]]; then [[ "$ref" == security-review ]] && ok "skill $ref (built-in, not on disk)" || bad "skill $ref not found"; continue; fi
  grep -q '^disable-model-invocation: *true' "$f" && bad "skill $ref is user-invoked; the Skill tool will refuse it" || ok "skill $ref"
done
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
for f in "$CLAUDE/agents/mew-worker-mech.md" "$HOME/.codex/agents/mew-worker-mech.toml" "$HOME/.grok/agents/mew-worker-mech.md" "$HOME/.cursor/agents/mew-worker-mech.md"; do
  grep -q 'exit codes' "$f" && grep -q 'failing excerpts only' "$f" && ok "mechanical report evidence $f" || bad "mechanical report evidence incomplete in $f"
done

echo "# codex"
for s in grilling domain-modeling; do [[ -f "$HOME/.agents/skills/$s/SKILL.md" ]] && ok "cross-runtime skill $s in ~/.agents/skills" || bad "~/.agents/skills/$s missing — Codex/Grok cannot load it"; done
[[ "$(cd -P "$HOME/.agents/skills/mew-kickoff" 2>/dev/null && pwd -P)" == "$SKILL_DIR" ]] && ok "~/.agents/skills/mew-kickoff → skill dir" || bad "~/.agents/skills/mew-kickoff does not resolve to $SKILL_DIR"
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-reviewer-heavy mew-critic; do
  f="$HOME/.codex/agents/$a.toml"
  [[ -f "$f" ]] || { bad "codex agent $a.toml missing"; continue; }
  grep -q '^model = ' "$f" && grep -q '150 words' "$f" && ok "codex agent $a ($(grep '^model = ' "$f" | cut -d'"' -f2))" || bad "codex agent $a lacks model or report rule"
done
for pair in 'mew-worker:gpt-6-astra' 'mew-worker-heavy:gpt-6-sol' 'mew-worker-mech:gpt-5.6-luna' 'mew-reviewer:gpt-6-astra' 'mew-reviewer-heavy:gpt-6-sol' 'mew-critic:gpt-6-astra'; do
  a="${pair%%:*}"; expected="${pair#*:}"; f="$HOME/.codex/agents/$a.toml"
  grep -qF "model = \"$expected\"" "$f" && ok "codex $a model economy ($expected)" || bad "codex $a must use $expected"
done
grep -qF 'fork_turns="none"' "$SKILL_DIR/adapters/codex.md" && ok "codex fresh-context dispatch" || bad "codex adapter must require fork_turns=none"
grep -qF '`followup_task`' "$SKILL_DIR/adapters/codex.md" && ok "codex current follow-up tool" || bad "codex adapter lacks followup_task"
for stale in send_input resume_agent close_agent; do
  grep -q "$stale" "$SKILL_DIR/adapters/codex.md" && bad "codex adapter carries stale tool $stale" || ok "codex adapter free of stale $stale"
done
if command -v codex >/dev/null; then
  codex features list 2>/dev/null | grep -Eq '^multi_agent\s+stable\s+true' && ok "codex multi_agent enabled" || bad "codex multi_agent flag not enabled — spawn_agent will be missing"
else ok "codex not installed here (skipped)"; fi

echo "# grok"
[[ "$(cd -P "$HOME/.grok/skills/mew-kickoff" 2>/dev/null && pwd -P)" == "$SKILL_DIR" ]] && ok "~/.grok/skills/mew-kickoff → skill dir" || bad "~/.grok/skills/mew-kickoff does not resolve to $SKILL_DIR"
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-reviewer-heavy mew-critic; do
  f="$HOME/.grok/agents/$a.md"
  [[ -f "$f" ]] || { bad "grok agent $a.md missing"; continue; }
  grep -q '^model:' "$f" && grep -q '^effort:' "$f" && grep -q '150 words' "$f" && grep -q 'mcpInheritance: none' "$f" && ok "grok agent $a ($(grep '^model:' "$f" | awk '{print $2}'), effort $(grep '^effort:' "$f" | awk '{print $2}'))" || bad "grok agent $a lacks model, effort, report rule, or mcpInheritance none"
done
grep -qF 'model: grok-4.7-build-fast' "$HOME/.grok/agents/mew-worker-mech.md" && grep -qF 'effort: low' "$HOME/.grok/agents/mew-worker-mech.md" && ok "grok mech model economy (grok-4.7-build-fast low)" || bad "grok mew-worker-mech must use grok-4.7-build-fast low"
grep -qF 'Suggest `high` for interview' "$SKILL_DIR/adapters/grok.md" && ok "grok adapter interview effort is high" || bad "grok adapter must suggest high for interview"
grep -qF 'only Mew launches' "$SKILL_DIR/adapters/grok.md" && ok "grok heavier review is opt-in" || bad "grok adapter must keep heavier review opt-in"
CRITIC="$HOME/.grok/agents/mew-critic.md"
grep -q '^tools:' "$CRITIC" && ok "grok mew-critic has tools allowlist" || bad "grok mew-critic lacks tools allowlist"
grep -Eq '^tools:.*(Bash|Edit|bash|search_replace|run_terminal_command)' "$CRITIC" && bad "grok mew-critic has shell or Edit" || ok "grok mew-critic has no shell and no Edit"
grep -Eq '^tools:.*(Write|write)' "$CRITIC" && ok "grok mew-critic can write its report" || bad "grok mew-critic tools cannot write a report"
for a in mew-reviewer mew-reviewer-heavy; do
  f="$HOME/.grok/agents/$a.md"
  grep -q '^tools:' "$f" && grep -Eq '^tools:.*(Write|write)' "$f" && grep -Eq '^tools:.*(Bash|bash|run_terminal_command)' "$f" && ! grep -Eq '^tools:.*(Edit|search_replace)' "$f" && ok "grok $a tools (verify+report, no Edit)" || bad "grok $a must allowlist Bash+Write without Edit"
done
GA="$SKILL_DIR/adapters/grok.md"
grep -qF 'enter_plan_mode' "$GA" && ok "grok adapter skips native plan mode" || bad "grok adapter must skip enter_plan_mode during the pipeline"
grep -qF 'isolation: worktree' "$GA" && ok "grok adapter pins implementer worktree isolation" || bad "grok adapter must pin isolation: worktree for implementers"
grep -qF 'Fix round:' "$GA" && grep -qF 'resume_from' "$GA" && ok "grok adapter uses resume_from for fix rounds" || bad "grok adapter must use resume_from for fix rounds"
grep -qF '/usage' "$GA" && ok "grok adapter usage checkpoint is /usage" || bad "grok adapter must record /usage at checkpoints"
README="$SKILL_DIR/../../README.md"
mech=$(grep -F '| `mew-worker-mech`' "$README" || true)
printf '%s\n' "$mech" | grep -q 'grok-4.7-build-fast · low' && ok "README Grok mech cell is grok-4.7-build-fast low" || bad "README mew-worker-mech Grok cell must be grok-4.7-build-fast · low"

echo "# cursor"
[[ "$(cd -P "$HOME/.cursor/skills/mew-kickoff" 2>/dev/null && pwd -P)" == "$SKILL_DIR" ]] && ok "~/.cursor/skills/mew-kickoff → skill dir" || bad "~/.cursor/skills/mew-kickoff does not resolve to $SKILL_DIR"
for a in mew-worker mew-worker-heavy mew-worker-mech mew-reviewer mew-reviewer-heavy mew-critic; do
  f="$HOME/.cursor/agents/$a.md"
  [[ -f "$f" ]] || { bad "cursor agent $a.md missing"; continue; }
  grep -q '150 words' "$f" && ok "cursor agent $a report rule" || bad "cursor agent $a lacks the 150-word report rule"
done
grep -qF 'generalPurpose' "$SKILL_DIR/adapters/cursor.md" && grep -qF 'composer-2.5-fast' "$SKILL_DIR/adapters/cursor.md" && ok "cursor adapter Task recipe" || bad "cursor adapter must document Task generalPurpose and a cheap model"
grep -qF 'new Cursor chat' "$SKILL_DIR/adapters/cursor.md" && ok "cursor adapter requires a fresh execute chat" || bad "cursor adapter must require a new chat for execute"

if (( fail )); then echo "SMOKE: FAIL"; exit 1; else echo "SMOKE: PASS"; fi
