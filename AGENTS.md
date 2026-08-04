# AGENTS.md — FutuOpenD

## Build

**Linux / macOS (build script):**
```bash
./dockerbuild.sh all                    # both variants (ubuntu + rocky)
./dockerbuild.sh ubuntu                # ubuntu only
./dockerbuild.sh rocky                # rocky only
./dockerbuild.sh --all         # multi-arch (amd64 + arm64)
```

**Linux / macOS (Makefile):**
```bash
make ubuntu                    # ubuntu only
make rocky                     # rocky only
make multiarch                 # multi-arch (amd64 + arm64)
make check                     # verify current version tarballs exist
```

**Windows:**
```bash
dockerbuild.bat all
dockerbuild.bat ubuntu
```

**Windows:**
```bash
dockerbuild.bat all
dockerbuild.bat ubuntu
```

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile.ubuntu` | Ubuntu 24.04 LTS build (amd64/arm64) |
| `Dockerfile.rocky` | Rocky Linux 9 build (amd64/arm64) |
| `Makefile` | Build targets: `make ubuntu`, `make rocky`, `make multiarch`, `make check` |
| `entrypoint.sh` | Container entry with graceful shutdown |
| `scripts/check-version.sh` | Verify or update FutuOpenD version in Dockerfiles |

## Current Version

- **FutuOpenD:** 10.9.6918 (2026-07-10)
- **Base:** Ubuntu 24.04 LTS / Rocky Linux 9
- **Entry Script:** `entrypoint.sh` (graceful SIGTERM/SIGINT handling)

## Gotchas

- CRLF line endings in shell scripts are auto-fixed during build via `sed`

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **futuopend** (213 symbols, 204 relationships). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

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

## Project Notes

- Dockerfile deduplication complete (`final-amd64` + `final-arm64` → single `final` stage)
- `--all` is the preferred multi-arch flag (alias for `--multiarch`)
- ARM builds use QEMU emulation; see README ARM perf section for box64 alternative

## Session Summary

### Completed
- Dockerfile deduplication: merged `final-amd64` + `final-arm64` → single `final` stage
- Added `--all` alias for `--multiarch` in dockerbuild.sh
- README: added ARM performance note and box64 recommendation
- Smoke test: container healthy, port 11111 listening, FutuOpenD binary running
- Fixed critical: Rocky Dockerfile was missing `final` stage body
- Fixed dockerbuild.bat: `--target final-%A%` → `--target final`
- Fixed dockerbuild.sh: PLATFORM env var now filters arch loop (was hardcoded)
- Fixed entrypoint.sh: use captured PID instead of pgrep (TOCTOU race fix)
- Updated docs/ARCHITECTURE.md: all stale `final-amd64`/`final-arm64` refs → `final`
- **futuopend-deploy updated to 10.6.6608**: version strings bumped in README.md, FutuOpenD.xml.template, docs/configuration.md; new features section added; FUTU_IMAGE + FUTU_PUSH_PROTO added to .env.example
- **futuopend upgraded to 10.7.6708**: 5 new vendored .so libraries (libcrypto.so.3, libcurl.so.4, libf3cnet.so, libprotobuf.so.32, libssl.so.3); FutuOpenD.xml byte-identical to 10.6.6608 (no schema changes); 8 Docker Hub tags pushed (ubuntu+rocky × amd64+arm64 + centos aliases)
- **futuopend upgraded to 10.8.6808**: Search API, Chart Indicators, Options Analysis, Market Fundamentals API; XML schema unchanged; 8 Docker Hub tags pushed
- **futuopend upgraded to 10.9.6918**: .so library set unchanged (11 libs); XML schema unchanged; fixed check-version.sh `$1` unbound bug (`${1:-}`)

### Next Steps
- [ ] ARM smoke test on Raspberry Pi (verify real hardware works, not just QEMU)
