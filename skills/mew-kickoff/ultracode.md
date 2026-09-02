# Ultracode escalation (optional, Mew-controlled)

Ultracode is a distinct `/effort` value, separate from `xhigh`: xhigh-level thinking plus dynamic multi-agent workflows that fan out adversarial review. Only Mew can switch to it. Suggest the switch when any of these fire:

1. **Cross-system diff** — the work spans more files/subsystems than one reviewer context can hold.
2. **Security-sensitive and large** — auth/payments/secrets/user-input work that is unusually big or novel (`/security-review` still runs regardless). Suggest it for the whole-branch review by default here.
3. **Fix round 4 reached** — rounds 4–5 are the last before the breaker.
4. **Mew asks for a thorough audit** — any phrasing to that effect.

Suggesting is not switching: name the trigger that fired and let Mew decide. If Mew declines, proceed with the normal tiers.
