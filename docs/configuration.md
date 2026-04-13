# FutuOpenD.xml Configuration Reference

Every setting available in `FutuOpenD.xml`, extracted from FutuOpenD v10.2.6208. If you're new, start with the [`FutuOpenD.xml.template`](../FutuOpenD.xml.template) in the repo root — it has sensible defaults and env-var substitution ready to go.

> **This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo.**

---

## Minimal Working Example

The smallest config that actually logs in and lets you trade:

```xml
<?xml version="1.0" encoding="utf-8"?>
<futu_opend>
  <!-- TCP API — bind locally -->
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

Everything below is additive — cherry-pick what you need.

> **Important:** FutuOpenD uses **lowercase XML tag names**. The root element is `<futu_opend>`. Tags like `<IP>` or `<Port>` (uppercase) won't be recognized.

---

## Account & Authentication

### `<login_account>`

Your Futu account identifier. Accepts three formats:

```xml
<!-- Futu account ID (牛牛号) — found in the app under Settings -->
<login_account>12345678</login_account>

<!-- Phone number — include country code -->
<login_account>+86 13800138000</login_account>

<!-- Email address -->
<login_account>you@example.com</login_account>
```

### `<login_pwd_md5>` *(strongly recommended)*

Your login password as a **32-character lowercase MD5 hex string**. Either this or `<login_pwd>` is required — use MD5 so your plaintext password never touches the disk.

Generate it:

```bash
# Linux
echo -n "your_password" | md5sum | cut -d' ' -f1

# macOS
echo -n "your_password" | md5 -r

# Python — works everywhere
python3 -c "import hashlib; print(hashlib.md5(b'your_password').hexdigest())"
```

> The `-n` is not a typo. It suppresses the trailing newline — include it or the hash will be wrong.

### `<login_pwd>`

Plain-text password. Only falls back when `<login_pwd_md5>` is absent. **Do not use in production.**

```xml
<!-- Quick local testing only — seriously, don't ship this -->
<login_pwd>hunter2</login_pwd>
```

### `<rsa_private_key>`

Path to your RSA private key file. Required for trading when `<ip>` is anything other than `127.0.0.1`.

**How to get one:**
1. Head to the [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI) → **Manage Key**
2. Generate a key pair and download the private key
3. Store it somewhere safe, then `chmod 600` it

```xml
<rsa_private_key>/run/secrets/rsa_key.txt</rsa_private_key>
```

---

## Network & Protocol

### `<ip>` — TCP API bind address

Controls which network interfaces FutuOpenD listens on.

| Value | What it means |
|-------|---------------|
| `127.0.0.1` | Local connections only (default, safest) |
| `0.0.0.0` | All interfaces — **use this for remote access** |

```xml
<!-- Local dev — only processes on this machine can connect -->
<ip>127.0.0.1</ip>

<!-- Cloud server or remote SDK — any network interface -->
<ip>0.0.0.0</ip>
```

> **Security:** If you set `<ip>0.0.0.0</ip>`, you **must** also set `<rsa_private_key>`. Trading API calls will be rejected without it. Quote-only access works without encryption.

### `<api_port>` — TCP API port

Default: `11111`. Only change this if something else is already on that port.

```xml
<api_port>11111</api_port>
```

### `<websocket_ip>` / `<websocket_port>` — WebSocket API

WebSocket is the go-to for JavaScript clients and web frontends. Leave `<websocket_port>` unset to disable.

```xml
<!-- Bind to all interfaces -->
<websocket_ip>0.0.0.0</websocket_ip>

<!-- Enable on port 11112 -->
<websocket_port>11112</websocket_port>
```

### `<websocket_key_md5>`

An MD5 hex string that WebSocket clients use to authenticate. If unset, any client can connect (subject to RSA rules for trading calls).

```xml
<!-- Generate with: echo -n "your_secret_key" | md5sum | cut -d' ' -f1 -->
<websocket_key_md5>14e1b600b1fd579f47433b88e8d85291</websocket_key_md5>
```

### `<websocket_private_key>` / `<websocket_cert>` — TLS/SSL

Both must be set together to enable WSS. Required when exposing WebSocket over an untrusted network.

Generate a self-signed cert (fine for testing, not for production):

```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=futuopend"

