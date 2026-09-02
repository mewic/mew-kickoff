# mew-kickoff improvement plan (Phases 1, 2, 3, 5 now; Phase 4 research now, split later)

**Goal:** make `~/.claude/skills/mew-kickoff/SKILL.md` and `~/.claude/agents/mew-*.md` say what actually runs (SDD 6.3.0 overlay, working interview entry), cut session overhead (fresh execute session, reports as files, pinned models, effort hint), add the cheapest quality gates (plan critic, TDD, constraints lens), and guard against upstream drift (smoke script).

**Decisions locked with Mew 2026-09-02:** SDD 5 rounds + breaker; mew-reviewer keeps running build+tests (deliberate override of SDD's template); Claude execute loop stays on superpowers SDD; Phase 4 = research now, core/adapter split in a later session.

**Routing:** all edits are session-inline (prose). Gate = mew-critic vs the Acceptance Criteria below, then session final gate. Verification is grep/script based: `~/.claude` is not a git repo.

## Execution Directive
| # | Task | Agent | Mode | Blocked by | Review gates |
|---|------|-------|------|-----------|--------------|
| 1 | Rewrite SKILL.md (Step 2 pointer, Step 4/5 SDD overlay, $ARGUMENTS, model pinning, report rules, effort hint, plan critic, TDD/constraints, rubric line, description, red flags) | (session) | inline | — | smoke.sh + critic |
| 2 | Update 5 agent files (report rule; TDD in worker/heavy; reviewer inputs; critic without Bash) | (session) | inline | — | critic |
| 3 | scripts/smoke.sh + archive stale plan | (session) | inline | — | script runs green |
| 4 | Research Codex/Grok subagent + skill formats | mew-worker | subagent | — | file exists with citations |
| 5 | Dry-run the new wording with a fresh subagent (writing-skills GREEN check) | mew-worker | subagent | 1,2 | session reads result |
| 6 | Trim memory `mew-kickoff-workflow.md` to pointer + why; mark audit memory fixed; update HANDOFF.md | (session) | inline | 1,2,3 | — |

## Acceptance Criteria
- [ ] SKILL.md never mentions `grill-with-docs`; Step 2 tells the session to call `grilling` then `domain-modeling` via the Skill tool and states the one-question-at-a-time override explicitly.
- [ ] Step 4/5 state that superpowers:subagent-driven-development owns the loop (ledger, review-package, 5 rounds + breaker, whole-branch review) and list exactly the mew-kickoff overrides: implementer agents from the Execution Directive, task reviewer = mew-reviewer which runs build+tests by design, escalation by agent tier (mech → worker → heavy), parallel frontier dispatch (declared override of SDD's one-at-a-time rule, justified by the Blocked-by column).
- [ ] Step 4 requires `model` on every Agent call including built-in agents, and replaces the "temporarily edit ~/.claude/agents" hack with "add a sixth agent file".
- [ ] Modes uses `$ARGUMENTS` and describes execute-in-a-fresh-session as the intended path.
- [ ] Approval gate suggests Mew switch `/effort high` for Step 4 and back to max for the final gate; phrased as a suggestion Mew makes.
- [ ] Subagent report rule present in SKILL.md and in all five agent files: ≤150-word chat summary + full report written to a file path.
- [ ] Plans with more than 5 tasks get a mew-critic pre-flight before the approval gate.
- [ ] mew-worker and mew-worker-heavy carry a tests-first rule; mew-reviewer receives the review package + Global Constraints verbatim; mew-critic's `tools` no longer includes Bash.
- [ ] Security-review fallback for repos without a git remote is in SKILL.md.
- [ ] Rubric line names Fable 5.1; description is a one-line human-facing summary.
- [ ] No stale plan file inside the skill directory; `scripts/smoke.sh` exists, is executable, and exits 0.
- [ ] SKILL.md word count does not exceed 2,250 (cap raised from 2,150 after critic round 1 added override #4, the whole-branch reviewer, Mode vocabulary, and effort choreography; map + ultracode reference disclosed to sibling files).
- [ ] Every existing rule that was kept (off-ramp, recon, map, facts vs decisions, AFK research, vertical slices, Blocked-by, approval gate, ultracode triggers, document conventions, language rules) is still present with unchanged meaning.

## Phase 4 (added 2026-09-02 after Mew asked to finish everything in this session)

Decisions: source of truth stays `~/.claude/skills/mew-kickoff/`, symlinked into `~/.agents/skills/` (Codex + Grok) and `~/.grok/skills/`; one model per vendor (Codex = gpt-5.6-sol, Grok = grok-4.6), tiering by effort; Grok adapter shipped PARTIAL with UNVERIFIED items explicit.

| # | Task | Agent | Mode | Blocked by | Review gates |
|---|------|-------|------|-----------|--------------|
| 7 | Harness-neutral core SKILL.md + adapters/{claude,codex,grok,loop}.md + agents/openai.yaml | (session) | inline | 4 | smoke + critic |
| 8 | Codex agent TOMLs (5) + symlinks | (session) | inline | 4 | smoke + headless discovery run |
| 9 | smoke.sh covering core neutrality + 3 harnesses | (session) | inline | 7,8 | exits 0 |
| 10 | Dry-run of the Claude path on the split skill | general-purpose (sonnet) | subagent | 7 | session reads result |
| 11 | Critic round 3 vs Phase 4 criteria | mew-critic | subagent | 7,8,9 | session final gate |

Phase 4 acceptance criteria:
- [ ] SKILL.md is harness-neutral (no `Skill tool`, `subagent_type`, `superpowers:`, `/effort`, `/security-review`), ≤2,100 words, and tells the session to read its adapter before Step 0.
- [ ] adapters/claude.md carries every Claude-specific rule removed from SKILL.md: Skill tool names, Agent tool + `subagent_type`, built-in model pinning, SDD overlay with the four declared overrides, effort choreography, ultracode pointer, security-review + no-remote fallback, model table (Fable 5.1 / Opus 5 / Sonnet 5 / Haiku 4.5), agent-edit-needs-new-session note.
- [ ] adapters/codex.md: skills load from `~/.agents/skills`, `spawn_agent` family, `~/.codex/agents/*.toml`, loop.md, one model gpt-5.6-sol with effort tiers, UNVERIFIED items marked.
- [ ] adapters/grok.md: marked PARTIAL; every UNVERIFIED item has a fallback; one model grok-4.6.
- [ ] adapters/loop.md mirrors SDD's shape: ledger, per-task review package, 5 rounds (1–3 resume, 4–5 tier up), breaker adjudication, whole-branch review, one fix wave, session gate.
- [ ] Five `~/.codex/agents/mew-*.toml` parse and mirror the Claude agent bodies (tests-first in worker/heavy, 150-word report rule in all, critic read-only by instruction).
- [ ] `agents/openai.yaml` present with interface + `policy.allow_implicit_invocation: false`.
- [ ] Symlinks resolve; smoke.sh passes; Codex and Grok headless runs each list mew-kickoff as an available skill (or the failure is recorded).
- [ ] Every "adapter's …" reference in SKILL.md (skill loading, agent definitions, execute loop, Step-4 effort, security review, escalation, model table) resolves to a section in each adapter; no contradiction between core and any adapter.

## Out of scope
- (none left — Grok agent definitions were created 2026-09-03 after the format was found locally)
- Changing the model economy or the five-agent set.

## Status
interviewed 2026-09-02 (audit + 4 decisions; Phase 4 added same day at Mew's request, one-model-per-vendor decided mid-run) | approved: 2026-09-02 | executed: 2026-09-03 (Tasks 1–11; smoke PASS 51 ok at 2,140 core words; dry-runs 12/12 twice; critic rounds 1–3 PASS with fixes folded in; Codex `$mew-kickoff` and Grok `/mew-kickoff` headless loads verified) | delivered: 2026-09-03 — all phases live incl. Grok native agents (`~/.grok/agents/mew-*.md`, format taken from Grok's bundled agents, all five listed by spawn_subagent headlessly; smoke 55 ok); Grok per-agent `effort:` verified live (mew-worker-mech child at medium, parent at low); open: first real pipeline run on Codex and on Grok
