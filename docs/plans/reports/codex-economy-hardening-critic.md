# Critic report: Codex economy hardening

**Final verdict: PASS** — all 12 acceptance criteria are met after the criterion-7 correction on 2026-09-04.

## Evidence and verdicts

| # | Acceptance criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | Codex dispatch is fresh and bounded | Met | `adapters/codex.md` requires `fork_turns="none"` for every worker, reviewer, critic, and explorer, and requires complete prompts or exact bounded paths. `SKILL.md` repeats the fresh-dispatch and bounded-report rules. |
| 2 | Current Codex collaboration names; no stale names | Met | `adapters/codex.md` names `spawn_agent`, `followup_task`, `send_message`, `wait_agent`, `interrupt_agent`, and `list_agents`; no `send_input`, `resume_agent`, or `close_agent` occurs in that adapter. |
| 3 | Terra/Luna/Sol role defaults | Met | Codex TOMLs and `adapters/codex.md` map default worker/reviewer/critic to Terra, mechanical worker to Luna, and session/heavy worker/conditional heavy reviewer to Sol. |
| 4 | Proportional whole-branch and security review | Met | `SKILL.md` and `adapters/loop.md` give low risk Tier 1 only, medium risk a standard whole-branch review, and high risk a heavy whole-branch review plus security review. |
| 5 | Blocking-only automatic fixes; advisory ledger | Met | `SKILL.md` and `adapters/loop.md` limit automatic fixes to high-confidence medium-or-higher findings and ledger advisory findings for Tier 2. |
| 6 | Scoped task verification; one full suite at final gate | Met | Task reviewers are instructed to run task-scoped checks; `adapters/loop.md` runs the complete suite exactly once after all task fixes. |
| 7 | Three-line package context and concise command-bearing reports | Met | `adapters/loop.md` writes `git diff -U3`. All three mechanical workers now require verification commands, exit codes, concise results, and failing excerpts only, matching the default/heavy worker and reviewer policy. `smoke.sh` asserts the mechanical-policy evidence across Claude, Codex, and Grok, and passed. |
| 8 | Decision/risk/verifiability off-ramp | Met | `SKILL.md` Step 0 requires all three conditions and explicitly says file count alone never forces the pipeline. |
| 9 | Plan assurance, ceiling, concurrency, and usage | Met | The Step 3 template has Profile, Risk, fix rounds, live-slot concurrency, and three usage checkpoints. |
| 10 | Installer/smoke heavy-reviewer and policy coverage | Met | `install.sh` links the optional Codex heavy reviewer; `smoke.sh` checks its existence, six role mappings, the expected models, `fork_turns="none"`, `followup_task`, and stale tool names. |
| 11 | README accuracy | Met | Thai README explains risk-based review behavior, standard/high-assurance fix ceilings, fresh Codex dispatch, and the Terra/Luna/Sol mappings consistently with the role files. |
| 12 | Smoke and portable validation | Met | `bash skills/mew-kickoff/scripts/smoke.sh` exited 0 with `SMOKE: PASS`. `quick_validate.py skills/mew-kickoff` exited 1 solely with `Unexpected key(s) ... disable-model-invocation`, the explicitly allowed cross-runtime extension. |

## Verification record

| Command | Exit | Summary |
|---|---:|---|
| `bash skills/mew-kickoff/scripts/smoke.sh` | 0 | `SMOKE: PASS`; includes optional Codex heavy reviewer, all expected Codex model mappings, fresh-context assertion, current follow-up tool, and stale-tool checks. |
| `python3 .../quick_validate.py skills/mew-kickoff` | 1 | Only failure: `disable-model-invocation` is an unexpected portable-schema key, matching the plan ruling. |
| Python `tomllib` parse of `agents/codex/*.toml` | 0 | All six Codex agent TOMLs parsed. |
| Python YAML parse of the scoped Claude/Grok agent frontmatter | 0 | All seven scoped agent files parsed. |
| `git diff --check` | 0 | No whitespace errors. |
| Re-run: `bash skills/mew-kickoff/scripts/smoke.sh` | 0 | `SMOKE: PASS`, including all three new `mechanical report evidence` assertions. |

## Criterion-7 re-review

The correction is complete. `agents/{codex,claude,grok}/mew-worker-mech` now require verification commands, exit codes, concise results, and failure-only excerpts; `smoke.sh` checks the three installed definitions for `exit codes` and `failing excerpts only`. The full smoke run passed. The portable validator still rejects only the plan-approved `disable-model-invocation` extension.
