# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Comprehensive documentation (README, docs/configuration.md, docs/security.md, CONTRIBUTING.md, CHANGELOG.md)
- `.env.example` environment variable template
- `.gitignore` file
- CentOS 7 multi-stage build target in Dockerfile

### Changed
- FutuOpenD version bumped from `9.6.5618` to `10.2.6208`
- Dockerfile refactored with new multi-stage build structure
- docker-compose.yaml now uses Docker Secrets for credential management

### Fixed
- _(none yet — see [CONTRIBUTING.md](CONTRIBUTING.md) for open issues)_

### Security
- _(none yet)_

---

## [1.0.0] — Initial Release

### Added
- Docker packaging for FutuOpenD v9.6.5618
- Ubuntu 18.04 and CentOS 7 variants
- docker-compose.yaml for easy container orchestration
- `dockerbuild.sh` CI/CD script
