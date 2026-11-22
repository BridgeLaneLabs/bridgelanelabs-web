#!/usr/bin/env bash
# Bridge Lane Labs - server bootstrap
# Turns a fresh Ubuntu 24.04 VM (Oracle Cloud) into a standard BLL host:
# patched, auto-updating, Docker + compose, cloudflared, log rotation.
# Run once as the default user:  sudo bash bootstrap.sh <hostname>
set -euo pipefail

HOST="${1:-bll-prod-01}"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo"; exit 1; }

echo "==> Hostname: $HOST"
hostnamectl set-hostname "$HOST"
timedatectl set-timezone America/New_York

echo "==> System updates"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg unattended-upgrades fail2ban git
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "==> SSH: keys only"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload ssh || systemctl reload sshd

echo "==> Docker"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'JSON'
{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
JSON
systemctl restart docker
usermod -aG docker "${SUDO_USER:-ubuntu}"

echo "==> cloudflared"
mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg -o /usr/share/keyrings/cloudflare-main.gpg
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' \
  > /etc/apt/sources.list.d/cloudflared.list
apt-get update -y && apt-get install -y cloudflared

echo "==> App folder"
mkdir -p /opt/bll && chown "${SUDO_USER:-ubuntu}": /opt/bll

echo
echo "Done. Log out and back in (so 'docker' works without sudo), then check:"
echo "  docker run --rm hello-world"
echo "  cloudflared --version"
