---
name: mew-kickoff
description: Mew's interview-to-delivery pipeline for substantial work. Start it by name; add `execute <plan-file>` to resume an approved plan.
disable-model-invocation: true
metadata:
  author: mew
  short-description: Interview-to-delivery pipeline with model economy
---

# Mew Kickoff

**Adapter first.** This file is the harness-neutral process. Before Step 0, read the adapter for the CLI you run in — `adapters/claude.md` (Claude Code), `adapters/codex.md` (OpenAI Codex), `adapters/grok.md` (xAI Grok). The system prompt names the CLI; failing that, the tool set does (`Skill` + `Agent` tools = Claude Code, `spawn_agent` = Codex). The adapter says how to load a skill, dispatch the five roles, set effort, run security review, and get heavier review. "Adapter" below means that file.

## Goal

Maximize the value of the session model by spending it ONLY where sharpness matters — interviewing, specifying, routing, and reviewing — while workers do the production work. The output must be finished work that passes its gates (builds, tests, criteria), not a draft Mew has to debug.

Three principles that survive model churn:

1. **Effort economy** — top effort is paid only where judgment compounds (decisions, specs, reviews), never on production keystrokes.
2. **Context economy** — the session keeps its interview/plan context clean; production burns a fresh worker context, not the planning window.
3. **Review independence** — the author of work is never its final judge. Workers produce; the session gates.

**Division of labor (never violate):**
- Session model: thinks, decides, writes specs/strategy/copy, routes tasks, reviews.
- Worker models (subagents): produce code, run tools, generate assets — always from a complete spec.
- The session model never writes production code itself when the pipeline is active, even when it shares a base model with the worker.

## Modes

Arguments: the text after the skill name (`$ARGUMENTS` in Claude Code).

- Empty → full pipeline below. The interview session ends at the approval gate.
- `execute <docs/plans/FILE.md>` → the intended way to run Step 4: a **fresh session** that holds the plan, CONTEXT.md, and referenced ADRs — not the interview transcript. Read those first. **Check the plan's Status line**: if `approved:` still says `pending`, present the plan summary and get Mew's approval before executing. Open by suggesting the adapter's Step-4 effort; suggest top effort again before the Tier-2 gate.

## Step 0 — Triage (off-ramp)

If the request meets **ALL three**: no new design decisions, touches ≤2 files (or, for non-file work, is a single small adjustment), and fits in one sentence (clear bug fix, copy tweak, config change): announce "งานนี้เข้าเกณฑ์ off-ramp" and just do it directly with normal self-verification. Skip the rest of the pipeline. Mew can always say "เข้า pipeline เต็ม" to override.

Everything else enters the pipeline.

## Step 1 — Recon

Check for `CONTEXT.md` and `docs/` in the project root.

- **Nothing exists** (fresh project): full interview.
- **Anything exists**: read whatever is there (`CONTEXT.md`, `docs/adr/`, latest plans) FIRST. Then interview only about the **delta** — the new feature/engagement. Never re-ask what the docs already answer.

### Too big for one plan → chart a map

If the work cannot fit one plan — decisions ahead can't all be named yet, or the effort will span multiple sessions — read `map.md` in this folder and chart the map first: Destination, Decisions so far, Not yet specified, Out of scope. One decision per session; the map is an index, not a store.

## Step 2 — Interview

Load the `grilling` skill, then `domain-modeling` (the adapter says how; both are installed for every harness). Mew's convention overrides grilling's batching: **one question at a time, with a recommended answer each time.** The interview ends when grilling's own criterion is met (shared understanding, every design branch resolved) — the two questions below are additional **mandatory minimums**, not the stopping condition:

1. **Deliverable format** — code in repo / markdown doc / Gamma presentation / Canva design / website / images / mix. Record it as a fixed requirement.
2. **Acceptance criteria** — concrete, checkable "done" conditions per deliverable (for non-code work too: questions it must answer, segments it must cover, slide count, required evidence).

**Facts vs decisions:** a *fact* — anything answerable from the codebase, project docs, or external sources — is never asked; look it up. A *decision* — a choice about what to build or how it should behave — is always put to Mew and waits for his answer. The session never answers a decision on Mew's behalf.

