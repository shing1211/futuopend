# FutuOpenD.xml Configuration Reference

Every tag FutuOpenD v10.4.6408 understands, documented with examples. Start with the [`FutuOpenD.xml.template`](../FutuOpenD.xml.template) in the repo root — it's pre-wired with env-var substitution and sensible defaults.

> **Disclaimer:** This is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo.

---

## The One Rule

**FutuOpenD uses lowercase XML tag names.** The root element is `<futu_opend>`. Tags like `<IP>`, `<Port>`, or `<LoginAccount>` (uppercase or CamelCase) are silently ignored. When in doubt, lowercase it.

---

## Minimal Working Config

This is everything you need for a functional, authenticated session:

```xml
<?xml version="1.0" encoding="utf-8"?>
<futu_opend>
  <!-- TCP API — bind locally -->
  <ip>127.0.0.1</ip>
  <api_port>11111</api_port>

  <!-- Account -->
  <login_account>your_account_id</login_account>
  <login_pwd_md5>YOUR_32CHAR_MD5_HASH_HERE</login_pwd_md5>
  <rsa_private_key>/run/secrets/rsa_key.txt</rsa_private_key>

  <!-- Behaviour -->
  <lang>en</lang>
  <log_level>info</log_level>
  <pdt_protection>1</pdt_protection>
  <dtcall_confirmation>1</dtcall_confirmation>
</futu_opend>
```

Add whatever you need from the sections below. Everything else is optional.

---

## Account & Authentication

### `<login_account>`

Your Futu account identifier. Three formats work:

```xml
<!-- Futu account ID (牛牛号) — find it in the app under Settings -->
<login_account>12345678</login_account>

<!-- Phone number with country code -->
<login_account>+86 13800138000</login_account>

<!-- Email address -->
<login_account>you@example.com</login_account>
```

### `<login_pwd_md5>` — strongly recommended

Your password as a **32-character lowercase MD5 hex string**. Use this instead of plaintext — your actual password never touches the disk.

Generate it:

```bash
# Linux
echo -n "your_password" | md5sum | cut -d' ' -f1

# macOS
echo -n "your_password" | md5 -r

# Python — works anywhere
python3 -c "import hashlib; print(hashlib.md5(b'your_password').hexdigest())"
```

> The `-n` is not a typo. It suppresses the trailing newline. Without it, the hash is wrong.

### `<login_pwd>` — for local testing only

Plaintext fallback when `<login_pwd_md5>` is absent. **Never use this in production.**

```xml
<!-- Seriously, don't ship this -->
<login_pwd>hunter2</login_pwd>
```

### `<rsa_private_key>`

Path to your RSA private key file. Required for trading when `<ip>` is anything other than `127.0.0.1`.