# Strip the password — FutuOpenD doesn't support encrypted keys
openssl rsa -in key.pem -out key_nopass.pem
```

```xml
<websocket_private_key>/run/secrets/ws_key_nopass.pem</websocket_private_key>
<websocket_cert>/run/secrets/ws_cert.pem</websocket_cert>
```

---

## Behaviour & Tuning

### `<log_level>`

Controls how chatty the logs are.

| Value | Use when |
|-------|----------|
| `debug` | First setup, debugging connection issues |
| `info` | Normal day-to-day running (default) |
| `warning` | You want less noise |
| `error` | Production, keep it quiet |
| `fatal` | Only catastrophic failures |
| `no` | Logging off entirely — don't use during setup |

```xml
<log_level>info</log_level>
```

### `<log_path>`

Custom log directory. Leave unset to use FutuOpenD's default.

```xml
<!-- <log_path>/var/log/futuopend</log_path> -->
```

### `<push_proto_type>`

Format for pushed subscription data.

| Value | Format | Best for |
|-------|--------|----------|
| `0` | Protocol Buffers | Production (compact, fast) |
| `1` | JSON | Debugging (human-readable) |

```xml
<push_proto_type>0</push_proto_type>
```

### `<qot_push_frequency>`

Cap how often FutuOpenD pushes quote updates, in milliseconds per subscription. Does not affect K-line or time-frame pushes. Leave unset for unlimited.

```xml
<!-- One push per second per subscription — reduces bandwidth -->
<qot_push_frequency>1000</qot_push_frequency>
```

### `<price_reminder_push>`

Receive price alert notifications pushed from Futu's server.

| Value | Behaviour |
|-------|-----------|
| `1` | Receive price reminders (default) |
| `0` | Ignore them |

```xml
<price_reminder_push>1</price_reminder_push>
```

### `<auto_hold_quote_right>`

If another terminal kicks you off your quote rights, should FutuOpenD automatically try to reclaim them for 10 seconds?

| Value | Behaviour |
|-------|-----------|
| `1` | Auto-reclaim (default) |
| `0` | You manually re-login |

```xml
<auto_hold_quote_right>1</auto_hold_quote_right>
```

### `<telnet_ip>` / `<telnet_port>`

Enable the Telnet debug console. Useful for phone verification and live debugging. Bind to `127.0.0.1` unless you're on a trusted network.

```xml
<telnet_ip>127.0.0.1</telnet_ip>
<telnet_port>22222</telnet_port>
```

> **Warning:** Telnet is plaintext. Never expose port `22222` to untrusted networks.

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
<future_trade_api_time_zone>UTC+8</future_trade_api_time_zone>    <!-- Hong Kong, Singapore -->
<future_trade_api_time_zone>UTC+9</future_trade_api_time_zone>    <!-- Japan -->
<future_trade_api_time_zone>UTC+11</future_trade_api_time_zone>  <!-- Sydney (AEST) -->
<future_trade_api_time_zone>UTC-5</future_trade_api_time_zone>    <!-- New York (EST) -->
<future_trade_api_time_zone>UTC-6</future_trade_api_time_zone>    <!-- Chicago (CST) -->
```

---

## US Market Protections

> Applicable only to Futu US / moomoo US accounts.

### `<pdt_protection>`

**Pattern Day Trade Protection** — blocks orders that would trigger PDT status.

| Value | Behaviour |
|-------|-----------|
| `1` | Active (recommended) |
| `0` | Disabled |

PDT protection helps, but doesn't eliminate risk. If your equity drops below $25,000 and you're flagged as a PDT, you can't open new positions until you deposit funds.

```xml
<pdt_protection>1</pdt_protection>
```

### `<dtcall_confirmation>`

**Day-Trading Call Warning** — blocks orders that would exhaust your DT buying power.

| Value | Behaviour |
|-------|-----------|
| `1` | Active (recommended) |
| `0` | Disabled |

If triggered, the Day-Trading Call can only be cleared by depositing the full call amount.

```xml
<dtcall_confirmation>1</dtcall_confirmation>
```

---

## Environment Variable Substitution

FutuOpenD resolves `${VAR_NAME}` patterns in the XML at startup. Docker passes these in automatically — no file rewriting required.

```xml
<login_account>${FUTU_ACCOUNT}</login_account>
<login_pwd_md5>${FUTU_PWD_MD5}</login_pwd_md5>
<rsa_private_key>${FUTU_RSA_KEY}</rsa_private_key>
<ip>${FUTU_IP:-127.0.0.1}</ip>
<log_level>${FUTU_LOG_LEVEL:-info}</log_level>
```

The `:-default` syntax works too — FutuOpenD handles it.

**Pass values via Docker Compose:**

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

**Or on the command line:**

```bash
docker run \
  -e FUTU_ACCOUNT=12345678 \
  -e FUTU_PWD_MD5="$(echo -n 'mypassword' | md5sum | cut -d' ' -f1)" \
  -e FUTU_RSA_KEY=/run/secrets/rsa_key.txt \
  shing1211/futuopend:latest
```