**External research (AFK):** when a needed fact lives outside the project (third-party docs, APIs, pricing, specs), dispatch `mew-worker` to research it instead of reading inline: **primary sources only** (official docs, source code, specs — never secondary write-ups), findings written to `docs/research/` as a Markdown file citing each claim's source. The session keeps interviewing/planning while the worker reads.

## Step 3 — Plan

Write `docs/plans/YYYY-MM-DD-<task-slug>.md`: goal, architecture, one section per task with files, interfaces, and checkbox steps (the adapter may name a plan-format skill), plus the sections the executor needs:

```markdown
## Global Constraints
- <binding requirements copied verbatim into every reviewer dispatch: exact values, formats, "same as X" relationships>

## Execution Directive
| # | Task | Agent | Mode | Blocked by | Review gates |
|---|------|-------|------|-----------|--------------|
| 1 | ...  | mew-worker | subagent | — | build+test, code review |
| 2 | ...  | mew-worker-heavy | subagent | 1 | build+test, code review, security review |
| 3 | strategy doc | (session model) | inline | — | critic vs acceptance criteria |

## Acceptance Criteria
- [ ] ...

## Out of scope
- <work consciously excluded from this plan + one-line why>

## Status
interviewed YYYY-MM-DD | approved: pending | executed: - | delivered: -
```

Rules:
- **Vertical slices (tracer bullets)**: each code task cuts a narrow but COMPLETE path through every layer it touches (schema → API → UI → tests) and is demoable or verifiable on its own — never a horizontal one-layer task. Size each task to one fresh worker context window; prefactoring tasks go first.
- **Mode**: `subagent` = dispatched as the named agent; `inline` = the session model itself (Agent column `(session model)`).
- **Blocked by**: every task declares the task numbers that must finish before it can start (`—` = none). Declare only genuine dependencies — independent tasks are the point; they unlock parallel dispatch in Step 4.
- **Reference, never copy**: point to CONTEXT.md terms and ADR numbers instead of restating them. Restated content goes stale — that is the real bloat.
- Consulting/marketing plans must contain the **complete brief**: every sentence of copy, structure, tone, image specs. A worker following the brief verbatim must be able to produce the deliverable.
- External outputs (Gamma/Canva links) get recorded back into this file with date + status.

### Pre-flight critic (plans with more than 5 tasks)

Before the approval gate, dispatch `mew-critic` with ONLY the plan file and its Acceptance Criteria; fix what it flags, then present. Spec defects caught here cost one critic run; caught in Step 5 they cost every task built on them.

### 🛑 Approval gate

STOP. Present the plan summary and wait for Mew. Two valid outcomes:
- **"execute"** → write `approved: <date>` in the Status line, suggest Mew set the adapter's Step-4 effort (top effort returns before the Tier-2 gate), then start a fresh session with `execute <file>` — or continue here if Mew prefers.
- **"พักไว้" / defer** → the plan is approved, execution is not: write `approved: <date>`, `executed: deferred` and end.

Never start executing without explicit approval.

## Step 4 — Execute

**Code tasks** → the adapter's execute loop (per-plan ledger, review package per task, capped fix rounds, whole-branch review at the end). Four rules hold in every harness:

1. **Implementer** = the agent named in the Execution Directive (`mew-worker` / `mew-worker-heavy` / `mew-worker-mech`), dispatched with the complete task spec; model + effort come from the agent's definition.
2. **Reviewers** = `mew-reviewer` per task (Step 5), dispatched with the review package, the brief, the worker's report file, and the plan's Global Constraints verbatim; a whole-branch review on the heavy tier at the end. The session is the final gate, never a reviewer subagent.
3. **Escalation** at fix rounds 4–5 (both loops resume the same implementer for rounds 1–3) = the next agent tier (mech → worker → heavy). A heavy worker failing twice usually means the spec is wrong: rule on it, ledger it, fix the plan, redispatch.
4. **Parallel frontier**: the plan's Blocked-by column already serializes tasks that share files, so independent tasks run together; if two implementers still collide in git, serialize the rest of that wave.

