# FutuOpenD.xml Configuration Reference

This is the definitive reference for every `FutuOpenD.xml` setting, extracted from the official FutuOpenD v10.2.6208 release.

> **Quick start?** Copy [`FutuOpenD.xml.template`](../FutuOpenD.xml.template) from the repo root — it has every setting documented inline with sensible defaults and env-var substitution.

The official XML uses **lowercase tag names** (e.g. `<ip>`, not `<IP>`). The root element is `<futu_opend>`.

---

## Minimal Working Example

```xml
<?xml version="1.0" encoding="utf-8"?>
<futu_opend>
  <!-- TCP API -->
  <ip>127.0.0.1</ip>
  <api_port>11111</api_port>

  <!-- Account -->
  <login_account>your_account_id</login_account>
  <login_pwd_md5>5f4dcc3b5aa765d61d8327deb882cf99</login_pwd_md5>
  <rsa_private_key>/run/secrets/rsa_key.txt</rsa_private_key>

  <!-- Defaults -->
  <lang>en</lang>
  <log_level>info</log_level>
  <pdt_protection>1</pdt_protection>
  <dtcall_confirmation>1</dtcall_confirmation>
</futu_opend>
```

Everything below is additive — copy only what you need.

---

## Account & Authentication

### `<login_account>`

Your Futu account identifier. Can be:
- **Account ID** (牛牛号) — found in the app under Settings
- **Phone number** — format: `+86 13800138000`
- **Email address**

```xml
<login_account>12345678</login_account>
```

### `<login_pwd_md5>` — *(recommended)*

Login password as a 32-character lowercase MD5 hex string. Either this OR `<login_pwd>` is required; MD5 is strongly preferred so your plaintext password never touches the config file.

Generate the hash:

```bash
# Linux
echo -n "your_password" | md5sum | cut -d' ' -f1

# macOS
echo -n "your_password" | md5 -r

# Python (works everywhere)
python3 -c "import hashlib; print(hashlib.md5(b'your_password').hexdigest())"
```

> The `-n` flag is critical — it suppresses the trailing newline that would otherwise corrupt the hash.

### `<login_pwd>`

Plain-text login password. Only used if `<login_pwd_md5>` is absent. **Do not use in production.**

```xml
<!-- Only use this for quick local testing -->
<login_pwd>hunter2</login_pwd>
```

### `<rsa_private_key>`

Path to your RSA private key file. Required for trading when `<ip>` is not `127.0.0.1`.

**Generate a key pair:**
1. Visit [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI) → **Manage Key**
2. Generate a new key pair and download the private key
3. Store it somewhere safe (`chmod 600` on Linux/macOS)

```xml
<rsa_private_key>/run/secrets/rsa_key.txt</rsa_private_key>
```

---

## Network & Protocol

### `<ip>` — TCP API bind address

| Value | Behaviour |
|-------|-----------|
| `127.0.0.1` | Local connections only (default) |
| `0.0.0.0` | All network interfaces — **use this for remote access** |

```xml
<!-- For a local dev setup -->
<ip>127.0.0.1</ip>

<!-- For a cloud server or remote access -->
<ip>0.0.0.0</ip>
```

> **Security:** If you set `<ip>0.0.0.0</ip>`, you **must** also set `<rsa_private_key>`. Trading API calls will be rejected without it. Quote APIs work without encryption.

### `<api_port>` — TCP API port

Default: `11111`. Change if you have a port conflict.

```xml
<api_port>11111</api_port>
```

### `<websocket_ip>` / `<websocket_port>` — WebSocket API

WebSocket is the recommended protocol for JavaScript clients and web frontends. Leave `<websocket_port>` unset to disable.

```xml
<!-- Bind to all interfaces -->
<websocket_ip>0.0.0.0</websocket_ip>

<!-- Enable on port 33333 -->
<websocket_port>33333</websocket_port>
```

### `<websocket_key_md5>`

WebSocket authentication key — a 32-bit MD5 hex string used by JavaScript clients to authenticate. If unset, any client can connect (subject to `<rsa_private_key>` rules).

