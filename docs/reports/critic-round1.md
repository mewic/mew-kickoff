# mew-kickoff rewrite — critic report (round 1)

Scope: SKILL.md, map.md, ultracode.md, scripts/smoke.sh, five agent files.
Independently verified: `wc -w SKILL.md` = 2144; `scripts/smoke.sh` mode `-rwxr-xr-x`, run locally → `SMOKE: PASS`, exit 0; skill dir contains only SKILL.md, map.md, ultracode.md, scripts/.

## 1. Per-criterion verdicts

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | No `grill-with-docs`; Step 2 calls `grilling` then `domain-modeling` via Skill tool; one-question-at-a-time override explicit | **Met** | L50: "Call the Skill tool for `grilling`, then for `domain-modeling`. Mew's convention overrides grilling's batching: **one question at a time, with a recommended answer each time.**" `grill-with-docs` appears nowhere in SKILL.md (only as a negative check in smoke.sh L31). Also correctly separates the stopping condition from the two mandatory minimums. |
| 2 | Step 4/5 state SDD owns the loop (ledger, review package, 5 rounds + breaker, whole-branch review) and list exactly the three overrides | **Met, with one undeclared fourth override (see F1)** | L105 names Setup/worktree/workspace/ledger/pre-flight, implementer dispatch, review package, "fix rounds (five max, then the breaker)", "final whole-branch review". Overrides 1–3 at L107–109: implementer from Execution Directive as `subagent_type`; task reviewer = `mew-reviewer`; escalation mech → worker → heavy. "runs build and tests itself — a deliberate override of SDD's reviewer template" at L123. SDD cross-check: `Never dispatch multiple implementation subagents in parallel` (SDD SKILL.md L282) is contradicted by L113 but not listed as an override. |
| 3 | `model` required on every Agent call incl. built-ins; sixth-agent-file replaces the edit hack | **Met** | L111: "**Every Agent call carries `model`** — including built-ins (Explore, Plan, general-purpose)… add a sixth agent file; never edit an existing `~/.claude/agents/mew-*.md` while sessions are running". No occurrence of "temporarily edit". Claim "an omitted model inherits the session model" is corroborated by SDD SKILL.md L205. |
| 4 | Modes uses `$ARGUMENTS`; execute-in-fresh-session described as intended path | **Met (placement note)** | L29: "the intended way to run Step 4: a **fresh session**". `$ARGUMENTS` is at L9 ("Arguments: `$ARGUMENTS` … see Modes"), not literally inside `## Modes`. Functionally equivalent; flagging only for exactness. |
| 5 | Approval gate suggests `/effort high` for Step 4, max back at final gate, as a suggestion Mew acts on | **Partially met** | L98: "suggest Mew switch `/effort high` for Step 4 (max returns at the final gate)". Rubric L146 "high (suggested at the approval gate)". Gap: "max returns at the final gate" names no actor and no trigger — see R2. |
| 6 | ≤150-word chat summary + full report to a file, in SKILL.md and all five agents | **Met** | SKILL.md L115. mew-worker L15, mew-worker-heavy L18, mew-worker-mech L13, mew-reviewer L18, mew-critic L16 — all "at most 150 words" + explicit report path with a `docs/plans/reports/` default. **But two agents lack the tool to comply — see F2.** |
| 7 | >5 tasks → mew-critic pre-flight before the approval gate | **Met** | L91–93: "### Pre-flight critic (plans with more than 5 tasks) — Before the approval gate, dispatch `mew-critic` with ONLY the plan file and its Acceptance Criteria; fix what it flags, then present." mew-critic.md L3/L9 accepts the plan-preflight role; L14 adds the executor-readability lens. |
| 8 | worker+heavy tests-first; reviewer gets review package + Global Constraints verbatim; critic has no Bash | **Met** | mew-worker L13 "tests first — write the failing test the spec implies, watch it fail"; mew-worker-heavy L14 same. mew-reviewer L3 + L11 list "a review package (commit list + diff) as a file path, and the plan's Global Constraints copied verbatim"; SKILL.md L108 dispatches them. mew-critic L4 `tools: Read, Grep, Glob, WebFetch` — no Bash. |
| 9 | Security-review fallback for remote-less repos in SKILL.md | **Met** | L123: "In a repo with no git remote `/security-review` fails — dispatch the `code-reviewer` agent with `model: opus` and a security-focused prompt instead." smoke.sh L42 verifies `code-reviewer.md` exists (confirmed present, model: sonnet — the dispatch-time `model: opus` override covers it). |
| 10 | Rubric names Fable 5.1; description is a one-line human-facing summary | **Met** | L141: "**Current top available model: Fable 5.1** (session role, effort max; alias `fable`)." Frontmatter description (L3) is one line, states what it does and both invocations. |
| 11 | No stale plan file; smoke.sh exists, executable, exits 0 | **Met (verified myself)** | Directory listing shows only the four intended paths; `smoke.sh` is `0755`; local run printed all `ok` lines and `SMOKE: PASS`, exit 0. |
| 12 | SKILL.md ≤ 2,150 words | **Met** | 2144 (verified). Headroom is 6 words — any future edit trips the guard, which is the intent. |
| 13 | Kept rules present with unchanged meaning | **Met** | off-ramp L33 (all-three test + "เข้า pipeline เต็ม" override); recon L37–42 (delta-only rule); map L44–46 + map.md (Destination / Decisions so far / Not yet specified / Out of scope, one decision per session, index-not-store); facts vs decisions L55; AFK research L57 (primary sources only, `docs/research/`); vertical slices L85 (tracer bullet, one worker context, prefactoring first); Blocked-by L86; approval gate L95–101 (two outcomes, never execute without approval); ultracode triggers L131 + ultracode.md 1–4 (Mew-only switch); document conventions L156–163; language rules L165 (English tech docs, Thai deliverables, asset-language copy blocks, Thai interviews). All coherent as standalone rules. |

