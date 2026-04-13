# Contributing to FutuOpenD Docker

All contributions are welcome — bug reports, documentation fixes, new features, or even just a friendly "thanks, this worked for me" issue. This project is small, and there's plenty to do.

---

## Ways to Contribute

- **Bug reports** — File an issue with steps to reproduce and your environment (OS, Docker version, FutuOpenD version).
- **Feature requests** — Open an issue to discuss the idea before writing code. Saves everyone time.
- **Documentation** — Typos, clearer explanations, better examples — all appreciated.
- **Code** — Fix bugs, improve the Dockerfile, or tackle one of the open issues below.

---

## Development Setup

```bash
# Clone the repo
git clone https://github.com/shing1211/futuopend.git
cd futuopend

# Build the image
docker build -t futuopend:test .

# Start with docker-compose
docker compose -f docker-compose.yaml up -d

# Watch the logs
docker compose logs -f
```

---

## Code Style

- **Shell scripts** — `shellcheck`-clean. Use [shellcheck.net](https://www.shellcheck.net/) to catch issues before submitting.
- **YAML** — 2-space indentation, keys in alphabetical order where it makes sense.
- **Markdown** — Sentence case headings, wrap lines at ~100 characters.

---

## Pull Request Process

1. **Fork** the repo and create a branch from `main`:

   ```bash
   git checkout -b fix/my-fix
   ```

2. **Make your changes.** Keep commits focused and well-described:

   ```bash
   git commit -m "fix: correct secrets path from /bin to /run/secrets"
   ```

3. **Test locally:**

   ```bash
   docker build -t futuopend:test .
   docker run --rm futuopend:test /bin/FutuOpenD --help 2>/dev/null || true
   ```

4. **Push and open a PR:**

   ```bash
   git push origin fix/my-fix
   ```

5. A maintainer will review. Please be responsive to feedback.

---

## Open Issues

These were flagged during a code review and are good starting points:

| Priority | File | Issue |
|----------|------|-------|
| High | `Dockerfile` | Base image Ubuntu 18.04 is EOL — migrate to 22.04 or 24.04. |
| Medium | `Dockerfile` | PTY/TTY not allocated — `stdin_open: true` and `tty: true` in compose have no effect without `-it`. |
| Medium | `docker-compose.yaml` | `PUID`/`PGID` not wired through — container still runs as `futuopend` UID 1000; add `--userns=keep-id` or pass PUID/PGID via env. |
| Low | `.env` | `PUID`/`PGID`/`TZ` defined but unused — these could be wired into a custom entrypoint. |
| Low | `CI` | No GitHub Actions — builds are manual. See `.github/workflows/` for a starter workflow. |

---

## Project Standards

- **Breaking changes** must update `CHANGELOG.md` under `## [Unreleased]`.
- **Version bumps** must update all four `FUTU_OPEND_VER` occurrences in `Dockerfile` in the same PR.
- **No new dependencies** without discussion — this image aims to stay minimal.
- **Apache 2.0 license** applies to all contributions.

---

## Code of Conduct

Be respectful and constructive. Disagreements happen; personal attacks do not.

---

*This project is an unofficial community packaging and is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
