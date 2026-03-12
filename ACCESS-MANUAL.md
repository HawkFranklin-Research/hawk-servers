# Hawk Delta Access Manual

## Purpose

`hawk-delta` is a lightweight secondary server managed from `hawk-omega`.

Recommended role:

- small internal services
- lightweight databases
- logs and background jobs
- lightweight web apps

Do not treat it as the main development machine.

## Current Access

From `hawk-omega`:

```bash
ssh pop@hawk-delta
```

Fallback by LAN IP:

```bash
ssh pop@192.168.50.64
```

Current login password:

```text
0718****
```

Current username:

```text
pop
```

Current hostname:

```text
hawk-delta
```

## Auto Login

`hawk-delta` auto-logs into `pop` on `tty1` at boot.

Installed override:

```text
/etc/systemd/system/getty@tty1.service.d/autologin.conf
```

## Tailscale

Current state:

- installed on `hawk-delta`
- `tailscaled` enabled at boot
- Tailscale SSH enabled
- Tailscale IPv4: `100.95.45.23`

This means `hawk-delta` should come online after boot without needing a local Ubuntu login first.

## Mac Access

This should work from the Mac on the same Tailscale tailnet:

```bash
ssh pop@hawk-delta
```

Fallback:

```bash
ssh pop@100.95.45.23
```

This is not limited to the home LAN. It should work while traveling as long as:

- the Mac is online
- Tailscale is running on the Mac
- `hawk-delta` is powered on
- `hawk-omega` is providing upstream connectivity to `hawk-delta`

## LAN Sharing Model

`hawk-delta` gets wired internet through `hawk-omega`.

Current LAN facts:

- `hawk-omega` LAN-side IP: `192.168.50.1`
- `hawk-delta` LAN-side IP lease: `192.168.50.64`
- `hawk-omega` shares internet from Wi-Fi to Ethernet

Implementation model on `hawk-omega`:

- static private IP on LAN port
- DHCP for downstream device
- IPv4 forwarding
- NAT from LAN to WAN

The same model can later be reproduced on Pop!_OS if needed.

## GitHub

Do not configure GitHub SSH on `hawk-delta` unless that machine itself must clone or deploy from GitHub.

Keep GitHub auth on `hawk-omega` by default.

## Operating Model

Use `hawk-omega` as:

- controller
- Codex host
- GitHub-authenticated machine

Use `hawk-delta` as:

- service node
- lightweight server
- remotely managed machine
