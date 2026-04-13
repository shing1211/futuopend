# Changelog

All notable changes to this project follow [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased]

### Added
- `.env.example` — annotated environment variable template
- `.gitignore` — keeps secrets, `.env`, and build artifacts out of version control
- `FutuOpenD.xml.template` — official config extracted from FutuOpenD v10.2.6208, with `${ENV_VAR}` substitution ready
- Full documentation suite: `README.md`, `docs/configuration.md`, `docs/security.md`, `CONTRIBUTING.md`, `CHANGELOG.md`
- CentOS 7 multi-stage build target alongside Ubuntu

### Changed
- FutuOpenD bumped from `9.6.5618` → `10.2.6208`
- `Dockerfile` refactored into a clean multi-stage build with separate Ubuntu and CentOS targets
- `docker-compose.yaml` now uses Docker Secrets (`/run/secrets/`) with `mode: 0400` for credential management
- `dockerbuild.sh` now builds and pushes both Ubuntu and CentOS variants in a single run (`./dockerbuild.sh` defaults to `all`)
- Healthcheck switched from `curl` to `pgrep FutuOpenD` — eliminates the curl dependency entirely
- LICENSE upgraded from MIT to Apache 2.0
- Documentation rewritten in vivid, engaging open-source style

### Fixed
- CentOS 7 build broken by EOL yum repos — curl dependency removed entirely

### Security
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
