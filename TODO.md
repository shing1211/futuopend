# TODO

Open issues and planned improvements for the futuopend project. Contribution welcome on any of these.

> Last updated: 2026-04-14

---

## High Priority

- [ ] **Both build stages always run** — `docker build --target final-ubuntu` still executes the CentOS stage. Restructure Dockerfile so only the relevant stage runs, cutting build time in half.
- [ ] **No env vars in compose files** — Docs show `environment:` examples but neither compose file exposes them. Either wire env vars through or remove the examples from docs.
- [ ] **`${FUTU_RSA_KEY}` missing from template** — `FutuOpenD.xml.template` has the RSA key line commented out as a plain path. Docs show `${FUTU_RSA_KEY}` but the template doesn't use it.
- [ ] **Phone verification warning absent from Quick Start** — Users panic when they see "Waiting for phone verify code". Add a one-liner in the Quick Start pointing to the phone verification section.
- [ ] **Phone verification docs duplicated** — Exists in both `README.md` and `docs/configuration.md`. Keep the canonical version in `docs/configuration.md`, trim the README copy to a brief callout.

## Medium Priority

- [ ] **GitHub Actions CI** — No workflow to build/push on merge or run shellcheck on PRs. See `.github/workflows/` for a starter.
- [ ] **Remove unused `RSA_FILE_PATH` from `.env.example`** — Defined but never referenced anywhere.
- [ ] **`--help` doesn't list `--list` option** in `dockerbuild.sh`.
- [ ] **`.env` file with real paths committed to repo** — Should not exist in the repo at all. Remove it.

## Low Priority

- [ ] **`dockerbuild.sh` hardcoded image name** — `IMAGE="shing1211/futuopend"` has no override mechanism. Make it an env var or argument.
- [ ] **Parallelize builds in `dockerbuild.sh`** — Ubuntu and CentOS build sequentially. They could run in parallel with `&` + `wait`.
- [ ] **No `SECURITY.md`** — A proper security policy file (GitHub-supported) documenting disclosure process.
- [ ] **No `Makefile`** — Targets for `build`, `test`, `push`, `lint` would make local iteration easier.
- [ ] **Incomplete Kubernetes Secret example** — The example in `docs/security.md` shows raw YAML but doesn't explain how to mount or apply it.
- [ ] **FutuQuant SDK link deprecated** — The [Python SDK link](https://github.com/Futuromy/FutuQuant) in README may be stale. Verify and update to current SDK.
- [ ] **No image size badge** — A Docker image size badge (e.g., via `dockeri.co`) would help users on bandwidth-constrained connections.
- [ ] **No `docker-compose.yaml` vs `simple.yaml` distinction** — No docs explain which to use and when. Document it.

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
