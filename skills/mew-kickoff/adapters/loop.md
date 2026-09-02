# Minimal execute loop (harnesses without superpowers SDD)

Used by the Codex and Grok adapters. Mirrors SDD's shape so plans and Status lines read the same everywhere.

**Setup.** Work in a worktree (or a branch if the harness has no worktree support). Create `docs/plans/reports/<plan-slug>/` and a ledger `progress.md` there whose first line names the plan file. If a ledger exists, resume from its last line. Scan the plan once for contradictions and rule on them before dispatching (ledger each ruling as `Ruling: <what> — <why> — <cost if wrong>`).

**Per task.**
1. Record `BASE=$(git rev-parse HEAD)`. Dispatch the implementer named in the Execution Directive with: the task text, the interfaces it touches, Global Constraints, and the report path `reports/<slug>/task-<N>.md`.
2. On DONE: write the review package — `git log --oneline BASE..HEAD`, `git diff --stat BASE..HEAD`, `git diff -U10 BASE..HEAD` — into `reports/<slug>/task-<N>-package.md`. Dispatch `mew-reviewer` with the brief, the report path, the package path, and Global Constraints verbatim; report path `task-<N>-review.md`.
3. Findings → fix rounds, five max per task: rounds 1–3 resume the same implementer with the open findings; rounds 4–5 dispatch a fresh implementer one tier up. Each round = one fix dispatch + one scoped re-review of the fix diff. Ledger each round: `Task <N>: fix round <R>/5 (<X> addressed, <Y> open)`.
4. At round 5 with findings still open, the session adjudicates: park with a ruling, or rule on the smallest change that unblocks dependent work. Never discard silently.
5. Ledger completion; recompute the frontier; dispatch the newly unblocked tasks together.

**Final.** Package the whole branch (`git merge-base <default-branch> HEAD`..HEAD) and dispatch the whole-branch review on the adapter's heavy-tier reviewer with the ledger's parked lines. One fix dispatch for all findings, one scoped re-review, then the session's Tier-2 gate. Delete `reports/<slug>/` after delivery if the plan is disposable.
