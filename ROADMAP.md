# futuopend Roadmap

> Last Updated: 2026-05-18

---

## Vision

futuopend is the most reliable Docker packaging for FutuOpenD. This repo focuses on **building the Docker image** — clean, consistent, multi-arch. For runtime deployment, see [futuopend-deploy](https://github.com/shing1211/futuopend-deploy).

---

## Version History

### v2.0.0 (Current)
- Split Dockerfiles: `Dockerfile.ubuntu` + `Dockerfile.rocky` (no wasted build time)
- `entrypoint.sh` with robust SIGTERM/SIGINT handling
- Windows support: `dockerbuild.bat` with full parity to `dockerbuild.sh`
- CRLF line ending fix for Windows builds
- Non-root user, health checks bundled in image
- Ubuntu 24.04 LTS + Rocky Linux 9 variants
- Multi-arch: amd64 + arm64 builds
- Published on Docker Hub (`shing1211/futuopend`)
- Repo split: build-only here, deploy concerns moved to `futuopend-deploy`

### v1.0.0
- Initial production-ready release
- Multi-stage Dockerfile with 8 build targets

---

## Upcoming

| Item | Priority | Status |
|------|----------|--------|
| GitHub Actions CI pipeline | High | Pending |
| Automated version bumping | High | Pending |
| Build smoke test in CI | High | Pending |
| Makefile with standard targets | Medium | Pending |
| Parallel build pipeline | Low | Pending |

---

*Generated with community contributions — 2026-05-18*
