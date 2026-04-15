# FutuOpenD Gateway API Documentation

> OpenAPI documentation for the FutuOpenD gateway daemon. This documents the protocol-level API for developers implementing their own SDK or connecting directly via TCP/WebSocket.

> **Disclaimer:** This is an unofficial community packaging. Not affiliated with, endorsed by, or supported by Futu Securities or moomoo.

---

## Overview

FutuOpenD exposes three network endpoints:

| Port | Protocol | Description |
|------|----------|-------------|
| `11111` | TCP | Main trading and quote API |
| `11112` | WebSocket | Real-time push, web clients |
| `22222` | Telnet | Debug console, phone verification |

---

## TCP API (Port 11111)

The primary interface for all SDK connections. Uses a custom binary protocol with optional AES encryption.

### Protocol Header

Every request and response begins with a fixed 36-byte header:

```
struct APIProtoHeader {
    u8_t   szHeaderFlag[2];   // "FT" (0x4654)
    u32_t  nProtoID;          // Protocol identifier
    u8_t   nProtoFmtType;     // 0=Protobuf, 1=JSON
    u8_t   nProtoVer;         // Protocol version (currently 0)
    u32_t  nSerialNo;          // Packet serial number
    u32_t  nBodyLen;          // Body length in bytes
    u8_t   arrBodySHA1[20];   // SHA1 hash of body
    u8_t   arrReserved[8];    // Reserved
};
```

**Byte order:** Little-endian (no ntohl needed)

### Protocol IDs

| ID | Name | Category | Description |
|----|------|----------|-------------|
| 1001 | InitConnect | Basic | Initialize connection |
| 1002 | GetGlobalState | Basic | Get global market status |
| 1003 | Notify | Basic | Event notification callback |
| 1004 | KeepAlive | Basic | Heartbeat keep-alive |
| 2001 | Trd_GetAccList | Trade | Get account list |
| 2005 | Trd_UnlockTrade | Trade | Unlock trading |
| 2101 | Trd_GetFunds | Trade | Get account funds |
| 2102 | Trd_GetPositionList | Trade | Get positions |
| 2111 | Trd_GetMaxTrdQtys | Trade | Get max trade quantity |
| 2201 | Trd_GetOrderList | Trade | Get order list |
| 2202 | Trd_PlaceOrder | Trade | Place order |
| 2205 | Trd_ModifyOrder | Trade | Modify/cancel order |
| 2221 | Trd_GetHistoryOrderList | Trade | Get historical orders |
| 3001 | Qot_Sub | Quote | Subscribe to data |
| 3003 | Qot_GetSubInfo | Quote | Get subscription info |
| 3004 | Qot_GetBasicQot | Quote | Get stock quote |
| 3203 | Qot_GetSecuritySnapshot | Quote | Get market snapshot |
| 3204 | Qot_GetKL | Quote | Get K-line data |
| 3210 | Qot_GetOptionChain | Quote | Get option chain |

### Basic Functions

#### InitConnect (1001)

Initialize connection to FutuOpenD.

**Request (C2S):**
```protobuf
message C2S {
    required int32  clientVer = 1;    // Client version (e.g., 172 = 1.72)
    required string clientID = 2;     // Client identifier
    optional string password = 3;     // Password (MD5 for remote)
    optional int32  protoFmtType = 4; // 0=Protobuf, 1=JSON
    optional int32  pushProtoFmtType = 5; // Push format
    optional int32  connID = 6;       // Connection ID (reconnect)
}
```

**Response (S2C):**
```protobuf
message S2C {
    required int32  serverVer = 1;     // Server version
    required string connID = 2;       // Connection ID
    required int32  keepAliveInterval = 3; // Heartbeat interval (seconds)
    optional bytes  aesKey = 4;       // AES key (if encrypted)
    repeated int32  trdLogins = 5;    // Logged-in accounts
}
```

**Example (Python):**
```python
import socket
import struct
import hashlib

# Build header
proto_id = 1001
serial_no = 1
body = b'...'  # Protobuf-encoded InitConnect request

header = b'FT'
header += struct.pack('<I', proto_id)
header += struct.pack('<B', 0)  # Protobuf
header += struct.pack('<B', 0)  # Version
header += struct.pack('<I', serial_no)
header += struct.pack('<I', len(body))
header += hashlib.sha1(body).digest()
header += b'\x00' * 8  # Reserved

sock.sendall(header + body)
```

#### GetGlobalState (1002)

Get global market status.

