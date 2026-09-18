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

## Upgrade

When Futu releases a new FutuOpenD version, bump both repos with one command:

```bash
./scripts/bump-version.sh 10.12.7208 --commit  # dry-run by default; omit --commit to preview
```

Or step-by-step:

```bash
# Check what version would be found (brute-force loop)
./scripts/check-version.sh --discover

# Validate a specific version exists on CDN
./scripts/check-version.sh 10.12.7208

# Update Dockerfiles + checksums (futuopend only)
./scripts/check-version.sh --update 10.12.7208

# Also patch futuopend-deploy files (README, docs, XML template)
./scripts/check-version.sh --update 10.12.7208 --deploy ../futuopend-deploy

# Full pipeline with commits and pushes
./scripts/check-version.sh --update 10.12.7208 --deploy ../futuopend-deploy --commit
```

**Automated option:** the `version-poller.yml` workflow runs every Sunday at 00:00 UTC (or manually via GitHub Actions UI). If it finds a new version on Futu's CDN it opens a PR against `main` with the Dockerfile bump. After merging that PR, trigger `version-bump.yml` in `futuopend-deploy`:

```bash
gh workflow run version-bump.yml -f version=10.12.7208 --repo shing1211/futuopend-deploy
```

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile.ubuntu` | Ubuntu 26.04 LTS build (amd64/arm64) |
| `Dockerfile.rocky` | Rocky Linux 9 build (amd64/arm64) |
| `Makefile` | Build targets: `make ubuntu`, `make rocky`, `make multiarch`, `make check` |
| `entrypoint.sh` | Container entry with graceful shutdown |
| `scripts/check-version.sh` | Check/discover versions; update Dockerfiles + checksums |
| `scripts/bump-version.sh` | Cross-repo version bump in one shot (dry-run default) |
| `.github/workflows/version-poller.yml` | Weekly schedule + manual: discovers new versions, opens PR |

## Current Version

- **FutuOpenD:** 10.11.7108 (2026-09-17)
- **Base:** Ubuntu 26.04 LTS / Rocky Linux 9
- **Entry Script:** `entrypoint.sh` (graceful SIGTERM/SIGINT handling)

## Gotchas

- CRLF line endings in shell scripts are auto-fixed during build via `sed`

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
- **futuopend upgraded to 10.10.7008**: .so library set unchanged (11 libs); `FutuOpenD.xml` no longer ships `login_account`/`login_pwd` (10.10 defaults to interactive login — headless must pass credentials via config or `-login_account`/`-login_by_remember`); fixed dockerbuild.sh multi-arch centos mislabel + centos→rocky normalization; `:latest` now a real multi-arch manifest list; dockerbuild.bat default version aligned

- **OSS/Pages/CI hardening**: GitHub Pages now deployed via Actions (`docs/index.md` landing + just-the-docs theme); Discussions surfaced (`SUPPORT.md` + issue templates); CI workflow (shellcheck, hadolint, version-check, build-smoke); Dependabot; `main` branch protection with required checks; `CLAUDE.md`/`.claude/` removed from public repo; base images digest-pinned; tarball SHA256 verified at build time
- **futuopend upgraded to 10.11.7108**: .so set unchanged (11 libs); `FutuOpenD.xml` byte-identical to 10.10.7008; 8 Docker Hub tags pushed
- **Ubuntu base upgraded to 26.04 LTS** (digest-pinned); FutuOpenD 10.11.7108 verified running on it (process, port, healthcheck, no missing libs)
- **Entrypoint renders config via envsubst**: discovered FutuOpenD does NOT expand `${VAR}`; entrypoint now uses `envsubst` + `-cfg_file`; added `gettext-base`/`gettext` to Dockerfiles; `area_code` defaults `+852`, opt-in WebSocket via `FUTU_WS_PORT`, `-no_monitor=1`
- **Released v10.11.7108-r2**: CHANGELOG cut, GitHub Release created manually
- **Released futuopend-deploy v1.1.0**: CHANGELOG cut, mkdocs banner bumped, `release.yml` PREV_TAG link fixed
- **Upgrade tooling added**: `check-version.sh` (--deploy, --commit, --discover, --dry-run), `bump-version.sh` (one-shot cross-repo), `version-poller.yml` (weekly Sunday cron + workflow_dispatch; opens PR on new version), `version-bump.yml` in futuopend-deploy (manual workflow to update deploy docs), `image-tag-verify` CI job (verifies Docker Hub tag exists before merging)

### Next Steps
- [ ] ARM smoke test on Raspberry Pi (verify real hardware works, not just QEMU)
- [ ] Confirm 10.10 interactive-login change doesn't break futuopend-deploy headless configs
