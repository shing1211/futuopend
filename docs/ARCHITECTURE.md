# FutuOpenD Docker — Architecture

> FutuOpenD in a container. Cloud VM, NAS, Raspberry Pi — anywhere Docker runs.

## Overview

FutuOpenD is the local gateway daemon for Futu's trading API. This project packages FutuOpenD into Docker images so it can run on servers, cloud VMs, NAS devices, and ARM hardware without a desktop session.

**Current version:** 10.8.6808

**For runtime deployment, see:** [futuopend-deploy](https://github.com/shing1211/futuopend-deploy)

---

## Build Architecture

### 1. Multi-Stage Dockerfiles

Two Dockerfiles for different base OS variants, each supporting `amd64` and `arm64`:

| File | Base OS | Tarball Source |
|------|---------|---------------|
| `Dockerfile.ubuntu` | Ubuntu 24.04 LTS | `Futu_OpenD_<ver>_Ubuntu18.04.tar.gz` |
| `Dockerfile.rocky` | Rocky Linux 9 | `Futu_OpenD_<ver>_Centos7.tar.gz` |

```
base-${TARGETARCH:-amd64}
     │
     ▼
build stage                     final stage
     │                              │
     ├── Download tarball           │
     ├── tar -xzf → /tmp/           │
     │                              │
     └── COPY binary ──────────────►│
                                    ├── /usr/local/bin/FutuOpenD
                                    ├── /usr/local/bin/entrypoint.sh
                                    ├── user: futuopend (non-root)
                                    └── HEALTHCHECK (pgrep)
```

Key features:
- `ARG FUTU_OPEND_VER` — version baked in at build time
- `HEALTHCHECK --interval=30s --start-period=60s` — waits for auth before marking healthy
- `pgrep FutuOpenD` — no curl dependency outside the image
- CRLF auto-fix for Windows shell compatibility
- Non-root user `futuopend:1000`

### 2. Build Scripts

**Linux/macOS** — `dockerbuild.sh`

| Command | Builds |
|---------|--------|
| `./dockerbuild.sh all` | ubuntu + rocky, amd64 only |
| `./dockerbuild.sh ubuntu` | ubuntu only |
| `./dockerbuild.sh rocky` | rocky only |
| `./dockerbuild.sh --all` | ubuntu + rocky, amd64 + arm64 (multi-arch) |

Multi-arch mode uses `docker buildx` and pushes to Docker Hub directly. Single-arch mode builds locally then pushes.

**Windows** — `dockerbuild.bat`

Same variants as the Linux script, minus multi-arch support.

### 3. Container Entry Point (`entrypoint.sh`)

Bundled into the image at build time. Responsibilities:
1. **Trap signals** — `SIGTERM`, `SIGINT`, `SIGHUP`
2. **Start** — launches `FutuOpenD` in background, records PID
3. **Wait** — blocks on the process
4. **Shutdown** — sends `TERM`, waits 30s, escalates to `KILL`

```
SIGTERM/SIGINT/SIGHUP
         │
         ▼
    shutdown()
         │
     kill -TERM $PID ──► wait 30s ──► kill -9 $PID
```

---

## Docker Image Tags

Tags pushed to Docker Hub (`shing1211/futuopend`):

| Tag | Description |
|-----|-------------|
| `latest` | Ubuntu amd64 (default) |
| `ubuntu-amd64`, `ubuntu-arm64` | Ubuntu variants |
| `rocky-amd64`, `rocky-arm64` | Rocky Linux variants |
| `centos-amd64`, `centos-arm64` | Rocky aliases (backward compat) |
| `:10.5.6508-*` | Versioned builds |

---

## Key Build Flow

```
dockerbuild.sh all
    │
    ├── Check tarballs exist on softwaredownload.futunn.com
    │
    ├── docker build -f Dockerfile.ubuntu --target final
    │       │
    │       └── Download → extract → COPY → tag → push
    │
    ├── docker build -f Dockerfile.rocky --target final
    │       │
    │       └── Download → extract → COPY → tag → push
    │
    └── Tag + push :latest (ubuntu-amd64)
```

---

*This project is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
