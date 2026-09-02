# Adapter: xAI Grok CLI (1.0.13+)

Read this when the harness is Grok. Status 2026-09-03: skill loading, agent-definition format, per-agent effort, and the spawn tool verified — bundled files (`~/.grok/bundled/agents/*.md`), the CLI's embedded docs, and a live spawn whose child session recorded `agent_name = mew-worker-mech`, `reasoning_effort = medium` while the parent ran at `low`.

## Loading skills
- Grok loads `~/.grok/skills/` and `~/.agents/skills/`; this skill is symlinked into `~/.grok/skills/`. It honors `disable-model-invocation`, so only Mew starts it: `/mew-kickoff` (verified headless).
- To load `grilling`, `domain-modeling`, or any other skill: read `~/.agents/skills/<name>/SKILL.md` and follow it. The plan template in SKILL.md is the plan format.
- Argument substitution is UNSURE: treat the text after the skill name as the arguments.

## Agents and dispatch
- Definitions: `~/.grok/agents/mew-{worker,worker-heavy,worker-mech,reviewer,critic}.md` — Markdown + YAML frontmatter, same shape as Grok's bundled agents: `name`, `description`, `prompt_mode: full`, `model: grok-4.6`, `effort: <low|medium|high|xhigh>`, `permission_mode: default`, `agents_md: true`, then the instructions as the body (copied from `~/.claude/agents/mew-*.md`). Project-scoped `.grok/agents/` overrides user-scoped; Grok also discovers `~/.claude/agents/*.md` as a compat source, so the Claude files would work unaltered but with `model` aliases it cannot resolve (falls back to the session model). The native files are the source here.
- Dispatch with the `spawn_subagent` tool: `subagent_type` = the agent name, `prompt` = the complete task spec, `description` = a 3–5 word label; optional `background`, `isolation` (`none` | `worktree`), `model`, `cwd`, `resume_from`. Background results come back through `get_command_or_subagent_output`.
- Built-ins: `general-purpose`, `explore` (read-only — the Step 4 explorer), `plan`. Pass `model` when spawning a built-in.
- Effort per agent: the `effort:` frontmatter key is applied to the child session (verified). Resolution order in Grok's docs: spawn-time override, role, persona, then the parent session; the `spawn_subagent` schema has no effort parameter, so the agent file is the place to set it. Heavy-tier reviewer = `mew-reviewer` with a sixth file at `effort: xhigh` if ever needed, or pass `model`/instructions to `mew-worker-heavy`.
- `/fork` branches the session; it is not a subagent. `--agent` / `--agent-profile` / `--agents <JSON>` select or inject definitions for the *session* — not needed for this skill. Personas (`/personas`) are tone overlays, not roles.
- Manage definitions in the TUI with `/config-agents` (alias `/agents`); edits to `~/.grok/agents/*.md` are picked up by discovery at session start.

## Execute loop
`adapters/loop.md`.

## Effort
`[models] default_reasoning_effort` in `~/.grok/config.toml` or `--reasoning-effort` (`low|medium|high|xhigh`); Mew sets it. Suggest `xhigh` for interview, plan, and the Tier-2 gate, `high` for Step 4.

## Heavier review
No ultracode equivalent: dispatch two heavy-tier reviewers with adversarial prompts (correctness, security) and adjudicate. Suggest it to Mew with the trigger named.

## Security review
No built-in command: dispatch `mew-reviewer` with a security-focused prompt over the review package.

## Models (Mew's decision 2026-09-02)
One model for every role — **grok-4.6** — flat-rate subscription; tiering by the `effort:` line in each `~/.grok/agents/mew-*.md`. grok-4.5 and grok-build exist (`~/.grok/models_cache.json`, config) if that changes.

| Role | Agent | Model | Effort |
|------|-------|-------|--------|
| Session | — | grok-4.6 | xhigh / high in Step 4 |
| Heavy code | `mew-worker-heavy` | grok-4.6 | xhigh |
| Default worker | `mew-worker` | grok-4.6 | high |
| Mechanical | `mew-worker-mech` | grok-4.6 | medium |
| Tier-1 review | `mew-reviewer` | grok-4.6 | high |
| Critic | `mew-critic` | grok-4.6 | high |
