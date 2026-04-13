# Changelog

All notable changes to this project follow [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased]

### Added
- `.env.example` — annotated environment variable template
- `.gitignore` — keeps secrets, `.env`, and build artifacts out of version control
- `FutuOpenD.xml.template` — official config extracted from FutuOpenD v10.2.6208, with `${ENV_VAR}` substitution ready
- Full documentation suite: `README.md`, `docs/configuration.md`, `docs/security.md`, `CONTRIBUTING.md`, `CHANGELOG.md`
- `docker-compose.simple.yaml` — lightweight compose file for standalone Docker (no Swarm required)
- `SECURITY.md` — security hardening guide and checklist

### Changed
- FutuOpenD bumped from `9.6.5618` → `10.2.6208`
- Base images upgraded to supported releases: Ubuntu 18.04 → **22.04**, CentOS 7 → **Rocky Linux 9**
- `Dockerfile` refactored into a clean multi-stage build with separate Ubuntu and Rocky targets
- `dockerbuild.sh` now builds and pushes both Ubuntu and Rocky variants in a single run (`./dockerbuild.sh` defaults to `all`)
- Healthcheck switched from `curl` to `pgrep FutuOpenD` — eliminates the curl dependency entirely
- Healthcheck `--start-period` increased from 10s to 60s — gives FutuOpenD time to connect and authenticate on first boot
- LICENSE upgraded from MIT to Apache 2.0
- Documentation rewritten in vivid, engaging open-source style
- CONTRIBUTING.md dev setup corrected to use `docker-compose.simple.yaml`

### Fixed
- CentOS 7 build broken by EOL yum repos — replaced with Rocky Linux 9
- `docker compose down` restart command in README now uses `-f docker-compose.simple.yaml`
- CONTRIBUTING.md dev setup no longer references Swarm-only compose file

### Security
- Base images upgraded from EOL releases (Ubuntu 18.04 EOL Apr 2023, CentOS 7 EOL Jun 2024) to actively supported versions
- Base image `ca-certificates` dropped from final stage — binary is statically linked
- Secrets path corrected from `/bin/` to `/run/secrets/` throughout

---

## [1.0.0] — Initial Release

### Added
- Docker packaging for FutuOpenD v9.6.5618
- Ubuntu 18.04 and CentOS 7 variants
- `docker-compose.yaml` for container orchestration
- `dockerbuild.sh` CI/CD helper script

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
