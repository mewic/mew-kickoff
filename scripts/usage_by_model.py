#!/usr/bin/env python3
"""Aggregate Claude Code token usage since a cutoff date, by role (main session vs subagent) and model."""
import os, sys, json, time
from collections import defaultdict

ROOT = os.path.expanduser("~/.claude/projects")
CUTOFF = time.mktime(time.strptime("2026-07-25", "%Y-%m-%d"))

# $/MTok: (input, output). cache write 5m = 1.25x input, 1h = 2x input, cache read = 0.1x input
PRICE = {
    "fable": (10, 50),
    "opus": (5, 25),
    "sonnet": (3, 15),
    "haiku": (1, 5),
}
def tier(model):
    m = (model or "").lower()
    for k in PRICE:
        if k in m:
            return k
    return "other"

agg = defaultdict(lambda: defaultdict(float))  # (role, model) -> metrics
files_by_role = defaultdict(int)
turns_by_role_model = defaultdict(int)
subagent_files = defaultdict(list)  # model -> list of (turns, total_tokens)
seen = set()
nfiles = 0

for dirpath, dirnames, filenames in os.walk(ROOT):
    for fn in filenames:
        if not fn.endswith(".jsonl"):
            continue
        p = os.path.join(dirpath, fn)
        try:
            if os.path.getmtime(p) < CUTOFF:
                continue
        except OSError:
            continue
        role = "subagent" if "/subagents/" in p else "main"
        nfiles += 1
        files_by_role[role] += 1
        per_file = defaultdict(float)
        per_file_turns = 0
        per_file_model = None
        with open(p, "r", errors="ignore") as fh:
            for line in fh:
                if '"assistant"' not in line:
                    continue
                try:
                    d = json.loads(line)
                except Exception:
                    continue
                if d.get("type") != "assistant":
                    continue
                msg = d.get("message") or {}
                u = msg.get("usage")
                if not u:
                    continue
                mid = msg.get("id") or d.get("uuid")
                key = (p, mid)
                if key in seen:
                    continue
                seen.add(key)
                model = msg.get("model") or "unknown"
                t = tier(model)
                k = (role, t)
                inp = u.get("input_tokens", 0) or 0
                out = u.get("output_tokens", 0) or 0
                cr = u.get("cache_read_input_tokens", 0) or 0
                cc = u.get("cache_creation_input_tokens", 0) or 0
                cc1h = ((u.get("cache_creation") or {}).get("ephemeral_1h_input_tokens", 0)) or 0
                cc5m = cc - cc1h if cc >= cc1h else cc
                a = agg[k]
                a["input"] += inp; a["output"] += out; a["cache_read"] += cr
                a["cache_w5m"] += cc5m; a["cache_w1h"] += cc1h
                turns_by_role_model[k] += 1
                per_file["total"] += inp + out + cr + cc
                per_file["out"] += out
                per_file_turns += 1
                per_file_model = t
        if role == "subagent" and per_file_model:
            subagent_files[per_file_model].append((per_file_turns, per_file["total"], per_file["out"]))

def cost(t, a):
    if t not in PRICE:
        return 0.0
    pi, po = PRICE[t]
    return (a["input"] * pi + a["cache_read"] * pi * 0.1 + a["cache_w5m"] * pi * 1.25 + a["cache_w1h"] * pi * 2.0 + a["output"] * po) / 1e6

print(f"files scanned: {nfiles}  main={files_by_role['main']} subagent={files_by_role['subagent']}")
print()
print(f"{'role':9} {'model':7} {'turns':>7} {'input':>10} {'cache_rd':>12} {'cache_w5m':>11} {'cache_w1h':>11} {'output':>10} {'est_$':>9}")
total_cost = 0.0
rows = []
for k, a in agg.items():
    c = cost(k[1], a)
    total_cost += c
    rows.append((c, k, a))
rows.sort(reverse=True)
for c, k, a in rows:
    print(f"{k[0]:9} {k[1]:7} {turns_by_role_model[k]:7d} {int(a['input']):10d} {int(a['cache_read']):12d} {int(a['cache_w5m']):11d} {int(a['cache_w1h']):11d} {int(a['output']):10d} {c:9.2f}")
print(f"\nTOTAL est_$ = {total_cost:.2f}")
by_role = defaultdict(float)
for c, k, a in rows:
    by_role[k[0]] += c
for r, c in by_role.items():
    print(f"  {r}: ${c:.2f} ({100*c/total_cost:.1f}%)")
print("\nsubagent files per model: count / median turns / median total tokens / median output tokens")
import statistics
for m, lst in subagent_files.items():
    if not lst: continue
    print(f"  {m:7} n={len(lst):5d}  turns~{statistics.median([x[0] for x in lst]):.0f}  total~{statistics.median([x[1] for x in lst]):.0f}  out~{statistics.median([x[2] for x in lst]):.0f}")