Get one from the [Futu OpenAPI Dashboard](https://www.futunn.com/en/OpenAPI) → **Manage Key** → generate and download. Then `chmod 600` it.

```xml
<rsa_private_key>/run/secrets/rsa_key.txt</rsa_private_key>
```

---

## Network & Protocol

### `<ip>` — TCP API bind address

Controls which interfaces FutuOpenD listens on.

| Value | Who can reach it |
|-------|-----------------|
| `127.0.0.1` | Local processes only (default, safest) |
| `0.0.0.0` | Anyone on the network — **set this for remote access** |

```xml
<!-- Local dev — only this machine -->
<ip>127.0.0.1</ip>

<!-- Cloud VM or remote SDK -->
<ip>0.0.0.0</ip>
```

> **Security:** When you set `<ip>0.0.0.0</ip>`, you **must** also set `<rsa_private_key>`. Trading calls get rejected without it. Quote-only works without encryption.

### `<api_port>` — TCP API port

Defaults to `11111`. Only change it if something else already owns that port.

```xml
<api_port>11111</api_port>
```

### `<websocket_ip>` / `<websocket_port>` — WebSocket

The WebSocket endpoint. Leave `<websocket_port>` unset to disable.

```xml
<websocket_ip>0.0.0.0</websocket_ip>
<websocket_port>11112</websocket_port>
```

### `<websocket_key_md5>`

WebSocket clients use this MD5 hex string to authenticate. If unset, any client can connect (subject to RSA rules for trading calls).

```xml
<!-- Generate with: echo -n "your_secret_key" | md5sum | cut -d' ' -f1 -->
<websocket_key_md5>YOUR_32CHAR_MD5_HASH_HERE</websocket_key_md5>
```

### `<websocket_private_key>` / `<websocket_cert>` — TLS/SSL

Both must be set together to enable WSS. Required when WebSocket crosses an untrusted network.

Generate a self-signed cert (fine for testing):

```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=futuopend"

# Strip the password — FutuOpenD can't handle encrypted keys
openssl rsa -in key.pem -out key_nopass.pem
```

```xml
<websocket_private_key>/run/secrets/ws_key_nopass.pem</websocket_private_key>
<websocket_cert>/run/secrets/ws_cert.pem</websocket_cert>
```

---

## Behaviour & Tuning

### `<log_level>`

How chatty are the logs?

| Value | Use it when |
|-------|------------|
| `debug` | First setup, chasing connection issues |
| `info` | Normal day-to-day running (default) |
| `warning` | You want less noise |
| `error` | Production, keep it quiet |
| `fatal` | Only catastrophic failures get logged |
| `no` | Logging disabled entirely — don't use during setup |

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
|-------|--------|---------|
| `0` | Protocol Buffers | Production (compact, fast) |
| `1` | JSON | Debugging (human-readable) |

```xml
<push_proto_type>0</push_proto_type>
```

### `<qot_push_frequency>`

Cap push frequency in milliseconds per subscription. Does not affect K-line pushes. Leave unset for unlimited.

```xml
<!-- One push per second — reduces bandwidth on high-activity subscriptions -->
<qot_push_frequency>1000</qot_push_frequency>
```

### `<price_reminder_push>`

Receive price alert notifications pushed from Futu's server.

```xml
<price_reminder_push>1</price_reminder_push>  <!-- on (default) -->
<price_reminder_push>0</price_reminder_push>  <!-- off -->
```

### `<auto_hold_quote_right>`

If another terminal kicks you off your quote rights, should FutuOpenD automatically try to reclaim them for 10 seconds?

```xml
<auto_hold_quote_right>1</auto_hold_quote_right>  <!-- auto-reclaim (default) -->
<auto_hold_quote_right>0</auto_hold_quote_right>  <!-- manual re-login -->
```

### `<telnet_ip>` / `<telnet_port>`

Enable the Telnet debug console. Bind to `127.0.0.1` unless you're on a trusted network.

```xml
<telnet_ip>127.0.0.1</telnet_ip>
<telnet_port>22222</telnet_port>
```

> **Warning:** Telnet is plaintext. Never expose port `22222` to untrusted networks.

---

## Language & Locale

### `<lang>`

| Value | Language |
|-------|---------|
| `en` | English |
| `chs` | Simplified Chinese |

```xml
<lang>en</lang>
```

### `<future_trade_api_time_zone>`

Required for futures trading. Sets the time zone for timestamps in futures API responses.

```xml
<future_trade_api_time_zone>UTC+8</future_trade_api_time_zone>   <!-- HK, Singapore -->
<future_trade_api_time_zone>UTC+9</future_trade_api_time_zone>   <!-- Japan -->
<future_trade_api_time_zone>UTC+11</future_trade_api_time_zone>  <!-- Sydney -->
<future_trade_api_time_zone>UTC-5</future_trade_api_time_zone>   <!-- New York -->
<future_trade_api_time_zone>UTC-6</future_trade_api_time_zone>   <!-- Chicago -->
```

---

## US Market Protections

> Applicable only to Futu US / moomoo US accounts.

### `<pdt_protection>`

**Pattern Day Trade Protection** — blocks orders that would trigger PDT status.

```xml
<pdt_protection>1</pdt_protection>  <!-- active (recommended) -->
<pdt_protection>0</pdt_protection>  <!-- disabled -->
```

PDT protection helps, but doesn't eliminate risk. If your equity drops below $25,000 and you're flagged as a PDT, you can't open new positions until you deposit funds.

### `<dtcall_confirmation>`

**Day-Trading Call Warning** — blocks orders that would exhaust your DT buying power.

```xml
<dtcall_confirmation>1</dtcall_confirmation>  <!-- active (recommended) -->
<dtcall_confirmation>0</dtcall_confirmation>  <!-- disabled -->
```

A triggered DT Call requires depositing the full call amount to clear.

---

## Environment Variable Substitution

FutuOpenD resolves `${VAR_NAME}` patterns at startup. Docker injects env vars automatically — no config file rewrites needed.

```xml
<login_account>${FUTU_ACCOUNT}</login_account>
<login_pwd_md5>${FUTU_PWD_MD5}</login_pwd_md5>
<rsa_private_key>${FUTU_RSA_KEY}</rsa_private_key>
<ip>${FUTU_IP:-127.0.0.1}</ip>
<log_level>${FUTU_LOG_LEVEL:-info}</log_level>
```

The `:-default` syntax works too — it falls back if the variable isn't set.

**Via Docker Compose:**

```yaml
services:
  futuopend:
    environment:
      FUTU_ACCOUNT: "12345678"
      FUTU_PWD_MD5: "aaaa0000aaaa0000aaaa0000aaaa0000"
      FUTU_RSA_KEY: "/run/secrets/rsa_key.txt"
      FUTU_IP: "0.0.0.0"
      FUTU_LOG_LEVEL: "debug"
```

**Via docker run:**

```bash
docker run \
  -e FUTU_ACCOUNT=12345678 \
  -e FUTU_PWD_MD5="$(echo -n 'mypassword' | md5sum | cut -d' ' -f1)" \
  -e FUTU_RSA_KEY=/run/secrets/rsa_key.txt \
  shing1211/futuopend:latest
```

> **Note:** FutuOpenD does the substitution, not Docker. Env vars must be present in the container's environment — mounting a file isn't enough.

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

On first login — especially from a new IP or device — Futu sends an SMS verification code. No GUI here, so you relay it through the Telnet debug interface. It sounds scarier than it is.

### How it flows

1. FutuOpenD starts and attempts to log in
2. Futu's server detects a new device/IP and texts a code to your registered phone
3. FutuOpenD blocks and waits for your input
4. You submit the code via Telnet → validation → you're in

### Step 1 — Enable Telnet

In `FutuOpenD.xml`:

```xml
<telnet_ip>127.0.0.1</telnet_ip>
<telnet_port>22222</telnet_port>
```

Or just uncomment the existing lines in the template.

### Step 2 — Expose the Telnet port

In `docker-compose.yaml`, add the mapping:

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

When phone verification is needed, you'll see:

```
[INFO] Waiting for phone verify code, please input by telnet...
[INFO] Use command: input_phone_verify_code -code=123456
```

### Step 4 — Submit the code

Run this **on your host machine** (not inside the container):

```bash
# Linux / macOS — the simplest way
echo "input_phone_verify_code -code=123456" | nc 127.0.0.1 22222

# With telnet — type the command, then press Enter
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

> **Watch the space.** The command is `input_phone_verify_code -code=123456` — there's a space before `-code=`. Forget it and the command is silently ignored.

### Step 5 — Confirm success

```bash
docker compose logs futuopend | grep -i "login\|verify\|success"
```

Look for:

```
[INFO] Login succeeded. Account: 12345678
```

### Troubleshooting

| Symptom | Fix |
|---------|-----|
| `nc` / `telnet` not found | `apt install netcat-openbsd` or `brew install netcat` |
| Connection refused on 22222 | Check `telnet_ip` and `telnet_port` are set in `FutuOpenD.xml` |
| Code rejected | Codes expire after ~5 minutes — request a new one via the Futu app |
| Code already used | Single-use; request a fresh one |
| No SMS received | Verify your account has a registered phone number |

### Scripting the flow

For CI or automated setups:

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
<?xml version="utf-8"?>
<futu_opend>
  <!-- Remote access: bind to all interfaces -->
  <ip>0.0.0.0</ip>
  <api_port>11111</api_port>

  <!-- WebSocket on 11112 -->
  <websocket_ip>0.0.0.0</websocket_ip>
  <websocket_port>11112</websocket_port>

  <!-- Account — env vars keep secrets out of this file -->
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
