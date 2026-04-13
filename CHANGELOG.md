# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## [Unreleased]

### Added
- Full documentation suite: README, `docs/configuration.md`, `docs/security.md`, `CONTRIBUTING.md`, `CHANGELOG.md`
- `.env.example` — environment variable template
- `.gitignore`
- CentOS 7 multi-stage build target in `Dockerfile`

### Changed
- FutuOpenD bumped from `9.6.5618` → `10.2.6208`
- `Dockerfile` refactored into multi-stage build with separate Ubuntu and CentOS targets
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
- `docker-compose.yaml` for easy container orchestration
- `dockerbuild.sh` CI/CD helper script
