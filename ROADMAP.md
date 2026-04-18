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
- [x] **Fix stage-execution bug** — Split into `Dockerfile.ubuntu` / `Dockerfile.rocky` — each builds only its own base
- [x] **SECURITY.md** — Security policy with disclosure process and supported versions
- [x] **Fix ROADMAP.md** — Replaced placeholder stubs with real roadmap (2026-04-18)
- [ ] **Wire env vars through compose files** — Align `.env.example` with `docker-compose.yaml`
- [x] **Fix `${FUTU_RSA_KEY}` in XML template** — Template now uses `${FUTU_RSA_KEY}` env var (2026-04-18)
- [ ] **Phone verification callout in Quick Start** — Prevent user panic on first-run verification
- [ ] **Deduplicate phone verification docs** — Keep canonical version in `docs/configuration.md`
- [ ] **Automated version bumping** — CI detects `FUTU_OPEND_VER` change and creates GitHub release

---

## Phase 1: Enterprise Ready (P1)

> *Suitable for serious production trading infrastructure.*

- [ ] **Kubernetes manifests** (`k8s/`) — Deployment, Service, Secret, PersistentVolumeClaim
- [ ] **Helm chart** — Published on GitHub Pages for `helm install`
- [x] **Graceful shutdown on all targets** — All 4 `final-*` targets use `wrapper.sh` (2026-04-18)
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
| Both build stages always run regardless of `--target` | [x] Done (P0) | Split into `Dockerfile`, `Dockerfile.ubuntu`, `Dockerfile.rocky` — each targets only its own base |
| Graceful shutdown only on 2 of 4 targets | [x] Done (P1) | All 4 targets now use `wrapper.sh` |
| No GitHub Actions CI | [ ] Fix pending (P0) | Manual builds only |
| `SECURITY.md` missing | [x] Done (P0) | Added 2026-04-17 |
| ROADMAP.md is placeholder stubs | [x] Done (P0) | Replaced with real roadmap (2026-04-18) |
| `${FUTU_RSA_KEY}` not wired in template | [x] Done (P0) | `FutuOpenD.xml.template` now uses `${FUTU_RSA_KEY}` env var |
| No health endpoint beyond `pgrep` | [ ] Fix pending (P1) | Port-based check would be more reliable |

---

## Architecture

```
futuopend (this project)
    │
    ├── Dockerfile              — Ubuntu 24.04 targets (final-amd64, final-arm64)
    ├── Dockerfile.ubuntu       — Alias for Dockerfile (Ubuntu variant)
    ├── Dockerfile.rocky        — Rocky Linux 9 variant (final-amd64, final-arm64)
    ├── docker-compose.yaml        — Docker Swarm production config
    ├── docker-compose.simple.yaml  — Standalone beginner config
    ├── scripts/wrapper.sh        — Graceful SIGTERM/SIGINT shutdown
    ├── FutuOpenD.xml.template   — Config template with env var support
    └── docs/
        ├── configuration.md     — Full config reference
        └── security.md          — Hardening checklist
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
