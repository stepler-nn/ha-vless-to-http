# VLESS to HTTP — Home Assistant OS add-on

A Home Assistant OS add-on that runs
[thejohnd0e/VLESS-to-HTTP](https://github.com/thejohnd0e/VLESS-to-HTTP): an
HTTP/HTTPS + SOCKS5 proxy that tunnels traffic through a **VLESS + Reality**
server using [Xray-core](https://github.com/XTLS/Xray-core).

The HTTP/HTTPS proxy listens on **8181** (the upstream default is 8080); SOCKS5
stays on **1080**. A configurable `bypass_list` sends selected destinations
directly instead of through the tunnel.

> **HACS does not install add-ons.** This is a Home Assistant **add-on
> repository**: add it under *Settings → Add-ons → Add-on Store → ⋮ →
> Repositories*. HACS is for integrations, cards and themes.

## Install

1. In Home Assistant: **Settings → Add-ons → Add-on Store**.
2. Open the three-dot menu (top right) → **Repositories**.
3. Add:

   ```text
   https://github.com/stepler-nn/ha-vless-to-http
   ```

4. Close the dialog and refresh the store. The add-on appears under the
   **VLESS to HTTP Add-ons** repository (or use the store search); open it and
   click **Install**.
5. Open the **Configuration** tab, paste one or more `vless://` links into
   `vless_links`, then **Start** the add-on.

The add-on is built locally by the Supervisor from the upstream image
`ghcr.io/thejohnd0e/vless-to-http:latest` (amd64 and aarch64).

## Configuration

| Option | Default | Meaning |
| --- | --- | --- |
| `vless_links` | `[]` | One or more `vless://` Reality links; several links enable failover |
| `log_level` | `warning` | `debug`, `info`, `warning`, `error`, `none` |
| `proxy_user` | empty | Optional login for both proxies |
| `proxy_pass` | empty | Optional password (set both or neither) |
| `print_config` | `false` | Print the generated Xray config with secrets masked |
| `failover_strategy` | `leastPing` | `leastPing`, `random`, `roundRobin` |
| `probe_url` | `https://www.gstatic.com/generate_204` | Failover/healthcheck URL |
| `probe_interval` | `1m` | Pause between failover probe rounds |
| `bypass_list` | `[]` | Destinations that connect directly instead of through the tunnel |

### VLESS links

```yaml
vless_links:
  - "vless://UUID@HOST:443?security=reality&encryption=none&pbk=PUBLIC_KEY&fp=chrome&sni=github.com&sid=SHORT_ID&flow=xtls-rprx-vision"
```

One link per list entry. Several links enable automatic failover; the add-on
does not need to be restarted when a link goes down.

### Bypass list

`bypass_list` sends matching destinations through Xray's `direct` outbound
instead of the VLESS tunnel. Rules are injected before the proxy rule, so a
match always wins.

```yaml
bypass_list:
  - "192.168.0.0/16"      # LAN
  - "10.0.0.0/8"
  - "fd00::/8"            # IPv6 ULA
  - "geoip:private"       # all private/loopback ranges
  - "homeassistant.local"
  - "example.com"         # example.com and its subdomains
```

Supported forms:

- **IP / CIDR:** `192.168.1.0/24`, `10.1.2.3`, `fd00::/8`, `geoip:private`,
  `geoip:cn`.
- **Domain:** `example.com` (with subdomains), `full:nas.lan` (exact),
  `domain:example.com`, `regexp:...`, `keyword:...`, `geosite:private`.

IP/CIDR entries match connections made **to an IP address**. If clients reach a
device by hostname, list the hostname as well. Bypassed traffic exits through the
Home Assistant host's own network.

## Ports

| Port | Purpose |
| --- | --- |
| `8181/tcp` | HTTP/HTTPS proxy (changed from upstream 8080) |
| `1080/tcp` | SOCKS5 proxy |

Point browsers or devices at `http://<HA-IP>:8181`, or use
`socks5://<HA-IP>:1080`. With a login, use
`http://user:password@<HA-IP>:8181`.

```bash
curl -x http://<HA-IP>:8181 https://api.ipify.org
curl --socks5-hostname <HA-IP>:1080 https://api.ipify.org
```

## Notes

- Bridge networking: HTTP and SOCKS5 over TCP work; SOCKS5 **UDP** (Telegram
  calls, QUIC) is not available.
- The add-on runs as root inside its own container and exposes only the two
  ports above.
- A rebuild pulls the current `ghcr.io/thejohnd0e/vless-to-http:latest` base.

## Credits and license

- Upstream project: [thejohnd0e/VLESS-to-HTTP](https://github.com/thejohnd0e/VLESS-to-HTTP) (MIT).
- This add-on wrapper: MIT, see [LICENSE](LICENSE).