```xml
<!-- Generate with: echo -n "your_secret_key" | md5sum | cut -d' ' -f1 -->
<websocket_key_md5>14e1b600b1fd579f47433b88e8d85291</websocket_key_md5>
```

### `<websocket_private_key>` / `<websocket_cert>` — SSL/TLS

Required when `<websocket_ip>` is `0.0.0.0` and you want encrypted connections. Both must be set together.

```bash
# Generate a self-signed cert (fine for testing)
openssl req -x509 -newkey rsa:4096 \
  -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=futuopend"

# Strip password from the key — FutuOpenD doesn't support encrypted keys
openssl rsa -in key.pem -out key_nopass.pem
```

```xml
<websocket_private_key>/run/secrets/ws_key.pem</websocket_private_key>
<websocket_cert>/run/secrets/ws_cert.pem</websocket_cert>
```

---

## Behaviour & Tuning

### `<log_level>`

| Value | Use case |
|-------|----------|
| `debug` | Initial setup, debugging connection issues |
| `info` | Normal operation (default) |
| `warning` | Reduced verbosity |
| `error` | Production, quiet |
| `fatal` | Only fatal errors |
| `no` | Logging off — **don't use during setup** |

```xml
<log_level>info</log_level>
```

### `<log_path>`

Custom log directory. Leave unset to use FutuOpenD's default.

```xml
<!-- <log_path>/var/log/futuopend</log_path> -->
```

### `<push_proto_type>`

API push protocol format for subscription data:

| Value | Format |
|-------|--------|
| `0` | Protocol Buffers (default, more compact) |
| `1` | JSON (human-readable) |

```xml
<push_proto_type>0</push_proto_type>
```

### `<qot_push_frequency>`

Throttle subscription push frequency in milliseconds. Does not affect K-line or time-frame pushes. Leave unset for unlimited.

```xml
<!-- Cap at 1 push per second per subscription -->
<qot_push_frequency>1000</qot_push_frequency>
```

### `<price_reminder_push>`

Receive price alert notifications pushed from the server.

| Value | Behaviour |
|-------|-----------|
| `1` | Receive price reminders (default) |
| `0` | Ignore |

```xml
<price_reminder_push>1</price_reminder_push>
```

### `<auto_hold_quote_right>`

Auto-grab the highest quote right if another terminal kicks you off. FutuOpenD retries for 10 seconds after being kicked.

| Value | Behaviour |
|-------|-----------|
| `1` | Auto-reclaim quote rights (default) |
| `0` | Manual re-login required |

```xml
<auto_hold_quote_right>1</auto_hold_quote_right>
```

### `<telnet_ip>` / `<telnet_port>`

Enable the telnet debug interface. Bind to `127.0.0.1` unless you're on a trusted network.

```xml
<telnet_ip>127.0.0.1</telnet_ip>
<telnet_port>22222</telnet_port>
```

> **Warning:** Telnet sends everything in plaintext. Never expose it to untrusted networks.

---

## Language & Locale

### `<lang>`

| Value | Language |
|-------|----------|
| `en` | English |
| `chs` | Simplified Chinese |

```xml
<lang>en</lang>
```

### `<future_trade_api_time_zone>`

Required for futures trading. Sets the time zone for all timestamps in futures API responses and order management.

```xml
<!-- Examples -->
<future_trade_api_time_zone>UTC+8</future_trade_api_time_zone>   <!-- Hong Kong, Singapore -->
<future_trade_api_time_zone>UTC+9</future_trade_api_time_zone>   <!-- Japan -->
<future_trade_api_time_zone>UTC+11</future_trade_api_time_zone>   <!-- Sydney (AEST) -->
<future_trade_api_time_zone>UTC-5</future_trade_api_time_zone>   <!-- New York (EST) -->
<future_trade_api_time_zone>UTC-6</future_trade_api_time_zone>   <!-- Chicago (CST) -->
```

---

## US Market Protections *(Futu US / moomoo US only)*

### `<pdt_protection>`

**Pattern Day Trade Protection** — blocks orders that would trigger PDT status.

| Value | Behaviour |
|-------|-----------|
| `1` | Active (recommended) |
| `0` | Disabled |

