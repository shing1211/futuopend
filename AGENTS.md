# AGENTS.md — FutuOpenD

## Build
```bash
./dockerbuild.sh              # builds & pushes ALL variants (ubuntu + rocky, amd64 only)
./dockerbuild.sh ubuntu       # ubuntu only (amd64)
./dockerbuild.sh rocky        # rocky only (amd64)
./dockerbuild.sh --multiarch  # all variants, both amd64 + arm64
```

> **Note:** Dockerfiles are split by OS (`Dockerfile`, `Dockerfile.rocky`) so `--target` only builds the relevant base image — no wasted build time on unselected OS variants.

## Run
```bash
docker compose -f docker-compose.simple.yaml up -d
```
- TCP: `localhost:11111`
- WebSocket: `localhost:11112`

## Key Files
- `Dockerfile` — Ubuntu 24.04 multi-stage build (amd64/arm64)
- `Dockerfile.rocky` — Rocky Linux 9 multi-stage build (amd64/arm64)
- `docker-compose.simple.yaml` — standalone deployment
- `FutuOpenD.xml.template` — official config with env-var substitution

## Current Version
- FutuOpenD: **10.3.6308** (2026-04-16)
- Base: Ubuntu 24.04 / Rocky Linux 9

## Gotchas
- Requires RSA private key for trading (generate at Futu OpenAPI dashboard)
- Healthcheck uses `pgrep FutuOpenD` — no curl needed
- `--start-period` is 60s on first boot (gives time for auth)