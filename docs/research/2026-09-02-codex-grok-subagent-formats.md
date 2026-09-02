# Skills & Subagents Across Claude Code, Codex CLI, and Grok CLI

Research date: 2026-09-02. Scope: primary-source only (official docs, vendor GitHub repos, local CLI `--help` output, and files actually present on this machine). Purpose: inform a port of `~/.claude/skills/mew-kickoff/SKILL.md` (a Claude Code skill that dispatches Claude-Code-specific subagents `mew-worker` / `mew-worker-heavy` / `mew-worker-mech` / `mew-reviewer` / `mew-critic` defined in `~/.claude/agents/mew-*.md`) to Codex CLI and Grok CLI.

Local versions at time of research: `codex-cli 0.152.0` (`codex --version`), `grok 1.0.13 (5e9a58528b76)` (`grok --version`). Docs sites redirect (308/301) to renamed hosts — `developers.openai.com/codex/*` → `learn.chatgpt.com/docs/*`, `docs.claude.com/en/docs/claude-code/skills` → `code.claude.com/docs/en/skills` — content below is from the resolved (redirect-target) URL in each case, noted explicitly.

---

## Claude Code

Source: `https://code.claude.com/docs/en/skills` (redirect target of `https://docs.claude.com/en/docs/claude-code/skills`, fetched directly), cross-checked against local file `~/.claude/skills/mew-kickoff/SKILL.md`.

### Skill directories

| Location | Path | Applies to |
|---|---|---|
| Enterprise | managed settings dir | org-wide |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | all projects |
| Project | `.claude/skills/<skill-name>/SKILL.md` | one project |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | where plugin enabled |

Also loads nested `.claude/skills/` under subdirectories the session touches (monorepo package skills), and `.claude/skills/` inside any `--add-dir`-added directory. `mew-kickoff` itself lives at the personal level: `~/.claude/skills/mew-kickoff/{SKILL.md, ultracode.md, map.md, scripts/smoke.sh}` (confirmed via local `find`).

### Frontmatter fields honored (full table, from `code.claude.com/docs/en/skills`)

`name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context` (`fork` = run in a subagent), `agent` (which subagent type when `context: fork`), `background`, `hooks`, `paths`, `shell`, `metadata`, `license`, `compatibility`. All fields optional; only `description` recommended.

`mew-kickoff`'s own frontmatter uses exactly two of these: `name: mew-kickoff` and `disable-model-invocation: true` (confirmed by reading the file) — i.e. it is user-invoked only (`/mew-kickoff`), never auto-triggered by the model.

Quoting the doc directly on the spec-vs-extension boundary:

> "Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard... Claude Code extends the standard with additional features like invocation control, subagent execution, and dynamic context injection."

> Outside Claude Code (claude.ai uploads, Skills API, `anthropics/skills` packaging), only six frontmatter fields are legal: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Anything else — e.g. `argument-hint` — fails packaging with a hard error: `"Unexpected key(s) in SKILL.md frontmatter: argument-hint. Allowed properties are: allowed-tools, compatibility, description, license, metadata, name"`.

### Invocation: user vs model

Default: both. `disable-model-invocation: true` → only the user can invoke (`/name`); the model is blocked even if it tries. `user-invocable: false` → only the model can invoke; hidden from the `/` menu.

### Subagents ("Run skills in a subagent")

