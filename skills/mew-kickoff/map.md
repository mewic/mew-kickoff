# Map (wayfinder-lite)

Chart a map when the work cannot fit one plan — the decisions ahead can't all be named yet, or the effort will clearly span multiple sessions. File: `docs/plans/YYYY-MM-DD-<slug>-map.md`. Name the **Destination** before anything else (the spec, decision, or completed change this effort is finding its way to — it fixes the scope), then sketch:

```markdown
## Destination
<1-2 lines; every session re-orients to this first>

## Decisions so far
- <one-line gist> — <pointer to the plan/ADR/doc holding the detail>

## Not yet specified
<in-scope fog: questions you can tell are coming but can't phrase sharply yet>

## Out of scope
<work consciously ruled beyond the Destination — returns only if the Destination is redrawn>
```

Rules:
- Resolve **one decision per session** — each pass runs the normal pipeline on that decision (interview the delta → plan → execute) and appends one gist line to Decisions so far.
- A question graduates from fog to a decision item when it can be **phrased sharply now**, even if it can't be answered yet.
- The map is an **index, not a store** — gist and point, never restate.
- The map is done when nothing is left to decide before the building starts.