## 2. Contradictions and unsupported claims

**F1 — Parallel frontier dispatch vs. SDD's explicit prohibition (must fix).**
SKILL.md L113: "send those Agent calls together in a single message, not one at a time", reinforced as a Red Flag at L175 ("Independent tasks dispatched one at a time when the frontier held several").
SDD SKILL.md L282: "Never dispatch multiple implementation subagents in parallel (conflicts)."
SKILL.md L105 says mew-kickoff "overrides exactly three things" and parallel dispatch is not one of them — so a session that reads SDD (which it is told to do) sees an unoverridden prohibition and an instruction to violate it, plus a Red Flag for obeying SDD. L113's "Tasks touching the same files should block each other in the plan" is the intended mitigation, but it is never framed as the reason SDD's rule is being overridden. Either make parallel frontier dispatch override #4 with that rationale, or drop it.

**F2 — mew-critic (and mew-reviewer) cannot write the report their own rule mandates (must fix).**
mew-critic.md L4 `tools: Read, Grep, Glob, WebFetch`; L16 orders "write the full report to the file path named in your dispatch". With an explicit `tools:` list, no Write/Edit/Bash means the agent has no way to create that file. Removing Bash satisfied criterion 8 but broke criterion 6 for this agent. mew-reviewer.md L4 `tools: Read, Grep, Glob, Bash` can only write via a Bash heredoc — it works but is never stated, so the agent may silently return the full report in chat instead. smoke.sh checks for the string "150 words" and for absence of Bash, so it passes both defects. Suggested guard: assert mew-critic has Write (or Bash-less file output is dropped in favour of a chat-only critic), and add a smoke check that each agent's `tools` list contains a write-capable tool.

**F3 — Whole-branch reviewer is unspecified.**
L125 refers to "SDD's whole-branch review" but no override names its agent or model, while L111 requires `model` on every Agent call and L107 maps SDD's tiers only for implementers. SDD (L192–193) says dispatch it on the most capable model. A session must guess between `mew-reviewer` with `model: opus`, `code-reviewer`, or a bare Agent call. One clause fixes it.

**F4 — "Status: approved" does not match the plan template.**
Template L81: `interviewed YYYY-MM-DD | approved: pending | executed: - | delivered: -`. Gate L98/L99 says "finalize the plan file (Status: approved)" and Modes L29 says "if it is not `approved`". A resuming session must guess whether to look for a literal token `approved` or a field `approved: <date|yes>`, and what to write. Name the exact written form once.

**F5 — Inline consulting work vs. resume mode.**
L117 justifies the session writing consulting/strategy/copy inline because "it owns the interview context", but L29 defines the intended Step 4 session as a fresh one holding the plan and not the transcript. For a consulting plan the two are in tension. L88 ("plans must contain the complete brief") is presumably the resolution, but it is not connected to L117.

**F6 — Undefined Execution Directive vocabulary.**
The `Mode` column shows `subagent` / `inline` and `Agent` shows `(session model)`; neither the allowed values nor their effect is stated. Inferable from examples, but a plan author will guess at edge cases (e.g. a Gamma task — `mew-worker` + `subagent`?).

**F7 — Effort naming in ultracode.md.**
"Ultracode is the `/effort` setting that runs the session at xhigh" (ultracode.md L3) vs. the rubric listing `ultracode` and `xhigh` as two distinct Effort values (L147, L148). A session cannot tell whether ultracode is a distinct setting or an alias for xhigh plus fan-out.

**Unsupported claims (low severity, all heuristic framing rather than fact):** L109 "A heavy worker failing twice usually means the spec is wrong"; L93 "Spec defects caught here cost one critic run; caught in Step 5 they cost every task built on them"; L123 "review independence is worth Sonnet's cost". These are rationale, clearly labelled as such, and harmless. L141 "alias `fable`" is the only factual claim in the doc that smoke.sh does not verify. L123 "In a repo with no git remote `/security-review` fails" is asserted without a pointer; it is load-bearing for the fallback, so a one-word source ("known limitation") would help future readers.

## 3. Readability

The intended reader is a session model plus Mew, not a Thai business audience, so the consulting-readability lens mostly does not apply. Against that audience the document is directive, scannable, and free of hedging; the Thai phrases (L33 "งานนี้เข้าเกณฑ์ off-ramp", L146 "มิวคุมเอง") are addressed to Mew and land correctly. Structure carries the reader from triage to delivery in one pass, and the Red Flags block is an effective self-check.

Points a session would have to guess at, in priority order: F1 (which dispatch discipline wins), F2 (how a tools-restricted agent writes its report), F3 (whole-branch reviewer identity), F4 (Status literal), F7 (ultracode vs xhigh). F5 and F6 are recoverable by inference.

**R2 (minor):** the effort choreography spans two sessions — the interview session suggests `/effort high` for Step 4, but Step 4 runs in a *fresh* session where that setting does not carry over, and nothing tells the executing session to suggest returning to max before the Tier-2 final gate. One sentence in Modes or Step 5 would close the loop.

## 4. Recommendation

**PASS with two must-fix defects.** 11 of 13 criteria fully met, 1 met with a placement nit (#4), 1 partially met (#5, actor/trigger for the return to max). Ship after fixing **F2** (mew-critic cannot write its report — the rule is inert as written) and **F1** (the parallel-dispatch instruction contradicts an SDD rule the skill tells the session to follow, while claiming there are only three overrides). F3 and F4 are one-clause fixes worth folding into the same pass; the 6-word headroom under the 2,150 cap means at least one existing sentence has to give.
