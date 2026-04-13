# FutuOpenD Docker

> **FutuOpenD** is the gateway daemon for the [Futu API](https://openapi.futunn.com/futu-api-doc/) (富途证券). This project packages it in a Docker container so you can run it headless on any Linux server — a cloud VM, a NAS, a Raspberry Pi, whatever you've got.

[![FutuOpenD](https://img.shields.io/badge/FutuOpenD-v10.2.6208-blue)](https://openapi.futunn.com/futu-api-doc/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/shing1211/futuopend)](https://hub.docker.com/r/shing1211/futuopend)

---

## ⚠️ Disclaimer

**This is an unofficial community Docker packaging.** It is _not_ affiliated with, endorsed by, or supported by Futu Securities (富途证券) / Futu Network Technology Limited or moomoo. All trademarks belong to their respective owners.

Trading financial instruments involves **substantial risk of loss** and is not suitable for all investors. Use at your own risk. This project makes no guarantees about accuracy, reliability, or completeness.

---

## Table of Contents

- [Why This Exists](#why-this-exists)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Environment Variables](#environment-variables)
- [Building from Source](#building-from-source)
- [Directory Layout](#directory-layout)
- [Troubleshooting](#troubleshooting)
- [References](#references)
- [Contributing](#contributing)
- [License](#license)

---

## Why This Exists

Futu Securities provides a solid trading API, but running FutuOpenD — the local gateway daemon — on a headless Linux server can be fiddly. The official installer is GUI-oriented, and managing dependencies across Ubuntu and CentOS variants is tedious.

This project does one thing: **it wraps FutuOpenD in a Docker image** so you can `docker run` it anywhere in under five minutes. That's it. No magic, no extra daemons. Just the official FutuOpenD binary, containerized cleanly.

---

## Features

- **Multi-market trading** — Equities, ETFs, options, futures, and more across HK, US, A-Share, Singapore, Japan, and Australia markets
- **Real-time market data** — Live quotes, order book, tick data, and historical candles via WebSocket push
- **Simulated & live trading** — Same API for paper trading and production accounts
- **Multi-language SDKs** — Official bindings for Python, Java, C#, C++, and JavaScript
- **Cloud-ready** — Runs on Ubuntu 18.04, CentOS 7, or any Docker host (cloud VMs, NAS devices, you name it)
- **TLS/SSL support** — Encrypt the WebSocket connection for remote deployments
- **Two base variants** — Ubuntu 18.04 and CentOS 7 images, built from the same Dockerfile

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Your App / SDK                          │
│        Python / Java / C# / C++ / JavaScript               │
└──────────────────────┬──────────────────────────────────────┘
                       │  Futu OpenAPI (TCP / WebSocket)
┌──────────────────────▼──────────────────────────────────────┐
│                   FutuOpenD Gateway                         │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │  TCP Server │  │  WebSocket   │  │  RSA Decryption   │  │
│  │   :11111    │  │   (TLS)      │  │  (Trading Auth)   │  │
│  └─────────────┘  └──────────────┘  └───────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │  HTTPS / WSS
┌──────────────────────▼──────────────────────────────────────┐
│                   Futu Servers                              │
│              (market data & trading backend)                │
└─────────────────────────────────────────────────────────────┘
```

FutuOpenD acts as the local bridge between your application and Futu's backend. It handles protocol translation, authentication, and data push — your SDK just talks TCP or WebSocket to `localhost:11111` (or whatever host you're running it on).

This Docker image packages the FutuOpenD binary so you can run it headless on a Linux server. The container exposes:

- **Port `11111`** — TCP API
- **Port `11112`** — WebSocket API

---

## Prerequisites

- **Docker** 20.10+ and **Docker Compose** v2
- A **Futu account** (牛牛号 / Futu account ID)
- An **RSA private key** — required for trading; strongly recommended for remote quote access too
- Outbound network access to `softwaredownload.futunn.com` and Futu's backend servers

---

## Quick Start

### 1. Grab the repo

```bash
git clone https://github.com/shing1211/futuopend.git
cd futuopend
```

### 2. Prepare your secrets

You'll need two files:

1. **RSA private key** — from your [Futu OpenAPI dashboard](https://www.futunn.com/en/OpenAPI), generate a key pair and download the private key
2. **FutuOpenD.xml** — your gateway configuration

```bash
# Create a safe home for secrets (never commit this!)
mkdir -p /opt/futuopend/secrets

# Place your RSA private key
cp ~/Downloads/private-key.txt /opt/futuopend/secrets/rsa_key.txt
chmod 600 /opt/futuopend/secrets/rsa_key.txt
```

The repo ships a **template** at `FutuOpenD.xml.template` with env-var substitution baked in. Copy it and fill in your values:

```bash
cp FutuOpenD.xml.template /opt/futuopend/secrets/FutuOpenD.xml
```

Open it in your editor and set these environment variables (or hardcode values directly):

```bash
# Set these before starting the container
export FUTU_ACCOUNT_ID=your_futu_account_id
export FUTU_PASSWORD_MD5=$(echo -n "your_password" | md5sum | cut -d' ' -f1)
export RSA_KEY_PATH=/opt/futuopend/secrets/rsa_key.txt
export FUTU_OPEND_IP=0.0.0.0       # use 127.0.0.1 for local-only
export FUTU_WS_IP=0.0.0.0          # use 127.0.0.1 for local-only
export FUTU_LOG_LEVEL=info          # debug | info | warn | error
export FUTU_LANGUAGE=en            # en | zh-CN | zh-HK
```

Pass them into Docker Compose:

```bash
docker compose up -d \
  -e FUTU_ACCOUNT_ID=your_account \
  -e FUTU_PASSWORD_MD5=your_md5 \
  -e RSA_KEY_PATH=/run/secrets/rsa_key.txt
```

Or wire them permanently in `docker-compose.override.yaml` (see [Configuration](#configuration)).

> **Security tip:** `FutuOpenD.xml` contains your account credentials. Keep it somewhere safe, and never commit it to version control. The template itself is safe to commit — it has no real secrets in it.

### 3. Configure environment

```bash
cp .env.example .env
# Open .env in your editor and fill in the paths
```

Or export directly:

```bash
export RSA_FILE_LOCAL_PATH=/opt/futuopend/secrets/rsa_key.txt
export FUTU_OPEND_XML_LOCAL_PATH=/opt/futuopend/secrets/FutuOpenD.xml
export RSA_FILE_PATH=/run/secrets/rsa_key.txt
export FUTU_OPEND_XML_PATH=/run/secrets/FutuOpenD.xml
```

### 4. Fire it up

```bash
docker compose up -d
docker compose logs -f futuopend
```

### 5. Verify

```bash
# Check the API is responding
curl -s http://localhost:11111/version

# Check container health
docker compose ps
```

If you see a version string, you're in business. Point your SDK at `ws://your-host:11111` (or `ws://your-host:11112` for WebSocket) and start trading.

---

## Configuration

FutuOpenD is configured entirely via `FutuOpenD.xml`. The repo ships a **ready-to-use template** at [`FutuOpenD.xml.template`](FutuOpenD.xml.template) — copy it, drop in your credentials, and go.

All settings in the template support `${ENV_VAR}` substitution, so you can keep your actual secrets out of the file and pass them in via Docker environment variables.

Here's a quick reference for the most-used settings — the [full reference](docs/configuration.md) has everything.

| Setting | Default | Description |
|---------|---------|-------------|
| `IP` | `127.0.0.1` | TCP API bind address. Use `0.0.0.0` for remote access. |
| `Port` | `11111` | TCP API port. |
| `WSIP` | `127.0.0.1` | WebSocket API bind address. |
| `WSPort` | `11112` | WebSocket API port. |
| `LogLevel` | `info` | Verbosity: `debug`, `info`, `warn`, `error`, `fatal`, `off`. |
| `Language` | `zh-CN` | Language: `zh-CN`, `zh-HK`, `en`. |
| `PrivateKey` | _(none)_ | Absolute path to your RSA private key file. |
| `WSCert` | _(none)_ | SSL certificate for encrypted WebSocket. |
| `WSKey` | _(none)_ | SSL private key (must have no password). |
| `WSLoginExpire` | `259200` | WebSocket session expiry in seconds (default: 72 hours). |
| `DataPushFreq` | _(none)_ | Max subscription push frequency in milliseconds. |
| `TelnetIP` | _(none)_ | Telnet debug interface bind address. |
| `TelnetPort` | _(none)_ | Telnet debug interface port. |

> **Security:** If you expose the TCP or WebSocket port beyond `localhost`, you **must** configure an RSA private key. Without it, trading API calls will be rejected.

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `RSA_FILE_LOCAL_PATH` | Absolute path on the **host** to your RSA private key file. |
| `FUTU_OPEND_XML_LOCAL_PATH` | Absolute path on the **host** to `FutuOpenD.xml`. |
| `TZ` | Container timezone. Defaults to `Asia/Hong_Kong`. |

---

## Building from Source

### Pull the pre-built image (recommended)

```bash
docker pull shing1211/futuopend:latest
```

### Build locally

The `dockerbuild.sh` helper script handles the `--target` and tagging:

```bash
# Ubuntu 18.04 variant
./dockerbuild.sh ubuntu 10.2.6208

# CentOS 7 variant
./dockerbuild.sh centos 10.2.6208
```

Or build manually:

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
├── Dockerfile                  # Multi-stage build: Ubuntu & CentOS variants
├── docker-compose.yaml         # Container orchestration with Docker Secrets
├── FutuOpenD.xml.template     # Ready-to-use config template (env-var aware)
├── dockerbuild.sh              # CI/CD build & push helper
├── .env.example                # Environment variable template
├── LICENSE                     # Apache 2.0
├── README.md                   # (you're here)
├── docs/
│   ├── configuration.md        # Full FutuOpenD.xml reference
│   └── security.md             # Security hardening tips
└── .gitignore
```

---

## Troubleshooting

### Container exits immediately

```bash
docker compose logs futuopend
```

Common culprits:

- **Missing secrets** — RSA key or `FutuOpenD.xml` not mounted, or paths don't match inside the container
- **Port conflict** — Something else is already using port `11111` on the host

### Can't connect from a remote SDK

1. Verify the container is binding to `0.0.0.0` (not `127.0.0.1`) in `FutuOpenD.xml`
2. Make sure your firewall allows inbound TCP on `11111` (and `11112` if using WebSocket)
3. Check that your Futu account has API access enabled

### Trading API returns permission error

- The `PrivateKey` path in `FutuOpenD.xml` must point to a **valid RSA key** registered with your Futu account
- Double-check the key file is mounted correctly inside the container

### Build fails downloading the tarball

Futu's download server can be flaky. Manually download the tarball and drop it in the build context:

```bash
wget -O Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz \
  https://softwaredownload.futunn.com/Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz
```

Then reference it in your Dockerfile:

```dockerfile
COPY Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz /tmp/
```

---

## References

- [Futu OpenAPI Documentation](https://openapi.futunn.com/futu-api-doc/)
- [Futu OpenAPI (English)](https://openapi.futunn.com/futu-api-doc/en/)
- [FutuOpenD Command-Line Reference](https://openapi.futunn.com/futu-api-doc/en/opend/opend-cmd.html)
- [Python SDK (futuquant)](https://github.com/Futuromy/FutuQuant)
- [Official Download Page](https://www.futunn.com/download/fetch-lasted-link?name=opend-ubuntu)
- [Docker Hub — shing1211/futuopend](https://hub.docker.com/r/shing1211/futuopend)

---

## Contributing

Found a bug? Have an idea? Contributions are welcome — please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting PRs.

---

## License

Copyright 2024 [Terence Chan](https://github.com/shing1211)

Licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for details.
