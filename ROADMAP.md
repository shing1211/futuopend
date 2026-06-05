# futuopend Roadmap

> Last Updated: 2026-06-05

---

## Vision

futuopend is the most reliable Docker packaging for FutuOpenD. This repo focuses on **building the Docker image** — clean, consistent, multi-arch. For runtime deployment, see [futuopend-deploy](https://github.com/shing1211/futuopend-deploy).

---

## Version History

### v2.2.0 (Current — 2026-06-05)
- FutuOpenD upgraded to **10.7.6708** (5 new vendored .so libraries: libcrypto.so.3, libcurl.so.4, libf3cnet.so, libprotobuf.so.32, libssl.so.3)
- Config schema unchanged — `FutuOpenD.xml` byte-identical to 10.6.6608
- No new XML tags to document; new APIs are server-side

### v2.1.0 (2026-05-21)
- FutuOpenD upgraded to **10.6.6608** with new fundamental data and conditional stock screening APIs
- Dockerfile deduplication: merged `final-amd64` + `final-arm64` → single `final` stage
- `--all` flag as preferred alias for `--multiarch`
- Rocky Dockerfile: `--http1.1` flag added to curl for reliable large tarball downloads
- Docker Hub: all 8 tags pushed per release (ubuntu+rocky × amd64+arm64 + centos aliases)
- ARM performance docs and box64 recommendation in README
- Signal handler TOCTOU race fixed in entrypoint.sh (uses captured PID)
- Platform-aware compose: `TARGETARCH` env var drives architecture selection

### v2.0.0 (2026-05-11)
- Split Dockerfiles: `Dockerfile.ubuntu` + `Dockerfile.rocky` (no wasted build time)
- `entrypoint.sh` with robust SIGTERM/SIGINT handling
- Windows support: `dockerbuild.bat` with full parity to `dockerbuild.sh`
- CRLF line ending fix for Windows builds
- Non-root user, health checks bundled in image
- Ubuntu 24.04 LTS + Rocky Linux 9 variants
- Multi-arch: amd64 + arm64 builds
- Published on Docker Hub (`shing1211/futuopend`)
- Repo split: build-only here, deploy concerns moved to `futuopend-deploy`

### v1.0.0
- Initial production-ready release
- Multi-stage Dockerfile with 8 build targets

---

## Upcoming

| Item | Priority | Status |
|------|----------|--------|
| GitHub Actions CI pipeline | High | Pending |
| Automated version bumping | High | Pending |
| Build smoke test in CI | High | Pending |
| Makefile with standard targets | Medium | Pending |
| Parallel build pipeline | Low | Pending |

---

*Generated with community contributions — 2026-05-18*
