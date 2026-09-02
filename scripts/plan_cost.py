#!/usr/bin/env python3
"""Cost + wall-clock of one pipeline run: sessions in a project dir whose activity falls on given dates."""
import os, json, time, sys
from collections import defaultdict
proj, dates = sys.argv[1], sys.argv[2].split(",")
ROOT = os.path.join(os.path.expanduser("~/.claude/projects"), proj)
PRICE={"fable":(10,50),"opus":(5,25),"sonnet":(3,15),"haiku":(1,5)}
def tier(m):
    m=(m or "").lower()
    for k in PRICE:
        if k in m: return k
    return "other"
def ts(s):
    try: return time.mktime(time.strptime(s[:19], "%Y-%m-%dT%H:%M:%S"))
    except Exception: return None
tot=defaultdict(lambda: defaultdict(float)); sess=[]; nsub=0
for dp,dn,fns in os.walk(ROOT):
    for fn in fns:
        if not fn.endswith(".jsonl"): continue
        p=os.path.join(dp,fn); role="subagent" if "/subagents/" in p else "main"
        seen=set(); t0=t1=None; hit=False; loc=defaultdict(lambda: defaultdict(float)); turns=0
        with open(p,errors="ignore") as fh:
            for line in fh:
                if '"assistant"' not in line: continue
                try: d=json.loads(line)
                except Exception: continue
                if d.get("type")!="assistant": continue
                tsv=d.get("timestamp","")
                if tsv[:10] in dates: hit=True
                msg=d.get("message") or {}; u=msg.get("usage")
                if not u: continue
                mid=msg.get("id") or d.get("uuid")
                if mid in seen: continue
                seen.add(mid); turns+=1
                k=(role,tier(msg.get("model"))); a=loc[k]
                a["in"]+=u.get("input_tokens",0) or 0; a["out"]+=u.get("output_tokens",0) or 0
                a["cr"]+=u.get("cache_read_input_tokens",0) or 0
                cc=u.get("cache_creation_input_tokens",0) or 0; c1=((u.get("cache_creation") or {}).get("ephemeral_1h_input_tokens",0)) or 0
                a["c1h"]+=c1; a["c5m"]+=max(cc-c1,0)
                t=ts(tsv)
                if t: t0=t if t0 is None else min(t0,t); t1=t if t1 is None else max(t1,t)
        if not hit: continue
        for k,a in loc.items():
            for m,v in a.items(): tot[k][m]+=v
        if role=="main": sess.append((fn, turns, (t1-t0)/60 if t0 and t1 else 0))
        else: nsub+=1
def cost(t,a):
    if t not in PRICE: return 0
    pi,po=PRICE[t]; return (a["in"]*pi+a["cr"]*pi*.1+a["c5m"]*pi*1.25+a["c1h"]*pi*2+a["out"]*po)/1e6
grand=0
for k,a in sorted(tot.items(), key=lambda x:-cost(x[0][1],x[1])):
    c=cost(k[1],a); grand+=c
    print(f"{k[0]:9}{k[1]:8} out={int(a['out']):9d} cache_rd={int(a['cr']):12d} est_$={c:8.2f}")
print(f"TOTAL est_$={grand:.2f}  main sessions={len(sess)} subagent runs={nsub}")
for s in sorted(sess,key=lambda x:-x[1])[:5]: print(f"  main {s[0][:8]} turns={s[1]} dur={s[2]:.0f}m")
