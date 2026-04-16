# AGENTS.md — FutuOpenD

## Build
```bash
./dockerbuild.sh              # builds & pushes ALL variants (ubuntu + rocky)
./dockerbuild.sh ubuntu       # ubuntu only
./dockerbuild.sh rocky        # rocky only
```

## Run
```bash
docker compose -f docker-compose.simple.yaml up -d
```
- TCP: `localhost:11111`
- WebSocket: `localhost:11112`

## Key Files
- `Dockerfile` — multi-stage build
- `docker-compose.simple.yaml` — standalone deployment
- `FutuOpenD.xml.template` — official config with env-var substitution

## Current Version
- FutuOpenD: **10.3.6308** (2026-04-16)
- Base: Ubuntu 24.04 / Rocky Linux 9

## Gotchas
- Requires RSA private key for trading (generate at Futu OpenAPI dashboard)
- Healthcheck uses `pgrep FutuOpenD` — no curl needed
- `--start-period` is 60s on first boot (gives time for auth)