**Request (C2S):**
```protobuf
message C2S {
    // Empty - no parameters required
}
```

**Response (S2C):**
```protobuf
message S2C {
    required int32  market = 1;           // Market (HK=1, US=2, CN=6)
    required int32  marketStatus = 2;   // 0=Closed, 1=Open
    required string tradeDate = 3;       // Trading date (YYYY-MM-DD)
    repeated int32  tradingMinutes = 4;  // Trading session times
}
```

#### KeepAlive (1004)

Heartbeat to maintain connection.

**Request (C2S):**
```protobuf
message C2S {
    required int64 time = 1;  // Unix timestamp (seconds)
}
```

**Response (S2C):**
```protobuf
message S2C {
    required int64 time = 1;  // Server timestamp
}
```

---

## WebSocket API (Port 11112)

WebSocket clients connect to this endpoint for real-time data push. Supports both WS (unencrypted) and WSS (TLS).

### Connection

```javascript
// JavaScript example
const ws = new WebSocket('ws://localhost:11112');

// Or with TLS (if configured)
const wss = new WebSocket('wss://localhost:11112');

ws.onopen = () => {
    // Send InitConnect
    const initMsg = {
        // InitConnect request object
    };
    ws.send(JSON.stringify(initMsg));
};

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log('Received:', data);
};
```

### Message Format

WebSocket messages use JSON by default:

```json
{
    "protocolID": 1001,
    "serialNo": 1,
    "body": {
        "clientVer": 172,
        "clientID": "my-client"
    }
}
```

---

## Telnet API (Port 22222)

Debug console for troubleshooting and phone verification.

### Connecting

```bash
# Using netcat
echo "help" | nc 127.0.0.1 22222

# Using telnet
telnet 127.0.0.1 22222
help
```

### Commands

| Command | Description |
|---------|-------------|
| `help` | Show available commands |
| `status` | Show connection status |
| `input_phone_verify_code -code=XXXXXX` | Submit SMS verification code |
| `relogin` | Force re-login |
| `exit` | Close connection |

**Phone Verification:**
```
[INFO] Waiting for phone verify code, please input by telnet...
[INFO] Use command: input_phone_verify_code -code=123456

# Submit code:
echo "input_phone_verify_code -code=123456" | nc 127.0.0.1 22222
```

---

## Encryption

### InitConnect with RSA Encryption

When `rsa_private_key` is configured in FutuOpenD.xml, the InitConnect request must use RSA encryption:

1. Generate a random AES key (32 bytes)
2. Encrypt the AES key with the RSA public key
3. Send encrypted AES key in InitConnect
4. All subsequent requests use AES encryption

```python
import Crypto.PublicKey.RSA as RSA
import Crypto.Cipher.AES as AES
import Crypto.Cipher.PKCS1_OAEP as PKCS1
import os

# Load RSA private key (same as OpenD's key)
with open('rsa_key.txt', 'r') as f:
    key = RSA.import_key(f.read())

# Generate random AES key
aes_key = os.urandom(32)

# Encrypt AES key with RSA
cipher = PKCS1.new(key)
encrypted_key = cipher.encrypt(aes_key)

# Build InitConnect with encrypted key
# ... (send InitConnect request)

# For subsequent requests, encrypt with AES
def aes_encrypt(data: bytes, key: bytes) -> bytes:
    # Pad to 16-byte multiple
    padding = 16 - (len(data) % 16)
    data += bytes([padding] * padding)
    
    # AES ECB mode (Futu uses modified ECB)
    cipher = AES.new(key, AES.MODE_ECB)
    encrypted = cipher.encrypt(data)
    
    return encrypted
```

---

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| 0 | RET_OK | Success |
| -1 | RET_ERROR | General error |
| -100 | RET_TIMEOUT | Request timeout |
| -400 | RET_UNKNOWN | Unknown result |
| 1001 | ERR_NO_LOGIN | Not logged in |
| 1002 | ERR_NO_QUOTA | No quote permission |
| 1003 | ERR_NO_TRADE | No trade permission |
| 1004 | ERR_INVALID_PASSWORD | Invalid password |
| 1005 | ERR_EXCLUSIVE_OP | Exclusive operation in progress |

---

## Examples

### Python TCP Client

