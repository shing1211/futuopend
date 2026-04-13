# FutuOpenD Docker

> Wrap the official FutuOpenD gateway daemon in a container. Run it on a cloud VM, a NAS, a Raspberry Pi — anywhere Docker lives.

[![FutuOpenD v10.2.6208](https://img.shields.io/badge/FutuOpenD-v10.2.6208-blue)](https://openapi.futunn.com/futu-api-doc/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/shing1211/futuopend)](https://hub.docker.com/r/shing1211/futuopend)

---

## Disclaimer

**This is an unofficial community Docker packaging.** It is _not_ affiliated with, endorsed by, or supported by Futu Securities (富途证券) / Futu Network Technology Limited or moomoo. All trademarks belong to their respective owners.

Trading financial instruments involves **substantial risk of loss** and is not suitable for all investors. Use at your own risk.

---

## Why This Exists

You want to trade via Futu's API from a headless Linux box. FutuOpenD — the local gateway daemon — is built for GUI desktops, and the official installer assumes a desktop session. Juggling dependencies across Ubuntu and CentOS variants is a chore you shouldn't have to do.

One `docker run`, and you're live on port `11111`. No X11, no dependency hunting, no guessing. That's the whole point of this project.

---

## Features at a Glance

- **Multi-market** — Equities, ETFs, options, futures across HK, US, A-Share, Singapore, Japan, Australia
- **Real-time data** — Live quotes, order book, ticks, candles via WebSocket push
- **Paper or live** — Same API for test accounts and production
- **TCP + WebSocket** — Choose your protocol; SDKs in Python, Java, C#, C++, JavaScript
- **TLS/SSL-ready** — Encrypt the WebSocket link for remote deployments
- **Two OS variants** — Ubuntu 24.04 LTS and Rocky Linux 9, from the same Dockerfile
- **Docker Secrets** — Clean credential management out of the box

---

## How It All Fits Together

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
│  └─────────────┘  └──────────────┘  └───────────────────┘   │
└──────────────────────────┬───────────────────────────────────┘
                            │  HTTPS / WSS
┌──────────────────────────▼───────────────────────────────────┐
│                    Futu Servers                               │
│               (market data & trading backend)                 │
└──────────────────────────────────────────────────────────────┘
```

Your SDK connects to `localhost:11111` (TCP) or `ws://host:11112` (WebSocket). FutuOpenD handles protocol translation, auth, and data push — your app just talks to the local gateway.

| Port | Protocol | What it's for |
|------|----------|---------------|
| `11111` | TCP | Main API — all SDKs use this |
| `11112` | WebSocket | Real-time push, web frontends |
| `22222` | Telnet | Debug console, phone verification |

---

## Prerequisites

- Docker 20.10+ and Docker Compose v2
- A Futu account (find your 牛牛号 in the app under Settings)
- An RSA private key — generate one at the [Futu OpenAPI dashboard](https://www.futunn.com/en/OpenAPI). Required for trading; strongly recommended for remote quotes too.
- Outbound HTTPS access to `softwaredownload.futunn.com` and Futu's backend

---

## Quick Start

Zero to live market data in under 5 minutes. Uses the pre-built image from Docker Hub — no building, no compiling.

**What you get:** Live quote data from Futu's servers. No RSA key needed. Perfect for local development and price monitoring.

### Step 1 — Download the repo

```bash
git clone https://github.com/shing1211/futuopend.git
cd futuopend
```

### Step 2 — Create your config file

```bash
cp FutuOpenD.xml.template FutuOpenD.xml
```

Open `FutuOpenD.xml` in a text editor. Fill in these two lines:

```xml
<login_account>YOUR_FUTU_ACCOUNT_ID</login_account>
<login_pwd_md5>YOUR_PASSWORD_AS_MD5_HASH</login_pwd_md5>
```

**How to generate your MD5 hash** — run this in your terminal:

```bash
# Linux
echo -n "your_password" | md5sum | cut -d' ' -f1

# macOS
echo -n "your_password" | md5 -r
```

The `-n` matters — it stops your shell from adding a newline before hashing. Copy the 32-character output into `<login_pwd_md5>`.

### Step 3 — Pull the image and start

```bash
docker compose -f docker-compose.simple.yaml up -d
docker compose -f docker-compose.simple.yaml logs -f
```

### Step 4 — Wait for login

Watch the logs. Two things can happen:

**Option A — Login succeeds immediately:**

```
[INFO] Login succeeded. Account: 12345678
```

You're in. Skip to Step 5.

**Option B — Phone verification is triggered:**

```
[INFO] Waiting for phone verify code, please input by telnet...
```

This is normal on first login or a new IP. See [Phone Verification](#phone-verification) below to get past it.

### Step 5 — Verify it's running

Open a new terminal and run:

```bash
curl -s http://localhost:11111/version
```

You should see a version string. FutuOpenD is live — point your SDK at `localhost:11111` and start receiving market data.

To stop watching logs, press `Ctrl+C`.

---

## Build from Source

Build the image yourself instead of pulling from Docker Hub. Useful if you want to pin a specific version, audit the Dockerfile, or use a different base image.

### Prerequisites

- Docker 20.10+
- Docker Compose v2

### Build and run

```bash
# Build the Ubuntu variant
docker build \
  --target final-ubuntu \
  --build-arg FUTU_OPEND_VER=10.2.6208 \
  -t futuopend:ubuntu .

# Build the Rocky Linux 9 variant
docker build \
  --target final-rocky \
  --build-arg FUTU_OPEND_VER=10.2.6208 \
  -t futuopend:rocky .

# Run it
docker compose -f docker-compose.simple.yaml up -d
```

Or use the helper script — it builds both variants and pushes to Docker Hub in one shot:

```bash
./dockerbuild.sh              # build both ubuntu + centos
./dockerbuild.sh ubuntu       # ubuntu only
./dockerbuild.sh centos      # centos only
./dockerbuild.sh all 10.2.6208  # override version
```

### Multi-platform build (amd64 + arm64)

```bash
docker buildx create --use
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --target final-ubuntu \
  --build-arg FUTU_OPEND_VER=10.2.6208 \
  -t shing1211/futuopend:10.2.6208-ubuntu \
  --push .
```

### Docker Hub tags

| Tag | Description |
|-----|-------------|
| `:latest` | Ubuntu variant, latest build |
| `:ubuntu` | Ubuntu 24.04 LTS variant |
| `:rocky` | Rocky Linux 9 variant |
| `:centos` | Rocky Linux 9 variant (alias of `:rocky`) |
| `:10.2.6208-ubuntu` | Ubuntu, versioned |
| `:10.2.6208-rocky` | Rocky Linux 9, versioned |
| `:10.2.6208-centos` | Rocky Linux 9, versioned (alias of `:10.2.6208-rocky`) |

The quick-start path above gives you **quote-only access** — live market data, no trading. To submit orders or connect from another machine, you need two extra things: an RSA key and to bind to all network interfaces.

### Add an RSA private key

1. Go to the [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI) → **Manage Key**
2. Generate a new key pair and download the private key file
3. Copy it to your secrets directory:

```bash
mkdir -p /opt/futuopend/secrets
cp ~/Downloads/your-key-file.txt /opt/futuopend/secrets/rsa_key.txt
chmod 600 /opt/futuopend/secrets/rsa_key.txt
```

4. Uncomment and fill in the RSA key line in `FutuOpenD.xml`:

```xml
<rsa_private_key>/run/secrets/rsa_key.txt</rsa_private_key>
```

5. Change the bind address to accept connections from anywhere:

```xml
<ip>0.0.0.0</ip>
```

6. Restart:

```bash
docker compose -f docker-compose.simple.yaml down \
  && docker compose -f docker-compose.simple.yaml up -d
docker compose -f docker-compose.simple.yaml logs -f
```

> **What this enables:** Trading API calls, and connections from other machines on your network or the internet. Without this, trading calls are rejected and only local processes can connect.

For full security hardening (TLS, firewall, read-only filesystem), see [docs/security.md](docs/security.md).

---

## Phone Verification

First-time logins — or logins from a new IP — trigger an SMS verification code. FutuOpenD pauses and waits for you to type it in.

Look for this in the logs:

```
[INFO] Waiting for phone verify code, please input by telnet...
```

If you see it, here's what to do:

**1. Enable the Telnet port** in `docker-compose.yaml`:

```yaml
services:
  futuopend:
    ports:
      - "11111:11111"
      - "11112:11112"
      - "22222:22222"   # ← add this line
```

Then restart: `docker compose -f docker-compose.simple.yaml down && docker compose -f docker-compose.simple.yaml up -d`

**2. Submit your SMS code** from your host terminal:

```bash
echo "input_phone_verify_code -code=123456" | nc 127.0.0.1 22222
```

Replace `123456` with the actual code Futu texted you.

> **Note the space** — it's `input_phone_verify_code -code=` with a space before `-code=`. Without it, the command silently does nothing.

**3. Confirm success** in the logs:

```bash
docker compose logs futuopend | grep -i "login\|success"
```

Look for `Login succeeded`. You're verified and good to go.

---

## Configuration

All settings live in `FutuOpenD.xml`. Every tag supports `${ENV_VAR}` substitution — FutuOpenD resolves them at startup, so your config file stays clean.

> **Heads up:** FutuOpenD uses **lowercase** XML tag names. `<ip>`, `<api_port>`, `<login_account>` — not `<IP>` or `<ApiPort>`. Uppercase tags are silently ignored. The [full reference](docs/configuration.md) covers every setting.

### Quick reference

| Setting | Default | When to touch it |
|---------|---------|-----------------|
| `ip` | `127.0.0.1` | `0.0.0.0` for remote access |
| `api_port` | `11111` | Only if 11111 is taken |
| `websocket_port` | _(off)_ | Set a port to enable WebSocket |
| `login_account` | _(required)_ | Your account ID, phone, or email |
| `login_pwd_md5` | _(required)_ | 32-char MD5 hex of your password |
| `rsa_private_key` | _(none)_ | Required for trading over the network |
| `log_level` | `info` | `debug` to troubleshoot, `error` in production |
| `websocket_cert` / `websocket_private_key` | _(none)_ | Set both for WSS |
| `telnet_ip` / `telnet_port` | _(none)_ | Enable debug console |
| `pdt_protection` | `1` | PDT guard for US accounts |
| `dtcall_confirmation` | `1` | DT buying power guard for US accounts |

> **Trading over the network?** You **must** set `rsa_private_key`. Without it, trading calls get rejected. Quote-only access works fine without encryption.

For every single tag, see [docs/configuration.md](docs/configuration.md).

### Environment variable cheat sheet

| Variable | Maps to |
|----------|---------|
| `FUTU_ACCOUNT` | `<login_account>` |
| `FUTU_PWD_MD5` | `<login_pwd_md5>` |
| `FUTU_RSA_KEY` | `<rsa_private_key>` |
| `FUTU_IP` | `<ip>` (default: `127.0.0.1`) |
| `FUTU_API_PORT` | `<api_port>` (default: `11111`) |
| `FUTU_WS_PORT` | `<websocket_port>` |
| `FUTU_LOG_LEVEL` | `<log_level>` (default: `info`) |
| `FUTU_LANG` | `<lang>` (default: `en`) |
| `RSA_FILE_LOCAL_PATH` | Host path to RSA key |
| `FUTU_OPEND_XML_LOCAL_PATH` | Host path to FutuOpenD.xml |
| `TZ` | Container timezone (default: `Asia/Hong_Kong`) |

---

## Project Layout

```
futuopend/
├── Dockerfile                  # Multi-stage: Ubuntu 24.04 & Rocky Linux 9
├── docker-compose.yaml         # Docker Swarm orchestration (secrets, restart policy)
├── docker-compose.simple.yaml # Standalone Compose (beginner path — no Swarm required)
├── FutuOpenD.xml.template     # Config template, ${ENV_VAR}-ready
├── dockerbuild.sh              # Build & push both variants
├── .env.example                # Environment variable template
├── LICENSE                     # Apache 2.0
├── README.md                   # (you're here)
├── TODO.md                     # Open issues and planned improvements
├── docs/
│   ├── configuration.md        # Every FutuOpenD.xml tag, documented
│   └── security.md             # Hardening guide, checklists
└── .gitignore
```

---

## Troubleshooting

### Container exits immediately

```bash
docker compose logs futuopend
```

The usual suspects: missing secrets (RSA key or `FutuOpenD.xml` not mounted), port `11111` already in use, or invalid config syntax.

### "Waiting for phone verify code" — stuck

Normal on first login or a new IP. Futu sends an SMS code and FutuOpenD waits for it via Telnet. Full walkthrough is in [docs/configuration.md](docs/configuration.md#first-time-login-phone-verification).

### Can't reach FutuOpenD from another machine

Three things to check:
1. `<ip>` is set to `0.0.0.0` — not `127.0.0.1`
2. Firewall allows TCP `11111` (and `11112` for WebSocket)
3. Your account has API access enabled in the Futu app

### Trading calls return permission errors

The `rsa_private_key` in `FutuOpenD.xml` must match a key registered to your account. Double-check the key file is mounted at the right path inside the container.

### Tarball download fails during build

Futu's download server can be flaky. Pull the tarball manually and drop it in the build context:

```bash
wget -O Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz \
  https://softwaredownload.futunn.com/Futu_OpenD_10.2.6208_Ubuntu18.04.tar.gz
```

Then update the Dockerfile's `COPY` step to use the local file instead of `curl`.

---

## Further Reading

- [Futu OpenAPI Documentation](https://openapi.futunn.com/futu-api-doc/)
- [FutuOpenD Command-Line Reference](https://openapi.futunn.com/futu-api-doc/en/opend/opend-cmd.html)
- [Python SDK (futuquant)](https://github.com/Futuromy/FutuQuant)
- [Official FutuOpenD Download](https://www.futunn.com/download/fetch-lasted-link?name=opend-ubuntu)
- [Docker Hub — shing1211/futuopend](https://hub.docker.com/r/shing1211/futuopend)

---

## Contributing

Found a bug? Have an idea? Docs fix? Jump in. See [CONTRIBUTING.md](CONTRIBUTING.md). For a full list of open improvements, see [TODO.md](TODO.md).

---

## License

**This project** — the Docker packaging, scripts, documentation, and YAML files — is Copyright 2024 [Terence Chan](https://github.com/shing1211) and licensed under **Apache 2.0**. See [LICENSE](LICENSE).

**FutuOpenD itself** is proprietary software owned by Futu Network Technology Limited (富途证券). This project does not distribute the FutuOpenD binary — it downloads it from Futu's official server at build time. By using this image you agree to Futu's terms of service.

**The `FutuOpenD.xml.template`** is derived from the official FutuOpenD tarball. It belongs to Futu Securities and is included here for convenience only.

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
