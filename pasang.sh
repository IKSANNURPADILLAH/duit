#!/bin/bash
apt update
apt install -y cron
systemctl enable cron
systemctl start cron
echo
read -p "🔧 Masukkan URL script IP setup dari provider (misal: https://noez.de/api/ipsetup/...): " IPSETUP_URL

# Validasi input tidak kosong
if [[ -z "$IPSETUP_URL" ]]; then
  echo "❌ URL kosong. Cron job tidak dipasang."
else
  CRON_CMD="wget -qO- $IPSETUP_URL | bash"
  (crontab -l 2>/dev/null | grep -v "$IPSETUP_URL"; echo "*/5 * * * * $CRON_CMD") | crontab -
  echo "✅ Cron job berhasil dipasang dan akan menjalankan IP setup setiap 5 menit."
fi
echo "restart squid..."
sudo systemctl restart squid
