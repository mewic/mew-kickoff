# Adapter: Claude Code

Read this when the harness is Claude Code (the system prompt says so). Everything here is Claude-specific; the process is in `SKILL.md`.

## Loading skills
- Use the Skill tool: `grilling`, then `domain-modeling` (Step 2); `superpowers:writing-plans` for the plan format (Step 3). All are model-invoked. Never point at a user-invoked skill — the Skill tool refuses those.

## Agents and dispatch
- Definitions: `~/.claude/agents/mew-{worker,worker-heavy,worker-mech,reviewer,critic}.md`, model + effort in frontmatter. **Edits to these files take effect in new sessions only.** For a model+effort combo none of the five covers, add a sixth file; never edit an existing one while sessions run on this machine.
- Dispatch with the Agent tool, `subagent_type` = the agent name. mew-* agents take model + effort from frontmatter; **every built-in dispatch (Explore, Plan, general-purpose) must pass `model`** — an omitted model inherits the session model. The read-only explorer for Step 4 is `Explore` with `model: sonnet`.
- Research (Step 2 AFK) and marketing production use `mew-worker`.
- Heavy-tier reviewer (very complex diffs): `mew-reviewer` with `model: opus` — a call-site `model` overrides the agent file, so no sixth file is needed.

## Execute loop: superpowers:subagent-driven-development (SDD)
SDD owns the loop: its Setup (worktree, per-plan workspace via `scripts/sdd-workspace`, ledger, pre-flight review), implementer dispatch, review package (`scripts/review-package`), fix rounds (five max, then the breaker), and the final whole-branch review. SKILL.md's four rules are the declared overrides of SDD:
1. Implementer = the Execution Directive agent as `subagent_type` (SDD's tiers: cheap = mech, standard = worker, most capable = heavy).
2. Reviewers: task review = `mew-reviewer` (it re-runs build + tests — a deliberate override of SDD's reviewer template); whole-branch review = SDD's `requesting-code-review/code-reviewer.md` template on `general-purpose` with `model: opus`, not the session model.
3. Escalation at rounds 4–5 = next agent tier.
4. Parallel frontier dispatch overrides SDD's one-implementer-at-a-time rule (Blocked-by column carries the conflict guard).
Full reports go in the plan's SDD workspace.

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
| Heavy code | `mew-worker-heavy` | Opus 5 (`opus`) | xhigh |
| Default worker | `mew-worker` | Sonnet 5 (`sonnet`) | high |
| Mechanical | `mew-worker-mech` | Haiku 4.5 (`haiku`) | — |
| Tier-1 review | `mew-reviewer` | Sonnet 5 | high |
| Critic | `mew-critic` | Opus 5 | high |
