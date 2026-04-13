# FutuOpenD.xml Configuration Reference

This page is a detailed reference for every `FutuOpenD.xml` setting. If the Quick Start in the README got you up and running, this is where you come to understand the knobs.

> **Prefer a head start?** Copy [`FutuOpenD.xml.template`](../FutuOpenD.xml.template) from the repo root — it has every setting documented inline with sensible defaults.

---

## Minimal Working Example

```xml
<?xml version="1.0" encoding="utf-8"?>
<FutuOpenD>
  <AccList>
    <Account>
      <AccID>your_account_id</AccID>
      <PwdMD5>your_password_md5</PwdMD5>
      <PrivateKey>/run/secrets/rsa_key.txt</PrivateKey>
    </Account>
  </AccList>
  <Config>
    <IP>0.0.0.0</IP>
    <Port>11111</Port>
    <WSIP>0.0.0.0</WSIP>
    <WSPort>11112</WSPort>
    <LogLevel>info</LogLevel>
    <Language>zh-CN</Language>
  </Config>
</FutuOpenD>
```

Everything below is additive — copy only what you need.

---

## Account Section (`<AccList>`)

| Element | Required | Description |
|---------|----------|-------------|
| `AccID` | Yes | Your Futu account ID (牛牛号). |
| `PwdMD5` | Yes | MD5 hash of your password — 32-char lowercase hex string. |
| `PrivateKey` | For trading | Absolute path to your RSA private key file. Quote APIs work without it; trading APIs do not. |

### Generating MD5 Password

```bash
# Linux
echo -n "your_password" | md5sum | cut -d' ' -f1

# macOS
echo -n "your_password" | md5 -r

# Python (works everywhere)
python3 -c "import hashlib; print(hashlib.md5(b'your_password').hexdigest())"
```

The `-n` flag matters — you want the hash of the string itself, not the string plus a trailing newline.

### RSA Key Pair

1. Go to [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI).
2. Navigate to **Manage Key** and generate a new key pair.
3. Download the private key — store it somewhere safe, like your secrets directory.
4. Point `PrivateKey` at it in `FutuOpenD.xml`.

---

## Network Section (`<Config>`)

### Basic Connection

| Element | Default | Description |
|---------|---------|-------------|
| `IP` | `127.0.0.1` | TCP API bind address. Use `0.0.0.0` to accept connections from any interface. |
| `Port` | `11111` | TCP API port. |
| `WSIP` | `127.0.0.1` | WebSocket API bind address. |
| `WSPort` | `11112` | WebSocket API port. |
| `LogLevel` | `info` | Verbosity: `debug`, `info`, `warn`, `error`, `fatal`, `off`. |
| `Language` | `zh-CN` | UI/API language: `zh-CN`, `zh-HK`, `en`. |

**Log level recommendations:** Use `debug` during initial setup — the verbose output is invaluable for tracking down connection issues. Switch to `info` once things are stable. Never use `off` early on; logs are your primary debugging tool.

### Remote Access (Cloud Deployment)

If FutuOpenD runs on a cloud VM and you connect from your local machine:

```xml
<Config>
  <IP>0.0.0.0</IP>
  <WSIP>0.0.0.0</WSIP>
  <LogLevel>info</LogLevel>
</Config>
```

> **Warning:** Binding to `0.0.0.0` exposes the API to your network. You **must** use an RSA private key to authenticate trading requests. Without it, the trading APIs are blocked. Quote APIs are unrestricted.

### SSL / TLS (WebSocket)

For encrypted connections over the public internet, add a certificate:

```bash
# Generate a self-signed certificate (fine for testing)
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=your-server-hostname"

# Strip the password from the key (FutuOpenD doesn't support encrypted keys)
openssl rsa -in key.pem -out key_nopass.pem
```

Then in `FutuOpenD.xml`:

```xml
<Config>
  <WSCert>/run/secrets/cert.pem</WSCert>
  <WSKey>/run/secrets/key_nopass.pem</WSKey>
  <WSLoginExpire>259200</WSLoginExpire>  <!-- 72 hours in seconds -->
</Config>
```

