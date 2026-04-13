# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased]

### Added
- Full documentation suite: `README.md`, `docs/configuration.md`, `docs/security.md`, `CONTRIBUTING.md`, `CHANGELOG.md`
- `.env.example` — environment variable template
- `.gitignore` — keeps secrets out of version control
- CentOS 7 multi-stage build target alongside Ubuntu

### Changed
- FutuOpenD bumped from `9.6.5618` → `10.2.6208`
- `Dockerfile` refactored into a multi-stage build with separate Ubuntu and CentOS targets
- `docker-compose.yaml` now uses Docker Secrets for credential management

### Fixed
- _(none yet — see [CONTRIBUTING.md](CONTRIBUTING.md) for open issues)_

### Security
- _(none yet)_

---

## [1.0.0] — Initial Release

### Added
- Docker packaging for FutuOpenD v9.6.5618
- Ubuntu 18.04 and CentOS 7 variants
- `docker-compose.yaml` for container orchestration
- `dockerbuild.sh` CI/CD helper script

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