Every dispatch of a built-in agent names its model where the adapter's Agents section allows it; a dispatch that inherits the session model pays the session's price.

**Dispatch the frontier in parallel:** every task whose Blocked-by entries have all passed review is on the frontier — dispatch those together, not one at a time. When a task clears Step 5, re-compute the frontier and dispatch the newly unblocked.

**Keep the session context clean:** every subagent replies with at most 150 words and writes its full report to a file (the loop's workspace; `docs/plans/reports/` outside it). The session opens a full report only when its summary flags something, and never reads source files itself in Step 4 — a read-only explorer agent does. Run continuously; do not check in between tasks.

**Consulting / strategy / copy** → the session model writes this inline in the interview session (it owns the context; the plan's complete brief lets a fresh session take over if needed). Write the deliverable to `docs/deliverables/`.

**Marketing production** (Gamma, Canva, image gen, video) → dispatch `mew-worker` with a prompt containing the full brief from the plan. The worker executes tools; it does not invent copy — a missing sentence is a brief defect to fix first.

## Step 5 — Review

**Tier 1 — `mew-reviewer`** (the loop's task review): spec compliance + code quality, and it **runs build and tests itself** by design — review independence is worth the mid-tier cost. Very complex diffs: the adapter's heavy-tier reviewer. Run the adapter's **security review** additionally when the work touches: auth, payments, user input handling, external API calls, file/secret handling.

**Tier 2 — final gate (session model, top effort):** after the whole-branch review, read the Tier-1 summaries, the whole-branch findings, and the acceptance criteria. Only this gate can declare the work done.

**Non-code deliverables:** dispatch `mew-critic` with ONLY the acceptance criteria + the deliverable (not the conversation). The session revises per critic feedback, three-round ceiling, then report to Mew.

**Stopping:** ask before an irreversible operation, a security-sensitive action, a side effect outside the worktree (merge, push, publish), a plan broken past guessing, or a breaker that leaves a security-sensitive finding open. Heavier review than the tiers give: the adapter's **Heavier review** section, suggested to Mew with the trigger named.

## Step 6 — Deliver

Report: what was delivered, evidence each gate passed (build/test output, criteria checklist), external asset links, and how many frontier waves the tasks took. Update the plan's Status line. Update CONTEXT.md / write ADRs for any decisions that crystallized (per domain-modeling).

## Roles (the model economy)

Five roles: `mew-worker` (default: spec'd code, tests, refactors, tool-driven production), `mew-worker-heavy` (complex or security-sensitive code), `mew-worker-mech` (pure mechanical edits), `mew-reviewer` (Tier-1 review), `mew-critic` (non-code critic and plan pre-flight). The session holds interview, plan, copy, routing, and the final gate at top effort, one notch lower while routing in Step 4. The adapter maps each role to that harness's model and effort and says where the definitions live; `scripts/smoke.sh` checks every pointer — run it after any harness or plugin update.

## Document Conventions

```
CONTEXT.md            living glossary (update in place, never recreate)
docs/adr/             decisions, append small files (domain-modeling)
docs/plans/           one file per task, date-prefixed, disposable after delivery
docs/plans/reports/   full subagent reports outside the loop's workspace, disposable
docs/research/        AFK research, primary sources cited
docs/deliverables/    consulting outputs
```

**Language:** technical docs (plans, ADRs, CONTEXT.md) in English; consulting deliverables in Thai; production copy in the language of the actual asset — embedding Thai (or other asset-language) copy blocks inside an English plan file is the intended format. Interviews are conducted in Thai.

## Red Flags — stop and re-read this skill

- The session model is writing production code while the pipeline is active.
- A worker is inventing copy or design decisions not in the brief.
- Executing without an approved plan.
- A plan restates CONTEXT.md/ADR content.
- Re-interviewing facts already recorded in project docs.
- A design decision answered on Mew's behalf.
- Independent tasks dispatched one at a time when the frontier held several.
- A built-in agent dispatched without a model, a full report pasted into the session, the session reading source files in Step 4, or running without the adapter.
