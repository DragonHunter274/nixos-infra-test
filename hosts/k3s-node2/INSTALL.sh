#!/usr/bin/env bash
# Installation script for k3s-node2
# Usage: ./INSTALL.sh <target-ip>

set -e

REMOTE_USER="nixos"
STATIC_IP="10.100.1.56"

if [ -z "$1" ]; then
  echo "Usage: $0 <installer-ip>"
  echo "Example: $0 192.168.1.100"
  echo ""
  echo "The installer IP is the DHCP address of the NixOS install media."
  echo "After install, the machine will use its static IP: $STATIC_IP"
  exit 1
fi

TARGET_IP="$1"

echo "Installing k3s-node2 to $TARGET_IP (as $REMOTE_USER with sudo)"
echo "After reboot, the machine will be reachable at $STATIC_IP"
echo ""

# Ask for the k3s join token
read -sp "Enter the k3s cluster join token: " K3S_TOKEN
echo ""

if [ -z "$K3S_TOKEN" ]; then
  echo "Error: Token cannot be empty"
  exit 1
fi

# Verify SSH agent is running
if [ -z "$SSH_AUTH_SOCK" ]; then
  echo "Warning: SSH_AUTH_SOCK not set. SSH agent may not be running."
  echo "Run: eval \$(ssh-agent) && ssh-add ~/.ssh/id_ed25519"
  exit 1
fi

# Check if key is loaded
if ! ssh-add -l &>/dev/null; then
  echo "No SSH keys loaded in agent. Loading default key..."
  ssh-add ~/.ssh/id_ed25519
fi

echo "SSH agent status:"
ssh-add -l
echo ""

# Test SSH connection
echo "Testing SSH connection to $TARGET_IP..."
if ssh -A -o ConnectTimeout=5 "$REMOTE_USER@$TARGET_IP" 'echo "SSH connection successful"'; then
  echo ""
else
  echo "Failed to connect to $TARGET_IP"
  echo "Make sure the host is reachable and accepts $REMOTE_USER login"
  exit 1
fi

# Run nixos-anywhere
echo "Starting nixos-anywhere installation..."
echo "This will DESTROY all data on the target machine's disk!"
read -p "Continue? (yes/no): " -r
echo ""

if [ "$REPLY" != "yes" ]; then
  echo "Installation cancelled"
  exit 0
fi

nixos-anywhere --flake .#k3s-node2 "$REMOTE_USER@$TARGET_IP" \
  --ssh-option "ForwardAgent=yes" \
  --build-on remote \
  --no-reboot

echo ""
echo "============================================"
echo "  Installation complete - DO NOT reboot yet!"
echo "  Remove the USB install media now."
echo "============================================"
read -p "Press Enter once USB media is removed..."

# Reboot the machine
echo "Rebooting..."
ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$TARGET_IP" 'sudo reboot' || true

echo ""
echo "Removing old host keys..."
ssh-keygen -R "$TARGET_IP" 2>/dev/null || true
ssh-keygen -R "$STATIC_IP" 2>/dev/null || true

echo "Waiting for host to come back up at $STATIC_IP..."
sleep 30

SSH_OPTS="-o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new"

# After install, SSH as root at the static IP
for i in $(seq 1 30); do
  if ssh $SSH_OPTS root@"$STATIC_IP" true 2>/dev/null; then
    echo "Host is up."
    break
  fi
  echo "Waiting for SSH... (attempt $i/30)"
  sleep 10
done

# Push the k3s token to the target machine
echo "Pushing k3s join token to /var/lib/k3s/token..."
ssh $SSH_OPTS root@"$STATIC_IP" 'mkdir -p /var/lib/k3s && printf "%s" "'"$K3S_TOKEN"'" > /var/lib/k3s/token && chmod 600 /var/lib/k3s/token'

echo "Restarting k3s..."
ssh $SSH_OPTS root@"$STATIC_IP" 'systemctl restart k3s'

echo ""
echo "Installation complete!"
echo "Host is reachable at: ssh root@$STATIC_IP"
