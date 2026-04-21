# futuopend Roadmap

> Last Updated: 2026-04-22

---

## Vision

futuopend is the most reliable Docker packaging for FutuOpenD. Zero-config deployment on any infrastructure — cloud VM, NAS, Raspberry Pi, Kubernetes — with security hardening and graceful shutdown out of the box.

---

## Version History

### v2.0.0 (Current)
- Split Dockerfiles: `Dockerfile.ubuntu` + `Dockerfile.rocky` (no wasted build time)
- `entrypoint.sh` with robust SIGTERM/SIGINT handling (replaces wrapper.sh)
- Windows support: `dockerbuild.bat` with full parity to `dockerbuild.sh`
- CRLF line ending fix for Windows builds
- Non-root user, health checks, Docker Secrets support
- Ubuntu 24.04 LTS + Rocky Linux 9 variants
- Multi-arch: amd64 + arm64 builds
- Published on Docker Hub (`shing1211/futuopend`)

### v1.0.0
- Initial production-ready release
- Multi-stage Dockerfile with 8 build targets

---

## Phase 1: Production Ready ✅

| Item | Status | Notes |
|------|--------|-------|
| Split Dockerfiles | ✅ Done | `Dockerfile.ubuntu` + `Dockerfile.rocky` |
| Graceful shutdown | ✅ Done | `entrypoint.sh` on all targets |
| SECURITY.md | ✅ Done | Security policy with disclosure |
| Phone verification docs | ✅ Done | In configuration.md |
| Env var wiring | ✅ Done | `.env.example` aligned |

---

## Phase 2: Enterprise Ready 🚧

| Item | Priority | Status |
|------|----------|--------|
| GitHub Actions CI | High | Pending |
| Kubernetes manifests | High | Pending |
| Helm chart | Medium | Pending |
| Connection health monitoring | Medium | Pending |
| Structured logging + Prometheus | Medium | Pending |
| Parallel builds | Low | Pending |

---

## Phase 3: Ecosystem 📋

| Item | Priority |
|------|----------|
| Helm chart publish | Medium |
| Multi-arch CI parallelization | Medium |
| Grafana dashboard | Low |
| OrbStack support docs | Low |
| Upgrade guide | Low |

---

## Architecture

```
futuopend (this project)
    │
    ├── Dockerfile.ubuntu     — Ubuntu 24.04 (final-amd64, final-arm64)
    ├── Dockerfile.rocky     — Rocky Linux 9 (final-amd64, final-arm64)
    ├── docker-compose.yaml       — Docker Swarm (secrets)
    ├── docker-compose.simple.yaml — Standalone
    ├── dockerbuild.sh/.bat      — Build scripts
    ├── entrypoint.sh            — Graceful shutdown
    └── docs/
        ├── configuration.md  — Full config reference
        ├── security.md      — Hardening guide
        └── api.md           — Protocol docs
```

---

## Known Issues

| Issue | Status |
|-------|--------|
| No GitHub Actions CI | Pending |
| No Kubernetes manifests | Pending |
| Healthcheck uses pgrep only | Acceptable |

---

*Generated with community contributions — 2026-04-22*