```python
import socket
import struct
import json
from typing import Any

class FutuClient:
    def __init__(self, host: str = '127.0.0.1', port: int = 11111):
        self.host = host
        self.port = port
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.serial_no = 0
    
    def connect(self):
        self.sock.connect((self.host, self.port))
    
    def send_request(self, proto_id: int, body: bytes) -> bytes:
        self.serial_no += 1
        
        # Build header
        header = b'FT'
        header += struct.pack('<I', proto_id)
        header += struct.pack('<B', 1)  # JSON format
        header += struct.pack('<B', 0)  # Version
        header += struct.pack('<I', self.serial_no)
        header += struct.pack('<I', len(body))
        header += b'\x00' * 28  # SHA1 + reserved
        
        self.sock.sendall(header + body)
        
        # Read response
        response_header = self.sock.recv(36)
        body_len = struct.unpack('<I', response_header[12:16])[0]
        
        return self.sock.recv(body_len)
    
    def get_global_state(self) -> dict:
        body = json.dumps({}).encode()
        response = self.send_request(1002, body)
        return json.loads(response)

# Usage
client = FutuClient()
client.connect()
state = client.get_global_state()
print(state)
```

### JavaScript WebSocket Client

```javascript
class FutuWS {
    constructor(url = 'ws://127.0.0.1:11112') {
        this.ws = new WebSocket(url);
        this.serialNo = 0;
        this.pending = new Map();
        
        this.ws.onmessage = (event) => {
            const msg = JSON.parse(event.data);
            if (msg.serialNo && this.pending.has(msg.serialNo)) {
                const resolve = this.pending.get(msg.serialNo);
                resolve(msg);
                this.pending.delete(msg.serialNo);
            }
        };
    }
    
    async send(protoId, body) {
        return new Promise((resolve) => {
            this.serialNo++;
            this.pending.set(this.serialNo, resolve);
            
            this.ws.send(JSON.stringify({
                protocolID: protoId,
                serialNo: this.serialNo,
                body: body
            }));
        });
    }
    
    async getGlobalState() {
        return this.send(1002, {});
    }
    
    async subscribe(securities, types) {
        return this.send(3001, {
            securities: securities,
            subTypes: types
        });
    }
}

// Usage
const futu = new FutuWS();
await futu.getGlobalState();
const quotes = await futu.subscribe([
    { code: '00700', market: 1 }
], [0]);  // 0 = SubType_Qot
```

---

## Troubleshooting

### Connection Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| `Connection refused` on 11111 | FutuOpenD not running | Check container is running |
| `Connection refused` on 11112 | WebSocket not enabled | Set `<websocket_port>` in config |
| `Connection refused` on 22222 | Telnet not enabled | Set `<telnet_port>` in config |
| Timeout after 30s | Firewall blocking | Allow ports in firewall |

### Authentication Errors

| Symptom | Cause | Solution |
|---------|-------|----------|
| `ERR_NO_LOGIN` | Not logged in | Check credentials in FutuOpenD.xml |
| Phone verification required | New device/IP | Submit code via Telnet |
| `ERR_NO_TRADE` | No trade permission | Enable API in Futu app |
| `ERR_NO_QUOTA` | No quote permission | Subscribe to quote rights |

### Data Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| No push data | Not subscribed | Call Qot_Sub to subscribe |
| Stale data | Subscription expired | Re-subscribe |
| Incomplete order book | Push frequency limit | Adjust `<qot_push_frequency>` |

### Encryption Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| `InitConnect` fails | Wrong RSA key | Use matching key pair |
| AES decryption fails | Key mismatch | Verify same key used |
| Trading rejected | No encryption | Set `rsa_private_key` in config |

### Debug Steps

1. **Check FutuOpenD status:**
   ```bash
   curl http://127.0.0.1:11111/version
   ```

2. **Check logs:**
   ```bash
   docker compose logs futuopend | grep -i error
   ```

3. **Enable debug logging:**
   ```xml
   <log_level>debug</log_level>
   ```

4. **Test connection:**
   ```bash
   nc -zv 127.0.0.1 11111
   nc -zv 127.0.0.1 11112
   nc -zv 127.0.0.1 22222
   ```

5. **Verify phone verification:**
   ```bash
   echo "status" | nc 127.0.0.1 22222
   ```

---

## See Also

- [FutuOpenD.xml Configuration Reference](configuration.md)
- [Security Hardening Guide](security.md)
- [Official Futu Protocol Docs](https://openapi.futunn.com/futu-api-doc/en/ftapi/protocol.html)
- [Python SDK (FutuQuant)](https://github.com/Futuromy/FutuQuant)

---

*This project is an unofficial community packaging. It is not affiliated with, endorsed by, or supported by Futu Securities or moomoo. All trademarks belong to their respective owners.*
