# Security Best Practices

FutuOpenD handles sensitive credentials (account passwords, trading APIs) and should be treated accordingly.

## Credential Handling

### Passwords (MD5)

- Never store plaintext passwords. The `PwdMD5` field stores a one-way MD5 hash.
- Do not use the same password hash across environments (dev/prod).
- Rotate passwords regularly through Futu's official portal.

### RSA Private Keys

- Store private keys in a directory with `chmod 600` (owner read/write only).
- **Never** commit keys to version control. Add them to `.gitignore`:

```
# .gitignore
**/*.pem
**/*.key
**/FutuOpenD.xml
**/.rsa*
```

- Use separate keys per environment (dev vs. prod) if possible.
- Rotate keys periodically via the [Futu OpenAPI dashboard](https://www.futunn.com/en/OpenAPI).

### FutuOpenD.xml

- Treat this file like a secret — it contains account IDs and credential references.
- Use Docker Secrets or a secrets manager (Vault, AWS Secrets Manager) in production.
- Set file permissions: `chmod 600 FutuOpenD.xml`.

## Network Security

### Local-Only Binding (Default)

By default FutuOpenD binds to `127.0.0.1`. This is safe because only local processes can connect:

```xml
<IP>127.0.0.1</IP>
<Port>11111</Port>
```

### Remote Access with TLS

If you must expose FutuOpenD over a network:

1. **Bind to `0.0.0.0`** only with SSL enabled.
2. Generate a TLS certificate and configure it in `FutuOpenD.xml`:

```xml
<WSCert>/run/secrets/cert.pem</WSCert>
<WSKey>/run/secrets/key_nopass.pem</WSKey>
```

3. Use a VPN (WireGuard, Tailscale) or SSH tunnel instead of exposing raw ports when possible.
4. Restrict firewall rules to known client IPs only.

### Firewall Rules

```bash
# Allow only your client subnet
iptables -A INPUT -p tcp --dport 11111 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 11111 -j DROP
```

Or use Docker's network isolation:

```yaml
services:
  futuopend:
    networks:
      - futu-network
    # Don't use host networking in untrusted environments

networks:
  futu-network:
    internal: true  # No external access
```

## Docker Security

### Run as Non-Root

The base image runs as root. Create a dedicated user:

```dockerfile
RUN useradd -m -u 1000 futuopend
USER futuopend
```

> **Current limitation:** The Dockerfile does not yet enforce this. See [CONTRIBUTING.md](CONTRIBUTING.md) if you'd like to contribute this fix.

### Read-Only Secrets

Mount secrets as read-only volumes:

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

### Container Hardening

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

## Secrets Management

### Docker Secrets (Swarm Mode)

```yaml
secrets:
  rsa-key:
    file: ./secrets/rsa_key.txt
  config:
    file: ./FutuOpenD.xml
```

### External Secrets Manager

For production at scale, integrate a secrets manager:

- **HashiCorp Vault** — Inject secrets at runtime via Vault Agent sidecar
- **AWS Secrets Manager** — Use `v3-labs/aws-secrets-manager-sidecar` or similar
- **Azure Key Vault** — Use the akv-sidecar sidecar container

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

## Monitoring & Audit

- Enable `LogLevel>debug</LogLevel>` during initial setup. Switch to `info` once stable.
- Ship logs to a central logging system (ELK, Loki, CloudWatch) for audit trails.
- Set up alerts on authentication failures or unusual trading activity.
- Monitor container resource usage — unexpected spikes may indicate compromise.

## Dependency Security

- Regularly rebuild the Docker image to pull the latest OS security patches:

```bash
docker build --no-cache -t futuopend:latest .
```

- Pin the FutuOpenD version in production. Automatic upgrades can introduce breaking changes.

## Security Checklist

- [ ] RSA private key has no password and correct file permissions (`chmod 600`)
- [ ] `FutuOpenD.xml` is not committed to version control
- [ ] Remote access uses TLS (certificate + key configured)
- [ ] Firewall restricts port `11111` to known IPs
- [ ] Container runs with `--read-only` and `cap_drop: ALL`
- [ ] Logs are reviewed for authentication failures
- [ ] FutuOpenD version is pinned and up-to-date

---

*This project is an unofficial community packaging and is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
