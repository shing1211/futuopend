---
title: Home
layout: default
nav_order: 1
permalink: /
---

# FutuOpenD Docke

Docker build for [FutuOpenD](https://openapi.futunn.com/futu-api-doc/) - the local gateway for Futu's trading API.

**Current version:** 10.11.7108

## What and why

FutuOpenD is the local gateway daemon for Futu's trading API. The official installer assumes a desktop session; this project packages it into a Docker image for headless deployment on any Linux host: cloud VM, NAS, or Raspberry Pi.

This project only builds the image. For runtime deployment, see [futuopend-deploy](https://github.com/shing1211/futuopend-deploy).

## Quick start

```bash
docker run -d --name futuopend \
  -p 11111:11111 -p 22222:22222 \
  -v "$PWD/FutuOpenD.xml:/usr/local/bin/FutuOpenD.xml:ro" \
  -v futuopend-data:/home/futuopend/.com.futunn.FutuOpenD \
  -e FUTU_ACCOUNT=your_account_id \
  -e FUTU_IP=0.0.0.0 \
  shing1211/futuopend:latest
```

The container exposes `11111` (quote API), `11112` (trade API), and `22222` (Telnet debug/2FA). OpenD reads its config from `/usr/local/bin/FutuOpenD.xml`, and resolves `${VAR}` placeholders itself, so it can be driven entirely from environment variables. See the [deployment guide](https://github.com/shing1211/futuopend-deploy) for a ready-to-use template.

## Login (FutuOpenD 10.10+)

FutuOpenD 10.10+ **no longer reads `login_account` / `login_pwd` from `FutuOpenD.xml`** ([official changelog](https://openapi.futunn.com/futu-api-doc/en/changelog/changelog.html)). It uses **remember-login** instead:

1. **First login (once).** Run without `FUTU_ACCOUNT` and attach a TTY, then enter your account/password and choose *remember*:

   ```bash
   docker run --rm -it \
     -p 11111:11111 -p 22222:22222 \
     -v "$PWD/FutuOpenD.xml:/usr/local/bin/FutuOpenD.xml:ro" \
     -v futuopend-data:/home/futuopend/.com.futunn.FutuOpenD \
     shing1211/futuopend:latest
   ```

   If Futu challenges the device (`Waiting for phone verify code...`), submit the code over Telnet port `22222`.

2. **Subsequent starts.** Set `FUTU_ACCOUNT` — the entrypoint passes `-login_account=<id> -login_by_remember=1`, and OpenD logs in from the cached credential.

The `futuopend-data` volume holds the cached session — **do not delete it**, or the one-time login is required again. A bare `docker run` without a config mount uses the image's built-in defaults (`ip 127.0.0.1`, Telnet disabled).

## Documentation

- [Architecture](ARCHITECTURE.html)
- [Changelog](https://github.com/shing1211/futuopend/blob/main/CHANGELOG.md)
- [Roadmap](https://github.com/shing1211/futuopend/blob/main/ROADMAP.md)

## Links

- [GitHub repository](https://github.com/shing1211/futuopend)
- [Docker Hub](https://hub.docker.com/r/shing1211/futuopend)
- [Discussions](https://github.com/shing1211/futuopend/discussions)

## Disclaime

Unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo. Trading involves risk; use at your own risk.
