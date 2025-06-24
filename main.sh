#!/bin/bash
# Auto-tune file descriptor limits system-wide

set -e

TARGET_LIMIT=262144
SYSCTL_FILE="/etc/sysctl.conf"
LIMITS_CONF="/etc/security/limits.conf"
SYSTEMD_CONF="/etc/systemd/system.conf"
USERD_CONF="/etc/systemd/user.conf"

echo "🔧 Setting hard and soft nofile limits to $TARGET_LIMIT"

# 1. limits.conf
if ! grep -q "nofile" "$LIMITS_CONF"; then
  echo -e "* soft nofile $TARGET_LIMIT\n* hard nofile $TARGET_LIMIT" | sudo tee -a "$LIMITS_CONF"
else
  sudo sed -i "s/^\* soft nofile.*/\* soft nofile $TARGET_LIMIT/" "$LIMITS_CONF"
  sudo sed -i "s/^\* hard nofile.*/\* hard nofile $TARGET_LIMIT/" "$LIMITS_CONF"
fi

# 2. PAM limits activation
for PAM_FILE in /etc/pam.d/common-session /etc/pam.d/common-session-noninteractive; do
  if ! grep -q "pam_limits.so" "$PAM_FILE"; then
    echo "session required pam_limits.so" | sudo tee -a "$PAM_FILE"
  fi
done

# 3. system.conf (global systemd)
sudo sed -i "s/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=$TARGET_LIMIT/" "$SYSTEMD_CONF" 2>/dev/null || true
if ! grep -q "^DefaultLimitNOFILE=" "$SYSTEMD_CONF"; then
  echo "DefaultLimitNOFILE=$TARGET_LIMIT" | sudo tee -a "$SYSTEMD_CONF"
fi

# 4. user.conf (systemd --user)
sudo sed -i "s/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=$TARGET_LIMIT/" "$USERD_CONF" 2>/dev/null || true
if ! grep -q "^DefaultLimitNOFILE=" "$USERD_CONF"; then
  echo "DefaultLimitNOFILE=$TARGET_LIMIT" | sudo tee -a "$USERD_CONF"
fi

# 5. sysctl file-max
if grep -q "^fs.file-max" "$SYSCTL_FILE"; then
  sudo sed -i "s/^fs\.file-max.*/fs.file-max = $TARGET_LIMIT/" "$SYSCTL_FILE"
else
  echo "fs.file-max = $TARGET_LIMIT" | sudo tee -a "$SYSCTL_FILE"
fi
sudo sysctl -p

# 6. Reload systemd
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "✅ Semua limit telah di-set ke $TARGET_LIMIT"
echo

# 7. Verifikasi otomatis
echo "📋 Verifikasi setelah perubahan:"
ulimit -n
systemctl show --property=DefaultLimitNOFILE
cat /proc/1/limits | grep "Max open files"
echo
echo "🎉 Selesai. Disarankan untuk reboot agar semua efek diterapkan penuh."
