# Handoff: `/mew-kickoff` improvement — STATUS UPDATE 2026-09-02 (same session)

**Done in the audit session (Mew chose to execute immediately):** Phases 1, 2, 3, 5 are live. Plan + gates: `docs/2026-09-02-mew-kickoff-improvement-plan.md` (Status line has the evidence), critic reports in `reports/`, Phase 4 research in `research/`. The rewritten files: `~/.claude/skills/mew-kickoff/{SKILL.md,map.md,ultracode.md,scripts/smoke.sh}` and `~/.claude/agents/mew-*.md`.

**Codex economy hardening done 2026-09-04:** Codex dispatch is explicitly fresh (`fork_turns="none"`), uses the current collaboration tool names, and routes default worker/reviewer/critic to Terra, mechanical work to Luna, and only heavy implementation/review to Sol. The core now records assurance + budget, uses two automatic fix rounds in `standard` and five in `high-assurance`, makes whole-branch/security review risk-driven, and runs the full suite once after task fixes. `mew-reviewer-heavy` is a conditional native role on Codex and Grok. See `docs/plans/2026-09-04-codex-economy-hardening.md`.

**Phase 4 also done (2026-09-03):** core is harness-neutral + `adapters/{claude,codex,grok,loop}.md` + `agents/openai.yaml`; symlinks expose one source to all CLIs. Historical model and discovery decisions from that phase are superseded by the 2026-09-04 Codex mapping above.

**Next session's job:** run one bounded `standard` Codex feature through the complete pipeline in a fresh session; record usage at the three checkpoints and confirm the worker starts without the interview transcript. Then run one `high-assurance` dry run to confirm `mew-reviewer-heavy` discovery. Agent-file edits apply only to new sessions.

The original handoff follows for context; its "improvement plan" section is now history.

---

# (original) Handoff: improve `/mew-kickoff` (audit done 2026-09-02)

**Next session's job (superseded):** turn the audit + improvement plan below into changes to
`~/.claude/skills/mew-kickoff/SKILL.md` and `~/.claude/agents/mew-*.md`.

Mew (มิว) is a Thai speaker. Interview in Thai; write technical docs in English.

## Where things are

| Thing | Path |
|---|---|
| The skill under review | `~/.claude/skills/mew-kickoff/SKILL.md` (2124 words, user-invoked) |
| Stale plan inside the skill dir (to remove) | `~/.claude/skills/mew-kickoff/docs/plans/2026-07-08-defable-rubric.md` |
| The 5 worker/reviewer agents | `~/.claude/agents/mew-{worker,worker-heavy,worker-mech,reviewer,critic}.md` |
| Audit findings + measured cost profile | memory `mew-kickoff-audit-2026-09.md` (index in MEMORY.md) — read first |
| Pipeline description + model economy | memory `mew-kickoff-workflow.md`, `mew-pipeline-model-policy.md` |
| superpowers SDD the skill delegates to | `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.3.0/skills/subagent-driven-development/` (SKILL.md, implementer-prompt.md, task-reviewer-prompt.md, scripts/review-package) |
| Matt Pocock skills, local copy | `~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/1.2.3/` and cross-runtime dir `~/.agents/skills/` (grilling, domain-modeling, tdd, implement-spec, research, wayfinder, writing-for-agents …) |
| Writing standards to audit against | `~/.claude/skills/writing-for-agents/SKILL.md` + `SKILL-MECHANICS.md` |
| Measurement scripts (re-run after changes) | `docs/scripts/` — see "How to measure" |

`~/.claude` is NOT a git repo: no commits; verify edits with grep, as the 2026-07-08 plan did.

## Verified facts (do not re-research)

- Skill tool refuses `grill-with-docs` (user-invoked): exact error "cannot be used with Skill tool due to disable-model-invocation … Do not replicate this skill's workflow by other means". `grilling` and `domain-modeling` are model-invoked and callable.
- Claude Code docs: agent frontmatter supports `model` (aliases opus→Opus 5, sonnet→Sonnet 5, haiku→Haiku 4.5, `fable`→Fable 5.1), `effort` (low…max), `tools`, `disallowedTools`, `permissionMode`. Call-site `model` overrides the agent file. The Agent tool in this build exposes only `model`, not `effort`.
- Skill frontmatter supports `disable-model-invocation`, `user-invocable`, `allowed-tools`, `$ARGUMENTS`/`$1`. Not `model`/`effort`.
- `/effort` accepts low, medium, high, xhigh, max, ultracode, auto. Ultracode = xhigh + dynamic workflow orchestration; user-only switch.
- `/skill-doctor` and `claude plugin eval` are early-access, not available here.
- Cross-CLI: Codex 0.152.0 (config model `gpt-5.6-sol`, xhigh) has feature flags `multi_agent` and `skill_search` stable; reads `~/.codex/skills` (empty) and `~/.agents/skills`. Grok 1.0.13 (default `grok-4.6`, xhigh; `fork_secondary_model = grok-build`) reads `~/.grok/skills` and takes `--agent <name|file>`, `--agents <JSON>`, `--model`, `--reasoning-effort`. Subagent definition formats for Codex/Grok NOT yet read from primary docs.
- Matt's set: 22/37 skills user-invoked; invariant "no other skill can call a user-invoked skill"; SKILL.md median 559 words, max 2000 (wayfinder).

## Line anchors in SKILL.md (as of 2026-09-02)