> **Important:** The private key **must have no password**. Run `openssl rsa -in key.pem -out key_nopass.pem` to strip it. If your key has a password, FutuOpenD will silently fail to start TLS.

### Rate & Push Control

| Element | Description |
|---------|-------------|
| `DataPushFreq` | Max push frequency for subscription data, in milliseconds. Prevents overwhelming slow clients. |
| `TelnetIP` | Bind address for the telnet debug interface. |
| `TelnetPort` | Port for the telnet debug interface. |

### Futures-Specific Settings

| Element | Description |
|---------|-------------|
| `FutureHKExchCode` | Hong Kong futures exchange code. |
| `FutureUSExchCode` | US futures exchange code. |
| `FutureSGTZ` | Singapore futures time zone. |
| `FutureJPTZ` | Japan futures time zone. |
| `FutureASTZ` | Australia futures time zone. |

---

## Advanced: Multiple Accounts

FutuOpenD supports multiple accounts simultaneously:

```xml
<AccList>
  <Account>
    <AccID>12345678</AccID>
    <PwdMD5>...</PwdMD5>
    <PrivateKey>/run/secrets/rsa_key_1.txt</PrivateKey>
  </Account>
  <Account>
    <AccID>87654321</AccID>
    <PwdMD5>...</PwdMD5>
    <PrivateKey>/run/secrets/rsa_key_2.txt</PrivateKey>
  </Account>
</AccList>
```

Your SDK can then target a specific account by ID when placing orders.

---

## Environment Variable Substitution

FutuOpenD can expand environment variables inside `FutuOpenD.xml` at startup. This is especially handy in Docker, where secrets are injected at runtime.

```xml
<PrivateKey>${RSA_KEY_PATH}</PrivateKey>
```

The [`FutuOpenD.xml.template`](../FutuOpenD.xml.template) in the repo root uses this throughout — no hardcoded values, no secrets committed to version control. Set the variables in `docker-compose.yaml`:

```yaml
services:
  futuopend:
    environment:
      FUTU_ACCOUNT_ID: "12345678"
      FUTU_PASSWORD_MD5: "5f4dcc3b5aa765d61d8327deb882cf99"
      RSA_KEY_PATH: /run/secrets/rsa_key.txt
      FUTU_OPEND_IP: "0.0.0.0"
      FUTU_LOG_LEVEL: "debug"
      FUTU_LANGUAGE: "en"
```

Or pass them directly on the command line:

```bash
docker run -e FUTU_ACCOUNT_ID=12345678 \
           -e FUTU_PASSWORD_MD5=$(echo -n "mypassword" | md5sum | cut -d' ' -f1) \
           -e RSA_KEY_PATH=/run/secrets/rsa_key.txt \
           shing1211/futuopend:latest
```

> **Note:** Substitution is evaluated by FutuOpenD itself, not by Docker. The variable must be present in the container's environment — mounting a file alone is not enough.

### Supported variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FUTU_ACCOUNT_ID` | Your Futu account ID (牛牛号) | _(required)_ |
| `FUTU_PASSWORD_MD5` | MD5 hash of your password | _(required)_ |
| `RSA_KEY_PATH` | Path to your RSA private key | _(required for trading)_ |
| `FUTU_OPEND_IP` | TCP API bind address | `0.0.0.0` |
| `FUTU_OPEND_PORT` | TCP API port | `11111` |
| `FUTU_WS_IP` | WebSocket bind address | `0.0.0.0` |
| `FUTU_WS_PORT` | WebSocket port | `11112` |
| `FUTU_LOG_LEVEL` | Log verbosity | `info` |
| `FUTU_LANGUAGE` | Language | `en` |
| `SSL_CERT_PATH` | SSL certificate path | _(none — omit for local)_ |
| `SSL_KEY_PATH` | SSL private key path | _(none — omit for local)_ |
| `FUTU_DATA_PUSH_FREQ` | Max push frequency (ms) | _(none — use default)_ |

---

*This project is an unofficial community packaging and is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
