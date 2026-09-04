# Codex economy hardening

## Goal
Align the Codex implementation of `mew-kickoff` with its stated effort, context, and review-economy principles while preserving the quality gates that make substantial work reliable.

## Architecture
Keep the harness-neutral workflow in `SKILL.md`, Codex-specific dispatch and model choices in `adapters/codex.md`, shared Codex/Grok execution mechanics in `adapters/loop.md`, and enforce role defaults in native Codex agent TOMLs. Make assurance proportional to risk instead of applying the maximum review stack to every task.

## Global Constraints
- Preserve explicit approval before execution.
- Preserve facts-versus-decisions interviewing, acceptance criteria, vertical slices, independent review, security review, and the final session gate.
- Codex production and review agents start without the parent conversation and receive a complete bounded dispatch.
- Technical documentation remains English; the README remains Thai.
- Do not change Claude or Grok model selections in this change.

## Execution Directive
| # | Task | Agent | Mode | Blocked by | Review gates |
|---|------|-------|------|-----------|--------------|
| 1 | Add risk profiles, execution budgets, and proportional review rules to the core workflow | (session model) | inline | — | smoke + critic |
| 2 | Update Codex dispatch API, fresh-context rules, and model routing | (session model) | inline | 1 | smoke + critic |
| 3 | Update the shared execute loop and Codex agent definitions, including a conditional heavy reviewer | (session model) | inline | 1,2 | smoke + TOML parse + critic |
| 4 | Update installer, smoke assertions, README, and handoff | (session model) | inline | 2,3 | smoke + repository diff review |
| 5 | Run an independent critic and final verification | mew-critic | subagent | 1,2,3,4 | acceptance-criteria review |

## Execution Budget
- Profile: `standard`; use `high-assurance` only for the risk triggers recorded in the plan.
- Automatic fix rounds: 2 per task in `standard`, 5 in `high-assurance`.
- Maximum subagent runs: 1 fresh-context critic; production is session-inline prose/config work.
- Concurrency: fill only the live slots reported by the harness.
- Usage checkpoints: before execution, after each frontier wave, and before the final gate when the harness exposes usage.

## Acceptance Criteria
- [x] Codex dispatches workers, reviewers, critics, and explorers with `fork_turns="none"` and complete bounded prompts.
- [x] The Codex adapter uses the currently exposed collaboration tool names and contains no stale `send_input`, `resume_agent`, or `close_agent` instructions.
- [x] Default Codex roles use Terra for ordinary production/review, Luna for mechanical work, and Sol only for the session, heavy implementation, and conditional heavy review.
- [x] Low-risk work no longer receives an unconditional whole-branch reviewer; medium/high-risk work does, and high-risk work also receives security review.
- [x] Only high-confidence medium/high-severity findings enter automatic fix rounds; advisory findings are ledgered for the final gate.
- [x] Task reviewers run scoped verification; the complete build/test suite runs once at the final verification gate.
- [x] Review packages use three lines of diff context and reports record commands, exit codes, summaries, and failing excerpts instead of full successful logs.
- [x] Off-ramp routing is based on decision/risk/verifiability rather than a two-file limit.
- [x] Plans record assurance profile, fix-round ceiling, concurrency rule, and usage checkpoints.
- [x] Installer and smoke checks cover the optional Codex heavy reviewer and assert the model/fresh-context policy.
- [x] README describes the new behavior and model mapping accurately.
- [x] `skills/mew-kickoff/scripts/smoke.sh` passes; `quick_validate.py` either passes or rejects only the intentional cross-runtime `disable-model-invocation` extension.

## Rulings
- `quick_validate.py` rejects `disable-model-invocation` because its schema is the portable agentskills.io subset. Keep the field: it preserves explicit-only invocation in Claude and Grok, while Codex also enforces the same policy through `agents/openai.yaml`. The repository smoke test is authoritative for this cross-runtime package.
- The current session rejected `agent_type="mew-critic"`; agent definitions are loaded at session start. The independent gate therefore used a fresh `default` agent pinned to Terra/high with `fork_turns="none"` and the critic's bounded brief. New sessions discover the installed native critic/heavy-reviewer definitions.

## Out of scope
- Changing Claude or Grok model families; this review and the observed usage issue were Codex-specific.
- Reconstructing usage from a different machine or account whose logs are not present here.

## Delivery Evidence
- `SMOKE: PASS`, including model mapping, fresh dispatch, current tool names, six Codex TOMLs, and mechanical report evidence across all harnesses.
- Six Codex TOMLs parse with Python `tomllib`; `bash -n` and `git diff --check` pass.
- Independent fresh-context critic: PASS, 12/12 criteria. Report: `docs/plans/reports/codex-economy-hardening-critic.md`.
- One critic thread in one frontier wave; one scoped follow-up corrected its only finding.
- The app API exposed no `/status` reading tool during this run, so no numeric usage checkpoint was recorded; no multi-agent forward-test was launched.

## Status
interviewed 2026-09-04 | approved: 2026-09-04 | executed: 2026-09-04 | delivered: 2026-09-04
