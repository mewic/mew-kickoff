# De-Fable mew-kickoff Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **mew-kickoff routing note:** Per the interview, Tasks 1–2 are session-inline work (strategy/prose, the session model's own domain), NOT worker dispatches. Task 3 is the mew-critic gate.

**Goal:** Make `~/.claude/skills/mew-kickoff/SKILL.md` model-agnostic (no Fable references), set the session role to Opus 4.8 @ effort max, and add an ultracode escalation path for reviews; update the paired memory file to match.

**Architecture:** Three prose edits to SKILL.md (Goal rationale, Model Rubric, Step 5 escalation block) + one memory-file update. No code, no agent-definition changes. Verification is `grep`-based since `~/.claude` is not a git repository (no commit steps).

**Tech Stack:** Markdown only. Files live under `~/.claude/` (global, not project-scoped).

## Global Constraints

- SKILL.md stays in English (Thai only inside strings that are Thai in the current file, e.g. "มิวคุมเอง").
- Do NOT touch any file in `~/.claude/agents/` — reviewed 2026-07-07, confirmed model-agnostic already.
- Do NOT restructure the pipeline: Steps 0–6, the 3-round escalation rule, Document Conventions, and the five agents stay as they are.
- ultracode is a session-level `/effort` setting only Mew can switch on. Every mention must be phrased as "suggest Mew switch", never as something the session does itself.
- After all edits: `grep -i fable` over SKILL.md and the memory file must return nothing.

---

### Task 1: Rewrite SKILL.md — Goal, Model Rubric, Step 5

**Files:**
- Modify: `/Users/mewsocialmacmini/.claude/skills/mew-kickoff/SKILL.md`

**Interfaces:**
- Consumes: current SKILL.md content (as of 2026-07-03 build).
- Produces: the three edited sections below, verbatim. Task 3's critic checks the file against the Acceptance Criteria at the bottom of this plan.

- [ ] **Step 1: Replace the Goal section**

Replace the entire `## Goal` section (from `## Goal` down to, but not including, `## Modes`) with:

```markdown
## Goal

Maximize the value of the session model by spending it ONLY where sharpness matters — interviewing, specifying, routing, and reviewing — while workers do the production work. The output must be finished work that passes its gates (builds, tests, criteria), not a draft Mew has to debug.

This division does not depend on which model is newest. It rests on three principles that survive model churn:

1. **Effort economy** — top effort is paid only where judgment compounds (decisions, specs, reviews), never on production keystrokes.
2. **Context economy** — the session keeps its interview/plan context clean; production burns a fresh worker context, not the planning window.
3. **Review independence** — the author of work is never its final judge. Workers produce; the session gates.

**Division of labor (never violate):**
- Session model: thinks, decides, writes specs/strategy/copy, routes tasks, reviews.
- Worker models (subagents): produce code, run tools, generate assets — always from a complete spec.
- The session model never writes production code itself when the pipeline is active — even when session and worker happen to share the same base model.
```

- [ ] **Step 2: Replace the Model Rubric table and intro**

Replace the `## Model Rubric` section body (the intro paragraph + table, keeping the `## Model Rubric` heading, stopping before `## Document Conventions`) with:

```markdown
Model + effort live in the agent definitions at `~/.claude/agents/mew-*.md` — when new models ship, edit those frontmatter files; this table and the logic above stay unchanged.

**Current top available model: Opus 4.8** (session role, effort max). When a new top model ships, update this line only.

| Work | Agent (`subagent_type`) | Model | Effort |
|------|------------------------|-------|--------|
| Interview, plan, strategy, copy, routing, final review | — (session, inline) | top available model | max (มิวคุมเอง via /effort) |
| Escalated review: multi-agent adversarial (see Step 5) | — (session + subagents) | top available model | ultracode (มิวสลับเองผ่าน /effort) |
| Complex code: multi-file, hard debugging, security-sensitive, algorithms | `mew-worker-heavy` | Opus 4.8 | xhigh |
| Spec'd code, tests, refactors, tool-driven production (**default**) | `mew-worker` | Sonnet 5 | high |
| Pure mechanical: rename, typo sweeps, repeated boilerplate | `mew-worker-mech` | Haiku 4.5 | — (unsupported on Haiku) |
| Tier-1 review (spec + quality + build/test) | `mew-reviewer` | Sonnet 5 | high |
| Non-code critic (criteria check, fresh context) | `mew-critic` | Opus 4.8 | high |
```

- [ ] **Step 3: Add the ultracode escalation block to Step 5**

In `## Step 5 — Review (two tiers)`, insert the following block immediately AFTER the `**Escalation rule (hard limits):**` list (i.e., between the escalation rule and `## Step 6 — Deliver`):

