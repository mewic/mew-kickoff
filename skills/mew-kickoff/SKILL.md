---
name: mew-kickoff
description: Mew's interview-to-delivery pipeline for substantial work. Start it by name; add `execute <plan-file>` to resume an approved plan.
disable-model-invocation: true
metadata:
  author: mew
  short-description: Interview-to-delivery pipeline with model economy
---

# Mew Kickoff

**Adapter first.** This file is the harness-neutral process. Before Step 0, read the adapter for the CLI you run in — `adapters/claude.md` (Claude Code), `adapters/codex.md` (OpenAI Codex), `adapters/grok.md` (xAI Grok). The system prompt names the CLI; failing that, the tool set does (`Skill` + `Agent` tools = Claude Code, `spawn_agent` = Codex). The adapter says how to load a skill, dispatch roles with fresh context, set effort, run security review, and get heavier review. "Adapter" below means that file.

## Goal

Maximize the value of the session model by spending it ONLY where sharpness matters — interviewing, specifying, routing, and reviewing — while workers do the production work. The output must be finished work that passes its gates (builds, tests, criteria), not a draft Mew has to debug.

Three principles that survive model churn:

1. **Effort economy** — model, effort, and review depth rise with task risk; top effort is paid only where judgment compounds.
2. **Context economy** — the session keeps its interview/plan context clean; production burns a fresh worker context, not the planning window.
3. **Review independence** — the author of work is never its final judge. Workers produce; the session gates.

**Division of labor (never violate):**
- Session model: thinks, decides, writes specs/strategy/copy, routes tasks, reviews.
- Worker models (subagents): produce code, run tools, generate assets — always from a complete spec.
- The session model never writes production code itself when the pipeline is active, even when it shares a base model with the worker.

## Modes

Arguments: the text after the skill name (`$ARGUMENTS` in Claude Code).

- Empty → full pipeline below. The interview session ends at the approval gate.
- `execute <docs/plans/FILE.md>` → run Step 4 in a **fresh session** with the plan, CONTEXT.md, and referenced ADRs. If `approved:` is pending, present the summary and wait for approval. Suggest the adapter's Step-4 effort, then top effort before Tier 2.

## Step 0 — Triage (off-ramp)

If the request meets **ALL three**: no new design decisions, low risk, and independently verifiable as one bounded change, announce "งานนี้เข้าเกณฑ์ off-ramp" and do it directly with normal self-verification. File count alone never forces the pipeline. Low risk excludes auth, payments, secrets, user-input boundaries, external side effects, data migration, and irreversible operations. Mew can always say "เข้า pipeline เต็ม" to override.

Everything else enters the pipeline.

## Step 1 — Recon

Check for `CONTEXT.md` and `docs/` in the project root.

- **Nothing exists** (fresh project): full interview.
- **Anything exists**: read whatever is there (`CONTEXT.md`, `docs/adr/`, latest plans) FIRST. Then interview only about the **delta** — the new feature/engagement. Never re-ask what the docs already answer.

### Too big for one plan → chart a map

If the work cannot fit one plan — decisions ahead can't all be named yet, or the effort will span multiple sessions — read `map.md` in this folder and chart the map first: Destination, Decisions so far, Not yet specified, Out of scope. One decision per session; the map is an index, not a store.

## Step 2 — Interview

Load `grilling`, then `domain-modeling` as the adapter directs. Ask **one question at a time, with a recommended answer.** End when shared understanding is reached and every design branch is resolved; these are additional mandatory minimums:

1. **Deliverable format** — code in repo / markdown doc / Gamma presentation / Canva design / website / images / mix. Record it as a fixed requirement.
2. **Acceptance criteria** — concrete, checkable "done" conditions per deliverable (for non-code work too: questions it must answer, segments it must cover, slide count, required evidence).

**Facts vs decisions:** a *fact* — anything answerable from the codebase, project docs, or external sources — is never asked; look it up. A *decision* — a choice about what to build or how it should behave — is always put to Mew and waits for his answer. The session never answers a decision on Mew's behalf.

**External research (AFK):** when a needed fact lives outside the project (third-party docs, APIs, pricing, specs), dispatch `mew-worker` to research it instead of reading inline: **primary sources only** (official docs, source code, specs — never secondary write-ups), findings written to `docs/research/` as a Markdown file citing each claim's source. The session keeps interviewing/planning while the worker reads.

## Step 3 — Plan

Write `docs/plans/YYYY-MM-DD-<task-slug>.md`: goal, architecture, task sections with files/interfaces/checklist, and these executor sections:

