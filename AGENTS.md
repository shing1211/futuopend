# AGENTS.md — FutuOpenD

## Build

**Linux / macOS:**
```bash
./dockerbuild.sh all                    # both variants (ubuntu + rocky)
./dockerbuild.sh ubuntu                # ubuntu only
./dockerbuild.sh rocky                # rocky only
./dockerbuild.sh --multiarch         # multi-arch (amd64 + arm64)
```

**Windows:**
```bash
dockerbuild.bat all
dockerbuild.bat ubuntu
```

## Run

```bash
docker compose -f docker-compose.simple.yaml up -d
```

- **TCP:** `localhost:11111`
- **WebSocket:** `localhost:11112`

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile.ubuntu` | Ubuntu 24.04 LTS build (amd64/arm64) |
| `Dockerfile.rocky` | Rocky Linux 9 build (amd64/arm64) |
| `docker-compose.simple.yaml` | Standalone deployment |
| `docker-compose.yaml` | Docker Swarm (production) |
| `entrypoint.sh` | Container entry with graceful shutdown |
| `FutuOpenD.xml.template` | Config template with env-var substitution |

## Current Version

- **FutuOpenD:** 10.4.6408 (2026-04-26)
- **Base:** Ubuntu 24.04 LTS / Rocky Linux 9
- **Entry Script:** `entrypoint.sh` (graceful SIGTERM/SIGINT handling)

## Gotchas

- Requires RSA private key for trading (generate at [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI))
- Healthcheck uses `pgrep FutuOpenD` — no curl needed
- `--start-period` is 60s on first boot (gives time for auth)
- CRLF line endings in shell scripts are auto-fixed during build via `sed`
