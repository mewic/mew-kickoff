# Execute loop (all harnesses)

Used by every adapter: Claude Code, Codex, Grok, Cursor. Review depth is proportional to the plan's risk and assurance profile; the shape (ledger, review package, capped fix rounds) is borrowed from superpowers' subagent-driven-development, which is no longer a dependency.

**Setup.** Work in a worktree, or a branch when the harness has no worktree support. Create `docs/plans/reports/<plan-slug>/progress.md`; its first lines name the plan, profile, risk, automatic fix-round ceiling (`2` standard, `5` high-assurance), and usage baseline when available. Resume an existing ledger from its last line. Scan the plan once for contradictions and ledger each ruling as `Ruling: <what> — <why> — <cost if wrong>`.

**Per task.**
1. Record `BASE=$(git rev-parse HEAD)`. Fresh-dispatch the named implementer with the task, touched interfaces, Global Constraints, verification scope, and report path `reports/<slug>/task-<N>.md`.
2. On DONE at **low risk**: read the worker report's commands and exit codes; if they cover the brief's verification scope the task passes, otherwise one fix round. At **medium or high risk**: write `git log --oneline BASE..HEAD`, `git diff --stat BASE..HEAD`, and the changed-file path list to `task-<N>-package.md`. Do not dump a full unified diff. Fresh-dispatch `mew-reviewer` with the brief and exact paths to the worker report and package; it reads named files only for a specific concern and runs task-scoped verification independently.
3. Split findings into **blocking** (high confidence and medium-or-greater severity) and **advisory** (low severity or lower confidence). Ledger advisory findings for Tier 2; only blocking findings enter the automatic fix loop.
4. A fix round is one follow-up to the same implementer plus one scoped re-review of only the fix diff. In high-assurance, rounds 4–5 use a fresh implementer one tier up. At the plan's ceiling, the session parks the finding with a ruling or specifies the smallest safe correction; it never expands the loop silently.
5. Ledger completion and usage when available, recompute the frontier, and fill the live agent slots with newly unblocked tasks.

**Final verification.** After all task fixes, run the complete build/test suite exactly once. Record command, exit code, concise result, and a failing excerpt only when needed.

**Profile review.** Low risk proceeds from final verification to Tier 2. Medium risk fresh-dispatches the adapter's standard whole-branch reviewer over `git merge-base <default-branch> HEAD`..HEAD. High risk/high-assurance uses the heavy whole-branch reviewer and the adapter's security review. Whole-branch blocking findings receive one combined fix dispatch and one scoped re-review; advisory findings go to Tier 2. Delete `reports/<slug>/` after delivery when the plan is disposable.
