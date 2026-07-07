# Hawk Prime Server Manual

## Purpose

`hawk-prime` is the primary laptop/server node.

Expected access pattern:

```bash
ssh hawk-prime
```

Current local Linux user:

```text
prime
```

Do not assume usernames from other Hawk machines. `hawk-delta` and `hawk-omega` used different local users.

## Current Server Model

`hawk-prime` should be treated as a Tailscale-first server:

- Tailscale provides private network reachability.
- Tailscale SSH and OpenSSH are enabled at boot.
- The local desktop auto-logs into `prime`.
- Wi-Fi is configured to auto-connect before desktop login.
- Laptop lid close on AC power is configured not to suspend.

Primary setup script:

```bash
cd /home/prime/hawk-servers
sudo bash ./setup-hawk-prime.sh
```

## Power Outage Behavior

Ubuntu can start services after the machine boots, but Ubuntu usually cannot power on a fully powered-off laptop when AC power returns. That behavior is firmware/BIOS controlled.

For the HP Victus laptop, check BIOS/UEFI for a setting named similar to:

- Power on AC attach
- Power on when AC is detected
- Restore after AC power loss
- AC recovery
- Wake on AC

Enable it if available.

If the laptop still has battery during the outage, the important OS behavior is already handled by the setup script:

- do not suspend while plugged in
- reconnect Wi-Fi
- start `tailscaled`
- start `ssh`

Recommended home-server practice:

- Keep the laptop plugged in.
- Keep the lid open or confirm lid-close-on-AC is not suspending.
- Use a small UPS if remote access matters during short outages.
- After changing BIOS power settings, test by shutting down, unplugging AC, waiting, then reconnecting AC.

## Sudo And Password Policy

Do not commit the real sudo/login password to this repository.

Do not create scripts that type the sudo password automatically. For unattended server work, use one of these instead:

- a systemd service that runs as root at boot
- a timer/service pair for scheduled root tasks
- a narrow sudoers rule for one specific command, if absolutely necessary

For interactive maintenance over SSH:

```bash
ssh hawk-prime
sudo -v
```

Then enter the local password interactively.

## Tailscale Machine Name

Current observed state on July 7, 2026:

```text
100.98.217.32   hawk-prime-1
100.73.7.67     hawk-prime      offline, stale old install
```

This means the new Ubuntu install is online, but Tailscale renamed it because an old `hawk-prime` machine record still exists.

Cleanup path:

1. Open the Tailscale admin console.
2. Delete the stale/offline old `hawk-prime` machine record.
3. On this machine, run:

```bash
sudo tailscale set --hostname=hawk-prime
```

4. Verify:

```bash
tailscale status --self
```

Expected machine name after cleanup:

```text
hawk-prime
```

## Access From Another Machine

Any new trusted laptop/desktop can use the same simple command:

```bash
ssh hawk-prime
```

Requirements on that client machine:

- Install Tailscale.
- Log into the same tailnet as `hawk-prime`.
- Confirm `tailscale status` shows `hawk-prime` or `hawk-prime-1`.
- Add an SSH config alias for local user `prime`.

Client SSH config:

```sshconfig
Host hawk-prime
    HostName hawk-prime
    User prime
```

If the Tailscale machine is still temporarily named `hawk-prime-1`, use this temporary client config:

```sshconfig
Host hawk-prime
    HostName hawk-prime-1
    User prime
```

After the stale Tailscale entry is deleted and the hostname is reset, change `HostName` back to `hawk-prime`.

Verification from any client:

```bash
ssh hawk-prime 'hostname; whoami; tailscale status --self'
```

Expected essentials:

```text
hawk-prime
prime
```

## If `ssh hawk-prime` Fails

Check the client-side resolved SSH config:

```bash
ssh -G hawk-prime | egrep '^(hostname|user) '
```

Expected:

```text
hostname hawk-prime
user prime
```

Check the tailnet:

```bash
tailscale status
tailscale ping hawk-prime
```

Fallback by Tailscale IP:

```bash
ssh prime@100.x.y.z
```

If the error says `failed to look up local user`, the client is trying the wrong Linux username. Use `User prime`.