`context: fork` + `agent: <subagent_type>` runs the skill body in a forked subagent context instead of inline; `background` (default `true`) controls whether the invoking turn waits for the result. This is the mechanism `mew-kickoff` relies on indirectly: it dispatches via the **Agent tool** with `subagent_type` set to one of `mew-worker` / `mew-worker-heavy` / `mew-worker-mech` / `mew-reviewer` / `mew-critic`, each a separate file under `~/.claude/agents/mew-*.md` whose own frontmatter pins model + effort (per `mew-kickoff`'s "Model Rubric" section, confirmed by reading the file: e.g. `mew-worker` → Sonnet 5 / high, `mew-worker-heavy` → Opus 5 / xhigh).

### `$ARGUMENTS` and other substitutions

`$ARGUMENTS` (all args), `$ARGUMENTS[N]`/`$N` (indexed), `$name` (named, via `arguments:` frontmatter), plus `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`. `mew-kickoff` uses the plan-file argument pattern (`/mew-kickoff execute <docs/plans/FILE.md>`) which resolves through this substitution mechanism.

### Other Claude-Code-specific mechanics observed in `mew-kickoff` that are NOT part of the agentskills.io spec

- Calling another skill by its plugin-namespaced name from inside skill prose: `superpowers:subagent-driven-development`, `superpowers:writing-plans`, `grill-with-docs` (a bare, non-namespaced personal-skill reference).
- Slash commands invoked as user actions from within the skill's narrative: `/effort`, `/security-review`.
- Dynamic context injection via `` !`command` `` inline shell execution in `SKILL.md` bodies (documented separately in the skills doc; not directly used in `mew-kickoff`'s body but is a Claude-Code-only body feature per the doc: *"Claude Code-only body features, such as dynamic context injection, don't function in claude.ai chat or through the API."*).

---

## Codex CLI

Sources: `https://learn.chatgpt.com/docs/build-skills.md` (redirect target of `https://developers.openai.com/codex/skills.md`), `https://learn.chatgpt.com/docs/customization/overview` (redirect target of `https://developers.openai.com/codex/concepts/customization`), `https://learn.chatgpt.com/docs/agent-configuration/subagents` (redirect target of `https://developers.openai.com/codex/concepts/subagents`), `https://learn.chatgpt.com/docs/config-file/config-reference` (redirect target of `https://developers.openai.com/codex/config-reference`); local commands `codex --help`, `codex features list`, `codex agents --help`; local file `~/.codex/config.toml`; local dir listing `~/.codex/skills/`; npm package `@openai/codex` README (`/opt/homebrew/lib/node_modules/@openai/codex/README.md`, points to `github.com/openai/codex` and `developers.openai.com/codex`).

### Skill directories (scan order, per `learn.chatgpt.com/docs/build-skills.md`)

1. `$CWD/.agents/skills` (where you launch Codex)
2. `$CWD/../.agents/skills` (parent, nested repos)
3. `$REPO_ROOT/.agents/skills` (git repo root)
4. `$HOME/.agents/skills` (user personal)
5. `/etc/codex/skills` (machine/container shared)
6. system-level, bundled with Codex by OpenAI

Confirmed locally: `~/.codex/skills/` contains only a `.system` directory (no user skills) — Codex does **not** use `~/.codex/skills/` as a personal skills directory the way Claude Code uses `~/.claude/skills/`; personal skills instead live at `~/.agents/skills/`, which on this machine holds 27 skills (`research`, `tdd`, `wizard`, `handoff`, etc. — `ls ~/.agents/skills`).

### Frontmatter fields honored

Doc example shows only the two required fields:
```md
---
name: skill-name
description: Explain exactly when this skill should and should not trigger.
---
```
The fetched page did not enumerate a Codex-specific extension list analogous to Claude Code's `disable-model-invocation`/`allowed-tools`/etc. table — **UNVERIFIED**: whether Codex CLI itself reads any frontmatter fields beyond `name`/`description` (e.g. whether it honors `disable-model-invocation` when present) was not found in the fetched documentation; the `disable-model-invocation` field is confirmed as a Claude-Code frontmatter key, not confirmed as read by Codex.

### Invocation: user vs model

> Explicit user invocation: "run `/skills` or type `$` to mention a skill." Implicit model invocation: "ChatGPT or Codex can choose a skill when your task matches the skill `description`."

### `agents/openai.yaml` policy file (per-skill, sits alongside `SKILL.md` under an `agents/` subdirectory)

Confirmed on this machine at `~/.agents/skills/*/agents/openai.yaml` (26 of the 27 personal skills have one, e.g. `~/.agents/skills/wizard/agents/openai.yaml`, `~/.agents/skills/handoff/agents/openai.yaml`). Two blocks observed:

```yaml
interface:
  display_name: "Wizard"
  short_description: "Generate an interactive setup wizard"
```
```yaml
interface:
  display_name: "Handoff"
  short_description: "Compact a conversation into a handoff"
policy:
  allow_implicit_invocation: false
```

Per the doc: `policy.allow_implicit_invocation` (default `true`) — *"When `false`, Codex won't implicitly invoke the skill based on user prompt; explicit `$skill` invocation still works."* The `interface` block additionally supports icon paths and an optional `default_prompt` per the doc (not observed locally). **UNVERIFIED**: whether `agents/openai.yaml` is itself part of the agentskills.io spec, or an OpenAI/Codex-only extension consumed by tooling that authors these `~/.agents/skills/*` skills (no `agents/grok.yaml` or `agents/claude.yaml` sibling files were found locally — `find ~/.agents/skills -path "*/agents/*" -type f ! -iname "openai.yaml"` returned nothing — so this convention as observed is single-runtime today).

### Subagents (`multi_agent` feature flag)

Confirmed stable+enabled locally: `codex features list` → `multi_agent  stable  true`, plus related stable-true flags `skill_search`, `skill_mcp_dependency_install`, `hooks`. `~/.codex/config.toml` also shows `hooks.state` entries for `subagent_start` and `subagent_stop` hook points (local file), i.e. Codex has hook lifecycle events specifically for subagent spawn/exit.

Per `learn.chatgpt.com/docs/agent-configuration/subagents`:
- Custom agent definitions live as **standalone TOML files** under `.codex/agents/` (project) or `~/.codex/agents/` (personal). Each file requires: `name` (string), `description` (string), `developer_instructions` (string). Optional per-agent overrides: `model`, `model_reasoning_effort` (`low|medium|high|xhigh|ultra`), `sandbox_mode` (`read-only|workspace-write`), `mcp_servers`, `skills.config`.
- Global config in `config.toml`:
```toml
[agents]
enabled = true
max_concurrent_threads_per_session = 8
default_subagent_model = "gpt-5.6"
default_subagent_reasoning_effort = "medium"
interrupt_message = true
```
  Per-role overrides: `agents.<name>.config_file` (path to a TOML layer) and `agents.<name>.description`.
- Three built-in agents ship by default: `default` (general-purpose), `worker` (implementation), `explorer` (read-heavy exploration).
- Spawn mechanism, per `learn.chatgpt.com/docs/config-file/config-reference`: the `multi_agent` feature exposes five tools to the running session — **`spawn_agent`, `send_input`, `resume_agent`, `wait_agent`, `close_agent`** — matching an independent `WebSearch` result that named the same five tools. A user/session can request e.g. *"Spawn one subagent for security risks, one for test gaps, and one for maintainability"* and Codex orchestrates spawning, routing, waiting, and closing automatically.
- Concurrency limit: `agents.max_concurrent_threads_per_session` (config key confirmed in both the subagents page and config-reference page; the subagents page also called this `max_concurrent_threads_per_session = 8` as an example value, legacy alias `agents.max_threads`). **UNVERIFIED**: an explicit nesting-depth key (`max_depth`) was reported by a third-party WebSearch summary (not a primary source) but was **not** confirmed in either primary-source fetch of the subagents or config-reference pages — treat `max_depth` as unconfirmed.
- CSV batch fan-out (`spawn_agents_on_csv` mentioned in third-party search summaries) — **UNVERIFIED**: not found in the two primary-source pages fetched; flagging as a gap rather than asserting it exists.

### Skill ↔ subagent interaction

**UNVERIFIED**: no primary-source text was found confirming whether a Codex skill can itself name/spawn a specific `~/.codex/agents/*.toml`-defined subagent by name from inside its own instructions (analogous to Claude Code's `context: fork` + `agent:` frontmatter). The subagent-spawning tools (`spawn_agent` etc.) are session-level tools available to the running model; a skill's Markdown body could plausibly instruct the model to call them, but this was not directly documented in the fetched pages.

---

## Grok CLI

Sources: `grok --help`, `grok agent --help`, `grok inspect --help`, `grok plugin --help`, `grok memory --help` (local commands); `~/.grok/config.toml` (local file); local directory evidence (`~/.grok/skills/wizard` is a symlink to `../../.agents/skills/wizard`, confirmed via `ls -la`); `https://docs.x.ai/build/features/subagents`; `https://docs.x.ai/build/features/skills-plugins-marketplaces`; `https://docs.x.ai/build/overview`; `https://docs.x.ai/build/modes-and-commands`; `https://docs.x.ai/build/cli/headless-scripting`.

### Skill directories and frontmatter

Per `docs.x.ai/build/features/skills-plugins-marketplaces`, Grok searches, in order:
1. `./.grok/skills/` walked up to the repo root
2. `~/.grok/skills/`
3. plugin `skills/` directories
4. custom paths from `[skills] paths` in `~/.grok/config.toml`
5. additionally, user-level skills load from `~/.agents/skills/`

This last point matches local evidence exactly: `~/.grok/skills/wizard` is a symlink into `~/.agents/skills/wizard` (the same cross-runtime skill directory Codex also reads), and `~/.grok/config.toml` shows `[marketplace] default_skills_installs_purged = true` / `official_marketplace_auto_installed = true` plus a registered xAI official marketplace source (`git = "https://github.com/xai-org/plugin-marketplace.git"`) — local file, confirms marketplace-driven skill install is a first-class Grok concept.

Frontmatter fields recognized (per the fetched page): `name` (defaults to directory name), `description` (defaults to first paragraph), `when-to-use`, `paths` (gitignore-style visibility patterns), `allowed-tools`, `argument-hint`, `user-invocable` (default `true`), `disable-model-invocation` (default `false`), `metadata` (with `author`/`short-description` surfaced in UI). Notably, the doc states Grok's skill loader **accepts but does not apply** `model`, `effort`, `license`, `compatibility` — i.e. these fields are legal frontmatter but have no runtime effect in Grok, unlike Claude Code where `model`/`effort` are honored. **No `agents/openai.yaml`-style policy schema was found documented for Grok** on the fetched page — since the local `~/.grok/skills/wizard` symlink target (`~/.agents/skills/wizard`) does carry an `agents/openai.yaml`, but nothing in Grok's own docs describes Grok reading it, this is flagged **UNVERIFIED: whether Grok CLI reads or ignores `agents/openai.yaml`** (most likely ignored, since the doc's own frontmatter table has no equivalent policy block, but this is an inference, not a confirmed fact).

### Invocation: user vs model

Skills surface as `/` slash commands in the unified extensions modal (`/plugins`, `/hooks`, `/skills`, `/mcps`), consistent with `grok --help`'s general design (many subcommands: `plugin`, `mcp`, `memory`, `sessions`, etc., confirmed via local `grok --help`). `disable-model-invocation`/`user-invocable` gate model-vs-user invocation the same conceptual way as Claude Code and Codex.

### Subagents

Confirmed via local `grok --help`: top-level flags `--agent <NAME>` ("Agent name or definition file path"), `--agents <JSON>` ("Inline subagent definitions as JSON"), `--no-subagents` ("Disable subagent spawning"), `--reasoning-effort <EFFORT>` (alias `--effort`) — these apply to the *session's own* model, not confirmed to set a per-subagent value (see gap below). `grok agent --help` additionally shows `--agent-profile <PATH>` ("Path to an agent profile file") on the headless/stdio agent runner, a separate flag from the top-level `--agent`.

Per `docs.x.ai/build/features/subagents` (primary source, but page content is thin):
- Subagents are "independent child sessions with their own context. They return a summary to the parent when finished."
- Three built-in types: `general-purpose` (default full-capability child), `explore` (read/list/search only — no shell, no edits), `plan` (drafts an implementation plan — no shell, no edits).
- Custom agent types are added/overridden under `.grok/agents/` (project) or `~/.grok/agents/` (personal).
- **Personas** are a distinct, narrower concept — "behavioral overlays only (tone, focus, contracts)" — not separate agent types — defined under `[subagents.personas]` in config or `.grok/personas/*.toml` / `~/.grok/personas/*.toml`.
- Management via TUI: `/config-agents` (alias `/agents`) or `/personas`.
- Reserved names: an independent WebSearch summary (not directly re-confirmed by primary-source page fetch in this session) stated subagent names cannot be `general`, `explore`, `vision`, `verify`, or `computer` because those are reserved for built-ins — **UNVERIFIED at primary-source level**: this exact reserved-name list was reported by search-engine synthesis, not directly quoted from a fetched docs page, and the fetched `docs.x.ai/build/features/subagents` page in this session showed built-in names as `general-purpose`/`explore`/`plan` (a naming mismatch with the search-summary's `general`/`vision`/`computer`/`verify` list) — treat the reserved-name list as unverified/possibly stale until confirmed against the live page directly.

**Gaps — could not confirm from primary sources fetched in this session, despite trying `docs.x.ai/build/features/subagents`, `docs.x.ai/build/modes-and-commands`, and `docs.x.ai/build/cli/headless-scripting`:**
- **UNVERIFIED: the exact JSON schema of `--agents <JSON>`** (field names, types, whether `model`/`reasoning_effort`/`tools`/`system_prompt` are the literal key names). A WebSearch summary (secondary, not confirmed against the primary page directly) suggested a shape like `{ "subAgents": [ { "name": "security-review", "model": "grok-4.3", "instruction": "..." } ] }`, using `subAgents` and `instruction` as keys — this is **not** independently confirmed by a direct page fetch in this session and should be treated as unverified until checked against `grok --help agent` or the live docs page with a working fetch.
- **UNVERIFIED: the exact schema of an agent-definition file** used with `--agent <file>` (i.e. what a `.grok/agents/*.toml` or `.json` file must contain field-by-field).
- **UNVERIFIED: the tool/mechanism name** a running Grok session uses internally to spawn a named subagent from inside a skill (Codex's equivalent is the documented `spawn_agent` tool; no equivalent name was found in Grok's fetched docs).
- **UNVERIFIED: concurrency or nesting limits** for Grok subagents (no `max_threads`/`max_depth`-equivalent config key was found in the fetched pages).
- Grok does have a `/fork` concept ("Branch the current session into a peer agent," per `docs.x.ai/build/modes-and-commands`) which is a session-fork, not a subagent-spawn — worth distinguishing from actual subagents when porting.
- Headless mode (`docs.x.ai/build/cli/headless-scripting`) documents `-p`/`--single`, `-m`/`--model`, `--session-id`, `--resume`, `--continue`, `--cwd`, `--output-format`, `--always-approve`, `--no-alt-screen`, `--no-auto-update`, and a separate ACP (Agent Control Protocol) path via `grok agent stdio` using JSON-RPC — but the fetched page did not show `--agent`/`--agents` flag documentation or examples, despite `grok --help` showing them as real top-level flags. This is a documentation gap, not evidence the flags don't work — the flags are directly confirmed via local `grok --help` output even though the docs page didn't elaborate on them.

---

## agentskills.io spec

Source: `https://raw.githubusercontent.com/agentskills/agentskills/main/docs/specification.mdx` (the spec repo's own `docs/specification.mdx`, fetched directly). Cross-checked against Claude Code's own restatement of the same six fields (`code.claude.com/docs/en/skills`, "Using skill frontmatter outside Claude Code" section) — the two sources agree.

### Required fields
- **`name`** — max 64 chars, lowercase letters/numbers/hyphens only, no leading/trailing/consecutive hyphens, must match the parent directory name.
- **`description`** — max 1024 chars, non-empty; says what the skill does and when to use it.

### Optional fields
- **`license`** — license name or a reference to a bundled license file.
- **`compatibility`** — max 500 chars; environment requirements (product fit, system deps, network needs).
- **`metadata`** — a map of string keys to string values, for implementation-specific properties.
- **`allowed-tools`** — space-separated string of pre-approved tools; marked **experimental** in the spec.

The spec's own validator rejects anything outside these six keys (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`) — confirmed independently by Claude Code's docs, which quote the exact validator error: `"Unexpected key(s) in SKILL.md frontmatter: argument-hint. Allowed properties are: allowed-tools, compatibility, description, license, metadata, name"`.

### `agents/openai.yaml` — NOT part of the core spec

The fetched `specification.mdx` contains **no mention** of `agents/openai.yaml`, `policy.allow_implicit_invocation`, or an `interface` block (`display_name`, `short_description`). This confirms the `agents/openai.yaml` mechanism observed locally under `~/.agents/skills/*/agents/openai.yaml` is a **Codex/OpenAI-specific extension layered on top of the agentskills.io spec**, not a spec-mandated file — it is optional metadata a skill author adds for Codex specifically, sitting in a sibling `agents/` directory next to `SKILL.md` rather than in `SKILL.md`'s own frontmatter (which stays spec-compliant). No sibling `agents/claude.yaml` or `agents/grok.yaml` convention was found anywhere in `~/.agents/skills/`, so as observed on this machine, per-runtime policy override files are a Codex-only pattern today, not a generalized multi-runtime one.

---

## Portability hazards: what in `mew-kickoff`'s Claude-Code-style skill would break elsewhere

Concrete, based on reading `~/.claude/skills/mew-kickoff/SKILL.md` against the above:

1. **`disable-model-invocation: true` frontmatter key.** Confirmed Claude-Code-specific (in the full field table). Codex's fetched skill docs did not confirm this key is honored at all (only `name`/`description` were shown in the minimal example) — **UNVERIFIED whether Codex respects it**; Grok *does* have a same-named, same-default (`false`) field per its own docs, so this one is likely to port cleanly to Grok but is a genuine risk on Codex until confirmed.

2. **`Agent` tool + `subagent_type` referencing Claude-Code agent-definition files.** `mew-kickoff` dispatches work via `subagent_type: mew-worker` / `mew-worker-heavy` / `mew-worker-mech` / `mew-reviewer` / `mew-critic`, each a `~/.claude/agents/mew-*.md` file whose frontmatter bakes in model + effort. Neither Codex nor Grok has an identical mechanism:
   - Codex's nearest equivalent is a **TOML file** under `~/.codex/agents/<name>.toml` (fields `name`, `description`, `developer_instructions`, optional `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`) invoked via the `spawn_agent` tool — different file format (TOML vs Markdown+frontmatter), different required field (`developer_instructions` is mandatory where Claude Code's agent files are prose bodies), and a different key name for reasoning effort (`model_reasoning_effort` vs Claude Code's `effort`).
   - Grok's nearest equivalent is `.grok/agents/*` (format/schema **UNVERIFIED** — see gaps above) invoked via `--agent <name-or-path>` or inline `--agents <JSON>` (schema **UNVERIFIED**) — and Grok's own SKILL.md frontmatter table explicitly does **not** apply `model`/`effort` fields even when present, so any attempt to pin per-task model/effort from inside a *skill's* frontmatter (as opposed to the separate agent-definition file) silently no-ops on Grok.
   - Net effect: the five `mew-worker*`/`mew-reviewer`/`mew-critic` definitions cannot be ported as-is; they need to become native Codex `.codex/agents/*.toml` files and native Grok `.grok/agents/*` files (schema TBD pending the Grok gap above), with the model-economy table (`mew-worker` → Sonnet-tier/high effort, `mew-worker-heavy` → Opus-tier/xhigh, etc.) re-expressed in each runtime's own per-agent model/effort keys.

3. **Skill-to-skill references by name** (`superpowers:subagent-driven-development`, `superpowers:writing-plans`, `grill-with-docs`) rely on Claude Code's plugin-namespace resolution (`plugin-name:skill-name`) and on Claude auto-loading a referenced skill mid-task. Codex's and Grok's skill-directory conventions (flat `~/.agents/skills/<name>/` — no plugin-namespace prefix observed for either) mean namespaced references like `superpowers:writing-plans` have no direct equivalent; a port would need to either inline that guidance or restructure it as a plain top-level skill name both runtimes can resolve unambiguously.

4. **Slash commands invoked from within skill prose** (`/effort`, `/security-review`) are Claude-Code UI/session commands. Codex's user-facing skill invocation syntax is `/skills` or `$skillname` (per its docs); Grok's is `/` through its unified extensions modal plus `/config-agents`/`/personas`. None of these three overlap in spelling, so any in-skill instruction telling the user (or model) to "run `/effort`" needs a runtime-specific rewrite, not just a syntax tweak.

5. **`$ARGUMENTS`-style substitution and `${CLAUDE_*}` variables.** `mew-kickoff` uses the `/mew-kickoff execute <plan-file>` argument pattern (Claude Code's `$ARGUMENTS`/positional-arg mechanism, confirmed in the skills doc). Codex's fetched docs did not show an equivalent substitution syntax for skill arguments — **UNVERIFIED** whether Codex skills support positional/named argument substitution at all beyond the free-text prompt the user types after `$skillname`. Grok's frontmatter table has `argument-hint` (autocomplete hint) but the fetched page did not show a corresponding `$ARGUMENTS`/`$N` substitution mechanism either — **UNVERIFIED** for Grok too. Any `${CLAUDE_SESSION_ID}`/`${CLAUDE_PROJECT_DIR}`-style variable is Claude-Code-only by construction (the names are literally `CLAUDE_*`) and has no confirmed equivalent in either other CLI.

6. **`context: fork` + `agent:` frontmatter** (Claude Code's in-skill way of saying "run this skill's body in a named subagent") has no directly confirmed equivalent frontmatter key in either Codex's or Grok's SKILL.md field lists — both would instead rely on the skill's Markdown body explicitly instructing the model to invoke the runtime's own subagent-spawn mechanism (Codex: tell the model to call `spawn_agent`; Grok: mechanism **UNVERIFIED**, see gap above), rather than a declarative frontmatter switch.

7. **Hooks tied to subagent lifecycle.** Codex has first-class `subagent_start`/`subagent_stop` hook points (confirmed in `~/.codex/config.toml`'s `[hooks.state]` entries). Claude Code's skills doc mentions a `hooks` frontmatter field scoped to skill invocation, a different mechanism. **UNVERIFIED** whether Grok has any hook points at all tied to subagent spawn/exit — not found in the fetched Grok docs pages in this session.

---

## Comparison table

| | Claude Code | Codex CLI | Grok CLI |
|---|---|---|---|
| **Skills dir(s)** | `~/.claude/skills/` (personal), `.claude/skills/` (project, + nested), `<plugin>/skills/` (plugin), enterprise managed dir | `$CWD/.agents/skills` → parent → repo root → `$HOME/.agents/skills` → `/etc/codex/skills` → bundled system; **not** `~/.codex/skills/` for personal skills (confirmed empty except `.system` locally) | `./.grok/skills/` walked to repo root → `~/.grok/skills/` → plugin `skills/` dirs → `[skills] paths` in config → also `~/.agents/skills/` |
| **Frontmatter fields honored** | Full extended set: `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`, `metadata`, `license`, `compatibility` | Confirmed: `name`, `description`. Others **UNVERIFIED** (not enumerated in fetched docs) | Confirmed: `name`, `description`, `when-to-use`, `paths`, `allowed-tools`, `argument-hint`, `user-invocable`, `disable-model-invocation`, `metadata`. `model`/`effort`/`license`/`compatibility` accepted but **not applied** |
| **Spec-portable fields (agentskills.io)** | 6: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` (rest are Claude Code extensions) | Same 6, per spec; Codex's own docs only explicitly confirmed 2 of them (`name`, `description`) | Same 6, per spec; Grok's own docs confirm all 6 as recognized keys (2 applied only as metadata, not runtime-affecting) |
| **Subagent definition location/format** | `~/.claude/agents/*.md` (Markdown + YAML frontmatter, e.g. `mew-worker.md`) | `~/.codex/agents/*.toml` or `.codex/agents/*.toml` (TOML; required `name`, `description`, `developer_instructions`) | `~/.grok/agents/` or `.grok/agents/` (format **UNVERIFIED**); separately, `--agent <file>` and inline `--agents <JSON>` (schema **UNVERIFIED**) |
| **Per-agent model/effort** | Yes, in the agent's own frontmatter (`model:`, plus session/skill `effort:`) | Yes: `model`, `model_reasoning_effort` (`low\|medium\|high\|xhigh\|ultra`) in the agent TOML, or `agents.default_subagent_model` / `agents.default_subagent_reasoning_effort` globally | `--reasoning-effort`/`--effort` and `-m`/`--model` exist as CLI flags; whether an individual named subagent can pin its own independent of the parent session is **UNVERIFIED** from primary docs |
| **Spawn mechanism** | `Agent` tool with `subagent_type` param (session-level tool call) | `spawn_agent` tool (plus `send_input`, `resume_agent`, `wait_agent`, `close_agent`) exposed by the `multi_agent` feature (`codex features list` confirms `multi_agent stable true` locally) | **UNVERIFIED** — no tool name confirmed in fetched docs; `/fork` exists but is a session-fork, not a subagent spawn |
| **Concurrency/nesting limits** | Not applicable in the same sense (Agent tool calls are explicit per-message) | `agents.max_concurrent_threads_per_session` (config key; example value `8`); nesting-depth (`max_depth`) reported only by non-primary sources, **UNVERIFIED** | **UNVERIFIED** — no limit key found in fetched docs |
| **Argument passing into a skill** | `$ARGUMENTS`, `$ARGUMENTS[N]`/`$N`, named `$name` via `arguments:` frontmatter, plus `${CLAUDE_*}` session/project variables | **UNVERIFIED** — no substitution syntax shown in fetched docs beyond the free-text prompt after `$skillname` | **UNVERIFIED** — `argument-hint` exists for autocomplete display only; no confirmed `$ARGUMENTS`-equivalent substitution found |

---

## Summary of biggest verification gaps

- **Grok's `--agents <JSON>` and `--agent <file>` exact schemas** — confirmed to exist (via local `grok --help`) but their field-level shape was not confirmed against a primary docs page in this session; `docs.x.ai/build/features/subagents`, `/build/modes-and-commands`, and `/build/cli/headless-scripting` were all fetched and none showed the schema.
- **Codex's `max_depth`/nesting limit and CSV batch fan-out (`spawn_agents_on_csv`)** — reported only by secondary sources, not confirmed in the two primary Codex pages fetched.
- **Whether Codex or Grok honor `disable-model-invocation`, `allowed-tools`, or argument-substitution syntax** beyond the two-field (`name`/`description`) baseline Codex's docs showed — genuinely unresolved without either deeper docs pages (not surfaced by the fetches attempted) or direct experimentation with the local `codex`/`grok` binaries.
- **Whether Grok reads `agents/openai.yaml`** on skills it shares with Codex via the common `~/.agents/skills/` directory — inferred "probably not" from the absence of any matching field in Grok's own frontmatter docs, but not directly confirmed.
