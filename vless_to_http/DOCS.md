# VLESS to HTTP

HTTP/HTTPS and SOCKS5 proxy that tunnels all traffic through a **VLESS + Reality**
server, using [Xray-core](https://github.com/XTLS/Xray-core).
Based on [thejohnd0e/VLESS-to-HTTP](https://github.com/thejohnd0e/VLESS-to-HTTP).

**Ports**

| Port | Protocol | Purpose |
| --- | --- | --- |
| `8181` | TCP | HTTP/HTTPS proxy (replaces upstream's 8080) |
| `1080` | TCP | SOCKS5 proxy |

## Configuration

Add at least one `vless://` link under **vless_links** (one link per list entry).
Several links enable automatic failover.

```yaml
vless_links:
  - "vless://UUID@HOST:443?security=reality&encryption=none&pbk=PUBLIC_KEY&fp=chrome&sni=github.com&sid=SHORT_ID&flow=xtls-rprx-vision"
```

| Option | Default | Meaning |
| --- | --- | --- |
| `vless_links` | `[]` | One or more VLESS Reality links |
| `log_level` | `warning` | `debug`, `info`, `warning`, `error`, `none` |
| `proxy_user` | empty | Optional login for both proxies |
| `proxy_pass` | empty | Optional password (set both or neither) |
| `print_config` | `false` | Print the generated Xray config with secrets masked |
| `failover_strategy` | `leastPing` | `leastPing`, `random`, `roundRobin` |
| `probe_url` | `https://www.gstatic.com/generate_204` | URL used for failover probes and the healthcheck |
| `probe_interval` | `1m` | Pause between failover probe rounds |
| `bypass_list` | `[]` | Destinations that connect directly instead of through the tunnel |

## Bypass list

`bypass_list` sends matching destinations through the `direct` outbound instead of the
VLESS tunnel. Entries can be domains or IP addresses/CIDRs:

```yaml
bypass_list:
  - "192.168.0.0/16"      # LAN
  - "10.0.0.0/8"
  - "fd00::/8"            # IPv6 ULA
  - "geoip:private"       # all private/loopback ranges
  - "homeassistant.local"
  - "example.com"         # example.com and its subdomains
```

Rules are evaluated before the proxy rule, so a match always wins. Notes:

- IP/CIDR entries match connections made to an IP address. To bypass a hostname,
  list the hostname (e.g. `homeassistant.local` or `full:nas.lan`) as well.
- Domain entries use Xray syntax: `example.com` (with subdomains), `full:nas.lan`
  (exact), `domain:example.com`, `regexp:...`, `keyword:...`, `geosite:private`.
- IP entries accept `geoip:private`, `geoip:cn`, `192.168.1.0/24`, `10.1.2.3`, `fd00::/8`.
- Bypassed traffic leaves from the Home Assistant host's own network, not the VLESS server.

## Using the proxy

Replace `HOME_ASSISTANT_IP` with the address of your Home Assistant host:

```bash
# HTTP proxy (HTTPS via CONNECT)
curl -x http://HOME_ASSISTANT_IP:8181 https://api.ipify.org

# SOCKS5
curl --socks5-hostname HOME_ASSISTANT_IP:1080 https://api.ipify.org
```

With a login: `http://user:password@HOME_ASSISTANT_IP:8181` or
`curl --socks5-hostname HOME_ASSISTANT_IP:1080 --proxy-user user:password ...`.

Point browsers, apps or devices at the HTTP proxy `HOME_ASSISTANT_IP:8181`.

## Notes

- UDP through SOCKS5 (Telegram calls, QUIC, games) needs host networking and is not
  available in this bridge-mode add-on; HTTP and SOCKS5 over TCP work normally.
- Changing links requires a restart of the add-on.
- To update the upstream image, rebuild the add-on (Supervisor rebuilds from
  `ghcr.io/thejohnd0e/vless-to-http:latest`).