- 3 description (trigger-list style on a user-invoked skill; make it a one-liner)
- 64 Step 2 `grill-with-docs` + "One question at a time" (grilling now asks the whole frontier per round; say explicitly if overriding)
- 114 Step 4 hack: "temporarily edit ~/.claude/agents/mew-*.md" (unsafe: Mac mini runs many sessions; replace with "add a sixth agent file")
- 122 Tier 1 review + `/security-review` (needs the remote-less fallback from memory `security-review-needs-remote.md`)
- 130–131 escalation "haiku→sonnet→opus", 3-round hard stop (conflicts with SDD 5 rounds + breaker)
- 151 "Current top available model: Fable 5" (now Fable 5.1)

## Improvement plan agreed in conversation (Mew asked for recommendation; not yet approved as a plan file)

Keep unchanged: top-model plans / small models produce / top model reviews; vertical slices; Blocked-by frontier; Status line; facts-vs-decisions; approval gate; mew-reviewer running build+tests itself.

**Phase 1 — Repair (½ day):**
1. Step 2: call `grilling` then `domain-modeling` directly.
2. Step 5: rewrite as an explicit overlay on SDD 6.3.0 (SDD owns ledger, review-package, rulings, whole-branch review, round cap; mew-kickoff overrides only: agents from Execution Directive, task reviewer = mew-reviewer, reviewer runs tests by design). Escalation named by agent (mech → worker → heavy).
3. Remove stale plan from skill dir; rubric line → Fable 5.1; move security-review fallback into skill; replace the mid-run agent-edit hack.
4. mew-critic: `disallowedTools: Edit, Write`.

**Phase 2 — Session overhead (1 day), the cost/time lever:**
1. Fresh session for execute by default (approval gate ends the interview session; `/mew-kickoff execute <plan>` starts a clean one). Add `$ARGUMENTS` to Modes.
2. Report rules in all 5 agent files: ≤150-word chat summary, full report as a file; reviewers get the diff via SDD `review-package`.
3. Step 4: every Agent call carries `model`, including built-ins (Explore/Plan/general-purpose) — 72 runs leaked Fable (≈$368).
4. At approval gate, suggest Mew set `/effort high` for Step 4, back to max at final gate.

**Phase 3 — Quality (½ day):** mew-critic on the plan before approval when >5 tasks; TDD line in mew-worker/heavy; global constraints verbatim to reviewer (SDD template); ultracode whole-branch review default-suggested for auth/payments.

**Phase 4 — Portability to Codex + Grok (1–2 days, research first):** AFK research (primary sources) on Codex subagent definition format + skill discovery, and Grok `--agents` JSON / agent file format. Then split: SKILL.md core ≤800 words + `adapters/{claude,codex,grok}.md` (dispatch mechanics + model table per harness; rubric keeps roles only). Claude adapter keeps SDD; Codex/Grok adapters carry a minimal dispatch→review→fix loop. Single source at `~/.agents/skills/mew-kickoff`, symlinks into `~/.claude/skills`, `~/.codex/skills`, `~/.grok/skills`.

**Phase 5 — Drift guard (with Phase 1):** `scripts/smoke.sh` that checks every pointer the skill names exists and the 5 agent files parse; run after any plugin/CLI update.

Expected outcomes (estimates from the cache-read share, to be verified by re-measuring): session share of cost 64% → 45–50%; per-feature list cost $140–300 → $90–200; wall-clock 5–8 h → 3–5 h; quality unchanged (fix rounds already 0–1); one skill on three CLIs.

## Decisions only Mew can make (ask, don't assume)

1. Round policy: adopt SDD's 5 rounds + breaker, or keep 3 rounds + stop-and-report?
2. Keep mew-reviewer re-running build/tests (review independence) vs SDD's "don't re-run"? Recommendation given: keep.
3. Dependency for the execute loop: superpowers SDD (Claude-only) vs Matt's `implement-spec` (cross-runtime, still in progress)?
4. Do Phase 4 now or after Phases 1–3 have run on a couple of real features?
5. Run this improvement work through `/mew-kickoff` itself (as the 2026-07-08 de-fable change was) — recommended, and off-ramp does not apply (design decisions involved).

## How to measure

```bash
python3 docs/scripts/usage_by_model.py      # cost by role×model since CUTOFF in the script
python3 docs/scripts/usage_extra.py         # context/turn, thinking share, session durations
python3 docs/scripts/plan_cost.py <project-dir-name-under-~/.claude/projects> 2026-09-05,2026-09-06
```
Baseline numbers are in memory `mew-kickoff-audit-2026-09.md`. Change `CUTOFF` to the edit date to compare after 2–3 runs. Scripts take a few minutes over ~3 GB of transcripts.

## Suggested skills for the next session

- `mew-kickoff` — Mew types `/mew-kickoff`; the work is the plan above (interview the delta, plan, approval, execute).
- `writing-for-agents` — the standard every edit must meet (progressive disclosure, completion criteria, single source of truth). Read `SKILL-MECHANICS.md` too.
- `superpowers:writing-skills` — Iron Law: test the edited skill; at minimum dry-run the new Step 2/Step 5 wording with a subagent before declaring done.
- `research` — Phase 4 facts (Codex/Grok subagent formats), primary sources only, output to a `docs/research/` file.
- `grilling` — for the five decisions above.

## Gotchas

- Do not call user-invoked skills from the Skill tool; the harness refuses and tells you not to replicate them.
- Never edit `~/.claude/agents/*.md` while any session is dispatching agents on this machine.
- The scratchpad of the audit session is gone; everything durable is in the memory file and this folder.
