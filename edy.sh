#!/bin/sh
echo "Memulai proses instalasi..."

# --- 1. Instalasi Dependensi ---
echo "[1/6] Memperbarui daftar paket dan menginstal dependensi..."
opkg update
opkg install curl coreutils-date adb jq bc

if [ $? -ne 0 ]; then
    echo "ERROR: Gagal menginstal dependensi. Pastikan koneksi internet Anda stabil."
    exit 1
fi
echo "-> Dependensi berhasil diinstal."

# --- 2. Download Skrip dari GitHub ---
BASE_URL="https://raw.githubusercontent.com/edydevelopeler/w20q/main"

echo "[2/6] Mengunduh skrip utama 'edu'..."
wget -O /usr/bin/edu "$BASE_URL/edu"

echo "[3/6] Mengunduh skrip 'edu-ping-monitor'..."
wget -O /usr/bin/edu-ping-monitor "$BASE_URL/edu-ping-monitor"

# --- 3. Membuat File Service ---
echo "[4/6] Membuat service untuk pemantau ping..."
cat <<'EOF' > /etc/init.d/edu-monitor
#!/bin/sh /etc/rc.common
SERVICE_NAME="edu-ping-monitor"
SERVICE_SCRIPT="/usr/bin/edu-ping-monitor"
START=99
STOP=10

start() {
    echo "Starting $SERVICE_NAME"
    nohup "$SERVICE_SCRIPT" > /dev/null 2>&1 &
}

stop() {
    echo "Stopping $SERVICE_NAME"
    killall -q "$SERVICE_NAME"
}
EOF

# --- 4. Mengatur Hak Akses ---
echo "[5/6] Mengatur hak akses (permissions)..."
chmod +x /usr/bin/edu
chmod +x /usr/bin/edu-ping-monitor
chmod +x /etc/init.d/edu-monitor

# --- 5. Konfigurasi Awal ---
echo "-------------------------------------"
echo "Menjalankan konfigurasi awal. Silakan masukkan data Anda..."
# Jalankan skrip edu untuk pertama kali agar pengguna bisa memasukkan konfigurasi
/usr/bin/edu

# --- 6. Mengatur Otomatisasi ---
echo "-------------------------------------"
echo "[6/6] Mengatur jadwal (cron) dan mengaktifkan service..."

# Menambahkan cron job setiap 6 jam tanpa menghapus yang sudah ada
(crontab -l 2>/dev/null | grep -v "/usr/bin/edu"; echo "0 */6 * * * /usr/bin/edu") | crontab -
echo "-> Cron job untuk pengecekan 6 jam sekali berhasil ditambahkan."

# Mengaktifkan dan memulai service pemantau ping
/etc/init.d/edu-monitor enable
/etc/init.d/edu-monitor start
echo "-> Service pemantau ping berhasil diaktifkan dan dijalankan."

echo ""
echo "====================================="
echo "🎉 INSTALASI SELESAI! 🎉"
echo "Sistem sekarang berjalan otomatis."
echo "====================================="
