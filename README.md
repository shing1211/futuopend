# FutuOpenD Docker

> **FutuOpenD** is the local gateway daemon for the [Futu API](https://openapi.futunn.com/futu-api-doc/) (富途证券), enabling programmatic trading and real-time market data for Hong Kong, US, A-Share, Singapore, Japan, and Australia markets. This project packages FutuOpenD into a Docker container for easy deployment on Linux servers or cloud platforms.

[![Docker Image Version](https://img.shields.io/badge/FutuOpenD-v10.2.6208-blue)](https://openapi.futunn.com/futu-api-doc/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/shing1211/futuopend)](https://hub.docker.com/r/shing1211/futuopend)

---

## Table of Contents

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

## Features

- **Multi-market trading** — Equities, ETFs, options, futures, and more across HK, US, SG, JP, AU, and A-Share markets
- **Real-time market data** — Live quotes, order book, tick data, and historical candles via WebSocket push
- **Simulated & live trading** — Same API for paper trading and production accounts
- **Multi-language SDKs** — Official bindings for Python, Java, C#, C++, and JavaScript
- **Cloud-ready** — Runs on Ubuntu 18.04, CentOS 7, or any Docker host (including cloud VMs and NAS devices)
- **TLS/SSL support** — Encrypts the WebSocket connection for remote deployments

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Your App / SDK                        │
│  (Python / Java / C# / C++ / JavaScript / Proto)           │
└─────────────────────┬───────────────────────────────────────┘
                      │  Futu OpenAPI Protocol (TCP / WS)
┌─────────────────────▼───────────────────────────────────────┐
│                   FutuOpenD Gateway                          │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │  TCP Server │  │ WebSocket    │  │  RSA Decryption   │  │
│  │  :11111     │  │  (TLS)       │  │  (Trading Auth)   │  │
│  └─────────────┘  └──────────────┘  └───────────────────┘  │
└─────────────────────┬───────────────────────────────────────┘
                      │  HTTPS / WSS
┌─────────────────────▼───────────────────────────────────────┐
│                    Futu Servers                              │
│              (行情 & 交易 backend)                          │
└─────────────────────────────────────────────────────────────┘
```

**This Docker image** packages the FutuOpenD binary so you can run it headless on a Linux server. The container exposes port `11111` (TCP) and optionally `11112` (WebSocket) for SDK clients to connect.

---

## Prerequisites

- **Docker** 20.10+ and **Docker Compose** v2
- A **Futu account** (牛牛号 / Futu account ID)
- An **RSA private key** (required for trading; optional but recommended for quotes on non-localhost)
- Network access to `softwaredownload.futunn.com` (for the binary) and Futu's backend

---

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/your-user/futuopend.git
cd futuopend
```

### 2. Prepare secrets

You need two secrets — an RSA private key and the `FutuOpenD.xml` configuration file.

#### Generate RSA key pair

From your [Futu OpenAPI dashboard](https://www.futunn.com/en/OpenAPI), generate a key pair and download the private key file:

```bash
# Place it somewhere safe, e.g.:
mkdir -p /opt/futuopend/secrets
cp ~/Downloads/private-key.txt /opt/futuopend/secrets/rsa_key.txt
chmod 600 /opt/futuopend/secrets/rsa_key.txt
```

#### Create FutuOpenD.xml

Create `FutuOpenD.xml` with your account and connection settings. A minimal example:

```xml
<?xml version="1.0" encoding="utf-8"?>
<FutuOpenD>
  <AccList>
    <Account>
      <AccID>your_futu_account_id</AccID>
      <PwdMD5>your_md5_password</PwdMD5>
      <PrivateKey>${RSA_KEY_PATH}</PrivateKey>
    </Account>
  </AccList>
  <Config>
    <IP>0.0.0.0</IP>
    <Port>11111</Port>
    <WSIP>0.0.0.0</WSIP>
    <WSPort>11112</WSPort>
    <LogLevel>info</LogLevel>
    <Language>zh-CN</Language>
  </Config>
</FutuOpenD>
```

Place it alongside the RSA key:

```bash
cp FutuOpenD.xml /opt/futuopend/secrets/FutuOpenD.xml
```

> **Security note:** The XML file contains your account credentials. Never commit it to version control.

### 3. Configure environment

Copy and edit the environment file:

```bash
cp .env.example .env
# Edit .env with your paths
```

Or set variables directly:

```bash
export RSA_FILE_LOCAL_PATH=/opt/futuopend/secrets/rsa_key.txt
export FUTU_OPEND_XML_LOCAL_PATH=/opt/futuopend/secrets/FutuOpenD.xml
export RSA_FILE_PATH=/run/secrets/rsa_key.txt
export FUTU_OPEND_XML_PATH=/run/secrets/FutuOpenD.xml
```

### 4. Start the container

```bash
docker compose up -d
docker compose logs -f futuopend
```

### 5. Verify it is running

```bash
# Check the API is listening
curl -s http://localhost:11111/version

# Check container health
docker compose ps
```

You should see FutuOpenD start and listen on port `11111`. Connect your SDK of choice to `ws://your-host:11111`.

---

## Configuration

FutuOpenD is configured via the `FutuOpenD.xml` file. The following table documents the most important settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `IP` | `127.0.0.1` | TCP API listening address. Use `0.0.0.0` for remote access. |
| `Port` | `11111` | TCP API listening port. |
| `WSIP` | `127.0.0.1` | WebSocket API listening address. |
| `WSPort` | `11112` | WebSocket API listening port. |
| `LogLevel` | `info` | Log verbosity: `debug`, `info`, `warn`, `error`, `fatal`, `off`. |
| `Language` | `zh-CN` | UI/API language: `zh-CN`, `zh-HK`, `en`. |
| `PrivateKey` | _(none)_ | Absolute path to the RSA private key file for trading authentication. |
| `WSCert` | _(none)_ | Path to the SSL certificate for encrypted WebSocket. |
| `WSKey` | _(none)_ | Path to the SSL private key. The key must have no password. |
| `WSKey` | _(none)_ | Path to the SSL private key. |
| `WSLoginExpire` | `259200` | WebSocket login session expiry in seconds. |
| `DataPushFreq` | _(none)_ | Subscription push frequency limit in milliseconds. |
| `TelnetIP` | _(none)_ | Telnet command interface IP. |
| `TelnetPort` | _(none)_ | Telnet command interface port. |

> **Security:** If you expose the TCP or WebSocket port to a non-local network, you **must** configure an RSA private key. Without it, trading APIs will be rejected.

See the [official documentation](https://openapi.futunn.com/futu-api-doc/en/quick/opend-base.html) for the full reference.

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `RSA_FILE_LOCAL_PATH` | Absolute path on the **host** to the RSA private key file. Used by Docker Secrets. |
| `FUTU_OPEND_XML_LOCAL_PATH` | Absolute path on the **host** to `FutuOpenD.xml`. Used by Docker Secrets. |
| `TZ` | Container timezone. Defaults to `Asia/Hong_Kong`. |

---

## Building from Source

### Pull pre-built image (recommended)

```bash
docker pull shing1211/futuopend:latest
```

### Build locally

Use the `dockerbuild.sh` helper script — it handles the `--target` and tagging automatically:

```bash
# Ubuntu (default)
./dockerbuild.sh ubuntu 10.2.6208

# CentOS 7
./dockerbuild.sh centos 10.2.6208
```

Or build manually with Docker's `--target` flag:

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

#### Multi-platform build

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
├── Dockerfile           # Multi-stage build for Ubuntu & CentOS
├── docker-compose.yaml  # Container orchestration
├── dockerbuild.sh       # CI/CD build & push script
├── .env.example         # Environment variable template
├── LICENSE              # MIT License
├── README.md             # This file
├── docs/
│   ├── configuration.md  # Detailed FutuOpenD.xml reference
│   └── security.md       # Security best practices
└── .gitignore
```

---

## Troubleshooting

### Container exits immediately

Check the logs for error details:

```bash
docker compose logs futuopend
```

Common causes:
- **Missing secrets** — The RSA key or `FutuOpenD.xml` files are not mounted or have wrong paths.
- **Port conflict** — Port `11111` is already in use on the host.

### Cannot connect from remote SDK

1. Verify the container is listening on `0.0.0.0` (not `127.0.0.1`) in `FutuOpenD.xml`.
2. Ensure your firewall allows inbound TCP on port `11111`.
3. Check that your Futu account has API access enabled.

### Trading API returns permission error

- Ensure `PrivateKey` in `FutuOpenD.xml` points to a **valid RSA key** registered with your account.
- Verify the key file is mounted correctly inside the container.

### Build fails downloading the tarball

Futu's download server may be temporarily unreachable. Wait and retry, or manually download the tarball and place it in the build context:

```bash
wget -O Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz \
  https://softwaredownload.futunn.com/Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz
```

Then add it to the Dockerfile:

```dockerfile
COPY Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz /tmp/
RUN tar -xzf /tmp/Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz ...
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

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

> **Disclaimer:** This project is an **unofficial community Docker packaging** of FutuOpenD. It is **not affiliated with, endorsed by, or supported by** Futu Securities (富途证券) / Futu Network Technology Limited or moomoo. All trademarks belong to their respective owners. Use at your own risk. **Trading financial instruments involves substantial risk of loss and is not suitable for all investors.** Past performance is not indicative of future results. This project makes no guarantees about the accuracy, reliability, or completeness of any information provided.
