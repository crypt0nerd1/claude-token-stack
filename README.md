# claude-token-stack

Reproducible install + audit of a 10-tool token-optimization stack for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [OpenAI Codex CLI](https://github.com/openai/codex). Inventory, decision matrix, threat model, and verification commands.

> **Status**: personal setup snapshot, pinned to commits/versions resolved on `2026-05-04`. Re-run verification block in [`§ Verification`](#verification) before trusting numbers — upstream tools change quickly.

---

## Why a separate repo

Each tool has its own README and its own opinion. Running all ten in the same shell is not the sum of their docs:

- Hooks compose in a fixed order set by `~/.claude/settings.json` — **order matters** for tools that mutate `stdin`/`stdout` (RTK proxy vs Token Optimizer measurement).
- Three of the tools register MCP servers, two install Skills, one is a CLI proxy via shell hook, one is a CLAUDE.md profile. They cannot be swapped 1:1.
- Marketing claims (`60-90% reduction`, `97% navigation savings`, `49x token reduction`) are workload-dependent and **not portable across stacks**. This repo records *which workload* each claim was measured on, so I can decide what to keep.

Goal: `git clone && bash setup/verify.sh` reproduces the same MCP graph, the same hooks, and the same skill set on a new machine. No more.

---

## Inventory

| # | Tool | Type | Resolved version / commit | License | Install path |
|---|------|------|---------------------------|---------|--------------|
| 1 | [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) | Claude Code skill + Codex plugin | `ef6050c` | MIT | `~/.claude/skills/caveman/` |
| 2 | [rtk-ai/rtk](https://github.com/rtk-ai/rtk) | CLI proxy via PreToolUse hook | `0.37.2` | upstream | `/opt/homebrew/bin/rtk` |
| 3 | [tirth8205/code-review-graph](https://github.com/tirth8205/code-review-graph) | MCP (uvx) | launched via `uvx code-review-graph serve` | upstream | n/a (uvx) |
| 4 | [mksglu/context-mode](https://github.com/mksglu/context-mode) | MCP (npm) | `context-mode@1.0.107` | upstream | `~/.npm-global/bin/context-mode` |
| 5 | [alexgreensh/token-optimizer](https://github.com/alexgreensh/token-optimizer) | Claude Code plugin (hooks + skill) | `dfcf309` | PolyForm Noncommercial 1.0.0 | `~/.claude/token-optimizer/` |
| 6 | [ooples/token-optimizer-mcp](https://github.com/ooples/token-optimizer-mcp) | MCP (npm) | `token-optimizer-mcp@2.17.0` | upstream | `~/.npm-global/bin/token-optimizer-mcp` |
| 7 | [zilliztech/claude-context](https://github.com/zilliztech/claude-context) | MCP (npm) — **not installed** | `@zilliz/claude-context-mcp@0.1.12` | MIT | requires Zilliz Cloud + OpenAI keys |
| 8 | [drona23/claude-token-efficient](https://github.com/drona23/claude-token-efficient) | CLAUDE.md rule profile | `b32fa8b` | MIT | content merged into `~/.claude/CLAUDE.md` |
| 9 | [mibayy/token-savior](https://github.com/mibayy/token-savior) | MCP (pipx) | resolved at install | upstream | `~/.local/bin/token-savior` |
| 10 | [tessl](https://github.com/tessl) | MCP | `tessl mcp start` | upstream | n/a |

> Items 5 and 6 in the original list collapsed into one (`alexgreensh/token-optimizer`) because the second link points at the same repo. Tool count is **10 distinct binaries / artifacts** as installed.

License caveat: `alexgreensh/token-optimizer` is **non-commercial**. Personal use only.

---

## What actually runs (call graph)

Hooks registered in `~/.claude/settings.json` for every Claude Code session:

```
PreToolUse (Bash)
  ├── rtk hook claude                       # rewrite to rtk-proxied form
  ├── rm -rf root-path guard                # local safety
  └── token-optimizer bash_hook.py          # measurement + cache key

PreToolUse (Read)            → token-optimizer read_cache.py
PreToolUse (Agent|Task)      → token-optimizer measure.py checkpoint-trigger
PreToolUse (Write|Edit)      → anti-spam-filter, COI check, champion-readiness
UserPromptSubmit             → token-optimizer measure.py quality-cache
PreCompact                   → dynamic-compact-instructions, compact-capture, cache clear
SessionStart (resume)        → caveman level state, token-optimizer checkpoint pointer
```

MCP servers loaded on session start:

```
context-mode          (npm)   → SQLite output sink for tool dumps
token-optimizer-mcp   (npm)   → cache + compression for MCP responses
token-savior          (pipx)  → symbol-level codebase navigation
code-review-graph     (uvx)   → Tree-sitter graph
tessl                 (cli)   → context tiles
```

Order constraint: RTK must run before Token Optimizer's bash hook, otherwise the measurement counts un-rewritten tokens. Verified by reading `settings.json` left-to-right within the same `matcher`.

---

## Decision matrix

When to use which, with the actual cost.

| Workload | First tool | Why | Cost / risk |
|----------|-----------|-----|-------------|
| Long shell output (tests, builds, `npm install`) | RTK | Rewrites command transparently, drops boilerplate | Adds ~1ms/cmd; misclassification can hide useful output. `rtk proxy` to bypass. |
| Reading a monorepo to answer "where is X used" | code-review-graph + token-savior | Symbol/graph traversal beats `grep`/`Read` for cross-file work | First indexing pass is slow on large repos. Graph staleness if files change while paused. |
| Long-running MCP responses (HubSpot list, Stripe pages) | token-optimizer-mcp + context-mode | Cache hits avoid repeat fetches; SQLite avoids burning context on raw dumps | Cache TTL guesses can serve stale data. Always re-fetch on writes. |
| Forcing terse model output | caveman (`/caveman full`) | Drops articles/filler from generation, ~65-75% output reduction in upstream benchmarks | Code/PR/security blocks must opt out (caveman does this automatically). Misreads possible if order matters in a fragment. |
| Persistent rule profile across all sessions | drona23 CLAUDE.md merged into `~/.claude/CLAUDE.md` | One file, no runtime cost beyond context tokens | The CLAUDE.md itself spends input tokens every turn. Net only positive on output-heavy sessions. |
| Semantic codebase search | claude-context | Vector retrieval scales to large repos | Requires Zilliz Cloud account + OpenAI key. Embedding cost is real. Not free. |

---

## What I did not measure

- I did **not** independently re-run the headline benchmarks (`60-90%`, `49x`, `97%`). Those are upstream claims on upstream workloads. I link the source so readers can audit, but I did not reproduce them on my repos.
- I did **not** run a side-by-side bake-off between `token-optimizer-mcp` (ooples) and `token-optimizer` (alexgreensh). They optimize different layers (MCP responses vs hooks/measurement) and stack rather than compete.
- I did **not** evaluate failure modes under heavy concurrency. Single-session usage only.

If you need defensible numbers for your own workload, run [§ Verification](#verification), then re-measure with `python3 ~/.claude/token-optimizer/skills/token-optimizer/scripts/measure.py report` before and after toggling each tool.

---

## Privacy / threat model

What leaves the machine when each tool runs:

| Tool | Egress | Notes |
|------|--------|-------|
| caveman | none | Local skill, no network. |
| RTK | none | Local Rust binary. |
| code-review-graph | none | Local Tree-sitter parser. |
| context-mode | none | SQLite on disk. |
| alexgreensh/token-optimizer | none | Local Python, "zero telemetry" claim per upstream README. Verify with `lsof -p` if paranoid. |
| token-optimizer-mcp | none by default | Cache is local. Some commands hit external APIs only if you call them. |
| token-savior | none | Local symbol index. |
| **claude-context** | **OpenAI + Zilliz Cloud** | Embeddings of your code are sent to OpenAI; vectors stored on Zilliz Cloud. **Do not enable on regulated/proprietary code without DPA review**. |
| drona23 CLAUDE.md | none | Static file. |
| tessl | tessl backend | Verify with their privacy doc before enabling on sensitive repos. |

> Anything that reads your repo and embeds it externally (claude-context, tessl) needs a privacy decision **before** install, not after.

---

## Reproducible install

Tested on macOS 25.1 (darwin/arm64), Node `25.2.1`, Python `3.14.3`, `uv 0.10.6`, `pipx 1.8.0`.

```bash
# 1. caveman
git clone https://github.com/JuliusBrussee/caveman.git /tmp/caveman
bash /tmp/caveman/install.sh

# 2. RTK — see upstream README; install method varies (cargo / brew tap / release binary)

# 3. code-review-graph (MCP, uvx)
claude mcp add code-review-graph -- uvx code-review-graph serve

# 4. context-mode (MCP, npm)
npm install -g context-mode
claude mcp add context-mode -- context-mode

# 5. alexgreensh/token-optimizer
git clone https://github.com/alexgreensh/token-optimizer.git /tmp/agt
bash /tmp/agt/install.sh

# 6. token-optimizer-mcp (MCP, npm)
npm install -g token-optimizer-mcp
claude mcp add token-optimizer-mcp -- token-optimizer-mcp

# 7. token-savior (MCP, pipx)
pipx install token-savior
claude mcp add token-savior -- token-savior

# 8. claude-context (MCP, npm) — only if you accept the egress in § Privacy
bash setup/claude-context.sh   # requires OPENAI_API_KEY, MILVUS_ADDRESS, MILVUS_TOKEN

# 9. drona23 — pick a profile and append into ~/.claude/CLAUDE.md
git clone https://github.com/drona23/claude-token-efficient.git /tmp/cte
cat /tmp/cte/profiles/M-drona23-v8/CLAUDE.md >> ~/.claude/CLAUDE.md
```

Hook order in `~/.claude/settings.json` is **not** managed by this repo. After install, audit it manually (see [§ What actually runs](#what-actually-runs-call-graph)).

---

## Verification

Run after install. All commands should exit `0` and the MCP list should match the inventory table.

```bash
rtk --version
codex --version
node --version
python3 --version

claude mcp list | grep -E "context-mode|token-optimizer-mcp|token-savior|code-review-graph"

ls ~/.claude/skills/caveman/SKILL.md
ls ~/.claude/token-optimizer/skills/token-optimizer/SKILL.md

rtk gain                                        # RTK lifetime savings
python3 ~/.claude/token-optimizer/skills/token-optimizer/scripts/measure.py report
```

Output of these commands on `2026-05-04` is captured in [`audit/2026-05-04.txt`](./audit/2026-05-04.txt) (TODO: add on next run).

---

## Known limitations

1. **Hook order is fragile.** Adding any tool that registers a `PreToolUse Bash` hook must preserve `rtk hook claude` first.
2. **CLAUDE.md is a tax.** Every line in `~/.claude/CLAUDE.md` costs input tokens every turn. drona23's profile is small enough to net-positive only on output-heavy work; large profiles can lose money.
3. **MCP cache invalidation.** `token-optimizer-mcp` aggressively caches. After any write through MCP (HubSpot update, Vanta API call), trust the response of *that* call but consider invalidating the entity's cache before reading it back.
4. **claude-context cost is open-ended.** OpenAI embedding cost scales with repo size and re-index frequency. Set a budget alarm before pointing it at a large monorepo.
5. **alexgreensh license is non-commercial.** Do not bundle into a paid product.

---

## Maintenance

- Re-pin versions monthly: `cd <each tool> && git pull && git rev-parse --short HEAD`
- Re-run [§ Verification](#verification) after any `claude mcp add/remove` or any edit to `~/.claude/settings.json`.
- When a tool stops earning its keep on real workloads, remove it. Token-optimization tools that are never used still cost startup time.

---

## Owner

Lucas Galvao — Open Cybersecurity. `lucas@opencybersecurity.co`. Issues and PRs welcome but this repo tracks one machine; expect drift.
