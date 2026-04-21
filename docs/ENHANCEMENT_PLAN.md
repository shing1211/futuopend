# futuopend Enhancement Plan

> **Purpose**: Make futuopend a production-grade Docker deployment platform for FutuOpenD.
>
> **Status**: Core functionality complete. Split Dockerfiles, entrypoint.sh, dockerbuild.bat, CRLF fix all done (2026-04-22).
>
> **Priority**: P0 = Must fix | P1 = Major improvement | P2 = Nice-to-have

---

## 1. CI/CD & Automation — P0

| Priority | Item | Status |
|----------|------|--------|
| **P0** | GitHub Actions CI workflow | ⏳ Pending |
| **P0** | Docker build smoke test | ⏳ Pending |
| **P0** | Automated version bumping | ⏳ Pending |

---

## 2. Dockerfile & Build — P0

| Priority | Item | Status |
|----------|------|--------|
| **P0** | Split Dockerfiles (no wasted build) | ✅ Done |
| **P0** | Unified CMD across targets | ✅ Done |
| **P0** | CRLF line ending fix | ✅ Done |
| **P1** | Parallel build pipeline | ⏳ Pending |
| **P1** | Makefile with standard targets | ⏳ Pending |

---

## 3. Documentation — P0

| Priority | Item | Status |
|----------|------|--------|
| **P0** | SECURITY.md | ✅ Done |
| **P0** | Phone verification callout | ✅ Done |
| **P0** | Deduplicate phone verification docs | ✅ Done |
| **P1** | Platform deployment guides (VPS, Pi, NAS) | ⏳ Pending |
| **P2** | Upgrade guide | ⏳ Pending |

---

## 4. Runtime Reliability — P1

| Priority | Item | Status |
|----------|------|--------|
| **P1** | Connection health monitoring | ⏳ Pending |
| **P1** | Graceful shutdown consistency | ✅ Done |
| **P1** | Connection pool configuration docs | ⏳ Pending |
| **P2** | Resource limits in compose | ⏳ Pending |

---

## 5. Configuration & Ergonomics — P1

| Priority | Item | Status |
|----------|------|--------|
| **P0** | Env var wiring through compose | ✅ Done |
| **P0** | `${FUTU_RSA_KEY}` in template | ✅ Done |
| **P1** | Kubernetes manifests | ⏳ Pending |
| **P1** | Helm chart | ⏳ Pending |
| **P2** | Config validation script | ⏳ Pending |

---

## 6. Observability — P1

| Priority | Item | Status |
|----------|------|--------|
| **P1** | Structured logging to stdout | ⏳ Pending |
| **P1** | Prometheus metrics endpoint | ⏳ Pending |
| **P1** | Startup logging banner | ⏳ Pending |
| **P2** | Grafana dashboard | ⏳ Pending |

---

## 7. Security — P1

| Priority | Item | Status |
|----------|------|--------|
| **P0** | Complete SECURITY.md | ✅ Done |
| **P1** | TLS support documentation | ✅ Done |
| **P1** | Non-root user enforcement | ✅ Done |
| **P1** | Read-only root filesystem | ✅ Done |
| **P2** | Network segmentation docs | ⏳ Pending |

---

## 8. Multi-Arch & Deployment — P2

| Priority | Item | Status |
|----------|------|--------|
| **P2** | Multi-arch CI parallelization | ⏳ Pending |
| **P2** | OrbStack support docs | ⏳ Pending |
| **P3** | Native ARM64 without QEMU | ⏳ Pending |
| **P3** | Windows container support | ⏳ Pending |

---

## Summary

| Phase | Focus | Done | Pending |
|-------|-------|------|---------|
| **Phase 1** | Production Ready | 12 | 0 |
| **Phase 2** | Enterprise Ready | 0 | 10 |
| **Phase 3** | Ecosystem | 0 | 10 |

**Core project is production-ready.** Focus is now on CI/CD and enterprise features.

---

## Project Group

```
futuopend (Docker gateway)
    │
    │  TCP :11111 / WS :11112
    ▼
futuapi4go (Go SDK)
    │
    ▼
futugo4bot (Trading bot)
```

---

*Last updated: 2026-04-22*
