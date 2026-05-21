# FutuOpenD Docker

> Docker build for [FutuOpenD](https://openapi.futunn.com/futu-api-doc/) — the local gateway for Futu's trading API.

[![FutuOpenD v10.6.6608](https://img.shields.io/badge/FutuOpenD-v10.6.6608-blue)](https://openapi.futunn.com/futu-api-doc/)
[![Docker Pulls](https://img.shields.io/docker/pulls/shing1211/futuopend)](https://hub.docker.com/r/shing1211/futuopend)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

---

## What & Why

FutuOpenD is the local gateway for Futu's trading API. The official installer assumes a desktop session — this project
**wraps it in a Docker image** for headless deployment on any Linux host: cloud VM, NAS, Raspberry Pi.

This repo focuses on **building the image**. For deployment, see [futuopend-deploy](https://github.com/shing1211/futuopend-deploy).

---

## Build

```bash
# Linux/macOS (via build script)
./dockerbuild.sh all                    # both Ubuntu + Rocky variants
./dockerbuild.sh ubuntu                # Ubuntu only
./dockerbuild.sh rocky                # Rocky only

# Linux/macOS (via Makefile)
make ubuntu                            # same as ./dockerbuild.sh ubuntu
make rocky                             # same as ./dockerbuild.sh rocky
make multiarch                         # multi-arch (amd64 + arm64)

# Windows
dockerbuild.bat all
dockerbuild.bat ubuntu

# Multi-arch (amd64 + arm64)
./dockerbuild.sh --all    # both amd64 + arm64, ubuntu + rocky

# ARM boards (Raspberry Pi 3/4/5)
./dockerbuild.sh --all ubuntu   # ubuntu arm64 only

# Version check
make check                             # verify current version tarballs exist
./scripts/check-version.sh             # same, with full output
./scripts/check-version.sh --update    # bump version in Dockerfiles
```

**Note on ARM performance:** Futu provides x86_64 binaries only. ARM builds use QEMU user-mode emulation, which works but is ~2-5x slower than native x86_64. For latency-sensitive trading on a Raspberry Pi, consider [box64](https://github.com/ptitSeb/box64) — install it on the host and the container will use it automatically.

**Docker tags:**
| Tag | Description |
|-----|-------------|
| `latest`, `ubuntu` | Ubuntu 24.04 LTS (amd64) |
| `rocky`, `centos` | Rocky Linux 9 (amd64) |
| `:10.6.6608-*` | Versioned builds (amd64 + arm64) |

---

## Project Layout

```
futuopend/
├── Dockerfile.ubuntu     # Ubuntu 24.04 build
├── Dockerfile.rocky      # Rocky Linux 9 build
├── dockerbuild.sh        # Linux/macOS build script
├── dockerbuild.bat       # Windows build script
├── Makefile              # make targets (ubuntu, rocky, multiarch, check)
├── entrypoint.sh         # Container entry point
├── scripts/
│   └── check-version.sh  # Version verification & update
└── docs/
    └── ARCHITECTURE.md   # Build architecture & design
```

---

## Build Troubleshooting

**Build fails?**
```bash
# Manual tarball download
wget -O Futu_OpenD_10.6.6608_Ubuntu18.04.tar.gz \
  https://softwaredownload.futunn.com/Futu_OpenD_10.6.6608_Ubuntu18.04.tar.gz
```

---

## Disclaimer

**Unofficial community packaging.** Not affiliated with Futu Securities. Trading involves risk — use at your own risk.

---

*See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute. Full docs in [docs/](docs/).*
