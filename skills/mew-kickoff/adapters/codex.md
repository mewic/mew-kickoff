# Adapter: OpenAI Codex CLI (0.152+)

Read this when the harness is Codex. Status 2026-09-02: skills path and agent format verified from Codex docs; one model for all roles by Mew's decision.

## Loading skills
- Personal skills load from `~/.agents/skills/` (not `~/.codex/skills/`); this skill is symlinked there. Users invoke it as `$mew-kickoff` or via `/skills`; implicit invocation is off through `agents/openai.yaml`.
- To load `grilling`, `domain-modeling`, or any other skill: read `~/.agents/skills/<name>/SKILL.md` and follow it. There is no plan-format skill here — the template in SKILL.md is the format.
- `$ARGUMENTS` substitution is UNVERIFIED in Codex: treat the text the user typed after `$mew-kickoff` as the arguments.

## Agents and dispatch
- Definitions: `~/.codex/agents/mew-{worker,worker-heavy,worker-mech,reviewer,critic}.toml` (fields `name`, `description`, `developer_instructions`, `model`, `model_reasoning_effort`, `sandbox_mode`). Edit those to change model or effort.
- Dispatch with the `multi_agent` tools: `spawn_agent` (name the agent), `send_input` / `resume_agent` for fix rounds 1–3, `wait_agent`, `close_agent`. The `multi_agent` feature flag (`codex features list`) is what enables them and what smoke.sh checks; the `[agents]` block only sets defaults and concurrency — add it if `spawn_agent` is missing despite the flag:
  ```toml
  [agents]
  enabled = true
  max_concurrent_threads_per_session = 8
  ```
- Built-in agents: `default`, `worker`, `explorer`. The read-only explorer for Step 4 is `explorer`. Pass a model explicitly when spawning a built-in; otherwise `agents.default_subagent_model` applies.
- Heavy-tier reviewer (very complex diffs): all roles share one model, so heavy = effort. Spawn `mew-reviewer` and request `model_reasoning_effort = "xhigh"` if the spawn call accepts an override; otherwise its file's `high` stands.

## Execute loop
`adapters/loop.md`. Whole-branch review = `mew-reviewer` at heavy tier as loop.md says. (`codex review` exists as a CLI command; whether it accepts a diff range is UNVERIFIED.)

## Effort
Session effort = `model_reasoning_effort` in `~/.codex/config.toml` or `/model` in the TUI; Mew sets it. Suggest `xhigh` for interview, plan, and the Tier-2 gate, `high` for Step 4. Codex also accepts `ultra` per agent.

## Heavier review
No ultracode equivalent: spawn two heavy-tier reviewers with adversarial prompts (one hunting correctness, one hunting security) and let the session adjudicate. Suggest it to Mew with the trigger named.

## Security review
No built-in command: spawn `mew-reviewer` on the heavy tier with a security-focused prompt (boundaries, secrets, least privilege, injection) over the review package.

## Models (Mew's decision 2026-09-02)
One model for every role — **gpt-5.6-sol** — because the Codex subscription is flat-rate and the smaller OpenAI models are not a clear step down in cost for Mew. The model economy's tiering is carried by **effort** instead. Other models in `~/.codex/models_cache.json` (gpt-5.6-luna/terra, gpt-5.5, gpt-5.4, gpt-5.4-mini, gpt-5.3-codex-spark) are available if that changes: edit the `model` line in each `~/.codex/agents/mew-*.toml`.

| Role | Agent | Model | Effort |
|------|-------|-------|--------|
| Session | — | gpt-5.6-sol | xhigh / high in Step 4 |
| Heavy code | `mew-worker-heavy` | gpt-5.6-sol | xhigh |
| Default worker | `mew-worker` | gpt-5.6-sol | high |
| Mechanical | `mew-worker-mech` | gpt-5.6-sol | medium |
| Tier-1 review | `mew-reviewer` | gpt-5.6-sol | high |
| Critic | `mew-critic` | gpt-5.6-sol | high |