When enabled, FutuOpenD prevents orders that would mark your account as a Pattern Day Trader. Note: this reduces but does not eliminate PDT risk. If your equity falls below $25,000 and you're flagged as a PDT, you cannot open new positions until you deposit funds.

```xml
<pdt_protection>1</pdt_protection>
```

### `<dtcall_confirmation>`

**Day-Trading Call Warning** — blocks orders that would exhaust your day-trading buying power.

| Value | Behaviour |
|-------|-----------|
| `1` | Active (recommended) |
| `0` | Disabled |

When enabled, FutuOpenD blocks orders that exceed your remaining DT buying power. If triggered, the Day-Trading Call can only be cleared by depositing funds in the full call amount.

```xml
<dtcall_confirmation>1</dtcall_confirmation>
```

---

## Environment Variable Substitution

FutuOpenD resolves `${VAR_NAME}` in the XML at startup — Docker passes them in without touching the file.

```xml
<login_account>${FUTU_ACCOUNT}</login_account>
<login_pwd_md5>${FUTU_PWD_MD5}</login_pwd_md5>
<rsa_private_key>${FUTU_RSA_KEY}</rsa_private_key>
<ip>${FUTU_IP:-127.0.0.1}</ip>
<log_level>${FUTU_LOG_LEVEL:-info}</log_level>
```

Pass values in `docker-compose.yaml`:

```yaml
services:
  futuopend:
    environment:
      FUTU_ACCOUNT: "12345678"
      FUTU_PWD_MD5: "5f4dcc3b5aa765d61d8327deb882cf99"
      FUTU_RSA_KEY: "/run/secrets/rsa_key.txt"
      FUTU_IP: "0.0.0.0"
      FUTU_LOG_LEVEL: "debug"
```

Or on the command line:

```bash
docker run -e FUTU_ACCOUNT=12345678 \
           -e FUTU_PWD_MD5="$(echo -n 'mypassword' | md5sum | cut -d' ' -f1)" \
           -e FUTU_RSA_KEY=/run/secrets/rsa_key.txt \
           shing1211/futuopend:latest
```

> **Note:** FutuOpenD performs the substitution, not Docker. The env vars must be present in the container's environment — mounting a file alone is not enough.

### Supported variables

| Variable | Maps to | Default |
|----------|---------|---------|
| `FUTU_ACCOUNT` | `<login_account>` | _(required)_ |
| `FUTU_PWD_MD5` | `<login_pwd_md5>` | _(required)_ |
| `FUTU_RSA_KEY` | `<rsa_private_key>` | _(required for trading)_ |
| `FUTU_IP` | `<ip>` | `127.0.0.1` |
| `FUTU_API_PORT` | `<api_port>` | `11111` |
| `FUTU_WS_PORT` | `<websocket_port>` | _(unset)_ |
| `FUTU_LOG_LEVEL` | `<log_level>` | `info` |
| `FUTU_LANG` | `<lang>` | `en` |
| `FUTU_PUSH_PROTO` | `<push_proto_type>` | `0` (protobuf) |

---

## First-Time Login: Phone Verification in Docker

FutuOpenD requires **phone verification** on first login — especially for new accounts, fresh device installs, or accounts logging in from a new IP. The app sends an SMS code, which you must relay to FutuOpenD via its Telnet interface.

### How it works

1. FutuOpenD starts, connects to Futu's server, and requests a login
2. Futu detects a new device/IP and sends an SMS verification code to the account's registered phone
3. FutuOpenD blocks login and waits for the code
4. You send the code via Telnet → FutuOpenD validates → login completes

### Step 1 — Enable Telnet in FutuOpenD.xml

Add these lines to your config:

```xml
<telnet_ip>127.0.0.1</telnet_ip>
<telnet_port>22222</telnet_port>
```

In your `FutuOpenD.xml.template`, uncomment and set:

```xml
<!-- <telnet_ip>127.0.0.1</telnet_ip> -->
<!-- <telnet_port>22222</telnet_port> -->
```

Or pass via Docker environment (if supported by your version):

```bash
docker run -e FUTU_TELNET_IP=127.0.0.1 -e FUTU_TELNET_PORT=22222 ...
```

