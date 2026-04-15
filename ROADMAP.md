# futuopend Roadmap

> Last Updated: 2026-04-15

---

## Vision

futuopend is the most reliable, well-tested, and enterprise-ready Docker packaging for the FutuOpenD gateway. It enables zero-config deployment of FutuOpenD on any infrastructure — from a Raspberry Pi to a Kubernetes cluster — with full observability, graceful shutdown, and security hardening out of the box.

---

## Version History

### v1.0.0 (Current)
- Multi-stage Dockerfile with 8 build targets (Ubuntu/Rocky × amd64/arm64)
- Docker Compose with Docker Swarm support
- Non-root user execution
- Health checks on all targets
- Graceful shutdown via `wrapper.sh` (partial — see Known Issues)
- Comprehensive security docs
- Published on Docker Hub (`shing1211/futuopend`)

### v0.x — Pre-release
- Initial development

---

## Phase 0: Production Readiness (P0)

> *Before v1.0.0 release. All items are blockers.*

- [ ] **GitHub Actions CI** — Automated build, lint, security scan, and push on merge
- [ ] **Docker build smoke test** — Verify all 8 targets actually start FutuOpenD
- [ ] **Fix stage-execution bug** — `--target final-ubuntu` should not build Rocky stage
- [ ] **SECURITY.md** — Security policy with disclosure process and supported versions
- [ ] **Fix ROADMAP.md** — Replace placeholder stubs with real roadmap
- [ ] **Wire env vars through compose files** — Align `.env.example` with `docker-compose.yaml`
- [ ] **Fix `${FUTU_RSA_KEY}` in XML template** — Template must support env var for RSA key
- [ ] **Phone verification callout in Quick Start** — Prevent user panic on first-run verification
- [ ] **Deduplicate phone verification docs** — Keep canonical version in `docs/configuration.md`
- [ ] **Automated version bumping** — CI detects `FUTU_OPEND_VER` change and creates GitHub release

---

## Phase 1: Enterprise Ready (P1)

> *Suitable for serious production trading infrastructure.*

- [ ] **Kubernetes manifests** (`k8s/`) — Deployment, Service, Secret, PersistentVolumeClaim
- [ ] **Helm chart** — Published on GitHub Pages for `helm install`
- [ ] **Graceful shutdown on all targets** — All 4 `final-*` targets use `wrapper.sh`
- [ ] **Connection health monitoring** — Port-based check (not just `pgrep`)
- [ ] **Structured logging + Prometheus metrics** — stdout logs + debug port scraping
- [ ] **Connection pool configuration docs** — Recommended settings for production
- [ ] **Non-root + read-only filesystem** — Security hardening in compose
- [ ] **Kubernetes Secret example completion** — Complete walkthrough in `docs/security.md`
- [ ] **Platform deployment guides** — VPS, Raspberry Pi, NAS, Cloud per-platform docs
- [ ] **Parallel builds** — Parallelize Ubuntu + Rocky in `dockerbuild.sh`

---

## Phase 2: Ecosystem (P2)

- [ ] **Helm chart publish** — Release on GitHub Container Registry or ChartMuseum
- [ ] **Parallel multi-arch CI** — Matrix strategy for all 8 targets
- [ ] **OrbStack support documentation** — Apple Silicon Mac local dev
- [ ] **Docker Scout / Trivy CVE scanning** — Proactive vulnerability detection
- [ ] **Config validation script** — `scripts/validate_config.sh`
- [ ] **Startup logging banner** — Version, ports, mount points on container start
- [ ] **Grafana dashboard** — Pre-built dashboard JSON for connection monitoring
- [ ] **Docker image size optimization** — Minimal base image, layer caching
- [ ] **Makefile** — Standard targets: build, lint, test, push, clean
- [ ] **Upgrade guide** — `docs/UPGRADE.md`

---

## Phase 3: Ecosystem Polish (P3)

- [ ] **Reusable GitHub Actions workflow** — Shared workflow for all three projects
- [ ] **Docker Hub README automation** — Auto-sync GitHub README to Docker Hub
- [ ] **Stars history badge** — Community growth visualization
- [ ] **Native ARM64 investigation** — Can FutuOpenD run natively on Apple Silicon?
- [ ] **Windows container investigation** — Windows Nano/Server Core support

---

## Known Issues

| Issue | Status | Notes |
|-------|--------|-------|
| Both build stages always run regardless of `--target` | [ ] Fix pending (P0) | Doubles build time |
| Graceful shutdown only on 2 of 4 targets | [ ] Fix pending (P1) | `final-ubuntu-arm64` uses `FutuOpenD` directly |
| No GitHub Actions CI | [ ] Fix pending (P0) | Manual builds only |
| `SECURITY.md` missing | [ ] Fix pending (P0) | GitHub flags repo |
| ROADMAP.md is placeholder stubs | [ ] Fix pending (P0) | Misleading for contributors |
| `${FUTU_RSA_KEY}` not wired in template | [ ] Fix pending (P0) | Docs promise env vars, template doesn't deliver |
| No health endpoint beyond `pgrep` | [ ] Fix pending (P1) | Port-based check would be more reliable |

---

## Architecture

```
futuopend (this project)
    │
    ├── Dockerfile              — 8 multi-stage build targets
    ├── docker-compose.yaml       — Docker Swarm production config
    ├── docker-compose.simple.yaml — Standalone beginner config
    ├── scripts/wrapper.sh       — Graceful SIGTERM/SIGINT shutdown
    ├── FutuOpenD.xml.template  — Config template with env var support
    └── docs/
        ├── configuration.md    — Full config reference
        └── security.md         — Hardening checklist
```

```
futuopend
    │  TCP :11111 / WS :11112
    ▼
futuapi4go (Go SDK)
    │
    ▼
futugo4bot (Trading bot)
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

---

*Generated from comprehensive enhancement analysis — 2026-04-15*
