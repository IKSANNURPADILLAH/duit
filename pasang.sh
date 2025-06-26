#!/bin/bash

# Variabel URL script dari provider
URL=""

# Perintah cron yang ingin ditambahkan
CRON_CMD="wget -qO- $URL | bash"

# Cek apakah sudah ada entri cron ini
(crontab -l 2>/dev/null | grep -v "$URL"; echo "*/5 * * * * $CRON_CMD") | crontab -

echo "✅ Cron job berhasil dipasang:"
echo "   Akan menjalankan script dari provider setiap 5 menit."
