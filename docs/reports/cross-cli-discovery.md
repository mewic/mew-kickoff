# Cross-CLI discovery check — 2026-09-02

Method: headless one-shot runs from `~/projects`, low reasoning effort, no shell allowed.

| CLI | Implicit listing ("which skills are loaded?") | Explicit invocation | Path the CLI reported |
|---|---|---|---|
| Codex 0.152.0 (`codex exec`, gpt-5.6-sol) | mew-kickoff NOT listed (only bundled system skills appeared; user skills are not pre-listed in this mode) | `$mew-kickoff` → "Loaded successfully", heading `# Mew Kickoff`, adapter `adapters/codex.md` | `/Users/mewsocialmacmini/.claude/skills/mew-kickoff/SKILL.md` (via `~/.agents/skills` symlink) |
| Grok 1.0.13 (`grok -p`, grok-4.6) | mew-kickoff NOT listed (other skills were: wizard, code-review, tdd, research, ask-me) — consistent with `disable-model-invocation: true`, which Grok honors | `/mew-kickoff` → loaded, heading `# Mew Kickoff`, adapter `adapters/grok.md` | `/Users/mewsocialmacmini/.grok/skills/mew-kickoff/SKILL.md` (symlink) |
| Claude Code | hidden from the model by `disable-model-invocation: true` (verified earlier: Skill tool refuses it) | `/mew-kickoff` by Mew | `~/.claude/skills/mew-kickoff/SKILL.md` (source of truth) |

Conclusion: the skill is user-invoked on all three CLIs, exactly as designed; a single source directory with two symlinks is enough. Not yet exercised on Codex/Grok: an actual pipeline run (spawn_agent on Codex; Grok custom agents remain UNVERIFIED).

## Grok agent definitions — 2026-09-03

- Format found in `~/.grok/bundled/agents/{general-purpose,explore,plan}.md`: Markdown + YAML frontmatter (`name`, `description`, `prompt_mode`, `model`, `permission_mode`, `agents_md`) + body. Binary docs strings confirm `~/.grok/agents/` (user) and `.grok/agents/` (project), plus `~/.claude/agents/*.md` as a compat discovery source.
- Before native files existed, Grok's `spawn_subagent` already listed `mew-worker`, `mew-worker-heavy`, `mew-reviewer`, `mew-critic`, `code-reviewer` (from the Claude compat source) but NOT `mew-worker-mech`.
- After writing `~/.grok/agents/mew-*.md` (model grok-4.6), a headless run listed all five plus the three built-ins. Spawn tool: `spawn_subagent` with `subagent_type`, `prompt`, `description`, optional `background`, `isolation`, `model` (slugs grok-4.5 / grok-4.6), `cwd`, `resume_from`.
- Per-agent effort VERIFIED: added `effort:` to the five files; the agent-definition parser's field list in the binary includes `effort`; a live headless spawn of `mew-worker-mech` produced a child session summary with `agent_name = mew-worker-mech`, `reasoning_effort = medium` while the parent ran at `low`. `spawn_subagent` itself has no effort parameter (only `model`).
