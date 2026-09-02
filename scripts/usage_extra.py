#!/usr/bin/env python3
"""Extra metrics: thinking share, avg context per turn, session durations, per-session turn counts."""
import os, json, time, statistics
from collections import defaultdict
ROOT = os.path.expanduser("~/.claude/projects")
CUTOFF = time.mktime(time.strptime("2026-07-25", "%Y-%m-%d"))
def tier(m):
    m=(m or "").lower()
    for k in ("fable","opus","sonnet","haiku"):
        if k in m: return k
    return "other"
def ts(s):
    try: return time.mktime(time.strptime(s[:19], "%Y-%m-%dT%H:%M:%S"))
    except Exception: return None
agg = defaultdict(lambda: defaultdict(float))
files = defaultdict(list)  # (role,model) -> list of dict(turns, dur_min, ctx_avg)
for dp, dn, fns in os.walk(ROOT):
    for fn in fns:
        if not fn.endswith(".jsonl"): continue
        p = os.path.join(dp, fn)
        try:
            if os.path.getmtime(p) < CUTOFF: continue
        except OSError: continue
        role = "subagent" if "/subagents/" in p else "main"
        seen=set(); turns=0; ctx=0.0; t0=None; t1=None; model=None
        with open(p, errors="ignore") as fh:
            for line in fh:
                if '"assistant"' not in line: continue
                try: d=json.loads(line)
                except Exception: continue
                if d.get("type")!="assistant": continue
                msg=d.get("message") or {}; u=msg.get("usage")
                if not u: continue
                mid=msg.get("id") or d.get("uuid")
                if mid in seen: continue
                seen.add(mid)
                model=tier(msg.get("model")); k=(role,model)
                out=u.get("output_tokens",0) or 0
                th=((u.get("output_tokens_details") or {}).get("thinking_tokens",0)) or 0
                c=(u.get("cache_read_input_tokens",0) or 0)+(u.get("cache_creation_input_tokens",0) or 0)+(u.get("input_tokens",0) or 0)
                a=agg[k]; a["out"]+=out; a["think"]+=th; a["ctx"]+=c; a["turns"]+=1
                turns+=1; ctx+=c
                t=ts(d.get("timestamp",""))
                if t: t0 = t if t0 is None else min(t0,t); t1 = t if t1 is None else max(t1,t)
        if turns and model:
            files[(role,model)].append({"turns":turns,"dur":((t1-t0)/60 if t0 and t1 else None),"ctx":ctx/turns})
print(f"{'role':9}{'model':8}{'turns':>8}{'avg_ctx/turn':>14}{'thinking%ofOutput':>19}")
for k,a in sorted(agg.items(), key=lambda x:-x[1]['ctx']):
    if a["turns"]<50: continue
    print(f"{k[0]:9}{k[1]:8}{int(a['turns']):8d}{int(a['ctx']/a['turns']):14d}{(100*a['think']/a['out'] if a['out'] else 0):18.1f}%")
print("\nper-file (session) stats: n / median turns / median duration min / p75 duration / median avg-ctx")
for k,lst in sorted(files.items()):
    if len(lst)<5: continue
    durs=[x["dur"] for x in lst if x["dur"] is not None]
    big=[x for x in lst if x["turns"]>=20]
    print(f"  {k[0]:9}{k[1]:8} n={len(lst):5d} turns~{statistics.median([x['turns'] for x in lst]):.0f}  dur~{statistics.median(durs) if durs else 0:.0f}m p75={statistics.quantiles(durs,n=4)[2] if len(durs)>3 else 0:.0f}m  ctx~{statistics.median([x['ctx'] for x in lst]):.0f}")
    if big and k[0]=="main":
        bd=[x["dur"] for x in big if x["dur"] is not None]
        print(f"      main sessions with >=20 turns: n={len(big)} turns~{statistics.median([x['turns'] for x in big]):.0f} dur~{statistics.median(bd):.0f}m p75={statistics.quantiles(bd,n=4)[2]:.0f}m ctx~{statistics.median([x['ctx'] for x in big]):.0f}")
