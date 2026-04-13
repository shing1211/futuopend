# Contributing to futuopend

Thank you for your interest in contributing!

## Ways to Contribute

- **Bug reports** — File an issue with steps to reproduce and your environment details.
- **Feature requests** — Open an issue to discuss new features before submitting a PR.
- **Documentation** — Help improve docs, README, or this guide.
- **Code contributions** — Fix bugs, improve the Dockerfile, or add missing features.

## Development Setup

```bash
# Clone the repository
git clone https://github.com/shing1211/futuopend.git
cd futuopend

# Build the Docker image
docker build -t futuopend:test .

# Run tests (start the container with your config)
docker compose -f docker-compose.yaml up -d

# View logs
docker compose logs -f
```

## Code Style

- Shell scripts: `shellcheck`-compliant (use [shellcheck](https://www.shellcheck.net/)).
- YAML: 2-space indentation, alphabetical keys.
- Markdown: sentence case headings, one sentence per line.

## Pull Request Process

1. **Fork** the repository and create a branch from `main`:
   ```bash
   git checkout -b fix/my-fix
   ```

2. **Make your changes.** Keep commits atomic and well-described:
   ```bash
   git commit -m "fix: correct secrets path from /bin to /run/secrets"
   ```

3. **Test locally:**
   ```bash
   docker build -t futuopend:test .
   # Verify the build succeeds and the binary runs
   docker run --rm futuopend:test /bin/FutuOpenD --help 2>/dev/null || true
   ```

4. **Push and open a PR:**
   ```bash
   git push origin fix/my-fix
   ```

5. A maintainer will review and merge. Be responsive to feedback.

## Known Issues to Fix

The following issues from the code review are open for contribution:

| Priority | File | Issue | Status |
|----------|------|-------|--------|
| High | `docker-compose.yaml` | Secrets written to `/bin/` (world-readable). Move to `/run/secrets/`. | Open |
| Medium | `Dockerfile` | No `HEALTHCHECK` for the daemon. Add `HEALTHCHECK --interval=30s CMD ...`. | Open |
| Medium | `Dockerfile` | No `USER` directive. Add non-root user. | Open |
| Medium | `.env` | `PUID`/`PGID`/`TZ` defined but unused. Pass them into the container. | Open |
| Low | `dockerbuild.sh` | `git pull` is dangerous in a build script. Remove or guard with `set -e`. | Open |
| Low | `dockerbuild.sh` | No error handling. Add `set -e -o pipefail`. | Open |
| Low | `dockerbuild.sh` | Only builds Ubuntu. Add `--target` for CentOS variant. | Open |

## Project Standards

- **Breaking changes** must update `CHANGELOG.md` under an `## [Unreleased]` section.
- **Version bumps** must update `Dockerfile` (all 4 `FUTU_OPEND_VER` occurrences) in the same PR.
- **No new dependencies** without discussion. This image aims to be minimal.
- **MIT license** applies to all contributions.

## Code of Conduct

Be respectful and constructive. Disagreements are fine; personal attacks are not.