```markdown
**Ultracode escalation (optional, Mew-controlled):** ultracode is the `/effort` setting above max — the session thinks at xhigh and fans out subagents for multi-agent adversarial review. The session cannot switch to it; only Mew can, via `/effort`. Suggest the switch when any of these fire:

1. **Cross-system diff** — the work spans more files/subsystems than one reviewer context can hold.
2. **Security-sensitive and large** — auth/payments/secrets/user-input work that is unusually big or novel (`/security-review` still runs regardless).
3. **Failed review round 2** — round 3 is the last before a hard stop, so it gets maximum scrutiny.
4. **Mew asks for a thorough audit** — any phrasing to that effect.

Suggesting is not switching: name the trigger that fired and let Mew decide. If Mew declines, proceed with the normal tiers.
```

- [ ] **Step 4: Verify no Fable references and structure intact**

Run:
```bash
grep -ci fable /Users/mewsocialmacmini/.claude/skills/mew-kickoff/SKILL.md; grep -c '^## ' /Users/mewsocialmacmini/.claude/skills/mew-kickoff/SKILL.md
```
Expected: `0` on the first count (grep exits 1 — that is the pass condition) and the same `## ` heading count as before the edit (12: Goal, Modes, Steps 0–6 (7 headings), Model Rubric, Document Conventions, Red Flags).

### Task 2: Update the paired memory file

**Files:**
- Modify: `/Users/mewsocialmacmini/.claude/projects/-Users-mewsocialmacmini-projects/memory/mew-kickoff-workflow.md`

**Interfaces:**
- Consumes: nothing from Task 1 (edits are independent; content must merely agree with it).
- Produces: memory consistent with the new SKILL.md; checked by Task 3.

- [ ] **Step 1: Replace the Why paragraph**

Replace:
```markdown
**Why:** Mew wants to maximize the top model's (Fable 5) value — it interviews, specs, writes strategy/copy, routes, and reviews; worker subagents do production. The session model never writes production code when the pipeline is active.
```
with:
```markdown
**Why:** Mew wants to maximize the session model's value (top available model at effort max — currently Opus 4.8) — it interviews, specs, writes strategy/copy, routes, and reviews; worker subagents do production. The session model never writes production code when the pipeline is active. For heavy reviews (cross-system diffs, large security-sensitive work, a task entering review round 3, or an explicit audit request) the skill suggests Mew switch `/effort` to ultracode for multi-agent adversarial review — only Mew can flip that switch.
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -ci fable /Users/mewsocialmacmini/.claude/projects/-Users-mewsocialmacmini-projects/memory/mew-kickoff-workflow.md
```
Expected: `0` (grep exits 1).

### Task 3: mew-critic gate

**Files:**
- Read-only review of the two files above.

**Interfaces:**
- Consumes: Acceptance Criteria below + the two edited files. NOT the conversation.
- Produces: per-criterion verdict; session model holds the final gate.

- [ ] **Step 1: Dispatch `mew-critic`** with only the Acceptance Criteria and the two file paths.
- [ ] **Step 2: Session model reviews the critic report** against the criteria and declares done or revises (3-round ceiling per skill rules).

## Execution Directive
| # | Task | Agent | Mode | Review gates |
|---|------|-------|------|--------------|
| 1 | SKILL.md edits (Goal, Rubric, Step 5) | (session model) | inline | mew-critic vs acceptance criteria |
| 2 | memory update | (session model) | inline | mew-critic vs acceptance criteria |
| 3 | critic gate | mew-critic | subagent | session final gate |

## Acceptance Criteria
- [ ] `grep -i fable` returns nothing in SKILL.md and mew-kickoff-workflow.md.
- [ ] Model Rubric: session row = top available model @ max; a one-line current mapping names Opus 4.8; an ultracode escalation row exists.
- [ ] Step 5 contains the ultracode block with exactly the 4 triggers (cross-system diff / security-sensitive+large / failed round 2 / Mew asks), phrased as "suggest Mew switch via /effort", never self-switch.
- [ ] Goal section justifies division of labor via effort economy + context economy + review independence (model-agnostic), and keeps the "never write production code inline" rule.
- [ ] Pipeline structure untouched: Steps 0–6, 3-round escalation rule, Document Conventions, Red Flags, five agents all present and unmodified in meaning.
- [ ] No file under `~/.claude/agents/` modified.
- [ ] Memory file's Why paragraph reflects the new session-model wording and the ultracode escalation.
- [ ] SKILL.md remains in English (existing Thai strings preserved).

## Status
interviewed 2026-07-07 | approved: 2026-07-08 | executed: 2026-07-08 | delivered: 2026-07-08 (mew-critic PASS 8/8)
