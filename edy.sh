#!/bin/sh

# --- Definisi Warna (dari contoh Anda) ---
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

# --- Banner ---
echo -e "${YELLOW}###########################################${NC}"
echo -e "${YELLOW}#####${RED}    Installer Edy Auto BuyEdu    ${YELLOW}#####${NC}"
echo -e "${YELLOW}#####${GREEN}      Modder EdyDevelopeler      ${YELLOW}#####${NC}"
echo -e "${YELLOW}###########################################${NC}"
echo ""

# --- 1. Instalasi Dependensi ---
echo -e "${YELLOW}[1/6] Memperbarui daftar paket dan menginstal dependensi...${NC}"
opkg update > /dev/null 2>&1
opkg install curl coreutils-date adb jq bc > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Gagal menginstal dependensi. Pastikan koneksi internet Anda stabil.${NC}"
    exit 1
fi
echo -e "${GREEN} -> Dependensi berhasil diinstal.${NC}"

# --- 2. Download Skrip dari GitHub ---
BASE_URL="https://raw.githubusercontent.com/edydevelopeler/w20q/main"

echo -e "${YELLOW}[2/6] Mengunduh skrip utama 'edu'...${NC}"
# Menghapus --show-progress dan hanya menggunakan -q (quiet)
wget -q -O /usr/bin/edu "$BASE_URL/edu"
echo -e "${GREEN} -> Selesai.${NC}"

echo -e "${YELLOW}[3/6] Mengunduh skrip 'edu-ping-monitor'...${NC}"
wget -q -O /usr/bin/edu-ping-monitor "$BASE_URL/edu-ping-monitor"
echo -e "${GREEN} -> Selesai.${NC}"

# --- 3. Membuat File Service ---
echo -e "${YELLOW}[4/6] Membuat service untuk pemantau ping...${NC}"
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
echo -e "${GREEN} -> Service berhasil dibuat.${NC}"

# --- 4. Mengatur Hak Akses ---
echo -e "${YELLOW}[5/6] Mengatur hak akses (permissions)...${NC}"
chmod +x /usr/bin/edu
chmod +x /usr/bin/edu-ping-monitor
chmod +x /etc/init.d/edu-monitor
echo -e "${GREEN} -> Hak akses diatur.${NC}"

# --- 5. Konfigurasi Awal ---
clear
echo ""
echo -e "${YELLOW}-------------------------------------------------${NC}"
echo -e "${YELLOW}Menjalankan Konfigurasi Awal. Silakan masukkan data Anda...${NC}"
# Jalankan skrip edu untuk pertama kali dan sembunyikan outputnya yang tidak perlu
/usr/bin/edu > /dev/null 2>&1

# --- 6. Mengatur Otomatisasi ---
echo -e "${YELLOW}-------------------------------------------------${NC}"
echo -e "${YELLOW}[6/6] Mengatur jadwal (cron) dan mengaktifkan service...${NC}"

# Menambahkan cron job setiap 6 jam tanpa menghapus yang sudah ada
(crontab -l 2>/dev/null | grep -v "/usr/bin/edu"; echo "0 */6 * * * /usr/bin/edu") | crontab -
echo -e "${GREEN} -> Cron job untuk pengecekan 6 jam sekali berhasil ditambahkan.${NC}"

# Mengaktifkan dan memulai service pemantau ping
/etc/init.d/edu-monitor enable > /dev/null 2>&1
/etc/init.d/edu-monitor start
echo -e "${GREEN} -> Service pemantau ping berhasil diaktifkan dan dijalankan.${NC}"

rm /root/edy.sh
echo ""
echo -e "${YELLOW}=================================================${NC}"
echo -e "${GREEN}🎉          INSTALASI SELESAI!           🎉${NC}"
echo -e "${YELLOW}Sistem sekarang berjalan otomatis.${NC}"
echo -e "${YELLOW}=================================================${NC}"
