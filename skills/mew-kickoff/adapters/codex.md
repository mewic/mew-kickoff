# Adapter: OpenAI Codex CLI (0.153+)

Read this when the harness is Codex. Status 2026-09-04: skill path, native agent format, collaboration tools, fresh-context control, and model routing verified against the installed harness and official OpenAI guidance.

## Loading skills
- Personal skills load from `~/.agents/skills/`; this skill is symlinked there. Invoke it as `$mew-kickoff` or through `/skills`. Implicit invocation is disabled in `agents/openai.yaml`.
- Load `grilling`, `domain-modeling`, or another named skill by reading `~/.agents/skills/<name>/SKILL.md` completely and following it. The template in `SKILL.md` is the plan format.
- `$ARGUMENTS` substitution is unverified. Treat text after `$mew-kickoff` as the arguments.

## Agents and fresh dispatch
- Base definitions: `~/.codex/agents/mew-{worker,worker-heavy,worker-mech,reviewer,critic}.toml`. Conditional heavy review: `~/.codex/agents/mew-reviewer-heavy.toml`.
- Current collaboration tools are `spawn_agent`, `followup_task`, `send_message`, `wait_agent`, `interrupt_agent`, and `list_agents`. Use `followup_task` to resume the same implementer or reviewer for a fix round. If it is no longer reusable, spawn the same role again with the bounded fix brief.
- **Every worker, reviewer, critic, and explorer spawn sets `fork_turns="none"`.** The default full-history fork violates this pipeline's context economy and critic independence. Put the complete task/criteria in the prompt or give exact paths to the plan, report, and review package.
- Built-ins are `default`, `worker`, and `explorer`. Use `explorer` with `fork_turns="none"`, `model="gpt-5.6-terra"`, and medium effort for read-only Step-4 questions.
- Fill only the live concurrency slots reported by the harness. The root session occupies one slot; if the frontier is wider, dispatch it in waves. Parallelism changes elapsed time, not the review requirements.
- Agent files are read at session start. Open a new session after changing them.

## Execute loop
Read `adapters/loop.md`. Standard medium-risk whole-branch review uses `mew-reviewer`; high-assurance or high-risk whole-branch/security review uses `mew-reviewer-heavy`.

## Effort and usage
Session effort comes from `model_reasoning_effort` in `~/.codex/config.toml` or `/model` in the TUI. Suggest `xhigh` for interview, plan, and Tier 2; `high` for Step 4. Mew performs the switch.

When available, capture `/status` or the usage dashboard value before execution, after every frontier wave, and before Tier 2. Record it in the ledger. Usage is a guardrail, not a reason to skip an acceptance criterion; at the declared budget ceiling, stop automatic agent expansion and let the session rule on the smallest safe path.

## Heavier and security review
- Heavier review: dispatch two `mew-reviewer-heavy` agents with `fork_turns="none"` and independent prompts—one correctness-focused, one security-focused—then let the session adjudicate. Suggest this only when a trigger in `../ultracode.md` applies.
- Security review: dispatch `mew-reviewer-heavy` with `fork_turns="none"` and a security brief covering boundaries, secrets, least privilege, injection, and abuse cases.

## Models (2026-09)
Match model capability to the role. OpenAI's current [model guidance](https://learn.chatgpt.com/docs/agent-configuration/subagents) positions Terra for everyday production/review and Luna for narrow high-volume work; reserve Sol for the hardest judgment. Re-check the [usage rates](https://learn.chatgpt.com/docs/pricing) when changing this table.

| Role | Agent | Model | Effort |
|------|-------|-------|--------|
| Session: interview, plan, Tier 2 | — | gpt-5.6-sol | xhigh |
| Session: Step-4 routing | — | gpt-5.6-sol | high |
| Heavy/security code | `mew-worker-heavy` | gpt-5.6-sol | xhigh |
| Default production/research | `mew-worker` | gpt-5.6-terra | high |
| Mechanical | `mew-worker-mech` | gpt-5.6-luna | medium |
| Task/standard branch review | `mew-reviewer` | gpt-5.6-terra | high |
| High-risk/security review | `mew-reviewer-heavy` | gpt-5.6-sol | xhigh |
| Critic | `mew-critic` | gpt-5.6-terra | high |
| Read-only explorer | built-in `explorer` | gpt-5.6-terra | medium |
