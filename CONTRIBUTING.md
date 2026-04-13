# Contributing to FutuOpenD Docker

Got a bug? An idea? A docs fix? All of it is welcome. This project is small and there's always more to do — jump in.

> **Disclaimer:** This is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo.

---

## Ways to Contribute

- **Bug reports** — Include steps to reproduce and your environment (OS, Docker version, FutuOpenD version)
- **Feature requests** — Open an issue to discuss first. Saves everyone time.
- **Documentation** — Typos, clearer examples, better structure — all appreciated.
- **Code** — Pick up an open issue or improve the Dockerfile, compose files, or scripts.

---

## Dev Setup

```bash
git clone https://github.com/shing1211/futuopend.git
cd futuopend

# Build the image (Ubuntu variant)
docker build \
  --target final-ubuntu \
  --build-arg FUTU_OPEND_VER=10.2.6208 \
  -t futuopend:test .

# Start with compose (uses docker-compose.simple.yaml — no Swarm required)
docker compose -f docker-compose.simple.yaml up -d

# Watch the logs
docker compose -f docker-compose.simple.yaml logs -f
```

---

## Code Style

- **Shell scripts** — run through [shellcheck](https://www.shellcheck.net/) before submitting. No exceptions.
- **YAML** — 2-space indent, keys in alphabetical order where it makes sense.
- **Markdown** — Sentence case headings, wrap lines at ~100 characters.
- **XML examples** — Always use lowercase tag names matching FutuOpenD's expected format.

---

## Pull Request Process

1. **Fork** the repo and create a branch from `main`:

   ```bash
   git checkout -b fix/my-fix
   ```

2. **Make your changes.** Keep commits focused and descriptive:

   ```bash
   git commit -m "fix: correct secrets path from /bin to /run/secrets"
   ```

3. **Test locally:**

   ```bash
   # Build the image
   docker build --target final-ubuntu -t futuopend:test .

   # Quick smoke test — container starts and stays up
   docker run -d --name futuopend-test futuopend:test
   sleep 5
   docker ps --filter name=futuopend-test --format "{{.Status}}"
   docker stop futuopend-test && docker rm futuopend-test
   ```

4. **Push and open a PR.** Be responsive to review feedback.

---

## Open Issues

These are good starting points if you're looking for something to work on:

| Priority | Area | What it involves |
|----------|------|-----------------|
| High | `Dockerfile` | CentOS variant uses Rocky Linux 9 — binary compatibility untested under heavy load |
| Medium | `Dockerfile` | Both build stages always run regardless of target — doubles build time |
| Medium | CI | No GitHub Actions workflow — see `.github/workflows/` for a starter |
| Low | `dockerbuild.sh` | Add `--dry-run` flag for safe CI testing |
| Low | `dockerbuild.sh` | Parallelize ubuntu + centos builds |

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
