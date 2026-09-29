# Adapter: xAI Grok CLI (1.0.44+)

Read this when the harness is Grok CLI (not Cursor). Status 2026-09-29, checked on Grok 1.0.44: `spawn_subagent` accepts `prompt`, `description`, `background`, `isolation` (`none` | `worktree`), `resume_from`, and `cwd`. An omitted type is general-purpose, at the parent model and effort. The schema has no `model` field, so the execute.md red flag about a dispatch without a model does not apply.

## Loading skills
- Grok loads `~/.grok/skills/` and `~/.agents/skills/`; this skill is symlinked into `~/.grok/skills/`. It honors `disable-model-invocation`, so only Mew starts it: `/mew-kickoff`.
- To load `grilling`, `domain-modeling`, or any other skill: read `~/.agents/skills/<name>/SKILL.md` and follow it. The plan template in `SKILL.md` is the plan format. Execute mode then reads `../execute.md`.
- Arguments are the text after the skill name.

## Agents and dispatch
- Role contracts: `~/.grok/agents/mew-{worker,worker-heavy,worker-mech,reviewer,reviewer-heavy,critic}.md`. `grok --agent <name>` loads that file, including its `effort:` and `tools:`. A spawned child does not.
- Spawn fields are only the six above. `description` starts with `[worker]`, `[worker-heavy]`, `[worker-mech]`, `[reviewer]`, `[reviewer-heavy]`, or `[critic]`.
- `prompt` starts with `Follow ~/.grok/agents/<role>.md as your contract. Read it before acting.` Then the complete task spec or exact file paths, the report path, and a demand for that report plus a reply of at most 150 words.
- `background: true` when more than one child is in flight. Results come back through `get_command_or_subagent_output`.
- Implementers use `isolation: worktree`. Reviewers, critics, and the read-only explorer use `isolation: none`.
- The read-only explorer is general-purpose with a read-only prompt. The built-in `explore` type cannot be named from this schema.
- Fix round: `resume_from` the same implementer id with the bounded fix brief. If that id is gone, spawn the same role fresh with that brief.
- High-assurance rounds 4–5 spawn a fresh child on the `mew-worker-heavy.md` contract, with no `resume_from`. The model stays the parent's.
- Fill only a few live slots (2 unless Mew raises it). A wider frontier goes in waves.
- Spawned children inherit the parent's MCP servers. Keep MCP instructions out of dispatch prompts.

## Execute loop
`adapters/loop.md`. Grok overlays on that loop:

- Pipeline mode stays normal: interview, the plan file, and the approval gate are this skill. Skip `enter_plan_mode`.
- Capture `BASE` in the parent before the first implementer. Where loop.md reads `BASE..HEAD`, run git inside the implementer's worktree. The spawn result names `worktree_path`. Write the review package and read the worker report at absolute paths under that worktree.
  ```
  git fetch <worktree_path> HEAD --no-tags
  git -C <worktree_path> rev-parse HEAD
  git -C <worktree_path> log --oneline BASE..HEAD
  git -C <worktree_path> diff --stat BASE..HEAD
  ```
- Reviewers spawn with `cwd` set to that `worktree_path`. Leave the parent checkout on its current branch.
- After delivery, remove implementer worktrees with `grok worktree rm --force <worktree_path>`.

## Effort and usage
Children inherit the session effort. `effort:` in a role file applies only to `grok --agent <role>`. Suggest `high` for interview and Step 4 routing, and `xhigh` only for the plan-synthesis turn and the Tier-2 gate. A mechanical task runs at the session effort, so keep its prompt to the contract plus the file list.

Record `/usage` (session totals) in the ledger before execute, after every frontier wave, and before Tier 2. At the plan's agent-run or fix-round ceiling, stop automatic expansion and let the session rule on the smallest path to acceptance.

## Heavier review
No ultracode equivalent: suggest two children on the `mew-reviewer-heavy` contract with adversarial prompts (correctness, security) and adjudicate. Name the trigger; only Mew launches them.

## Security review
No built-in command: one child on the `mew-reviewer-heavy` contract with a security-focused prompt and `cwd` on the implementer worktree.

## Fresh session
Interview ends at the approval gate. Execute is a new Grok session: `/mew-kickoff execute <plan-path>`. If Mew says execute in the interview session, stop and hand back that command.

## Models (2026-09-29)
One model line: `grok-4.7-build-fast`. Spawn does not select a model or an effort. The contract text is the role.

| Role | Contract | Spawn |
|------|----------|-------|
| Session: interview, Step 4 routing | — | parent, effort high |
| Session: plan synthesis, Tier 2 | — | parent, effort xhigh |
| Heavy code | `mew-worker-heavy.md` | general-purpose, worktree |
| Default worker | `mew-worker.md` | general-purpose, worktree |
| Mechanical | `mew-worker-mech.md` | general-purpose, worktree |
| Tier-1 review | `mew-reviewer.md` | general-purpose, cwd = worktree |
| High-assurance review | `mew-reviewer-heavy.md` | general-purpose, cwd = worktree |
| Critic | `mew-critic.md` | general-purpose, isolation none |
| Read-only explorer | read-only prompt | general-purpose, isolation none |
