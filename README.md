# mew-kickoff

Mew's interview-to-delivery pipeline skill, runnable on **Claude Code**, **OpenAI Codex CLI**, and **xAI Grok CLI** from one source tree. Private.

The session model interviews, specs, routes, and reviews; five worker/reviewer/critic agents produce. The process is harness-neutral (`skills/mew-kickoff/SKILL.md`); everything CLI-specific lives in `skills/mew-kickoff/adapters/`.

## Layout

```
skills/mew-kickoff/        the skill: SKILL.md (core), adapters/{claude,codex,grok,loop}.md,
                           map.md, ultracode.md, agents/openai.yaml (Codex sidecar), scripts/smoke.sh
agents/claude/mew-*.md     Claude Code agent definitions (model + effort in frontmatter)
agents/codex/mew-*.toml    Codex agent definitions (all gpt-5.6-sol, tiered by effort)
agents/grok/mew-*.md       Grok agent definitions (all grok-4.6, tiered by effort)
docs/                      improvement plan, critic reports, cross-CLI verification, research, handoff
scripts/                   token/cost measurement over ~/.claude/projects transcripts
install.sh                 symlinks the above into ~/.claude, ~/.agents, ~/.codex, ~/.grok
```

## Install

```bash
git clone <this repo> ~/projects/mew-kickoff && ~/projects/mew-kickoff/install.sh
```

Then open a **new** session in each CLI (skills and agents load at session start) and verify:

```bash
bash ~/projects/mew-kickoff/skills/mew-kickoff/scripts/smoke.sh
```

Invoke: `/mew-kickoff` (Claude Code, Grok) or `$mew-kickoff` (Codex); resume an approved plan with `execute <plan-file>`. The skill is user-invoked only on all three CLIs.

## Editing

Edit files here; the CLIs see them through the symlinks. Re-run `smoke.sh` after any CLI or plugin update — it checks every pointer the skill depends on (superpowers SDD files, agent files, symlinks, word cap, harness-neutral core). Two facts to keep in mind:

- Agent-file edits apply to **new** sessions only, on every CLI.
- The Claude execute loop is `superpowers:subagent-driven-development`; Codex and Grok use `adapters/loop.md`.

## Model decisions (2026-09)

| Role | Claude Code | Codex | Grok |
|---|---|---|---|
| session | Fable 5.1, max (high in Step 4) | gpt-5.6-sol, xhigh | grok-4.6, xhigh |
| mew-worker-heavy | Opus 5, xhigh | gpt-5.6-sol, xhigh | grok-4.6, xhigh |
| mew-worker | Sonnet 5, high | gpt-5.6-sol, high | grok-4.6, high |
| mew-worker-mech | Haiku 4.5 | gpt-5.6-sol, medium | grok-4.6, medium |
| mew-reviewer | Sonnet 5, high | gpt-5.6-sol, high | grok-4.6, high |
| mew-critic | Opus 5, high | gpt-5.6-sol, high | grok-4.6, high |

Why one model per vendor on Codex/Grok: flat-rate subscriptions; the model economy's tiering is carried by effort there. See `docs/HANDOFF.md` and `docs/reports/` for the audit that produced this version, including the measured cost profile (session cache reads dominate; worker output is under 1%).
