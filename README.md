# FutuOpenD Docker

> Docker build for [FutuOpenD](https://openapi.futunn.com/futu-api-doc/) — the local gateway for Futu's trading API.

[![FutuOpenD v10.11.7108](https://img.shields.io/badge/FutuOpenD-v10.11.7108-blue)](https://openapi.futunn.com/futu-api-doc/)
[![CI](https://github.com/shing1211/futuopend/actions/workflows/ci.yml/badge.svg)](https://github.com/shing1211/futuopend/actions/workflows/ci.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/shing1211/futuopend)](https://hub.docker.com/r/shing1211/futuopend)
[![Docs](https://img.shields.io/badge/docs-shing1211.github.io-blue)](https://shing1211.github.io/futuopend/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

---

## What & Why

FutuOpenD is the local gateway for Futu's trading API. The official installer assumes a desktop session — this project
**wraps it in a Docker image** for headless deployment on any Linux host: cloud VM, NAS, Raspberry Pi.

This repo focuses on **building the image**. For deployment, see [futuopend-deploy](https://github.com/shing1211/futuopend-deploy).

---

## Upgrading

When Futu releases a new FutuOpenD version, bump both repos with:

```bash
./scripts/bump-version.sh 10.12.7208 --commit
```

Dry-run (default, no changes):
```bash
./scripts/bump-version.sh 10.12.7208
```

For more control:
```bash
# Discover next available version
./scripts/check-version.sh --discover

# Update Dockerfiles + checksums only
./scripts/check-version.sh --update 10.12.7208

# Also patch futuopend-deploy references (README, docs, XML template)
./scripts/check-version.sh --update 10.12.7208 --deploy ../futuopend-deploy

# Full pipeline with commits
./scripts/check-version.sh --update 10.12.7208 --deploy ../futuopend-deploy --commit
```

**Automated:** `version-poller.yml` (GitHub Actions, weekly Sunday 00:00 UTC) scans Futu's CDN and opens a PR if a new version is found. After merging, trigger `version-bump.yml` in `futuopend-deploy`.

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
| `latest` | Ubuntu 26.04 LTS — multi-arch (`amd64` + `arm64`) |
| `ubuntu-amd64`, `ubuntu-arm64` | Ubuntu variants |
| `rocky-amd64`, `rocky-arm64` | Rocky Linux 9 variants |
| `centos-amd64`, `centos-arm64` | Rocky aliases (backward compat) |
| `:10.11.7108-*` | Versioned builds (amd64 + arm64) |

Builds verify the downloaded FutuOpenD tarball against pinned SHA256 checksums in
[`checksums/futuopend-sha256.txt`](checksums/futuopend-sha256.txt), and base images are pinned by digest for reproducibility.

---

## Project Layout

```
futuopend/
├── Dockerfile.ubuntu     # Ubuntu 26.04 build
├── Dockerfile.rocky      # Rocky Linux 9 build
├── dockerbuild.sh        # Linux/macOS build script
├── dockerbuild.bat       # Windows build script
├── Makefile              # make targets (ubuntu, rocky, multiarch, check)
├── entrypoint.sh         # Container entry point
├── scripts/
│   └── check-version.sh  # Version verification & update
├── docs/                 # GitHub Pages site + architecture docs
└── .github/              # CI, Pages, and issue templates
```

---

## Build Troubleshooting

**Build fails?**
```bash
# Manual tarball download
wget -O Futu_OpenD_10.11.7108_Ubuntu18.04.tar.gz \
  https://softwaredownload.futunn.com/Futu_OpenD_10.11.7108_Ubuntu18.04.tar.gz
```

---

## Runtime & login

This repo builds the image; for deployment (compose, config template, TLS, monitoring) see [futuopend-deploy](https://github.com/shing1211/futuopend-deploy).

- **Ports:** `11111` quote/trade API, `11112` WebSocket (off by default), `22222` Telnet debug/2FA.
- **Config:** OpenD reads `/usr/local/bin/FutuOpenD.xml`; the entrypoint renders `${VAR}` placeholders via `envsubst` before startup.
- **Login (10.10+):** `login_account`/`login_pwd` are no longer read from the XML. Do a one-time interactive login (run without `FUTU_ACCOUNT`, with `-it`) and choose *remember*; thereafter set `FUTU_ACCOUNT` and the entrypoint passes `-login_account=<id> -login_by_remember=1 -area_code=<code>` (default `+852`; override with `FUTU_AREA_CODE`). The cached session lives in the `futuopend-data` volume — do not delete it.
- **2FA:** submit SMS/CAPTCHA over Telnet `22222` (`input_phone_verify_code -code=…` / `input_pic_verify_code -code=…`).
- **WebSocket:** off by default; set `FUTU_WS_PORT` to enable (optional `FUTU_WS_IP`, default `0.0.0.0`).
- **Entrypoint:** forwards extra CLI args, so `docker run … image -lang=en -api_port=11111` works.

---

## Community

- **Docs site** — <https://shing1211.github.io/futuopend/>
- **Discussions** — questions, ideas, and deployment help: <https://github.com/shing1211/futuopend/discussions>
- **Contributing** — see [CONTRIBUTING.md](CONTRIBUTING.md)
- **Support** — see [SUPPORT.md](SUPPORT.md)
- **Security** — see [SECURITY.md](SECURITY.md) (do not report vulnerabilities publicly)

---

## Disclaimer

**Unofficial community packaging.** Not affiliated with Futu Securities. Trading involves risk — use at your own risk.

---

*See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute. Full docs at [shing1211.github.io/futuopend](https://shing1211.github.io/futuopend/).*
