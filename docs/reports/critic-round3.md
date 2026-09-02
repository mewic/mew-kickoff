# critic round 3 (Phase 4 split) — recorded by the session (critic could not write files this session)

Verdict: PASS with one must-fix. Criteria 1–7, 9 met; 8 partially met → fixed:
- F1 heavy-tier reviewer unresolved in adapters → claude: `mew-reviewer` with `model: opus` (call-site override); codex/grok: same model, request xhigh effort; loop.md points at the adapter.
- F2 "escalation" overloaded → core now says "Heavier review" section; each adapter has a `## Heavier review` heading.
- F3 built-in model rule "per the adapter's table" → "where the adapter's Agents section allows it".
- F4 smoke vs `[agents]` block → codex.md explains the flag is the gate, the block is defaults/concurrency.
- Unguarded: `~/.agents/skills/{grilling,domain-modeling}` now checked by smoke; `codex review` claim marked UNVERIFIED.
- Nits: harness detection hint added to core; "Five roles"; defer wording; loop.md worktree + `<default-branch>`; cap raised to 2,200 (core at 2,140).
Not changed: critic TOML keeps `sandbox_mode = "workspace-write"` so it can write its report (read-only by instruction).
