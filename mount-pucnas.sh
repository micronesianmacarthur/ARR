#!/bin/bash
set -euo pipefail

[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

NAS_HOST="PUC-NAS"
NAS_IP="10.10.15.254"
NAS_USER="Mac"
NAS_SHARE="Mac"
MOUNT_POINT="/mnt/PUCNAS-MAC"
CRED_FILE="/etc/samba/pucnas.cred"
FSTAB_LINE="//$NAS_HOST/$NAS_SHARE $MOUNT_POINT cifs credentials=$CRED_FILE,uid=1000,gid=1000,file_mode=0644,dir_mode=0755,iocharset=utf8,vers=3.0,_netdev,x-systemd.automount,x-systemd.mount-timeout=30 0 0"

if ! command -v mount.cifs >/dev/null 2>&1; then
    pacman -S --needed --noconfirm cifs-utils
fi

grep -q "$NAS_HOST" /etc/hosts || echo "$NAS_IP $NAS_HOST" >> /etc/hosts

if [ ! -s "$CRED_FILE" ]; then
    if [ -z "${NAS_PASSWORD:-}" ]; then
        read -rs -p "NAS password for user $NAS_USER: " NAS_PASSWORD
        echo
    fi
    install -d /etc/samba
    printf 'username=%s\npassword=%s\ndomain=%s\n' "$NAS_USER" "$NAS_PASSWORD" "$NAS_HOST" > "$CRED_FILE"
    chmod 600 "$CRED_FILE"
fi

install -d "$MOUNT_POINT"

sed -i "\|$MOUNT_POINT|d" /etc/fstab
echo "$FSTAB_LINE" >> /etc/fstab

systemctl daemon-reload
systemctl start "mnt-$(systemd-escape --path "$MOUNT_POINT" --suffix=automount)"

mountpoint -q "$MOUNT_POINT" || ls "$MOUNT_POINT" >/dev/null

echo "Mounted $NAS_SHARE at $MOUNT_POINT (on-demand via systemd automount)"