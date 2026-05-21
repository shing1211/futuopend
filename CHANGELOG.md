# Changelog

All notable changes to this project follow [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased]

### Changed
- FutuOpenD bumped from `10.5.6508` → `10.6.6608`

### Added
- Support for conditional stock screening API (multi-factor: fundamental, technical, pattern)
- Support for fundamental data API (financial statements, analyst ratings, dividends, shareholder持股)
- Support for moomoo Australia simulated trading account

### Fixed
- CRLF line endings in entrypoint.sh causing "required file not found" error on Windows builds
- `TARGETARCH` variable naming in Dockerfiles (was `TARGET_ARCH`)
- Missing `ca-certificates` package causing SSL/TLS failures in Ubuntu builds

### Changed
- Replaced `wrapper.sh` with `entrypoint.sh` (more robust shutdown handling)
- Unified `docker-compose.simple.yaml` to use `Dockerfile.ubuntu`
- `dockerbuild.bat` now supports version parameter and matches `dockerbuild.sh` functionality

### Removed
- Redundant `Dockerfile` (superseded by `Dockerfile.ubuntu` and `Dockerfile.rocky`)
- Unused `scripts/wrapper.sh`

---

## [10.4.6408] - 2026-04-26

### Changed
- FutuOpenD bumped from `10.3.6308` → `10.4.6408`

---

## [10.3.6308] - 2026-04-16

### Added
- Support for free US stock market data during promotion period
- Support for non-account holder login
- Historical quota reset cycle shortened from 14 days to 7 days

### Changed
- FutuOpenD bumped from `10.2.6208` → `10.3.6308`

---

## [10.2.6208] - 2026-03-26

### Added
- `.env.example` — annotated environment variable template
- `.gitignore` — keeps secrets, `.env`, and build artifacts out of version control
- `FutuOpenD.xml.template` — official config extracted from FutuOpenD v10.2.6208, with `${ENV_VAR}` substitution ready
- Full documentation suite: `README.md`, `docs/configuration.md`, `docs/security.md`, `CONTRIBUTING.md`, `CHANGELOG.md`
- `docker-compose.simple.yaml` — lightweight compose file for standalone Docker (no Swarm required)
- `SECURITY.md` — security hardening guide and checklist

### Changed
- FutuOpenD bumped from `9.6.5618` → `10.2.6208`
- Base images upgraded to supported releases: Ubuntu 18.04 → **24.04**, CentOS 7 → **Rocky Linux 9**
- `Dockerfile` refactored into clean multi-stage builds with separate Ubuntu and Rocky targets
- `dockerbuild.sh` now builds and pushes both Ubuntu and Rocky variants in a single run
- Healthcheck switched from `curl` to `pgrep FutuOpenD` — eliminates curl dependency entirely
- Healthcheck `--start-period` increased from 10s to 60s
- LICENSE upgraded from MIT to Apache 2.0

### Fixed
- CentOS 7 build broken by EOL yum repos — replaced with Rocky Linux 9
- Secrets path corrected from `/bin/` to `/run/secrets/` throughout

### Security
- Base images upgraded from EOL releases to actively supported versions

---

## [1.0.0] — Initial Release

### Added
- Docker packaging for FutuOpenD v9.6.5618
- Ubuntu 18.04 and CentOS 7 variants
- `docker-compose.yaml` for container orchestration
- `dockerbuild.sh` CI/CD helper script

---

*This project is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
