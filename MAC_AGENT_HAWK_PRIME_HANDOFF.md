# Mac Agent Handoff: `hawk-prime`

## Goal

Configure the Mac so the user can run:

```bash
ssh hawk-prime
```

and land in the `prime` account on the Ubuntu laptop/server named `hawk-prime`.

## Assumptions

- The Mac is already logged into the same Tailscale tailnet as `hawk-prime`.
- The Ubuntu machine has run `/home/prime/hawk-servers/setup-hawk-prime.sh`.
- The real Linux username on `hawk-prime` is:

```text
prime
```

Do not use `vatsal`, `vatsal1`, `ubuntu`, or `pop` for this host unless a later Linux-side check explicitly says the account changed.

## Mac-Side SSH Config

Edit `~/.ssh/config` and add or update only this host block:

```sshconfig
Host hawk-prime
    HostName hawk-prime
    User prime
```

Do not remove unrelated entries for GitHub, Hugging Face, `hawk-omega`, `hawk-pop`, `nest`, or other hosts.

Recommended safe edit flow:

```bash
cp ~/.ssh/config ~/.ssh/config.before-hawk-prime
chmod 600 ~/.ssh/config
```

Then inspect the effective config:

```bash
ssh -G hawk-prime | egrep '^(hostname|user) '
```

Expected:

```text
hostname hawk-prime
user prime
```

## Applies To Other Client Machines

The same pattern works from any trusted client, not only the Mac:

- install Tailscale
- log into the same tailnet
- add an SSH config alias
- run `ssh hawk-prime`

The client-side alias should keep the command stable even if the underlying Tailscale IP changes.

## Connectivity Checks

Check that Tailscale is running on the Mac:

```bash
tailscale status
```

Look for `hawk-prime`. If it is not listed, ask the Linux-side agent/user to confirm that Tailscale login completed on `hawk-prime`.

If listed, try:

```bash
tailscale ping hawk-prime
```

Then test SSH:

```bash
ssh hawk-prime
```

## If SSH Fails

If the error says:

```text
tailscale: failed to look up local user
```

then the Mac is using the wrong SSH user. Confirm `ssh -G hawk-prime` shows `user prime`.

If the host resolves but SSH cannot connect, try the Tailscale IP from `tailscale status`:

```bash
ssh prime@100.x.y.z
```

If `hawk-prime` appears as `hawk-prime-1` or similar, the tailnet likely still has an old stale `hawk-prime` machine record. The temporary client config can point the stable alias at the temporary Tailscale name:

```sshconfig
Host hawk-prime
    HostName hawk-prime-1
    User prime
```

Then ask the user to delete the stale old `hawk-prime` from the Tailscale admin console, and ask the Linux-side agent to run:

```bash
sudo tailscale set --hostname=hawk-prime
```

## Success Criteria

Report success only when this works from the Mac:

```bash
ssh hawk-prime 'hostname; whoami; tailscale status --self'
```

Expected essentials:

```text
hawk-prime
prime
```
