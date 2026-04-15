# futuopend Enhancement Plan

> **Purpose**: Comprehensive enhancement checklist to make futuopend a production-grade, reliable Docker deployment platform for FutuOpenD.
>
> **Status**: Core functionality complete. Gap to production-ready: well-defined and actionable.
>
> **Tech Stack**: Docker, Docker Compose, Shell scripts, Docker Buildx
>
> **Priority Key**: P0 = Must fix before production use | P1 = Major improvement | P2 = Important | P3 = Nice-to-have

---

## Table of Contents

1. [CI/CD & Automation](#1-cicd--automation--p0)
2. [Dockerfile & Build Optimization](#2-dockerfile--build-optimization--p0)
3. [Documentation](#3-documentation--p0)
4. [Runtime Reliability](#4-runtime-reliability--p1)
5. [Configuration & Ergonomics](#5-configuration--ergonomics--p1)
6. [Observability](#6-observability--p1)
7. [Security](#7-security--p1)
8. [Multi-Arch & Deployment Targets](#8-multi-arch--deployment-targets--p2)
9. [Ecosystem & Tooling](#9-ecosystem--tooling--p2)
10. [Priority Roadmap](#10-priority-roadmap)

---

## 1. CI/CD & Automation — P0

| Priority | Effort | Item | Action | Why It Matters |
|----------|--------|------|--------|----------------|
| **P0** | Medium | **GitHub Actions CI workflow** | Add `.github/workflows/ci.yml`: (a) `shellcheck` lint on all `.sh` files on PR, (b) `docker build` smoke test for every target (all 8 targets), (c) push to Docker Hub on merge to `main` with version tags, (d) `docker scout` or `trivy` security scan. Gate on zero lint errors. | No CI = unvalidated changes to production Docker images. Every merge to main should produce a tested, tagged image. |
| **P0** | Medium | **Docker build smoke test** | In CI: run `docker build` for every target (`final-*`), then `docker run --rm <target> pgrep FutuOpenD` to verify the binary starts. Test both `amd64` and `arm64` variants. | Ensures every target actually produces a working image. Prevents broken images from reaching Docker Hub. |
| **P0** | Low | **Automated version bumping** | In CI: detect `FUTU_OPEND_VER` change in `Dockerfile` → auto-create GitHub release with release notes. Tag Docker Hub with semantic version. | Manual version bumping is error-prone. Automated tagging ensures Docker Hub always has the correct version. |

---

## 2. Dockerfile & Build Optimization — P0

| Priority | Effort | Item | Action | Why It Matters |
|----------|--------|------|--------|----------------|
| **P0** | Medium | **Fix stage-execution bug** | `docker build --target final-ubuntu` currently executes the Rocky build stage because base images are declared at the top. Restructure: move `base-centos` and `base-ubuntu` to be conditionally used only by the stages that need them. Use `--only` pattern or split into separate Dockerfiles per OS family. | Build time doubles for every invocation. A `--target` flag should only build the relevant stage. |
| **P0** | Low | **Unified CMD across targets** | `final-ubuntu-amd64` uses `wrapper.sh` but `final-ubuntu-arm64` uses `FutuOpenD` directly. `final-rocky-amd64` and `final-rocky-arm64` also differ. Standardize: all Ubuntu targets use `wrapper.sh`, all Rocky targets use `wrapper.sh`. | Inconsistent startup behavior = unpredictable production behavior. Graceful shutdown (SIGTERM handling) is essential for cloud orchestrators (K8s, ECS). |
| **P1** | Medium | **Parallel build pipeline** | `dockerbuild.sh` builds Ubuntu and Rocky sequentially. Parallelize with `build_and_push ubuntu &` + `build_and_push rocky &` + `wait`. For multi-arch, parallelize per variant. | Reduces total CI time from ~10min to ~5min. |
| **P1** | Low | **Makefile with standard targets** | Add `Makefile`: `make build`, `make build-all`, `make push`, `make lint`, `make test`, `make clean`. Document in CONTRIBUTING.md. | Consistent developer experience across all three projects. |
| **P2** | Medium | **Build caching optimization** | Use `docker build --cache-from shing1211/futuopend:ubuntu` to speed up rebuilds. Pin base image digests in CI instead of tags (`ubuntu@sha256:...`). | Faster CI runs, more deterministic builds. |

---

## 3. Documentation — P0

| Priority | Effort | Item | Action | Why It Matters |
|----------|--------|------|--------|----------------|
| **P0** | Low | **Fix ROADMAP.md** | Current ROADMAP.md is an AI-generated placeholder stub. Replace with this enhancement plan's phased roadmap. | Misleading for contributors. A clear roadmap attracts contributors. |
| **P0** | Low | **Add SECURITY.md** | Create `SECURITY.md` (GitHub-supported security policy): (a) disclosure process, (b) supported versions, (c) how to report vulnerabilities, (d) severity classification. | Required for open-source best practice. GitHub flags repos without it. |
| **P0** | Low | **Phone verification callout in Quick Start** | Add a one-liner in the Quick Start section of README: "If you see 'Waiting for phone verify code' — this is normal on first run. Complete phone verification in the Futu app." Link to the verification section. | Users panic and open issues when they see this message. It blocks first-time setup. |
| **P0** | Low | **Deduplicate phone verification docs** | Keep canonical version in `docs/configuration.md`. In README: trim to a one-sentence callout + link to the canonical section. | DRY principle. Reduces maintenance burden when verification process changes. |
| **P1** | Low | **`docker-compose.yaml` vs `simple.yaml` distinction** | Add a header comment in each compose file explaining when to use which: `simple.yaml` = beginners / single-host, `docker-compose.yaml` = Docker Swarm / production / secrets. | Users don't know which to pick. Misconfiguration leads to production issues. |
| **P1** | Medium | **Deployment guide per platform** | Add `docs/deploy/` directory with guides for: (a) VPS (Ubuntu, 1GB RAM), (b) Raspberry Pi 4, (c) NAS (Synology, QNAP), (d) Cloud (AWS EC2, GCP, Azure). Each with `docker-compose` examples. | The README is good but lacks deployment-specific guidance for different hardware. |
| **P2** | Low | **Upgrade guide** | Add `docs/UPGRADE.md`: how to upgrade FutuOpenD version (change `FUTU_OPEND_VER` arg), how to migrate config, how to backup state before upgrade. | Users fear breaking their setup. Clear upgrade instructions reduce support burden. |
| **P2** | Low | **Docker image size badge** | Add `dockeri.co` or `microbadger` badge in README showing image size. | Helps users on bandwidth-constrained connections (e.g., Raspberry Pi with slow internet). |
| **P2** | Low | **FutuQuant SDK link verification** | Verify the Python SDK link (`https://github.com/Futuromy/FutuQuant`) is still active. Update to current SDK if the repo has moved. | Dead links erode trust in documentation quality. |

---

## 4. Runtime Reliability — P1

| Priority | Effort | Item | Action | Why It Matters |
|----------|--------|------|--------|----------------|
| **P1** | Medium | **Connection pool configuration** | Document connection pool settings in `docs/configuration.md`: `maxConnCount`, `enableTimeSharing`, `timeSharingPer`. Add a compose example showing recommended production pool settings. | Default pool settings may not be optimal for multi-client or high-frequency trading setups. |
| **P1** | Medium | **Auto-restart on crash** | Configure `restart: always` in compose files (already set) but document the recovery behavior. Add a `restart: on-failure: 3` policy option in the production compose file. | Ensures the gateway recovers from crashes automatically without manual intervention. |
| **P1** | Low | **Graceful shutdown consistency** | Currently `wrapper.sh` (graceful SIGTERM/SIGINT handling) is only used on `final-ubuntu-amd64` and `final-rocky-*`. Extend to ALL final targets. Add `trap` for SIGTERM that sends `SIGTERM` to FutuOpenD and waits for clean exit. | All targets should behave the same. SIGTERM is how Kubernetes, Docker Swarm, and ECS stop containers. |
| **P1** | Medium | **Connection health monitoring** | Add a lightweight health check beyond `pgrep`: use `nc -z localhost 11111` to verify the TCP port is listening, or query the Telnet debug port (22222) for a quick health ping. More reliable than process-existence check. | `pgrep FutuOpenD` succeeds even if the binary crashed and left a zombie. Port check confirms actual network readiness. |
| **P2** | Medium | **Version compatibility matrix** | Document which FutuOpenD versions have been tested. Pin the version in CI (`ARG FUTU_OPEND_VER=10.2.6208`) and verify it still downloads from Futu's CDN in CI. | Futu updates their binary URL structure. Outdated links break builds silently. |
| **P2** | Low | **Resource limits** | Add `deploy.resources.limits` and `deploy.resources.reservations` to `docker-compose.yaml` for production use: memory limit, CPU shares. Document recommended values. | Prevents FutuOpenD from consuming all host resources in shared environments. |

---

## 5. Configuration & Ergonomics — P1

| Priority | Effort | Item | Action | Why It Matters |
|----------|--------|------|--------|----------------|
| **P0** | Low | **Wire env vars through compose files** | `docker-compose.yaml` has `environment:` and `secrets:` but `.env.example` and docs don't align. Document all environment variables (`TZ`, `FUTU_OPEND_VER`, etc.) and how to use Docker secrets for sensitive values. | Users copy-paste compose files and are confused when secrets don't work. |
| **P0** | Low | **Fix `${FUTU_RSA_KEY}` in XML template** | `FutuOpenD.xml.template` has RSA key line commented as a plain path. Add a proper `${FUTU_RSA_KEY}` env var reference with documentation on how Docker secrets are mounted as `/run/secrets/`. | The docs promise env var support but the template doesn't deliver it. |
| **P1** | Low | **Remove unused `RSA_FILE_PATH` from `.env.example`** | `RSA_FILE_PATH` is defined in `.env.example` but never referenced. Remove it or document its purpose if it's intentional. | Reduces user confusion about which env vars are actually used. |
| **P1** | Low | **Update `--help` in dockerbuild.sh** | The `--help` output at line 129-140 doesn't list `--list`. Add it: `--list — list available variants`. | Missing help for `--list` is confusing. Users should discover all options from `--help`. |
| **P1** | Medium | **Kubernetes deployment manifests** | Add `k8s/` directory with: (a) `Deployment.yaml` with resource limits and readiness/liveness probes, (b) `Service.yaml` for ClusterIP/NodePort, (c) `Secret.yaml` for RSA key, (d) `PersistentVolumeClaim.yaml` for data directory. | Kubernetes is the standard for production deployment. Docker Compose is not enough for enterprise users. |
| **P1** | Medium | **Helm chart** | Add `helm/futuopend/` with a proper Helm chart: `values.yaml` with all config options, `Chart.yaml` with versioning. Publish on GitHub Pages. | Helm is the standard package manager for Kubernetes. Makes enterprise adoption much easier. |
| **P2** | Low | **`--version` flag** | Add `--version` output to `dockerbuild.sh` that reads the pinned `FUTU_OPEND_VER`. | Standard CLI convention. Helps users confirm which version they're running. |
| **P2** | Low | **Config validation script** | Add `scripts/validate_config.sh`: validates `FutuOpenD.xml` syntax (XML well-formedness, required elements present). Run in CI and as a pre-flight check. | Config errors are discovered at runtime. Validation catches them at deploy time. |

---

## 6. Observability — P1

| Priority | Effort | Item | Action | Why It Matters |
|----------|--------|------|--------|----------------|
| **P1** | Medium | **Structured logging to stdout** | Configure FutuOpenD's log level to INFO/DEBUG and redirect logs to Docker's stdout/stderr. Add `logging:` section to compose file with JSON log format option. | Docker log aggregation (CloudWatch, ELK, Loki) expects structured logs on stdout/stderr. |
| **P1** | Medium | **Metrics endpoint** | If FutuOpenD exposes a metrics port (debug port on 22222), add a sidecar or log-based exporter for Prometheus. Alternatively, document how to scrape the Telnet debug port for connection stats. | FutuOpenD exposes useful stats via its debug/Telnet interface. Prometheus scraping enables Grafana dashboards. |
| **P1** | Medium | **Startup logging** | Add startup banner to `wrapper.sh`: log FutuOpenD version, build date, listening ports, and mount points. | Makes troubleshooting much faster. Currently the container starts silently. |
| **P2** | Low | **Alerting guide** | Add `docs/MONITORING.md`: define alert rules for: (a) container restart count > 3/hr, (b) log contains "connection failed", (c) port 11111 not listening. Integrate with Prometheus Alertmanager. | Automated alerting prevents outages from going unnoticed. |
| **P2** | Medium | **Grafana dashboard** | Add `monitoring/grafana/` with pre-built dashboard JSON: connection uptime, restart count, log error rate, memory usage. | Visual monitoring is essential for production. |

---

## 7. Security — P1

| Priority | Effort | Item | Action | Why It Matters |
|----------|--------|------|--------|----------------|
| **P0** | Low | **Complete `SECURITY.md`** | Document: (a) supported versions (only latest FutuOpenD), (b) how to report security issues, (c) severity + SLA for responses, (d) disclosure policy. | Open-source best practice. GitHub flags repos without it. |
| **P1** | Low | **TLS support documentation** | Document how to enable TLS in FutuOpenD config (FutuOpenD supports TLS). Add an example `FutuOpenD.xml` snippet showing TLS configuration. | Users running FutuOpenD over public networks need TLS. |
| **P1** | Medium | **Kubernetes Secret example** | Complete the Kubernetes Secret example in `docs/security.md`: show how to `kubectl create secret generic` from a PEM file, how to mount it as a volume, how to verify it works. | The current example is incomplete and users can't deploy securely. |
| **P1** | Low | **Non-root user enforcement** | Verify all targets run as `futuopend` user (already done in Dockerfile). Document that running as root is unsupported. Add `USER futuopend` as a comment in the Dockerfile. | Security best practice. Running as root inside containers is dangerous. |
| **P1** | Low | **Read-only root filesystem** | Add `security_opt: no-new-privileges:true` and `read_only: true` (with tmpfs for `/tmp`) to compose `deploy:` section. Document the trade-off. | Defense in depth. Prevents container escape attacks. |
| **P2** | Low | **Network segmentation docs** | Document the recommended network architecture: futuopend on an isolated Docker network, only `futuapi4go` client containers can reach it, no direct internet access from the container. | Users running on VPS need guidance on firewall configuration. |

---

## 8. Multi-Arch & Deployment Targets — P2

| Priority | Effort | Item | Action | Why It Matters |
|----------|--------|------|--------|----------------|
| **P2** | Medium | **Multi-arch CI parallelization** | In GitHub Actions CI, build all 8 targets in parallel using a matrix strategy. Currently builds are likely sequential. | Faster CI = faster feedback loop for contributors. |
| **P2** | Medium | **Windows container support** | Investigate Windows Nano Server or Windows Server Core as a FutuOpenD host. Windows containers are common in enterprise environments. | Some trading setups require Windows infrastructure. |
| **P2** | Low | **Native ARM64 without QEMU** | Investigate whether FutuOpenD can run natively on ARM64 (Apple Silicon Mac for local dev). The current ARM builds use QEMU emulation which is slow. | Native ARM = faster local development on M-series Macs. |
| **P3** | High | **Docker Scout / Trivy integration** | Add `docker scout quay shing1211/futuopend:latest` to CI to catch CVEs in base images and FutuOpenD dependencies. | Proactive security scanning catches vulnerabilities before they're exploited. |

---

## 9. Ecosystem & Tooling — P2

| Priority | Effort | Item | Action | Why It Matters |
|----------|--------|------|--------|----------------|
| **P2** | Low | **Docker image size optimization** | Use `FROM scratch` for a truly minimal base where possible. However, FutuOpenD needs libc — use `gcr.io/distroless/static:nonroot` if compatible. Or at minimum, add `COPY --from=build` with `--chown` to avoid layer bloat. | Smaller images = faster pulls = faster deployments. |
| **P2** | Medium | **OrbStack support** | Test and document running on OrbStack (macOS ARM-native Docker alternative). OrbStack is faster than Docker Desktop for local development. | OrbStack is gaining popularity among Mac developers. |
| **P3** | Medium | **GitHub Actions reusable workflow** | Create `.github/workflows/_futuopend-ci.yml` as a reusable workflow that futugo4bot and futuapi4bot can reference for their Docker-based CI needs. | DRY across the project group. |
| **P3** | Low | **Docker Hub README automation** | Set up Docker Hub auto-description via `repository-description.yml` so the Docker Hub page has the same info as the GitHub README. | Docker Hub is the primary discovery surface for Docker users. |
| **P3** | Low | **Stars history badge** | Add a stars history chart badge to README using `ossf/ossf-history` or similar. Shows community growth trajectory. | Demonstrates project traction and health to new users. |

---

## 10. Priority Roadmap

### Phase 0 — Production Readiness (P0 items only)
> *Before any v1.0.0 release. These are blockers.*

| # | Item | Category | Why |
|---|------|----------|-----|
| 1 | GitHub Actions CI workflow | CI/CD | No CI = unvalidated production images |
| 2 | Docker build smoke test | CI/CD | Every target must be verified on every PR |
| 3 | Fix stage-execution bug (both stages always run) | Dockerfile | Build time is 2× what it should be |
| 4 | Add SECURITY.md | Documentation | GitHub flags repos without it |
| 5 | Fix ROADMAP.md (replace placeholder stubs) | Documentation | Misleading for contributors |
| 6 | Wire env vars through compose files | Configuration | Users can't configure secrets correctly |
| 7 | Fix `${FUTU_RSA_KEY}` in XML template | Configuration | Docs promise env vars, template doesn't deliver |
| 8 | Add phone verification callout to Quick Start | Documentation | Users panic on first-run verification prompt |
| 9 | Deduplicate phone verification docs | Documentation | DRY violation creates maintenance burden |
| 10 | Automated version bumping on FUTU_OPEND_VER change | CI/CD | Manual tagging is error-prone |

### Phase 1 — Enterprise Ready (P1 items)
> *SDK is reliable enough for serious trading bots.*

| # | Item | Category |
|---|------|----------|
| 1 | Kubernetes manifests (`k8s/` directory) | Configuration |
| 2 | Helm chart | Configuration |
| 3 | Graceful shutdown consistency (all targets use `wrapper.sh`) | Runtime Reliability |
| 4 | Connection health monitoring (port check, not just `pgrep`) | Runtime Reliability |
| 5 | Structured logging to stdout + Prometheus metrics | Observability |
| 6 | Connection pool configuration documentation | Runtime Reliability |
| 7 | Non-root user + read-only root filesystem enforcement | Security |
| 8 | Kubernetes Secret example completion | Security |
| 9 | Deployment guides per platform (`docs/deploy/`) | Documentation |
| 10 | Parallel build in `dockerbuild.sh` | Dockerfile |

### Phase 2 — Ecosystem (P2 items)
> *Fine-tuning and community building.*

| # | Item | Category |
|---|------|----------|
| 1 | Helm chart (publish on GitHub Pages) | Configuration |
| 2 | Parallel multi-arch CI builds | Multi-Arch |
| 3 | OrbStack support documentation | Ecosystem |
| 4 | Docker Scout / Trivy CVE scanning | Security |
| 5 | Config validation script | Configuration |
| 6 | Startup logging banner | Observability |
| 7 | Grafana dashboard | Observability |
| 8 | Docker image size optimization | Ecosystem |
| 9 | Makefile with standard targets | Tooling |
| 10 | Upgrade guide | Documentation |

### Phase 3 — Ecosystem Polish (P3 items)
> *Nice-to-have for community and long-term maintenance.*

| # | Item | Category |
|---|------|----------|
| 1 | Reusable GitHub Actions workflow | Tooling |
| 2 | Docker Hub README automation | Ecosystem |
| 3 | Stars history badge | Ecosystem |
| 4 | Native ARM64 without QEMU investigation | Multi-Arch |
| 5 | Windows container investigation | Multi-Arch |

---

## Summary

| Phase | Focus | P0 | P1 | P2 | P3 | Total |
|-------|-------|----|----|----|----|-------|
| **Phase 0** | Production Readiness | 10 | — | — | — | 10 |
| **Phase 1** | Enterprise Ready | — | 10 | — | — | 10 |
| **Phase 2** | Ecosystem | — | — | 10 | — | 10 |
| **Phase 3** | Polish | — | — | — | 5 | 5 |

**Total: 35 enhancement items across 9 categories.**

---

## Project Group Architecture

```
futuopend (Docker gateway — this project)
    │
    │  TCP :11111 / WebSocket :11112
    ▼
futuapi4go (Go SDK — github.com/shing1211/futuapi4go)
    │                                          ↑
futuapi-java (Official Futu Python + Java SDKs) ─────────┘
    │
    ├── futugo4bot (Go bot — github.com/shing1211/futugo4bot)
    ├── futujava4bot (Java bot — github.com/shing1211/futujava4bot)
    └── futupython4bot (Python bot — github.com/shing1211/futupython4bot)
```

### Dependency Chain for Improvements

| futuopend Improvement | Benefits |
|----------------------|----------|
| Health check (port-based) | futugo4bot feed monitor detects gateway failures faster |
| Graceful shutdown (all targets) | futugo4bot recovers cleanly from container restarts |
| Structured logging + Prometheus | futugo4bot Grafana dashboard completeness |
| Connection pool docs | futugo4bot connection stability in high-frequency scenarios |
| TLS support docs | Secure remote deployment of OpenD (futugo4bot on different host) |
| Kubernetes manifests + Helm | Enterprise deployment of futugo4bot with proper orchestration |
| Parallel multi-arch CI | Faster builds = faster iteration on all three projects |

### futuopend → futuapi4go relationship
- `futuapi4go` connects to futuopend via TCP
- futuopend's connection pool docs help `futuapi4go` users configure optimal settings
- futuopend's health check improvements help `futuapi4go`'s `pkg/reliability/feed_monitor.go` (futugo4bot) detect failures

### futuopend → futugo4bot relationship
- futugo4bot's `pkg/reliability/failover.go` (multiple OpenD connections) works best with multiple futuopend containers
- futugo4bot's Docker compose (`run-docker.sh`) should reference the official `shing1211/futuopend` image from Docker Hub

---

## Related Documentation

- [ROADMAP.md](ROADMAP.md) — Project roadmap (update this with the phased plan above)
- [TODO.md](TODO.md) — Prioritized open items (incorporate into this plan)
- [docs/configuration.md](docs/configuration.md) — Configuration reference
- [docs/security.md](docs/security.md) — Security hardening guide
- [futuapi4go](https://github.com/shing1211/futuapi4go) — Go SDK that connects to futuopend
- [futugo4bot](https://github.com/shing1211/futugo4bot) — Go trading bot powered by futuapi4go + futuopend
- [futujava4bot](https://github.com/shing1211/futujava4bot) — Java trading bot (uses official Futu Java SDK)
- [futupython4bot](https://github.com/shing1211/futupython4bot) — Python quant research platform (uses official Futu Python SDK)
