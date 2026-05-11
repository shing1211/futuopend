# AGENTS.md — FutuOpenD

## Build

**Linux / macOS:**
```bash
./dockerbuild.sh all                    # both variants (ubuntu + rocky)
./dockerbuild.sh ubuntu                # ubuntu only
./dockerbuild.sh rocky                # rocky only
./dockerbuild.sh --multiarch         # multi-arch (amd64 + arm64)
```

**Windows:**
```bash
dockerbuild.bat all
dockerbuild.bat ubuntu
```

## Run

```bash
docker compose -f docker-compose.simple.yaml up -d
```

- **TCP:** `localhost:11111`
- **WebSocket:** `localhost:11112`

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile.ubuntu` | Ubuntu 24.04 LTS build (amd64/arm64) |
| `Dockerfile.rocky` | Rocky Linux 9 build (amd64/arm64) |
| `docker-compose.simple.yaml` | Standalone deployment |
| `docker-compose.yaml` | Docker Swarm (production) |
| `entrypoint.sh` | Container entry with graceful shutdown |
| `FutuOpenD.xml.template` | Config template with env-var substitution |

## Current Version

- **FutuOpenD:** 10.5.6508 (2026-05-11)
- **Base:** Ubuntu 24.04 LTS / Rocky Linux 9
- **Entry Script:** `entrypoint.sh` (graceful SIGTERM/SIGINT handling)

## Gotchas

- Requires RSA private key for trading (generate at [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI))
- Healthcheck uses `pgrep FutuOpenD` — no curl needed
- `--start-period` is 60s on first boot (gives time for auth)
- CRLF line endings in shell scripts are auto-fixed during build via `sed`

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **futuopend** (212 symbols, 202 relationships, 0 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/futuopend/context` | Codebase overview, check index freshness |
| `gitnexus://repo/futuopend/clusters` | All functional areas |
| `gitnexus://repo/futuopend/processes` | All execution flows |
| `gitnexus://repo/futuopend/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
