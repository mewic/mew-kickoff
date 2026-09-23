# Adapter: xAI Grok CLI (1.0.30+)

Read this when the harness is Grok CLI (not Cursor). Status 2026-09-13: skill loading, agent format, per-agent effort, and `spawn_subagent` verified; overlays below match 1.0.30 (`isolation`, `resume_from`, `/usage`). Session default effort belongs at `high`; `xhigh` is reserved for plan synthesis and Tier 2.

## Loading skills
- Grok loads `~/.grok/skills/` and `~/.agents/skills/`; this skill is symlinked into `~/.grok/skills/`. It honors `disable-model-invocation`, so only Mew starts it: `/mew-kickoff` (verified headless).
- To load `grilling`, `domain-modeling`, or any other skill: read `~/.agents/skills/<name>/SKILL.md` and follow it. The plan template in `SKILL.md` is the plan format. Execute mode then reads `../execute.md`.
- Argument substitution is UNSURE: treat the text after the skill name as the arguments.

## Agents and dispatch
- Base definitions: `~/.grok/agents/mew-{worker,worker-heavy,worker-mech,reviewer,critic}.md`; conditional heavy review: `mew-reviewer-heavy.md`. They use Markdown + YAML frontmatter in Grok's native agent format. Project-scoped `.grok/agents/` overrides user-scoped. The native files are the source here.
- Every `mew-*` agent sets `mcpInheritance: none` so children do not load the parent's MCP tool schemas.
- Dispatch with the `spawn_subagent` tool: `subagent_type` = the agent name, `prompt` = the complete task spec, `description` = a 3–5 word label; optional `background`, `isolation` (`none` | `worktree`), `model`, `cwd`, `resume_from`. Background results come back through `get_command_or_subagent_output`.
- Built-ins: `general-purpose`, `explore` (read-only — the Step 4 explorer), `plan`. Pass `model` when spawning a built-in. On `explore` pass `model: grok-4.5` even if the spawn schema says to omit it — otherwise the child inherits the session model.
- Critic and reviewer tool allowlists live in the agent files (critic: no shell; reviewers: Bash+Write, no Edit).
- Effort per agent: the `effort:` frontmatter key is applied to the child session (verified). Resolution order is spawn-time override, role, persona, then parent; because `spawn_subagent` has no effort parameter, high-assurance review uses `mew-reviewer-heavy` (`xhigh`).
- `/fork` branches the session; it is not a subagent. Personas (`/personas`) are tone overlays, not roles.
- Fill only a few live slots (2 unless Mew raises it). A wider frontier goes in waves.
- Manage definitions in the TUI with `/config-agents` (alias `/agents`); edits to `~/.grok/agents/*.md` are picked up by discovery at session start.

## Execute loop
`adapters/loop.md`. Grok overlays on that loop:

- Pipeline mode stays normal: interview, the plan file, and the approval gate are this skill. Skip `enter_plan_mode`.
- Frontier implementers spawn with `isolation: worktree`. Apply the child's worktree into the parent before writing the review package. Reviewers, critics, and explorers stay `isolation: none`.
- Fix round: `resume_from` the same implementer id with the bounded fix brief. If that id is gone, spawn the same role fresh with that brief.
- High-assurance rounds 4–5 still spawn a fresh implementer one tier up (no `resume_from`).

## Effort and usage
`[models] default_reasoning_effort` in `~/.grok/config.toml` or `--reasoning-effort` (`low|medium|high|xhigh`); Mew sets it. Suggest `high` for interview and Step 4, `xhigh` only for the plan-synthesis turn and the Tier-2 gate.

Record `/usage` (session totals) or `/session-info` in the ledger before execute, after every frontier wave, and before Tier 2. At the plan's agent-run or fix-round ceiling, stop automatic expansion and let the session rule on the smallest path to acceptance.

## Heavier review
No ultracode equivalent: suggest two heavy-tier reviewers with adversarial prompts (correctness, security) and adjudicate. Name the trigger; only Mew launches them.

## Security review
No built-in command: dispatch `mew-reviewer-heavy` with a security-focused prompt over the review package.

## Fresh session
Interview ends at the approval gate. Execute is a new Grok session: `/mew-kickoff execute <plan-path>`. If Mew says execute in the interview session, stop and hand back that command.

## Models (2026-09-13)
Tier by model and effort. grok-4.5 has no `xhigh`; use it for mechanical and explore work.

| Role | Agent | Model | Effort |
|------|-------|-------|--------|
| Session: interview, Step 4 routing | — | grok-4.6 | high |
| Session: plan synthesis, Tier 2 | — | grok-4.6 | xhigh |
| Heavy code | `mew-worker-heavy` | grok-4.6 | xhigh |
| Default worker | `mew-worker` | grok-4.6 | high |
| Mechanical | `mew-worker-mech` | grok-4.5 | low |
| Tier-1 review | `mew-reviewer` | grok-4.6 | high |
| High-assurance review | `mew-reviewer-heavy` | grok-4.6 | xhigh |
| Critic | `mew-critic` | grok-4.6 | high |
| Read-only explorer | built-in `explore` | grok-4.5 | low |
