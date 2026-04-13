# Configuration Reference

This page documents all `FutuOpenD.xml` settings in detail.

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

## Account Section (`<AccList>`)

| Element | Required | Description |
|---------|----------|-------------|
| `AccID` | Yes | Your Futu account (牛牛号). |
| `PwdMD5` | Yes | MD5 hash of your password (32-char lowercase hex). |
| `PrivateKey` | For trading | Absolute path to your RSA private key file. |

### Generating MD5 Password

```bash
# Linux / macOS
echo -n "your_password" | md5sum | cut -d' ' -f1
echo -n "your_password" | md5 -r        # macOS

# Python
python3 -c "import hashlib; print(hashlib.md5(b'your_password').hexdigest())"
```

### RSA Key Generation

1. Go to the [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI).
2. Navigate to **Manage Key** and generate a new key pair.
3. Download and store the private key file securely.

## Network Section (`<Config>`)

### Basic Connection

| Element | Default | Description |
|---------|---------|-------------|
| `IP` | `127.0.0.1` | TCP API bind address. Use `0.0.0.0` to accept connections from any interface. |
| `Port` | `11111` | TCP API port. |
| `WSIP` | `127.0.0.1` | WebSocket API bind address. |
| `WSPort` | `11112` | WebSocket API port. |
| `LogLevel` | `info` | Verbosity: `debug`, `info`, `warn`, `error`, `fatal`, `off`. |
| `Language` | `zh-CN` | UI language: `zh-CN`, `zh-HK`, `en`. |

### Logging Recommendations

During development, use `LogLevel>debug</LogLevel>` to capture all traffic. In production, switch to `info` to reduce disk usage. Never set `off` during initial setup — logs are the primary debugging tool.

### Remote Access (Cloud Deployment)

If FutuOpenD runs on a cloud VM and you connect from a different machine:

```xml
<Config>
  <IP>0.0.0.0</IP>        <!-- Accept all interfaces -->
  <WSIP>0.0.0.0</WSIP>   <!-- Accept all interfaces -->
  <LogLevel>info</LogLevel>
</Config>
```

> **Warning:** When binding to `0.0.0.0`, you **must** use an RSA private key to authenticate trading requests. Without it, trading APIs will be blocked. Quote APIs are unrestricted.

### SSL / TLS (WebSocket)

For encrypted remote connections, generate a self-signed or CA-signed certificate:

```bash
# Generate a self-signed certificate (for testing)
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=your-server-hostname"

# Convert to Futu's expected format (no password on key)
openssl rsa -in key.pem -out key_nopass.pem
```

Then in `FutuOpenD.xml`:

```xml
<Config>
  <WSCert>/run/secrets/cert.pem</WSCert>
  <WSKey>/run/secrets/key_nopass.pem</WSKey>
  <WSLoginExpire>259200</WSLoginExpire>  <!-- 72 hours -->
</Config>
```

> **Important:** The private key must have **no password**. Use `openssl rsa -in key.pem -out key_nopass.pem` to strip it.

### Rate & Push Control

| Element | Description |
|---------|-------------|
| `DataPushFreq` | Max push frequency for subscription data, in milliseconds. Setting this prevents overwhelming clients on slow connections. |
| `TelnetIP` | Bind address for the telnet debug interface. |
| `TelnetPort` | Port for the telnet debug interface. |

### Futures-Specific

| Element | Description |
|---------|-------------|
| `FutureHKExchCode` | Hong Kong futures exchange code (for HK futures accounts). |
| `FutureUSExchCode` | US futures exchange code. |
| `FutureSGTZ` | Singapore futures time zone. |
| `FutureJPTZ` | Japan futures time zone. |
| `FutureASTZ` | Australia futures time zone. |

## Advanced: Multiple Accounts

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

## Environment Variable Substitution

Paths in `FutuOpenD.xml` can reference environment variables using `${VAR_NAME}` syntax. This is useful in Docker environments:

```xml
<PrivateKey>${RSA_KEY_PATH}</PrivateKey>
```

Set the variable in `docker-compose.yaml`:

```yaml
environment:
  RSA_KEY_PATH: /run/secrets/rsa_key.txt
```

Or pass it directly when starting the container:

```bash
docker run -e RSA_KEY_PATH=/run/secrets/rsa_key.txt ...
```

> **Note:** Variable substitution is evaluated by FutuOpenD at startup, not by Docker. Ensure the variable is exported in the container's environment.

---

*This project is an unofficial community packaging and is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
