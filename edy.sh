#!/bin/sh
# --- Definisi Warna ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Banner ---
echo "${CYAN}"
echo "================================================="
echo "   Installer Otomatis Edy Auto-Purchase v6.9   "
echo "=================================================${NC}"
echo ""

# --- 1. Instalasi Dependensi ---
echo "${YELLOW}[1/6] Memperbarui daftar paket dan menginstal dependensi...${NC}"
opkg update > /dev/null 2>&1
opkg install curl coreutils-date adb jq bc > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: Gagal menginstal dependensi. Pastikan koneksi internet Anda stabil."
    exit 1
fi
echo "${GREEN} -> Dependensi berhasil diinstal.${NC}"

# --- 2. Download Skrip dari GitHub ---
BASE_URL="https://raw.githubusercontent.com/edydevelopeler/w20q/main"

echo "${YELLOW}[2/6] Mengunduh skrip utama 'edu'...${NC}"
wget -q --show-progress -O /usr/bin/edu "$BASE_URL/edu"
echo "${GREEN} -> Selesai.${NC}"

echo "${YELLOW}[3/6] Mengunduh skrip 'edu-ping-monitor'...${NC}"
wget -q --show-progress -O /usr/bin/edu-ping-monitor "$BASE_URL/edu-ping-monitor"
echo "${GREEN} -> Selesai.${NC}"

# --- 3. Membuat File Service ---
echo "${YELLOW}[4/6] Membuat service untuk pemantau ping...${NC}"
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
echo "${GREEN} -> Service berhasil dibuat.${NC}"

# --- 4. Mengatur Hak Akses ---
echo "${YELLOW}[5/6] Mengatur hak akses (permissions)...${NC}"
chmod +x /usr/bin/edu
chmod +x /usr/bin/edu-ping-monitor
chmod +x /etc/init.d/edu-monitor
echo "${GREEN} -> Hak akses diatur.${NC}"

# --- 5. Konfigurasi Awal ---
echo ""
echo "${CYAN}-------------------------------------------------${NC}"
echo "${YELLOW}Menjalankan Konfigurasi Awal. Silakan masukkan data Anda...${NC}"
# Jalankan skrip edu untuk pertama kali dan sembunyikan outputnya yang tidak perlu
/usr/bin/edu > /dev/null 2>&1

# --- 6. Mengatur Otomatisasi ---
echo "${CYAN}-------------------------------------------------${NC}"
echo "${YELLOW}[6/6] Mengatur jadwal (cron) dan mengaktifkan service...${NC}"

# Menambahkan cron job setiap 6 jam tanpa menghapus yang sudah ada
(crontab -l 2>/dev/null | grep -v "/usr/bin/edu"; echo "0 */6 * * * /usr/bin/edu") | crontab -
echo "${GREEN} -> Cron job untuk pengecekan 6 jam sekali berhasil ditambahkan.${NC}"

# Mengaktifkan dan memulai service pemantau ping
/etc/init.d/edu-monitor enable > /dev/null 2>&1
/etc/init.d/edu-monitor start
echo "${GREEN} -> Service pemantau ping berhasil diaktifkan dan dijalankan.${NC}"

echo ""
echo "${CYAN}=================================================${NC}"
echo "${GREEN}🎉          INSTALASI SELESAI!           🎉${NC}"
echo "${CYAN}Sistem sekarang berjalan otomatis.${NC}"
echo "${CYAN}=================================================${NC}"
