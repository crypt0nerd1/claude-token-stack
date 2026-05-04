# claude-token-stack

Stack pessoal de ferramentas de otimização de tokens para Claude Code, Codex e ferramentas relacionadas. Setup do Lucas Galvao (Open Cybersecurity).

## Status atual (2026-05-04)

| # | Ferramenta | Status | Como usa |
|---|-----------|--------|----------|
| 1 | [caveman](https://github.com/JuliusBrussee/caveman) | Instalado | `/caveman` no Claude Code, ou `caveman mode` na sessão. Skill global. |
| 2 | [RTK (Rust Token Killer)](https://github.com/rtk-ai/rtk) | Instalado | Hook Bash automatico via `~/.claude/settings.json`. `rtk gain` ve economia. |
| 3 | [Code Review Graph](https://github.com/tirth8205/code-review-graph) | Instalado (MCP) | `mcp__code-review-graph__*`. Auto-roda em monorepos. |
| 4 | [Context Mode](https://github.com/mksglu/context-mode) | Instalado (MCP) | `mcp__context-mode__*`. Joga output bruto no SQLite. |
| 5 | [Claude Token Optimizer (alexgreensh)](https://github.com/alexgreensh/token-optimizer) | Instalado | Hooks UserPromptSubmit/PreCompact ja registrados. `/token-optimizer`. |
| 6 | [Token Optimizer (alexgreensh)](https://github.com/alexgreensh/token-optimizer) | Instalado | Mesmo binario do item 5 (consolidado). |
| 7 | [Token Optimizer MCP (ooples)](https://github.com/ooples/token-optimizer-mcp) | Instalado (MCP) | `mcp__token-optimizer-mcp__*`. Cache + compressao. |
| 8 | [Claude Context (zilliztech)](https://github.com/zilliztech/claude-context) | Pendente | Requer `OPENAI_API_KEY` + `MILVUS_ADDRESS` + `MILVUS_TOKEN` (Zilliz Cloud). Ver `setup/claude-context.sh`. |
| 9 | [Claude Token Efficient (drona23)](https://github.com/drona23/claude-token-efficient) | Aplicado | Conteudo consolidado em `~/.claude/CLAUDE.md` (regras de concisao). |
| 10 | [Token Savior (mibayy)](https://github.com/mibayy/token-savior) | Instalado (MCP) | `mcp__token-savior__*`. Navegacao por simbolos. |

Codex tambem instalado (`/opt/homebrew/bin/codex`). Cave mode ja ativo.

## Hooks ativos em `~/.claude/settings.json`

- **PreToolUse / Bash**: `rtk hook claude` (RTK rewrite automatico) + token-optimizer bash hook
- **PreToolUse / Read**: `read_cache.py` (alexgreensh)
- **PreToolUse / Agent|Task**: `measure.py checkpoint-trigger`
- **PreToolUse / Write|Edit**: anti-spam-filter, COI check, champion-readiness
- **UserPromptSubmit**: `measure.py quality-cache`
- **PreCompact**: `dynamic-compact-instructions` + `compact-capture` + cache clear

## Combinacoes recomendadas

| Cenario | Stack |
|---------|-------|
| Repo enorme | Code Review Graph + Token Savior |
| Terminal pesado | RTK |
| Dumps de dados MCP | Context Mode |
| Resultado imediato | Caveman + drona23 CLAUDE.md |
| Dev em codebase nao-indexado | Claude Context (apos config) |

## Setup do zero

```bash
# 1. Caveman
git clone https://github.com/JuliusBrussee/caveman.git && cd caveman && bash install.sh

# 2. RTK (Cargo)
cargo install --git https://github.com/rtk-ai/rtk

# 3-7-10. MCP servers (ja registrados em claude mcp list)
npm install -g context-mode
npm install -g token-optimizer-mcp
pipx install token-savior
uvx code-review-graph serve

# 5/6. alexgreensh token-optimizer
git clone https://github.com/alexgreensh/token-optimizer.git && cd token-optimizer && bash install.sh

# 8. Claude Context (requer chaves)
bash setup/claude-context.sh

# 9. drona23 - so copia o CLAUDE.md profile escolhido para ~/.claude/CLAUDE.md
```

## Verificacao

```bash
rtk gain                  # economia RTK
claude mcp list           # MCPs conectados
ls ~/.claude/skills/      # skills (caveman, token-optimizer)
ls ~/.claude/token-optimizer/  # alexgreensh install
```

## Owner

Lucas Galvao - Open Cybersecurity. lucas@opencybersecurity.co
