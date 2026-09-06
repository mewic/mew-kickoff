# Adapter: Cursor (IDE agent)

Read this when the harness is Cursor — the system prompt names Cursor, or the `Task` tool exists and `spawn_subagent` / `spawn_agent` / the Skill tool do not. Status 2026-09-06: skill files are readable via Read; custom `~/.cursor/agents/mew-*.md` exist as role contracts; `Task` accepts only its built-in `subagent_type` enum, so roles are applied through the prompt, not the type name.

## Loading skills
- This skill is symlinked at `~/.cursor/skills/mew-kickoff`. Invoke it by name (`mew-kickoff`); model-invocation is disabled.
- Load `grilling`, `domain-modeling`, or another named skill by reading `~/.agents/skills/<name>/SKILL.md` (fallback `~/.claude/skills/<name>/SKILL.md`) and following it. The plan template in `SKILL.md` is the plan format. Execute mode then reads `../execute.md`.
- Arguments: the text after the skill name.

## Agents and dispatch
- Role contracts: `~/.cursor/agents/mew-{worker,worker-heavy,worker-mech,reviewer,reviewer-heavy,critic}.md`. They are not valid `Task` `subagent_type` values.
- Dispatch recipe:
  1. `Task` with `subagent_type` = `generalPurpose` for implement / review / critic, or `explore` for the read-only Step-4 explorer.
  2. `model` from the table below. Use only slugs the `Task` tool lists. `inherit` keeps this chat's model.
  3. Prompt, in order: "Follow `~/.cursor/agents/<role>.md` as your system contract." Then the complete task spec or exact file paths (plan, brief, report path, review package, Global Constraints). Demand a ≤150-word reply and a report file.
- Fix rounds: `Task` `resume` on the same implementer id with a bounded fix brief. If resume is unavailable, spawn the same role again with that brief.
- Parallel frontier: several `Task` calls in one message. Cap live children at 2 unless Mew raises it; extra frontier work waits for the next wave.
- Research (Step 2 AFK) and marketing production use the `mew-worker` contract via `generalPurpose`.

## Execute loop
`adapters/loop.md`. Standard medium-risk whole-branch review uses `mew-reviewer`; high-assurance or high-risk whole-branch/security review uses `mew-reviewer-heavy`.

## Effort and usage
Cursor has no `/effort` switch. Session cost is the model Mew picked for this chat. Suggest Grok for interview, plan, and the execute chat; do not switch the session to Sol.

Record child-run count in the ledger before execute, after every frontier wave, and before Tier 2. At the plan's agent-run or fix-round ceiling, stop automatic expansion and let the session rule on the smallest path to acceptance.

## Heavier review
No ultracode. Suggest two `generalPurpose` children on `mew-reviewer-heavy` (correctness, security) and adjudicate. Name the trigger; only Mew launches them.

## Security review
`Task` `security-review` when Step 5 calls for it. If that type is unavailable, one `generalPurpose` child on `mew-reviewer-heavy` with a security brief over the review package.

## Fresh session
Interview ends at the approval gate. Execute is a **new Cursor chat** whose first message is `mew-kickoff execute <plan-path>`. If Mew says execute in the interview chat, stop and hand back that first message.

## Models (2026-09)

| Role | How | Model |
|------|-----|-------|
| Session: interview, plan, copy, Tier 2 | this chat | inherit (Grok 4.6 when that is the chat model) |
| Session: Step-4 routing | execute chat | inherit |
| Heavy code | `Task` + `mew-worker-heavy` | inherit |
| Default worker / research | `Task` + `mew-worker` | inherit |
| Mechanical | `Task` + `mew-worker-mech` | composer-2.5-fast |
| Tier-1 / standard branch review | `Task` + `mew-reviewer` | inherit |
| High-assurance / security review | `Task` + `mew-reviewer-heavy` | inherit |
| Critic | `Task` + `mew-critic` | inherit |
| Read-only explorer | `Task` `explore` | composer-2.5-fast |
