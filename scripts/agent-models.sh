#!/usr/bin/env bash
# Rewrite the model line of the five Claude agent files. Open a new session afterwards.
#   scripts/agent-models.sh economy   # sonnet/opus/haiku per adapters/claude.md
#   scripts/agent-models.sh fable     # all five → fable (only when Mew says so)
set -euo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)/agents/claude"
case "${1:-}" in
  economy) declare -A M=([mew-worker]=sonnet [mew-reviewer]=sonnet [mew-worker-mech]=haiku [mew-worker-heavy]=opus [mew-critic]=opus) ;;
  fable)   declare -A M=([mew-worker]=fable  [mew-reviewer]=fable  [mew-worker-mech]=fable [mew-worker-heavy]=fable [mew-critic]=fable) ;;
  *) echo "usage: $0 economy|fable"; exit 1 ;;
esac
for a in "${!M[@]}"; do sed -i '' "s/^model: .*/model: ${M[$a]}/" "$D/$a.md"; echo "$a -> ${M[$a]}"; done
