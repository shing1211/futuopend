# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

We take the security of futuopend seriously. If you believe you have found a
security vulnerability, please report it to us as described below.

**Please do NOT report security vulnerabilities through public GitHub issues,
discussions, or pull requests.**

Instead, please email [shing1211@users.noreply.github.com](mailto:shing1211@users.noreply.github.com).

Please include the following information:

- Type of issue (e.g., credential exposure, privilege escalation, container escape, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit the issue

This information will help us triage your report more quickly.

We aim to acknowledge your report within **48 hours** and will provide a more
detailed response within **7 days**. After the initial reply, we will keep you
informed of the progress towards a fix and full announcement, and may ask for
additional information or guidance.

## Scope

This security policy covers the futuopend Docker packaging project. Issues with
FutuOpenD itself, Futu's servers, the futuapi4go SDK, or trading bots built on
top of Futu OpenD should be reported to their respective projects.

## Container Security

Because this image packages FutuOpenD (which handles trading credentials):

- **Never commit RSA private keys, passwords, or account credentials** to the repository
- Use Docker Secrets or environment variables for sensitive configuration
- Use `chmod 600` on any RSA key files mounted into the container
- Run the container as a non-root user (futuopend UID 1000) — this is configured by default in the Dockerfile
- The container downloads the FutuOpenD binary from Futu's official CDN at build time; verify checksums
- For runtime security hardening (TLS, secrets, firewall), see [futuopend-deploy](https://github.com/shing1211/futuopend-deploy)
