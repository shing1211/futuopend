# Contributing to FutuOpenD Docker

Bug reports, features, docs fixes — all welcome. This project is small and there's always more to do.

---

## Ways to Contribute

- **Bug reports** — Include steps to reproduce and your environment (OS, Docker version, FutuOpenD version)
- **Feature requests** — Open an issue to discuss first
- **Documentation** — Typos, clearer examples, better structure
- **Code** — Improve Dockerfiles, compose files, or scripts

---

## Dev Setup

### Linux / macOS

```bash
git clone https://github.com/shing1211/futuopend.git
cd futuopend

# Build the image
./dockerbuild.sh ubuntu                    # ubuntu variant
./dockerbuild.sh rocky                    # rocky variant

# Or use Docker directly
docker build -f Dockerfile.ubuntu --target final-amd64 -t futuopend:test .

# Start with compose
docker compose -f docker-compose.simple.yaml up -d
docker compose logs -f
```

### Windows

```bash
# Build
dockerbuild.bat ubuntu

# Or use Docker directly
docker build -f Dockerfile.ubuntu --target final-amd64 -t futuopend:test .

# Start with compose
docker compose -f docker-compose.simple.yaml up -d
```

---

## Code Style

- **Shell scripts** — Run through [shellcheck](https://www.shellcheck.net/) before submitting
- **YAML** — 2-space indent, keys in alphabetical order
- **Markdown** — Sentence case headings, wrap lines at ~100 characters
- **XML** — Always lowercase tag names

---

## Pull Request Process

1. **Fork** the repo and create a branch from `main`:
   ```bash
   git checkout -b fix/my-fix
   ```

2. **Make your changes.** Keep commits focused:
   ```bash
   git commit -m "fix: correct secrets path from /bin to /run/secrets"
   ```

3. **Test locally:**
   ```bash
   # Build the image
   docker build -f Dockerfile.ubuntu --target final-amd64 -t futuopend:test .

   # Quick smoke test
   docker run -d --name futuopend-test futuopend:test
   sleep 5
   docker ps --filter name=futuopend-test --format "{{.Status}}"
   docker stop futuopend-test && docker rm futuopend-test
   ```

4. **Push and open a PR.**

---

## Project Structure

```
futuopend/
├── Dockerfile.ubuntu     # Ubuntu 24.04 build
├── Dockerfile.rocky     # Rocky Linux 9 build
├── docker-compose.yaml   # Docker Swarm (secrets)
├── docker-compose.simple.yaml  # Standalone
├── dockerbuild.sh/.bat   # Build scripts
├── entrypoint.sh         # Container entry
└── docs/
    ├── configuration.md
    ├── security.md
    └── api.md
```

---

## Standards

- **Breaking changes** — Update `CHANGELOG.md` under `## [Unreleased]`
- **Version bumps** — Update all `FUTU_OPEND_VER` in Dockerfiles
- **No new dependencies** without discussion — this image stays minimal
- **Apache 2.0 license** applies to all contributions

---

## Code of Conduct

Be respectful and constructive. Disagreements happen; personal attacks don't.

---

*This project is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