### Step 2 — Map Telnet port to the host

In `docker-compose.yaml`, expose the Telnet port:

```yaml
services:
  futuopend:
    ports:
      - "11111:11111"   # TCP API
      - "11112:11112"   # WebSocket
      - "22222:22222"   # Telnet  ← add this
```

### Step 3 — Watch for the verification prompt

Start the container and tail the logs:

```bash
docker compose up -d
docker compose logs -f futuopend
```

When the phone verification is needed, you'll see something like this in the logs:

```
[INFO] Waiting for phone verify code, please input by telnet...
[INFO] Use command: input_phone_verify_code -code=123456
```

### Step 4 — Submit the code via Telnet

Send the code from your **host machine** (not inside the container):

```bash
# Linux / macOS
echo "input_phone_verify_code -code=123456" | nc 127.0.0.1 22222

# Or using telnet (type the command manually, then press Enter twice)
telnet 127.0.0.1 22222
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
input_phone_verify_code -code=123456

# Or with Python
python3 -c "import telnetlib; t=telnetlib.Telnet('127.0.0.1', 22222); t.write(b'input_phone_verify_code -code=123456\r\n'); print(t.read_all())"
```

> **Note:** There is a **space** before `-code=`. The full command is: `input_phone_verify_code -code=123456`

### Step 5 — Verify login succeeded

Check the logs again:

```bash
docker compose logs futuopend | grep -i "login\|verify\|success\|connected"
```

If successful, you'll see something like:

```
[INFO] Login succeeded. Account: 12345678
```

### Troubleshooting

| Problem | Fix |
|---------|-----|
| `nc` / `telnet` not found on host | `apt install netcat-openbsd` or `brew install netcat` |
| Connection refused on port 22222 | Check `telnet_ip` and `telnet_port` are set in `FutuOpenD.xml` |
| Code rejected | SMS codes expire after ~5 minutes — request a new one via the Futu app |
| Code already used | Each code can only be used once; request a fresh code |
| Can't receive SMS | Make sure the Futu account has a verified phone number; try resending via the app |

### Automation tip

If you're running CI/CD or need to automate the flow, wrap the Telnet step:

```bash
#!/bin/bash
# wait-for-phone-code.sh — blocks until FutuOpenD is logged in

HOST="${1:-127.0.0.1}"
PORT="${2:-22222}"
CODE="${3:-}"

until docker compose logs futuopend 2>&1 | grep -q "Waiting for phone verify code"; do
    sleep 2
done

if [[ -n "$CODE" ]]; then
    echo "input_phone_verify_code -code=$CODE" | nc "$HOST" "$PORT"
    echo "Code submitted."
else
    echo "Phone verification required. Check your SMS and run:"
    echo "  echo \"input_phone_verify_code -code=XXXXXX\" | nc $HOST $PORT"
    exit 1
fi
```

---

## Complete Config Example

```xml
<?xml version="1.0" encoding="utf-8"?>
<futu_opend>
  <!-- Bind to all interfaces for remote access -->
  <ip>0.0.0.0</ip>
  <api_port>11111</api_port>

  <!-- WebSocket on 33333 -->
  <websocket_ip>0.0.0.0</websocket_ip>
  <websocket_port>33333</websocket_port>

  <!-- Account -->
  <login_account>${FUTU_ACCOUNT}</login_account>
  <login_pwd_md5>${FUTU_PWD_MD5}</login_pwd_md5>
  <rsa_private_key>${FUTU_RSA_KEY}</rsa_private_key>

  <!-- Logging -->
  <lang>en</lang>
  <log_level>info</log_level>

  <!-- SSL (uncomment for WSS) -->
  <!-- <websocket_private_key>/run/secrets/ws_key.pem</websocket_private_key> -->
  <!-- <websocket_cert>/run/secrets/ws_cert.pem</websocket_cert> -->

  <!-- US market protections -->
  <pdt_protection>1</pdt_protection>
  <dtcall_confirmation>1</dtcall_confirmation>
</futu_opend>
```

---

*This project is an unofficial community packaging and is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
