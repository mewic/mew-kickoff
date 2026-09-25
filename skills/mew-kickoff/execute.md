# Execute (fresh session only)

Read this only in a session whose first pipeline argument is `execute <plan-file>`. If this session already ran the interview, stop and hand Mew a new-session first message instead.

Prereq: the adapter is already read. Open the plan, CONTEXT.md, and referenced ADRs. If `approved:` is pending, present the summary and wait. Suggest the adapter's execute-session effort; return to top effort before the Tier-2 gate.

Agent names: `mew-worker` (specified production), `mew-worker-heavy` (complex/security-sensitive), `mew-worker-mech` (mechanical), `mew-reviewer` (Tier 1), `mew-critic` (non-code/plan critic). An adapter may add a heavy reviewer. The adapter maps each role to model and effort. `scripts/smoke.sh` checks every pointer after harness or plugin updates.

## Step 4 — Execute

**Code tasks** → the adapter's execute loop (per-plan ledger, review package per task, capped fix rounds, and profile-driven final review). Four rules hold in every harness:

1. **Implementer** = the agent named in the Execution Directive, dispatched with the complete task spec; model + effort come from the agent's definition or the adapter table.
2. **Reviewers** = `mew-reviewer` per task at medium or high risk, dispatched with the review package, brief, worker report path, and Global Constraints. Low-risk tasks skip the reviewer: the worker's report (commands + exit codes) is the evidence, checked at the final gate. Medium/high risk also gets a whole-branch review; high risk uses the adapter's heavy reviewer plus security review. The session is the final gate.
3. **Escalation**: `standard` allows two automatic fix rounds; `high-assurance` allows five, escalating after round 3 (mech → worker → heavy). Only high-confidence findings of medium-or-greater severity enter the automatic loop. Ledger advisory findings for the final gate. A heavy worker failing twice usually means the spec is wrong: rule on it, fix the plan, and redispatch.
4. **Parallel frontier**: the plan's Blocked-by column already serializes tasks that share files, so independent tasks run together; if two implementers still collide in git, serialize the rest of that wave.

Every dispatch of a built-in agent names its model where the adapter's Agents section allows it; a dispatch that inherits the session model pays the session's price.

**Dispatch the frontier in parallel:** every task whose Blocked-by entries have all passed review is on the frontier — dispatch those together, not one at a time. When a task clears Step 5, re-compute the frontier and dispatch the newly unblocked.

**Fresh dispatch:** workers, reviewers, critics, and explorers start without the parent conversation. Give each a complete bounded prompt or exact file paths; the adapter defines the harness control. Every subagent replies with at most 150 words and writes its report to a file. The session opens a full report only when its summary flags something, and uses a fresh read-only explorer for source questions. Run continuously; do not check in between tasks.

At every plan checkpoint supported by the harness, record usage in the ledger. If the run reaches its declared agent-run or fix-round ceiling, stop automatic expansion and let the session rule on the smallest path to acceptance.

**Consulting / strategy / copy** already written in the interview session is reused here only for critic/delivery. If it is still missing, the session model writes it to `docs/deliverables/` from the plan's complete brief.

**Marketing production** → dispatch `mew-worker` with the full brief. It executes tools without inventing copy; fix brief gaps first.

## Step 5 — Review

**Tier 1 — `mew-reviewer`:** every medium- or high-risk code task receives fresh-context spec and quality review plus independently run task-scoped verification; low-risk tasks are verified by their worker and read at Tier 2. Successful logs are command + exit code + concise summary; include output excerpts only for failures.

**Profile gate:** low risk goes from worker verification to one final full-suite verification. Medium risk adds a fresh whole-branch review. High risk uses the adapter's heavy whole-branch reviewer and security review. The complete build/test suite runs once after all task fixes, not once per reviewer.

**Tier 2 — final gate (session model, top effort):** read the Tier-1 summaries, any profile-required whole-branch/security findings, the final verification result, and the acceptance criteria. Only this gate can declare the work done.

**Non-code deliverables:** dispatch `mew-critic` with ONLY the acceptance criteria + the deliverable (not the conversation). The session revises per critic feedback, three-round ceiling, then report to Mew.

**Stopping:** ask before an irreversible operation, a security-sensitive action, a side effect outside the worktree (merge, push, publish), a plan broken past guessing, or a breaker that leaves a security-sensitive finding open. Heavier review than the tiers give: the adapter's **Heavier review** section, suggested to Mew with the trigger named — never launched on the session's own initiative.

## Step 6 — Deliver

Report delivered work, gate evidence, criteria, asset links, and frontier-wave count. Update plan Status, CONTEXT.md, and ADRs for decisions that crystallized.

## Red Flags — stop and re-read execute.md plus the adapter

- The session model is writing production code while the pipeline is active.
- A worker is inventing copy or design decisions not in the brief.
- Independent tasks dispatched one at a time when the frontier held several.
- A reviewer dispatched for a low-risk task, or none for a medium/high-risk one.
- A built-in agent dispatched without a model, a full report pasted into the session, the session reading source files in Step 4, or running without the adapter.
- Automatic heavier review without Mew naming the trigger.