```markdown
## Global Constraints
- <binding requirements copied verbatim into every reviewer dispatch: exact values, formats, "same as X" relationships>

## Assurance and Budget
- Profile: standard | high-assurance
- Risk: low | medium | high — <why>
- Automatic fix rounds per task: 2 | 5
- Maximum subagent runs: <number>
- Concurrency: fill only live harness slots
- Usage checkpoints: before execute, after each frontier wave, before final gate

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
- **Tracer bullets**: each code task is a narrow, complete, independently verifiable path through every affected layer. Size it to one fresh worker context; prefactoring goes first.
- **Mode**: `subagent` = dispatched as the named agent; `inline` = the session model itself (Agent column `(session model)`).
- **Blocked by**: every task declares the task numbers that must finish before it can start (`—` = none). Declare only genuine dependencies — independent tasks are the point; they unlock parallel dispatch in Step 4.
- **Reference, never copy**: point to CONTEXT.md terms and ADR numbers instead of restating them. Restated content goes stale — that is the real bloat.
- **Proportional assurance**: default to `standard`. Use `high-assurance` for auth, payments, secrets, user-input boundaries, external side effects, data migration, irreversible operations, or unusually broad/novel changes. Record the reason and budget in the plan.
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

**Code tasks** → the adapter's execute loop (per-plan ledger, review package per task, capped fix rounds, and profile-driven final review). Four rules hold in every harness:

1. **Implementer** = the agent named in the Execution Directive (`mew-worker` / `mew-worker-heavy` / `mew-worker-mech`), dispatched with the complete task spec; model + effort come from the agent's definition.
2. **Reviewers** = `mew-reviewer` per task, dispatched with the review package, brief, worker report path, and Global Constraints. Medium/high risk also gets a whole-branch review; high risk uses the adapter's heavy reviewer plus security review. The session is the final gate.
3. **Escalation**: `standard` allows two automatic fix rounds; `high-assurance` allows five, escalating after round 3 (mech → worker → heavy). Only high-confidence findings of medium-or-greater severity enter the automatic loop. Ledger advisory findings for the final gate. A heavy worker failing twice usually means the spec is wrong: rule on it, fix the plan, and redispatch.
4. **Parallel frontier**: the plan's Blocked-by column already serializes tasks that share files, so independent tasks run together; if two implementers still collide in git, serialize the rest of that wave.

Every dispatch of a built-in agent names its model where the adapter's Agents section allows it; a dispatch that inherits the session model pays the session's price.

**Dispatch the frontier in parallel:** every task whose Blocked-by entries have all passed review is on the frontier — dispatch those together, not one at a time. When a task clears Step 5, re-compute the frontier and dispatch the newly unblocked.

**Fresh dispatch:** workers, reviewers, critics, and explorers start without the parent conversation. Give each a complete bounded prompt or exact file paths; the adapter defines the harness control. Every subagent replies with at most 150 words and writes its report to a file. The session opens a full report only when its summary flags something, and uses a fresh read-only explorer for source questions. Run continuously; do not check in between tasks.

At every plan checkpoint supported by the harness, record usage in the ledger. If the run reaches its declared agent-run or fix-round ceiling, stop automatic expansion and let the session rule on the smallest path to acceptance.

**Consulting / strategy / copy** → the session model writes this inline in the interview session (it owns the context; the plan's complete brief lets a fresh session take over if needed). Write the deliverable to `docs/deliverables/`.

**Marketing production** → dispatch `mew-worker` with the full brief. It executes tools without inventing copy; fix brief gaps first.

## Step 5 — Review

**Tier 1 — `mew-reviewer`:** every code task receives fresh-context spec and quality review plus independently run task-scoped verification. Successful logs are command + exit code + concise summary; include output excerpts only for failures.

**Profile gate:** low risk stops after Tier 1 and one final full-suite verification. Medium risk adds a fresh whole-branch review. High risk uses the adapter's heavy whole-branch reviewer and security review. The complete build/test suite runs once after all task fixes, not once per reviewer.

**Tier 2 — final gate (session model, top effort):** read the Tier-1 summaries, any profile-required whole-branch/security findings, the final verification result, and the acceptance criteria. Only this gate can declare the work done.

**Non-code deliverables:** dispatch `mew-critic` with ONLY the acceptance criteria + the deliverable (not the conversation). The session revises per critic feedback, three-round ceiling, then report to Mew.

**Stopping:** ask before an irreversible operation, a security-sensitive action, a side effect outside the worktree (merge, push, publish), a plan broken past guessing, or a breaker that leaves a security-sensitive finding open. Heavier review than the tiers give: the adapter's **Heavier review** section, suggested to Mew with the trigger named.

## Step 6 — Deliver

Report delivered work, gate evidence, criteria, asset links, and frontier-wave count. Update plan Status, CONTEXT.md, and ADRs for decisions that crystallized.

## Roles (the model economy)

Base roles: `mew-worker` (specified production), `mew-worker-heavy` (complex/security-sensitive work), `mew-worker-mech` (mechanical edits), `mew-reviewer` (Tier 1), and `mew-critic` (non-code/plan critic). An adapter may add a conditional heavy reviewer. The session owns interview, plan, copy, routing, and the final gate. The adapter maps each role to model and effort; `scripts/smoke.sh` checks every pointer after harness or plugin updates.

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
