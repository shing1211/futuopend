# Security Best Practices

FutuOpenD handles your trading credentials. Treat it accordingly.

> **Disclaimer:** This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo.

---

## Credential Handling

### Passwords (MD5 hash)

- Never store plaintext passwords. The MD5 hash is a one-way transform — use it.
- Don't reuse the same password hash across dev and production.
- Rotate passwords regularly through Futu's official portal.

### RSA Private Keys

- Set `chmod 600` on your private key file — owner read/write only.
- **Never commit keys to version control.** Add this to your `.gitignore`:

```gitignore
# .gitignore
**/*.pem
**/*.key
**/FutuOpenD.xml
**/.rsa*
```

- Use separate keys per environment when possible.
- Rotate them periodically via the [Futu OpenAPI dashboard](https://www.futunn.com/en/OpenAPI).

### FutuOpenD.xml

This file contains your account ID and references to secrets. Treat it like a secret itself:
- `chmod 600 FutuOpenD.xml`
- Use Docker Secrets or a secrets manager (Vault, AWS Secrets Manager) in production
- Keep it off version control

---

## Network Security

### Local binding (default)

FutuOpenD binds to `127.0.0.1` by default. Only local processes can connect — nothing from the network can reach it. This is the safest mode.

```xml
<ip>127.0.0.1</ip>
<api_port>11111</api_port>
```

### Remote access with TLS

If you need to connect from another machine, **TLS is non-negotiable**:

1. Bind to `0.0.0.0` **and** configure SSL:

```xml
<ip>0.0.0.0</ip>
<websocket_private_key>/run/secrets/ws_key_nopass.pem</websocket_private_key>
<websocket_cert>/run/secrets/ws_cert.pem</websocket_cert>
```

2. Better yet: use a VPN (WireGuard, Tailscale) or SSH tunnel instead of exposing raw ports.

3. Lock down the firewall to your known client IPs only.

### Firewall rules

```bash
# Allow only your client subnet
iptables -A INPUT -p tcp --dport 11111 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 11111 -j DROP
```

Or use Docker's internal network to isolate FutuOpenD from the outside world:

```yaml
services:
  futuopend:
    networks:
      - futu-internal

networks:
  futu-internal:
    internal: true   # No external egress — add explicit rules for Futu's servers
```

---

## Docker Security

### Read-only secrets

Mount secrets as read-only volumes with restricted permissions:

```yaml
services:
  futuopend:
    secrets:
      - source: rsa-key
        target: /run/secrets/rsa_key.txt
        mode: 0400
      - source: config
        target: /run/secrets/FutuOpenD.xml
        mode: 0400
```

### Container hardening

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

What each does:
- `no-new-privileges` — prevents the container from gaining new privileges via suid binaries
- `read_only` — makes the filesystem immutable except for mounted volumes
- `tmpfs` — stores temp data in memory, not on disk
- `cap_drop: ALL` — strips all Linux capabilities the process doesn't need

### Run as non-root

The base image defaults to root. Add this to the Dockerfile or entrypoint to drop privileges:

```dockerfile
RUN useradd -m -u 1000 futuopend
USER futuopend
```

---

## Secrets Management

### Docker Secrets (Swarm mode)

```yaml
secrets:
  rsa-key:
    file: ./secrets/rsa_key.txt
  config:
    file: ./FutuOpenD.xml
```

### External secrets managers

For production at scale, pull secrets in at runtime:

| Tool | Approach |
|------|----------|
| **HashiCorp Vault** | Vault Agent sidecar injects secrets |
| **AWS Secrets Manager** | aws-secrets-manager-sidecar container |
| **Azure Key Vault** | akv-sidecar container |

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

Mount as volumes or inject as environment variables via a mutating webhook.

---

## Monitoring & Audit

- Start with `log_level=debug` during setup. Switch to `info` once everything is stable.
- Ship logs to a central system (ELK, Loki, CloudWatch) — you'll want an audit trail.
- Set up alerts on authentication failures and unusual trading activity.
- Watch container resource usage. Unexpected spikes can be an early warning sign.

---

## Dependency Security

- Rebuild the image periodically to pull OS security patches:

```bash
docker build --no-cache -t futuopend:latest .
```

- Pin the FutuOpenD version in production. Auto-upgrades can introduce breaking changes at the worst time.

---

## Security Checklist

- [ ] RSA private key has no password and `chmod 600`
- [ ] `FutuOpenD.xml` is not committed to version control
- [ ] Remote access uses TLS (certificate + key configured)
- [ ] Firewall restricts port `11111` to known IPs
- [ ] Container runs with `--read-only`, `cap_drop: ALL`, and `no-new-privileges`
- [ ] Logs are reviewed for authentication failures
- [ ] FutuOpenD version is pinned and current
- [ ] Separate keys used for dev vs. production

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
