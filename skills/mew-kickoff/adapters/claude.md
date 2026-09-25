# Adapter: Claude Code

Read this when the harness is Claude Code (the system prompt says so). Everything here is Claude-specific; interview/plan are in `SKILL.md`, execute is in `execute.md` + `adapters/loop.md`.

## Loading skills
- Use the Skill tool: `grilling`, then `domain-modeling` (Step 2). Both are model-invoked. The plan format is the template in `SKILL.md`; no other skill is needed. Never point at a user-invoked skill — the Skill tool refuses those.

## Agents and dispatch
- Definitions: `~/.claude/agents/mew-{worker,worker-heavy,worker-mech,reviewer,critic}.md`, model + effort in frontmatter. **Edits to these files take effect in new sessions only.** For a model+effort combo none of the five covers, add a sixth file; never edit an existing one while sessions run on this machine.
- Dispatch with the Agent tool, `subagent_type` = the agent name. mew-* agents take model + effort from frontmatter; **every built-in dispatch (Explore, Plan, general-purpose) must pass `model`** — an omitted model inherits the session model, the costliest mistake in the 2026-09-24 audit. The read-only explorer for Step 4 is `Explore` with `model: sonnet` (`haiku` for pure lookups).
- Research (Step 2 AFK) and marketing production use `mew-worker`.
- Whole-branch reviewer: standard medium-risk review uses `mew-reviewer`; high-risk/high-assurance uses `mew-reviewer` with `model: opus` because a call-site model overrides the agent file.

## Execute loop
Read `adapters/loop.md`. Claude Code overlays:
- Implementer = the Execution Directive agent as `subagent_type`; frontier tasks run in parallel (the Blocked-by column is the conflict guard). Implementers work in the task's worktree (Orca or `EnterWorktree`); reviewers, critics, and explorers read in place.
- Fix round = a fresh dispatch of the same agent with the bounded fix brief; `SendMessage` may continue a subagent that is still live.
- The session never opens a full report unprompted: read the ≤150-word reply, open the report file only when it flags something.
- Full reports go in `docs/plans/reports/<plan-slug>/`.

## Context
Run on the standard 200K window (`claude-fable-5-1` or `claude-opus-5-5`, never `[1m]`) and let auto-compact run; the plan, ledger, and reports on disk carry state across compactions. `[1m]` only when Mew asks for a whole-codebase audit or a cross-system review that must sit in one window. `/handoff` is for stopping, not for controlling context.

## Fresh session
Interview ends at the approval gate. Execute is a new Claude Code session starting with `mew-kickoff execute <plan-path>`.

## Effort
`/effort`: `max` for interview, plan, and the Tier-2 gate; suggest `high` for Step 4 at the approval gate and at the start of an execute session; suggest `max` again before the Tier-2 gate. Only Mew switches.

## Heavier review
`/effort ultracode` — read `../ultracode.md` for the four triggers; the session suggests, naming the trigger; only Mew switches.

## Security review
Invoke the `security-review` skill when Step 5 calls for it. In a repo with no git remote it fails (known limitation) — dispatch the `code-reviewer` agent (`~/.claude/agents/code-reviewer.md`) with `model: opus` and a security-focused prompt instead.

## Models (2026-09-25)
Usage facts (support.claude.com, "Claude Fable models on your plan"): Fable usage counts against the **same weekly allowance** as Opus/Sonnet/Haiku, the Fable bar is a 50% ceiling inside it, and Fable burns the allowance faster. Fable is therefore never a way to get extra quota; spend it only where judgment compounds.

| Role | Agent | Model | Effort |
|------|-------|-------|--------|
| Session: interview, plan, copy, final gate | — | Opus 5.5 (Fable 5.1 when Mew chooses) | max |
| Session: routing in Step 4 | — | Opus 5.5 | high |
| Adversarial review | — | Fable 5.1 | ultracode |
| Heavy code | `mew-worker-heavy` | Opus 5.5 (`opus`) | xhigh |
| Default worker | `mew-worker` | Sonnet 5 (`sonnet`) | high |
| Mechanical | `mew-worker-mech` | Haiku 4.5 (`haiku`) | — |
| Tier-1 / standard branch review | `mew-reviewer` | Sonnet 5 | high |
| High-assurance branch review | `mew-reviewer` with `model: opus` | Opus 5.5 | high |
| Critic | `mew-critic` | Opus 5.5 | high |

`scripts/agent-models.sh economy|fable` rewrites the five agent files to this table or to all-Fable; open a new session afterwards. When a new top model ships, update this table and the script only.
