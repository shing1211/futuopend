# FutuOpenD Docker

> FutuOpenD in a container. Cloud VM, NAS, Raspberry Pi — anywhere Docker runs.

[![FutuOpenD v10.5.6508](https://img.shields.io/badge/FutuOpenD-v10.5.6508-blue)](https://openapi.futunn.com/futu-api-doc/)
[![Docker Pulls](https://img.shields.io/docker/pulls/shing1211/futuopend)](https://hub.docker.com/r/shing1211/futuopend)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

---

## What & Why

FutuOpenD is the local gateway for Futu's trading API. The official installer assumes a desktop session — this project Dockerizes it.

**One command, live on port 11111.** No X11, no dependency juggling.

---

## Features

- **Multi-market** — HK, US, A-Share, SG, JP, AU equities, ETFs, options, futures
- **Real-time push** — WebSocket quotes, order book, ticks, candles
- **TCP + WebSocket** — SDKs in Python, Java, C#, C++, JS
- **Two OS variants** — Ubuntu 24.04 LTS & Rocky Linux 9
- **Multi-arch** — amd64 + arm64 (Raspberry Pi)
- **Production-ready** — non-root user, secrets support, TLS-ready

---

## Quick Start

```bash
# 1. Clone & configure
git clone https://github.com/shing1211/futuopend.git
cd futuopend
cp FutuOpenD.xml.template FutuOpenD.xml

# 2. Edit FutuOpenD.xml with your account
# <login_account>YOUR_ID</login_account>
# <login_pwd_md5>YOUR_MD5_HASH</login_pwd_md5>

# 3. Start
docker compose -f docker-compose.simple.yaml up -d
docker compose -f docker-compose.simple.yaml logs -f
```

**Verify:**
```bash
curl http://localhost:11111/version
```

---

## Architecture

```
┌─────────────────────────────────────┐
│         Your App / SDK              │
└──────────────┬──────────────────────┘
               │ TCP / WebSocket
┌──────────────▼──────────────────────┐
│        FutuOpenD Gateway            │
│  :11111 TCP  │  :11112 WS  │  :22222 Telnet  │
└──────────────┬──────────────────────┘
               │ HTTPS / WSS
┌──────────────▼──────────────────────┐
│        Futu Servers                 │
└─────────────────────────────────────┘
```

---

## Build from Source

```bash
# Linux/macOS
./dockerbuild.sh all                    # both variants
./dockerbuild.sh ubuntu                # ubuntu only
./dockerbuild.sh rocky                # rocky only

# Windows
dockerbuild.bat all
dockerbuild.bat ubuntu

# Multi-arch (amd64 + arm64)
./dockerbuild.sh --all    # both amd64 + arm64, ubuntu + rocky

# ARM boards (Raspberry Pi 3/4/5)
./dockerbuild.sh --all ubuntu   # ubuntu arm64 only
```

**Note on ARM performance:** Futu provides x86_64 binaries only. ARM builds use QEMU user-mode emulation, which works but is ~2-5x slower than native x86_64. For latency-sensitive trading on a Raspberry Pi, consider [box64](https://github.com/ptitSeb/box64) (native x86_64 emulation with dynamic recompilation) — install it on the host and the container will use it automatically.

**Docker tags:**
| Tag | Description |
|-----|-------------|
| `latest`, `ubuntu` | Ubuntu 24.04 (amd64) |
| `rocky`, `centos` | Rocky Linux 9 (amd64) |
| `:10.5.6508-*` | Versioned builds |

---

## Trading Setup

Quote-only works without an RSA key. For trading or remote access:

1. Generate RSA key at [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI)
2. Mount it: `<rsa_private_key>/run/secrets/rsa_key.txt</rsa_private_key>`
3. Bind to all interfaces: `<ip>0.0.0.0</ip>`

Security hardening → see [docs/security.md](docs/security.md)

---

## Phone Verification

First login from a new IP triggers SMS verification:

```bash
# Add to docker-compose.yaml:
#   - "22222:22222"

# Submit code:
echo "input_phone_verify_code -code=123456" | nc 127.0.0.1 22222
```

---

## Configuration

`FutuOpenD.xml` supports `${ENV_VAR}` substitution.

| Variable | Maps to |
|----------|---------|
| `FUTU_ACCOUNT` | `<login_account>` |
| `FUTU_PWD_MD5` | `<login_pwd_md5>` |
| `FUTU_RSA_KEY` | `<rsa_private_key>` |
| `FUTU_IP` | `<ip>` (default: `127.0.0.1`) |
| `TZ` | Timezone (default: `Asia/Hong_Kong`) |

Full reference → [docs/configuration.md](docs/configuration.md)

---

## Project Layout

```
futuopend/
├── Dockerfile.ubuntu     # Ubuntu 24.04 build
├── Dockerfile.rocky      # Rocky Linux 9 build
├── docker-compose.yaml   # Swarm (secrets)
├── docker-compose.simple.yaml  # Standalone
├── dockerbuild.sh/.bat   # Build scripts
├── entrypoint.sh         # Container entry
├── FutuOpenD.xml.template
└── docs/
    ├── configuration.md
    └── security.md
```

---

## Troubleshooting

**Container exits immediately?**
```bash
docker compose logs futuopend
```

**Can't connect remotely?**
- Set `<ip>0.0.0.0</ip>`
- Check firewall rules
- Verify `<rsa_private_key>` is set

**Build fails?**
```bash
# Manual tarball download
wget -O Futu_OpenD_10.5.6508_Ubuntu18.04.tar.gz \
  https://softwaredownload.futunn.com/Futu_OpenD_10.5.6508_Ubuntu18.04.tar.gz
```

---

## Disclaimer

**Unofficial community packaging.** Not affiliated with Futu Securities. Trading involves risk — use at your own risk.

---

*See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute. Full docs in [docs/](docs/).*
