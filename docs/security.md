# Security Hardening Guide

Your trading credentials live inside this container. This guide shows you how to keep them there.

> **Disclaimer:** This is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo.

---

## The Golden Rules

1. **Never hardcode secrets.** Use MD5 for passwords, mount keys as files, pass nothing in plaintext.
2. **Least privilege.** Run as non-root, drop capabilities, lock down the filesystem.
3. **Network is enemy territory.** TLS on everything that crosses a wire. Firewall everything else.
4. **Rotate.** Keys wear out. Change them periodically via the [Futu OpenAPI dashboard](https://www.futunn.com/en/OpenAPI).

---

## Credential Handling

### Your password — hash it, never store it plaintext

The `<login_pwd_md5>` tag takes a one-way MD5 hash. Your actual password never touches the disk.

Generate it:

```bash
# Linux
echo -n "your_password" | md5sum | cut -d' ' -f1

# macOS
echo -n "your_password" | md5 -r

# Python (works everywhere)
python3 -c "import hashlib; print(hashlib.md5(b'your_password').hexdigest())"
```

The `-n` suppresses the trailing newline. Omit it and the hash is wrong.

### Your RSA private key — chmod 600, never commit it

Your RSA key is the most sensitive piece here. Guard it accordingly:

```bash
chmod 600 /opt/futuopend/secrets/rsa_key.txt
```

And keep it out of version control. The repo's `.gitignore` already handles this:

```gitignore
**/*.pem
**/*.key
**/FutuOpenD.xml
**/.rsa*
```

### FutuOpenD.xml — treat it like a secret

It contains your account ID and credential paths. Lock it down:

```bash
chmod 600 /opt/futuopend/secrets/FutuOpenD.xml
```

In production, pull it from a secrets manager — Docker Secrets, HashiCorp Vault, AWS Secrets Manager. Don't leave it sitting on a filesystem.

---

## Network Security

### Local binding — the safe default

FutuOpenD binds to `127.0.0.1` by default. Only local processes can reach it — the network can't touch it. This is the right mode for single-machine setups:

```xml
<ip>127.0.0.1</ip>
<api_port>11111</api_port>
```

### Remote access — TLS is non-negotiable

If another machine needs to connect, the WebSocket traffic must be encrypted. Generate a certificate and key, then:

```xml
<ip>0.0.0.0</ip>
<websocket_private_key>/run/secrets/ws_key_nopass.pem</websocket_private_key>
<websocket_cert>/run/secrets/ws_cert.pem</websocket_cert>
```

Generate a self-signed cert for testing:

```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=futuopend"

# Strip the password — FutuOpenD doesn't handle encrypted keys
openssl rsa -in key.pem -out key_nopass.pem
```

> **Better yet** for remote access: use a VPN (WireGuard, Tailscale) or an SSH tunnel. Encryption without managing certificates.

### Firewall — default deny

```bash
# Allow only your client subnet
iptables -A INPUT -p tcp --dport 11111 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 11111 -j DROP
```

Or isolate FutuOpenD inside a Docker internal network so it can't reach the outside world except where you explicitly allow:

```yaml
services:
  futuopend:
    networks:
      - futu-internal

networks:
  futu-internal:
    internal: true   # No external egress by default
```

---

## Container Hardening

### Read-only filesystem + dropped capabilities

This is the production baseline. Add it to your `docker-compose.yaml`:

```yaml
services:
  futuopend:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
```

What each line does:

| Option | What it does |
|--------|-------------|
| `no-new-privileges` | Prevents the container from gaining privileges via suid binaries |
| `read_only` | Filesystem is immutable except for mounted volumes |
| `tmpfs` | Temp data lives in RAM, not on disk |
| `cap_drop: ALL` | Strips every Linux capability the process doesn't need |

### Non-root user

The Dockerfile already creates a `futuopend` user (UID 1000) and switches to it. This is already in place — no action needed unless you're customizing the image.

### Docker Secrets

The compose file uses Docker Secrets for credential injection. Secrets land at `/run/secrets/` with `0400` permissions and are mounted read-only:

```yaml
secrets:
  rsa-key:
    file: ${RSA_FILE_LOCAL_PATH:?RSA_FILE_LOCAL_PATH is not set}
  config:
    file: ${FUTU_OPEND_XML_LOCAL_PATH:?FUTU_OPEND_XML_LOCAL_PATH is not set}
```

### External secrets managers

For larger deployments, pull secrets at runtime:

| Tool | How it works |
|------|-------------|
| HashiCorp Vault | Vault Agent sidecar injects secrets into the container |
| AWS Secrets Manager | aws-secrets-manager-sidecar pulls keys at startup |
| Azure Key Vault | akv-sidecar handles injection |

### Kubernetes

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: futuopend-secrets
type: Opaque
stringData:
  rsa_key.txt: |
    -----BEGIN RSA PRIVATE KEY-----
    ...
    -----END RSA PRIVATE KEY-----
  FutuOpenD.xml: |
    <?xml version="1.0" encoding="utf-8"?>
    ...
```

Mount as volumes or inject via a mutating webhook.

---

## Monitoring & Audit

- Start with `log_level=debug` during setup. Once everything is stable, switch to `info`.
- Ship logs somewhere centralized — ELK, Loki, CloudWatch. You want an audit trail, not just a terminal scrollback.
- Set up alerts on authentication failures. A failed login attempt from an unexpected IP is a red flag.
- Watch resource usage. Sudden spikes in CPU or memory can be an early warning something is wrong.

---

## Dependency Updates

The base images ship with known vulnerabilities patched at build time. Rebuild periodically to pull fresh OS security patches:

```bash
docker build --no-cache -t shing1211/futuopend:latest .
```

Pin the FutuOpenD version in production. Auto-upgrades at the wrong time can break your trading system.

---

## Security Checklist

Run through this before going live:

- [ ] RSA private key has no password and `chmod 600`
- [ ] `FutuOpenD.xml` is not committed to version control
- [ ] Remote access uses TLS (both `websocket_private_key` and `websocket_cert` set)
- [ ] Firewall restricts port `11111` to known client IPs
- [ ] Container runs with `read_only: true`, `cap_drop: ALL`, and `no-new-privileges: true`
- [ ] Logs are forwarded to a central system and reviewed for auth failures
- [ ] FutuOpenD version is pinned (not `latest`)
- [ ] Separate keys used for dev and production
- [ ] Password hash is not reused across environments

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
