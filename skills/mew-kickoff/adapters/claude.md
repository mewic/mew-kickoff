# Adapter: Claude Code

Read this when the harness is Claude Code (the system prompt says so). Everything here is Claude-specific; interview/plan are in `SKILL.md`, execute is in `execute.md`.

## Loading skills
- Use the Skill tool: `grilling`, then `domain-modeling` (Step 2); `superpowers:writing-plans` for the plan format (Step 3). All are model-invoked. Never point at a user-invoked skill — the Skill tool refuses those.

## Agents and dispatch
- Definitions: `~/.claude/agents/mew-{worker,worker-heavy,worker-mech,reviewer,critic}.md`, model + effort in frontmatter. **Edits to these files take effect in new sessions only.** For a model+effort combo none of the five covers, add a sixth file; never edit an existing one while sessions run on this machine.
- Dispatch with the Agent tool, `subagent_type` = the agent name. mew-* agents take model + effort from frontmatter; **every built-in dispatch (Explore, Plan, general-purpose) must pass `model`** — an omitted model inherits the session model. The read-only explorer for Step 4 is `Explore` with `model: sonnet`.
- Research (Step 2 AFK) and marketing production use `mew-worker`.
- Whole-branch reviewer: standard medium-risk review uses `mew-reviewer`; high-risk/high-assurance uses `mew-reviewer` with `model: opus` because a call-site model overrides the agent file.

## Execute loop: superpowers:subagent-driven-development (SDD)
SDD owns Setup, workspace/ledger, implementer dispatch, review-package mechanics, and the breaker. `standard` stops automatic fixes at round 2; `high-assurance` may use SDD's five. `execute.md`'s proportional gates override SDD where they differ:
1. Implementer = the Execution Directive agent as `subagent_type` (SDD's tiers: cheap = mech, standard = worker, most capable = heavy).
2. Task review = `mew-reviewer`, running task-scoped checks independently. Medium risk adds whole-branch review on Sonnet; high risk/high-assurance uses Opus and security review. Low risk skips whole-branch review.
3. Only high-confidence medium/high findings enter automatic fixes; escalation at rounds 4–5 = next agent tier.
4. Parallel frontier dispatch overrides SDD's one-implementer-at-a-time rule (Blocked-by column carries the conflict guard).
5. The complete build/test suite runs once after task fixes; successful logs are summarized instead of pasted.
Full reports go in the plan's SDD workspace.

## Fresh session
Interview ends at the approval gate. Execute is a new Claude Code session starting with `mew-kickoff execute <plan-path>`.

## Effort
`/effort`: `max` for interview, plan, and the Tier-2 gate; suggest `high` for Step 4 at the approval gate and at the start of an execute session; suggest `max` again before the Tier-2 gate. Only Mew switches.

## Heavier review
`/effort ultracode` — read `../ultracode.md` for the four triggers; the session suggests, naming the trigger; only Mew switches.

## Security review
Invoke the `security-review` skill when Step 5 calls for it. In a repo with no git remote it fails (known limitation) — dispatch the `code-reviewer` agent (`~/.claude/agents/code-reviewer.md`) with `model: opus` and a security-focused prompt instead.

## Models (2026-09)
Current top available model: **Fable 5.1** (alias `fable`). When a new top model ships, update this line and the agent frontmatter only.

| Role | Agent | Model | Effort |
|------|-------|-------|--------|
| Session: interview, plan, copy, final gate | — | Fable 5.1 | max |
| Session: routing in Step 4 | — | Fable 5.1 | high |
| Adversarial review | — | Fable 5.1 | ultracode |
| Heavy code | `mew-worker-heavy` | Opus 5.5 (`opus`) | xhigh |
| Default worker | `mew-worker` | Sonnet 5 (`sonnet`) | high |
| Mechanical | `mew-worker-mech` | Haiku 4.5 (`haiku`) | — |
| Tier-1 / standard branch review | `mew-reviewer` | Sonnet 5 | high |
| High-assurance branch review | `mew-reviewer` override | Opus 5.5 | high |
| Critic | `mew-critic` | Opus 5.5 | high |
