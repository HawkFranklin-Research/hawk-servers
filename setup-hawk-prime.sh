#!/usr/bin/env bash
set -euo pipefail

TARGET_HOSTNAME="hawk-prime"
TAILSCALE_TRACK="stable"
AUTO_LOGIN_USER="prime"
UBUNTU_CODENAME="$(. /etc/os-release && printf '%s' "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this with sudo: sudo bash $0" >&2
  exit 1
fi

if [[ -z "$UBUNTU_CODENAME" ]]; then
  echo "Could not detect Ubuntu codename from /etc/os-release" >&2
  exit 1
fi

echo "==> Setting system hostname to ${TARGET_HOSTNAME}"
hostnamectl set-hostname "$TARGET_HOSTNAME"

if grep -qE '^127\.0\.1\.1[[:space:]]+' /etc/hosts; then
  sed -i "s/^127\.0\.1\.1.*/127.0.1.1 ${TARGET_HOSTNAME}/" /etc/hosts
else
  printf '127.0.1.1 %s\n' "$TARGET_HOSTNAME" >> /etc/hosts
fi

echo "==> Configuring laptop/server boot behavior"
install -d -m 0755 /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/90-hawk-prime-server.conf <<'EOF'
[Login]
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
EOF

if [[ -f /etc/gdm3/custom.conf ]] && getent passwd "$AUTO_LOGIN_USER" >/dev/null; then
  echo "==> Enabling GDM automatic login for ${AUTO_LOGIN_USER}"
  cp -n /etc/gdm3/custom.conf /etc/gdm3/custom.conf.hawk-prime.bak
  if grep -qE '^[#[:space:]]*AutomaticLoginEnable[[:space:]]*=' /etc/gdm3/custom.conf; then
    sed -i 's/^[#[:space:]]*AutomaticLoginEnable[[:space:]]*=.*/AutomaticLoginEnable = true/' /etc/gdm3/custom.conf
  else
    sed -i '/^\[daemon\]/a AutomaticLoginEnable = true' /etc/gdm3/custom.conf
  fi

  if grep -qE '^[#[:space:]]*AutomaticLogin[[:space:]]*=' /etc/gdm3/custom.conf; then
    sed -i "s/^[#[:space:]]*AutomaticLogin[[:space:]]*=.*/AutomaticLogin = ${AUTO_LOGIN_USER}/" /etc/gdm3/custom.conf
  else
    sed -i "/^\[daemon\]/a AutomaticLogin = ${AUTO_LOGIN_USER}" /etc/gdm3/custom.conf
  fi
else
  echo "==> Skipping GDM automatic login; /etc/gdm3/custom.conf or user ${AUTO_LOGIN_USER} not found"
fi

echo "==> Installing Tailscale apt repository for Ubuntu ${UBUNTU_CODENAME}"
install -d -m 0755 /usr/share/keyrings /etc/apt/sources.list.d
curl -fsSL "https://pkgs.tailscale.com/${TAILSCALE_TRACK}/ubuntu/${UBUNTU_CODENAME}.noarmor.gpg" \
  -o /usr/share/keyrings/tailscale-archive-keyring.gpg
curl -fsSL "https://pkgs.tailscale.com/${TAILSCALE_TRACK}/ubuntu/${UBUNTU_CODENAME}.tailscale-keyring.list" \
  -o /etc/apt/sources.list.d/tailscale.list

echo "==> Installing Tailscale and OpenSSH server"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y tailscale openssh-server

echo "==> Enabling services"
systemctl enable --now tailscaled
systemctl enable --now ssh
systemctl reload systemd-logind || true

if command -v nmcli >/dev/null 2>&1; then
  ACTIVE_WIFI_CONNECTION="$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2 == "802-11-wireless" {print $1; exit}')"
  if [[ -n "${ACTIVE_WIFI_CONNECTION:-}" ]]; then
    echo "==> Making Wi-Fi connection '${ACTIVE_WIFI_CONNECTION}' available before desktop login"
    nmcli connection modify "$ACTIVE_WIFI_CONNECTION" connection.autoconnect yes connection.permissions '' || true
  fi
fi

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q '^Status: active'; then
  echo "==> Allowing SSH through ufw"
  ufw allow OpenSSH
fi

echo "==> Starting or updating Tailscale with hostname ${TARGET_HOSTNAME} and Tailscale SSH enabled"
if tailscale status --json 2>/dev/null | grep -q '"BackendState": "Running"'; then
  tailscale set --ssh=true
  tailscale set --hostname="$TARGET_HOSTNAME"
else
  tailscale up --hostname="$TARGET_HOSTNAME" --ssh
fi

echo
echo "==> Local verification"
hostnamectl --static
systemctl is-active tailscaled
systemctl is-active ssh
tailscale status
echo
echo "Expected Mac SSH alias:"
echo "  Host hawk-prime"
echo "      HostName hawk-prime"
echo "      User prime"
