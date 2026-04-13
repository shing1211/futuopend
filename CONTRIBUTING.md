# Contributing to FutuOpenD Docker

Got a bug, an idea, or a docs fix? All of it is welcome. This project is small and there's always more to do — jump in.

> **Disclaimer:** This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo.

---

## Ways to Contribute

- **Bug reports** — Include steps to reproduce and your environment (OS, Docker version, FutuOpenD version).
- **Feature requests** — Open an issue to discuss first. Saves everyone time.
- **Documentation** — Typos, clearer examples, better structure — all appreciated.
- **Code** — Pick up an open issue or improve the Dockerfile, compose files, or scripts.

---

## Dev Setup

```bash
# Clone and enter
git clone https://github.com/shing1211/futuopend.git
cd futuopend

# Build the image
docker build -t futuopend:test .

# Start with compose
docker compose -f docker-compose.yaml up -d

# Watch logs
docker compose logs -f
```

---

## Code Style

- **Shell scripts** — `shellcheck`-clean before submitting. Use [shellcheck.net](https://www.shellcheck.net/) to catch issues.
- **YAML** — 2-space indent, keys in alphabetical order where it makes sense.
- **Markdown** — Sentence case headings, wrap lines at ~100 characters.

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
   docker build -t futuopend:test .
   docker run --rm futuopend:test /bin/FutuOpenD --help 2>/dev/null || true
   ```

4. **Push and open a PR.**

5. A maintainer will review. Please be responsive to feedback.

---

## Open Issues

These are good starting points if you want to contribute:

| Priority | Area | Issue |
|----------|------|-------|
| High | `Dockerfile` | Base image Ubuntu 18.04 is EOL — migrate to 22.04 or 24.04 |
| Medium | `Dockerfile` | PTY/TTY not allocated — `stdin_open: true` and `tty: true` need `-it` to work |
| Medium | `docker-compose.yaml` | `PUID`/`PGID` not wired through — add `--userns=keep-id` or pass via env |
| Low | `.env` | `PUID`/`PGID`/`TZ` defined but unused — wire into a custom entrypoint |
| Low | CI | No GitHub Actions — see `.github/workflows/` for a starter workflow |

---

## Standards

- **Breaking changes** — update `CHANGELOG.md` under `## [Unreleased]`.
- **Version bumps** — update all `FUTU_OPEND_VER` occurrences in `Dockerfile` in the same PR.
- **No new dependencies** without discussion — this image stays minimal on purpose.
- **Apache 2.0 license** applies to all contributions.

---

## Code of Conduct

Be respectful and constructive. Disagreements happen; personal attacks don't.

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
