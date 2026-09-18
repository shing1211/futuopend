---
title: Home
layout: default
nav_order: 1
permalink: /
---

# FutuOpenD Docker

Docker build for [FutuOpenD](https://openapi.futunn.com/futu-api-doc/) - the local gateway for Futu's trading API.

**Current version:** 10.11.7108

## What and why

FutuOpenD is the local gateway daemon for Futu's trading API. The official installer assumes a desktop session; this project packages it into a Docker image for headless deployment on any Linux host: cloud VM, NAS, or Raspberry Pi.

This project only builds the image. For runtime deployment, see [futuopend-deploy](https://github.com/shing1211/futuopend-deploy).

## Quick start

```bash
docker run -d --name futuopend \
  -p 11111:11111 \
  -v "$PWD/FutuOpenD.xml:/usr/local/bin/FutuOpenD.xml:ro" \
  shing1211/futuopend:latest
```

The container exposes port `11111` (quote API) and `11112` (trade API). You must supply a `FutuOpenD.xml` with your account configuration; see the deployment guide above.

## Important: 10.10 login change

Starting with FutuOpenD 10.10, launching OpenD with no account configured opens **interactive login**. The bundled `FutuOpenD.xml` no longer ships `login_account` / `login_pwd`.

For headless deployments, provide credentials one of these ways:

- In the mounted `FutuOpenD.xml` (`login_account` / `login_pwd` are still supported)
- On the command line: `-login_account=<id> -login_by_remember=1`

## Documentation

- [Architecture](ARCHITECTURE.html)
- [Changelog](https://github.com/shing1211/futuopend/blob/main/CHANGELOG.md)
- [Roadmap](https://github.com/shing1211/futuopend/blob/main/ROADMAP.md)

## Links

- [GitHub repository](https://github.com/shing1211/futuopend)
- [Docker Hub](https://hub.docker.com/r/shing1211/futuopend)
- [Discussions](https://github.com/shing1211/futuopend/discussions)

## Disclaimer

Unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo. Trading involves risk; use at your own risk.
