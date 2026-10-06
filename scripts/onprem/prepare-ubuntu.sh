#!/usr/bin/env bash
# Run INSIDE UbuntuWAF (Ubuntu 18.04 LTS) from the Hyper-V console, as root.
# Prepares the VM for Azure and switches networking to DHCP.
# Ubuntu 18.04 is out of standard support: plan to move to 22.04/24.04 afterwards.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then echo "Run as root"; exit 1; fi

apt-get update
# Azure Linux agent and Hyper-V integration tools
apt-get install -y walinuxagent linux-azure hyperv-daemons

# Make sure SSH is available
systemctl enable ssh

# Serial console output helps troubleshooting in Azure
if ! grep -q "console=ttyS0" /etc/default/grub; then
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&console=tty1 console=ttyS0,115200n8 earlyprintk=ttyS0 /' /etc/default/grub
  update-grub
fi

# fstab must use UUIDs, not device names
if grep -Eq '^/dev/(sd|hd|vd)' /etc/fstab; then
  echo "WARNING: /etc/fstab uses device names. Convert them to UUIDs (blkid) before migrating."
fi

# Back to DHCP (Azure assigns the reserved IP). Keep a backup of the old config.
mkdir -p /root/netplan-backup
cp /etc/netplan/*.yaml /root/netplan-backup/
iface="$(ip -o -4 route show to default | awk '{print $5}' | head -n1)"
cat > /etc/netplan/01-azure-dhcp.yaml << NETPLAN
network:
  version: 2
  ethernets:
    ${iface}:
      dhcp4: true
NETPLAN
# Disable the old static definitions
for f in /etc/netplan/*.yaml; do
  [[ "$f" == "/etc/netplan/01-azure-dhcp.yaml" ]] || mv "$f" "$f.disabled"
done

echo "Done. Review the changes, then: shutdown -h now"
