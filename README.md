# FutuOpenD Docker

> Wrap the official FutuOpenD gateway daemon in a container. Run it on a cloud VM, a NAS, a Raspberry Pi — anywhere Docker lives.

[![FutuOpenD v10.2.6208](https://img.shields.io/badge/FutuOpenD-v10.2.6208-blue)](https://openapi.futunn.com/futu-api-doc/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/shing1211/futuopend)](https://hub.docker.com/r/shing1211/futuopend)

---

## ⚠️ Disclaimer

**This is an unofficial community Docker packaging.** It is _not_ affiliated with, endorsed by, or supported by Futu Securities (富途证券) / Futu Network Technology Limited or moomoo. All trademarks belong to their respective owners.

Trading financial instruments involves **substantial risk of loss** and is not suitable for all investors. Use at your own risk.

---

## Why This Exists

You want to trade via Futu's API from a headless Linux box — a cloud VM, your NAS, whatever. The catch? FutuOpenD, the local gateway daemon, is built for GUI desktops. Dependency juggling across Ubuntu and CentOS is tedious, and the official installer expects a desktop session.

This project sidesteps all of that. One `docker run`, and FutuOpenD is up on port `11111` — no X11, no system packages, no headaches. That's it.

---

## Features

- **Multi-market** — Equities, ETFs, options, futures across HK, US, A-Share, Singapore, Japan, Australia
- **Real-time data** — Live quotes, order book, ticks, candles via WebSocket push
- **Paper or live** — Same API for test accounts and production
- **TCP + WebSocket** — Choose your protocol; SDKs available in Python, Java, C#, C++, JavaScript
- **TLS/SSL-ready** — Encrypt the WebSocket link for remote deployments
- **Two OS variants** — Ubuntu 18.04 and CentOS 7, from the same Dockerfile
- **Docker Secrets** — Clean credential management out of the box

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Your App / SDK                            │
│            Python / Java / C# / C++ / JavaScript             │
└──────────────────────────┬───────────────────────────────────┘
                           │  Futu OpenAPI (TCP / WebSocket)
┌──────────────────────────▼───────────────────────────────────┐
│                      FutuOpenD Gateway                        │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐   │
│  │  TCP Server │  │  WebSocket   │  │  RSA Decryption   │   │
│  │   :11111    │  │   (TLS)      │  │  (Trading Auth)   │   │
│  │             │  │   :11112     │  │                   │   │
│  └─────────────┘  └──────────────┘  └───────────────────────┘  │
└──────────────────────────┬───────────────────────────────────┘
                           │  HTTPS / WSS
┌──────────────────────────▼───────────────────────────────────┐
│                    Futu Servers                               │
│               (market data & trading backend)                 │
└──────────────────────────────────────────────────────────────┘
```

FutuOpenD bridges your app and Futu's backend — protocol translation, auth, data push. Your SDK just connects to `localhost:11111` (or `ws://host:11112` for WebSocket). This Docker image wraps the official FutuOpenD binary so it runs headless on any Linux server.

**Ports exposed:**

| Port | Protocol | Use for |
|------|----------|---------|
| `11111` | TCP | Main API (all SDKs) |
| `11112` | WebSocket | Real-time push, web clients |
| `22222` | Telnet | Debug console, phone verification |

---

## Prerequisites

- **Docker** 20.10+ and **Docker Compose** v2
- A **Futu account** (牛牛号 / account ID — found in the app under Settings)
- An **RSA private key** — required for trading; strongly recommended for remote quotes too. Generate one at the [Futu OpenAPI dashboard](https://www.futunn.com/en/OpenAPI).
- Outbound access to `softwaredownload.futunn.com` and Futu's backend

---

## Quick Start

Zero to running in five minutes. Let's go.

### 1. Grab the repo

```bash
git clone https://github.com/shing1211/futuopend.git
cd futuopend
```

### 2. Prepare your secrets directory

Create a safe home for credentials — **never put this under version control**:

```bash
mkdir -p /opt/futuopend/secrets
chmod 700 /opt/futuopend/secrets
```

Drop your RSA private key in there:

```bash
cp ~/Downloads/private-key.txt /opt/futuopend/secrets/rsa_key.txt
chmod 600 /opt/futuopend/secrets/rsa_key.txt
```

### 3. Create your config

Copy the template — it has env-var substitution baked in so you don't hardcode secrets:

```bash
cp FutuOpenD.xml.template /opt/futuopend/secrets/FutuOpenD.xml
```

Edit it (or better yet, pass credentials via environment variables — see below).

### 4. Set your environment

The easiest route: export a few env vars before starting the container.

```bash
export FUTU_ACCOUNT=your_futu_account_id
export FUTU_PWD_MD5=$(echo -n "your_password" | md5sum | cut -d' ' -f1)
export FUTU_RSA_KEY=/run/secrets/rsa_key.txt
export FUTU_IP=0.0.0.0       # use 127.0.0.1 for local-only access
export FUTU_LOG_LEVEL=info   # debug | info | warning | error | fatal
export FUTU_LANG=en          # en | chs
```

Or copy the example `.env` file and fill it in:

```bash
cp .env.example .env
# Edit .env with your values
```

### 5. Fire it up

```bash
docker compose up -d
docker compose logs -f futuopend
```

### 6. Verify

```bash
# Check the TCP API is up
curl -s http://localhost:11111/version

# Check container status
docker compose ps
```

If you see a version string — you're in. Point your SDK at `ws://your-host:11111` (or `11112` for WebSocket) and start trading.

---

## Configuration

All settings live in `FutuOpenD.xml`. The repo ships a ready-to-use template at [`FutuOpenD.xml.template`](FutuOpenD.xml.template) — copy it, fill in your values, go.

Every setting in the template supports `${ENV_VAR}` substitution. FutuOpenD resolves them at startup, so your secrets never live in the config file permanently.

> **Heads up:** FutuOpenD uses **lowercase XML tag names** — `<ip>`, `<api_port>`, `<login_account>`, not the PascalCase you might expect. The [full reference](docs/configuration.md) covers every setting.

### Quick reference

| Setting | Default | When to change it |
|---------|---------|-------------------|
| `ip` | `127.0.0.1` | Set `0.0.0.0` for remote access |
| `api_port` | `11111` | Only if port 11111 is taken |
| `websocket_ip` | _(none)_ | Set `0.0.0.0` to enable WebSocket |
| `websocket_port` | _(none)_ | Set a port to enable WebSocket |
| `login_account` | _(required)_ | Your Futu account ID, phone, or email |
| `login_pwd_md5` | _(required)_ | MD5 hex of your password (32 chars) |
| `rsa_private_key` | _(none)_ | Required for trading over the network |
| `log_level` | `info` | `debug` for troubleshooting, `error` for quiet |
| `lang` | `en` | `en` or `chs` |
| `websocket_cert` / `websocket_private_key` | _(none)_ | Set both to enable WSS |
| `telnet_ip` / `telnet_port` | _(none)_ | Set both to enable the debug console |
| `pdt_protection` | `1` | PDT protection for US accounts |
| `dtcall_confirmation` | `1` | DT buying power guard for US accounts |

> **Remote access + trading?** You **must** set `rsa_private_key`. Without it, trading calls get rejected. Quotes work fine without it.

For the full deep-dive, see [docs/configuration.md](docs/configuration.md).

---

## Environment Variables

These map directly into `FutuOpenD.xml` via `${VAR}` substitution.

| Variable | Maps to | Notes |
|----------|---------|-------|
| `FUTU_ACCOUNT` | `<login_account>` | Your account ID, phone, or email |
| `FUTU_PWD_MD5` | `<login_pwd_md5>` | 32-char MD5 hex of your password |
| `FUTU_RSA_KEY` | `<rsa_private_key>` | Path inside the container, e.g. `/run/secrets/rsa_key.txt` |
| `FUTU_IP` | `<ip>` | Defaults to `127.0.0.1` |
| `FUTU_API_PORT` | `<api_port>` | Defaults to `11111` |
| `FUTU_WS_PORT` | `<websocket_port>` | Leave unset to disable WebSocket |
| `FUTU_LOG_LEVEL` | `<log_level>` | Defaults to `info` |
| `FUTU_LANG` | `<lang>` | Defaults to `en` |
| `RSA_FILE_LOCAL_PATH` | — | Host path to your RSA key file |
| `FUTU_OPEND_XML_LOCAL_PATH` | — | Host path to your FutuOpenD.xml |
| `TZ` | — | Container timezone, defaults to `Asia/Hong_Kong` |

---

## Building from Source

### Pull the image (recommended)

```bash
docker pull shing1211/futuopend:latest
```

### Build with the helper script

`dockerbuild.sh` handles builds and pushes for you:

```bash
# Build & push both Ubuntu + CentOS variants
./dockerbuild.sh

# Ubuntu only
./dockerbuild.sh ubuntu

# CentOS only
./dockerbuild.sh centos

# Override the FutuOpenD version
./dockerbuild.sh all 10.2.6208
```

**Docker Hub tags:**

| Tag | Description |
|-----|-------------|
| `:latest` | Ubuntu variant, latest build |
| `:ubuntu` | Ubuntu variant |
| `:centos` | CentOS 7 variant |
| `:10.2.6208-ubuntu` | Ubuntu, versioned |
| `:10.2.6208-centos` | CentOS 7, versioned |

### Build manually

```bash
# Ubuntu variant
docker build \
  --target final-ubuntu \
  --build-arg FUTU_OPEND_VER=10.2.6208 \
  --build-arg BASE_IMG=ubuntu \
  -t futuopend:10.2.6208-ubuntu .

# CentOS 7 variant
docker build \
  --target final-centos \
  --build-arg FUTU_OPEND_VER=10.2.6208 \
  --build-arg BASE_IMG=centos \
  -t futuopend:10.2.6208-centos .
```

### Multi-platform build (amd64 + arm64)

```bash
docker buildx create --use
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --target final-ubuntu \
  --build-arg FUTU_OPEND_VER=10.2.6208 \
  --build-arg BASE_IMG=ubuntu \
  -t shing1211/futuopend:10.2.6208-ubuntu \
  --push .
```

---

## Directory Layout

```
futuopend/
├── Dockerfile                  # Multi-stage: Ubuntu & CentOS in one file
├── docker-compose.yaml         # Container orchestration with Docker Secrets
├── FutuOpenD.xml.template     # Config template with ${ENV_VAR} substitution
├── dockerbuild.sh              # Build & push helper
├── .env.example                # Environment variable template
├── LICENSE                     # Apache 2.0
├── README.md                   # (you're here)
├── docs/
│   ├── configuration.md        # Full FutuOpenD.xml reference
│   └── security.md             # Security hardening guide
└── .gitignore
```

---

## Troubleshooting

### Container exits immediately

```bash
docker compose logs futuopend
```

Most common causes:
- **Missing secrets** — RSA key or `FutuOpenD.xml` not mounted, or path inside container doesn't match
- **Port conflict** — Something else already using `11111` on the host

### Stuck on "Waiting for phone verify code"

Normal for first-time logins or new devices. FutuOpenD needs an SMS code relayed via Telnet. Full walkthrough is in [docs/configuration.md#first-time-login-phone-verification](docs/configuration.md#first-time-login-phone-verification-in-docker).

### Can't connect from a remote SDK

1. Is `FutuOpenD.xml` binding to `0.0.0.0`? (Not `127.0.0.1`.)
2. Is your firewall letting through TCP `11111` (and `11112` if using WebSocket)?
3. Does your Futu account have API access enabled?

### Trading API returns a permission error

The `rsa_private_key` path in `FutuOpenD.xml` must point to a **valid key registered with your account**. Double-check the key file is correctly mounted inside the container.

### Tarball download fails during build

Futu's download server can be flaky. Grab the tarball manually:

```bash
wget -O Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz \
  https://softwaredownload.futunn.com/Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz
```

Drop it in the build context and reference it in the Dockerfile:

```dockerfile
COPY Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz /tmp/
```

---

## References

- [Futu OpenAPI Documentation](https://openapi.futunn.com/futu-api-doc/)
- [Futu OpenAPI (English)](https://openapi.futunn.com/futu-api-doc/en/)
- [FutuOpenD Command-Line Reference](https://openapi.futunn.com/futu-api-doc/en/opend/opend-cmd.html)
- [Python SDK (futuquant)](https://github.com/Futuromy/FutuQuant)
- [Official FutuOpenD Download](https://www.futunn.com/download/fetch-lasted-link?name=opend-ubuntu)
- [Docker Hub — shing1211/futuopend](https://hub.docker.com/r/shing1211/futuopend)

---

## Contributing

Bugs, ideas, docs fixes — all welcome. Check out [CONTRIBUTING.md](CONTRIBUTING.md) before opening a PR.

---

## License

Copyright 2024 [Terence Chan](https://github.com/shing1211). Licensed under **Apache 2.0** — see [LICENSE](LICENSE).

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