> **Note:** FutuOpenD performs the substitution, not Docker. Env vars must be present in the container's environment — mounting a file alone isn't enough.

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

On first login — especially from a new IP or device — Futu sends an SMS verification code. Since you have no GUI here, you relay it through the Telnet debug interface. It sounds scarier than it is.

### How it works

1. FutuOpenD starts and attempts to log in
2. Futu's server detects a new device/IP and texts a code to your registered phone
3. FutuOpenD blocks login and waits for your input
4. You send the code via Telnet → FutuOpenD validates → you're in

### Step 1 — Enable Telnet

Add these to your `FutuOpenD.xml`:

```xml
<telnet_ip>127.0.0.1</telnet_ip>
<telnet_port>22222</telnet_port>
```

Or in the template, just uncomment the existing lines.

### Step 2 — Expose the Telnet port

In `docker-compose.yaml`, make sure the Telnet port is mapped:

```yaml
services:
  futuopend:
    ports:
      - "11111:11111"   # TCP API
      - "11112:11112"   # WebSocket
      - "22222:22222"   # Telnet  ← this one
```

### Step 3 — Start and watch for the prompt

```bash
docker compose up -d
docker compose logs -f futuopend
```

When phone verification is needed, you'll see something like:

```
[INFO] Waiting for phone verify code, please input by telnet...
[INFO] Use command: input_phone_verify_code -code=123456
```

### Step 4 — Submit the code from your host

Run this **on your host machine** (not inside the container):

```bash
# Linux / macOS — the simplest way
echo "input_phone_verify_code -code=123456" | nc 127.0.0.1 22222

# With telnet — type the command, then press Enter twice
telnet 127.0.0.1 22222
input_phone_verify_code -code=123456

# Python — useful for scripting
python3 -c "
import telnetlib
t = telnetlib.Telnet('127.0.0.1', 22222)
t.write(b'input_phone_verify_code -code=123456\r\n')
print(t.read_all().decode())
"
```

> **Watch the space.** The command is `input_phone_verify_code -code=123456` — there's a space before `-code=`.

### Step 5 — Verify success

```bash
docker compose logs futuopend | grep -i "login\|verify\|success"
```

Look for:
```
[INFO] Login succeeded. Account: 12345678
```

### Troubleshooting

| Problem | Fix |
|---------|-----|
| `nc` / `telnet` not found | `apt install netcat-openbsd` or `brew install netcat` |
| Connection refused on 22222 | Check `telnet_ip` and `telnet_port` are set in `FutuOpenD.xml` |
| Code rejected | Codes expire after ~5 minutes — request a new one via the Futu app |
| Code already used | Each code is single-use; request a fresh one |
| No SMS received | Make sure your account has a verified phone number |

### Automating it

If you're running in CI or need to script the flow:

```bash
#!/bin/bash
# wait-for-phone-code.sh — blocks until FutuOpenD is logged in
# Usage: ./wait-for-phone-code.sh [host] [port] [code]

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
    echo "Phone verification required. SMS received? Run:"
    echo "  echo \"input_phone_verify_code -code=XXXXXX\" | nc $HOST $PORT"
    exit 1
fi
```

---

## Complete Config Example

```xml
<?xml version="1.0" encoding="utf-8"?>
<futu_opend>
  <!-- Remote access: bind to all interfaces -->
  <ip>0.0.0.0</ip>
  <api_port>11111</api_port>

  <!-- WebSocket on 11112 -->
  <websocket_ip>0.0.0.0</websocket_ip>
  <websocket_port>11112</websocket_port>

  <!-- Account — use env vars so secrets stay out of the file -->
  <login_account>${FUTU_ACCOUNT}</login_account>
  <login_pwd_md5>${FUTU_PWD_MD5}</login_pwd_md5>
  <rsa_private_key>${FUTU_RSA_KEY}</rsa_private_key>

  <!-- Behaviour -->
  <lang>en</lang>
  <log_level>info</log_level>
  <push_proto_type>0</push_proto_type>

  <!-- US market guards -->
  <pdt_protection>1</pdt_protection>
  <dtcall_confirmation>1</dtcall_confirmation>

  <!-- Uncomment for WSS (TLS) -->
  <!-- <websocket_private_key>/run/secrets/ws_key_nopass.pem</websocket_private_key> -->
  <!-- <websocket_cert>/run/secrets/ws_cert.pem</websocket_cert> -->

  <!-- Uncomment to enable Telnet debug console -->
  <!-- <telnet_ip>127.0.0.1</telnet_ip> -->
  <!-- <telnet_port>22222</telnet_port> -->
</futu_opend>
```

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
