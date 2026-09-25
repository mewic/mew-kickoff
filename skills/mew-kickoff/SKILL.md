---
name: mew-kickoff
description: Mew's interview-to-delivery pipeline for substantial work. Start it by name; add `execute <plan-file>` to resume an approved plan.
disable-model-invocation: true
metadata:
  author: mew
  short-description: Interview-to-delivery pipeline with model economy
---

# Mew Kickoff

**Adapter first.** This file is the harness-neutral interview-to-plan process. Before Step 0, read the adapter that matches this harness: `adapters/claude.md`, `adapters/codex.md`, `adapters/grok.md`, `adapters/cursor.md`. Match the product name in the system prompt; if absent, match the tool names the adapter lists. The adapter says how to load a skill, dispatch roles with fresh context, set effort, and get heavier review. "Adapter" below means that file.

Do not read `execute.md` in an interview session.

## Goal

Spend the session model only where sharpness matters — interviewing, specifying, routing, and reviewing. Workers do production work from a complete spec. Output must pass its gates, not leave a draft for Mew to debug.

1. **Effort economy** — model, effort, and review depth rise with task risk; top effort is paid only where judgment compounds.
2. **Context economy** — the interview/plan window stays clean; production burns a fresh worker context; state lives on disk (plan, ledger, reports) so the harness can compact freely.
3. **Review independence** — the author of work is never its final judge.

**Division of labor (never violate):** the session thinks, decides, writes specs/strategy/copy, routes, and gates. Workers produce code, run tools, and generate assets. The session never writes production code while the pipeline is active, even when it shares a base model with the worker.

## Modes

Arguments: the text after the skill name.

- Empty → Steps 0–3 below. The interview session ends at the approval gate.
- `execute <docs/plans/FILE.md>` → **fresh session only.** Read `execute.md` and follow it with the plan, CONTEXT.md, and referenced ADRs. If this session already ran Steps 1–3, stop and give Mew the exact first message for a new session instead.

## Step 0 — Triage (off-ramp)

If the request meets **ALL three**: no new design decisions, low risk, and independently verifiable as one bounded change, announce "งานนี้เข้าเกณฑ์ off-ramp" and do it directly with normal self-verification. File count alone never forces the pipeline. Low risk excludes auth, payments, secrets, user-input boundaries, external side effects, data migration, and irreversible operations. Mew can always say "เข้า pipeline เต็ม" to override.

Everything else enters the pipeline.

## Step 1 — Recon

Check for `CONTEXT.md` and `docs/` in the project root.

- **Nothing exists** (fresh project): full interview.
- **Anything exists**: read whatever is there (`CONTEXT.md`, `docs/adr/`, latest plans) FIRST. Then interview only the **delta**. Never re-ask what the docs already answer.

If the work cannot fit one plan — decisions ahead can't all be named yet, or the effort will span multiple sessions — read `map.md` in this folder and chart the map first: Destination, Decisions so far, Not yet specified, Out of scope. One decision per session; the map is an index, not a store.

## Step 2 — Interview

Load `grilling`, then `domain-modeling` as the adapter directs. Follow grilling: ask the **whole frontier** in one round — numbered questions, each with a recommended answer — then wait. A question that depends on an unanswered question in this round belongs to a later round. End when the frontier is empty and every design branch is resolved; these are additional mandatory minimums:

1. **Deliverable format** — code in repo / markdown doc / Gamma presentation / Canva design / website / images / mix. Record it as a fixed requirement.
2. **Acceptance criteria** — concrete, checkable "done" conditions per deliverable (for non-code work too: questions it must answer, segments it must cover, slide count, required evidence).

**Facts vs decisions:** a *fact* — anything answerable from the codebase, project docs, or external sources — is never asked; look it up. A *decision* — a choice about what to build or how it should behave — is always put to Mew and waits for his answer. The session never answers a decision on Mew's behalf.

**External research (AFK):** when a needed fact lives outside the project (third-party docs, APIs, pricing, specs), dispatch `mew-worker` to research it instead of reading inline: **primary sources only** (official docs, source code, specs — never secondary write-ups), findings written to `docs/research/` as a Markdown file citing each claim's source. The session keeps interviewing/planning while the worker reads.

## Step 3 — Plan

Write `docs/plans/YYYY-MM-DD-<task-slug>.md`: goal, architecture, task sections with files/interfaces/checklist, and these executor sections. Agent names in the Execution Directive are `mew-worker` / `mew-worker-heavy` / `mew-worker-mech` / `(session model)`; the adapter maps each name.

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
- **Blocked by**: every task declares the task numbers that must finish before it can start (`—` = none). Declare only genuine dependencies — independent tasks unlock parallel dispatch during execute.
- **Reference, never copy**: point to CONTEXT.md terms and ADR numbers instead of restating them.
- **Review gates by risk**: low → the worker's own build+test only (no reviewer dispatch); medium → `mew-reviewer` per task; high / `high-assurance` → `mew-reviewer` per task plus whole-branch and security review. Write the gate into the Review gates column.
- **Proportional assurance**: default to `standard`. Use `high-assurance` for auth, payments, secrets, user-input boundaries, external side effects, data migration, irreversible operations, or unusually broad/novel changes. Record the reason and budget.
- Consulting/marketing plans must contain the **complete brief**: every sentence of copy, structure, tone, image specs. A worker following the brief verbatim must be able to produce the deliverable.
- External outputs (Gamma/Canva links) get recorded back into this file with date + status.

### Pre-flight critic (plans with more than 5 tasks)

Before the approval gate, dispatch `mew-critic` with ONLY the plan file and its Acceptance Criteria; fix what it flags, then present.

### 🛑 Approval gate

STOP. Present the plan summary and wait for Mew. Two valid outcomes:
- **"execute"** → write `approved: <date>` in the Status line, suggest the adapter's execute-session effort, and **end this session**. Give Mew the exact first message for a new session: the skill name plus `execute` and the plan path. Never start code execution here.
- **"พักไว้" / defer** → write `approved: <date>`, `executed: deferred` and end.

**Session-authored consulting / strategy / copy** may be written in this interview session after approval (the session owns that context). Write it to `docs/deliverables/`. Production code and marketing-tool execution still wait for a fresh `execute` session.

Never start executing production code without explicit approval, and never in the interview session.

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
- Executing code, reading `execute.md`, or starting Step 4 in the interview session.
- A plan restates CONTEXT.md/ADR content.
- Re-interviewing facts already recorded in project docs.
- A design decision answered on Mew's behalf.
- Asking one question per turn when the frontier held several.
