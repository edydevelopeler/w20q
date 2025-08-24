#!/bin/sh
# --- LOKASI FILE & NAMA SERVICE ---
CONFIG_FILE="/etc/config/edu_config.conf"
SERVICE_FILE="/etc/init.d/edu-monitor"
LOG_FILE="/var/log/edu-monitor.log"
# Lokasi skrip ini akan dipasang
INSTALL_PATH="/usr/bin/edu-monitor"

# --- Definisi Warna ---
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

# --- Fungsi untuk mengirim notifikasi ---
send_telegram_notification() {
    # Muat konfigurasi di dalam fungsi agar selalu update
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
    else
        echo "File konfigurasi tidak ditemukan."
        return
    fi
    
    MESSAGE="$1"
    if [ -z "$MESSAGE" ]; then return; fi
    URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
    curl -s --max-time 15 -X POST "$URL" -d chat_id="$CHAT_ID" --data-urlencode "text=$MESSAGE" -d parse_mode="Markdown" > /dev/null
}

# --- Fungsi utama pemantauan koneksi ---
start_monitoring() {
    echo "Memulai skrip pemantau koneksi pada $(date)"
    
    # Muat konfigurasi sekali di awal
    . "$CONFIG_FILE"

    fail_count=0
    # FAIL_THRESHOLD sekarang dimuat dari file konfigurasi
    CHECK_INTERVAL=60 # Pengecekan tetap setiap 1 menit
    STABILIZE_WAIT=180 # Jeda 3 menit setelah beli

    # Tentukan target pengecekan berdasarkan pilihan user
    if [ "$PING_TYPE" = "1" ]; then
        CHECK_TARGET="http://detectportal.firefox.com/success.txt"
        EXPECTED_CONTENT="success"
        CHECK_METHOD="content"
    else
        CHECK_TARGET="104.17.3.81"
        CHECK_METHOD="ping"
    fi

    # Loop selamanya
    while true; do
        connection_ok=false
        # Lakukan pengecekan berdasarkan metode yang dipilih
        if [ "$CHECK_METHOD" = "content" ]; then
            if curl -s --max-time 5 "$CHECK_TARGET" | grep -q "$EXPECTED_CONTENT"; then
                connection_ok=true
            fi
        else # PING_METHOD
            if ping -c 1 -W 5 "$CHECK_TARGET" > /dev/null; then
                connection_ok=true
            fi
        fi

        if $connection_ok; then
            fail_count=0
            echo "[$(date +'%H:%M:%S')] Koneksi terverifikasi (Metode: $CHECK_METHOD)."
        else
            fail_count=$((fail_count + 1))
            echo "[$(date +'%H:%M:%S')] KONEKSI GAGAL! (Percobaan ke-$fail_count dari $FAIL_THRESHOLD)"
        fi

        # Cek jika ambang batas kegagalan tercapai
        if [ "$fail_count" -ge "$FAIL_THRESHOLD" ]; then
            echo "[$(date +'%H:%M:%S')] Menjalankan pembelian paket Edy, Bersiaplahh..."
            
            # Eksekusi perintah ADB langsung
            adb shell am start -a android.intent.action.CALL -d "tel:*808*5*2*1*1%23" && \
            sleep 20 && \
            adb shell input keyevent 4 && \
            sleep 10 && \
            adb shell am start -a android.intent.action.CALL -d "tel:*808*4*1*1*1%23" && \
            sleep 15 && \
            adb shell input keyevent 4 && \
            sleep 3 && \
            adb shell cmd connectivity airplane-mode enable && \
            sleep 3 && \
            adb shell cmd connectivity airplane-mode disable

            echo "[$(date +'%H:%M:%S')] Eksekusi ADB selesai. Notifikasi akan dikirim setelah jeda stabilisasi."

            # Jalankan jeda dan notifikasi di latar belakang
            (
                sleep "$STABILIZE_WAIT"
                send_telegram_notification "🚨 *Koneksi Terputus!*

Ping gagal dan telah menjalankan pembelian paket Edy mmpsshhhshhhh ahhhhhhhh."
                sleep 2
                send_telegram_notification "✅ *Pembelian Paket Edy Selesai*

Paket Edy Aktif su mmpsshhhshhhh ahhhhhhhh."
            ) &

            fail_count=0
            echo "[$(date +'%H:%M:%S')] Pemantauan dilanjutkan setelah jeda notifikasi."
        fi

        # Tunggu sebelum pengecekan berikutnya
        sleep "$CHECK_INTERVAL"
    done
}

# --- Fungsi instalasi ---
run_installation() {
    clear
    echo -e "${YELLOW}###########################################${NC}"
    echo -e "${YELLOW}#####${RED}    Installer Edu Auto BuyEdu    ${YELLOW}#####${NC}"
    echo -e "${YELLOW}#####${GREEN}      Modder EdyDevelopeler      ${YELLOW}#####${NC}"
    echo -e "${YELLOW}###########################################${NC}"
    echo ""

    # 1. Instalasi Dependensi
    echo -e "${YELLOW}[1/4] Menginstal dependensi...${NC}"
    opkg update > /dev/null 2>&1
    opkg install curl coreutils-date adb > /dev/null 2>&1
    echo -e "${GREEN} -> Dependensi berhasil diinstal.${NC}"

    # 2. Konfigurasi Awal
    echo ""
    echo -e "${YELLOW}[2/4] Konfigurasi Awal. Silakan masukkan data Anda...${NC}"
    
    printf "Masukkan BOT_TOKEN: "
    read BOT_TOKEN
    printf "Masukkan CHAT_ID: "
    read CHAT_ID
    
    echo "Pilih Jenis Pengecekan Koneksi:"
    echo "  1) Ping Konten"
    echo "  2) Ping ke Bug (104.17.3.81)"
    printf "Pilihan [1/2]: "
    read PING_TYPE
    if [ "$PING_TYPE" != "2" ]; then
        PING_TYPE="1"
    fi

    # --- PERUBAHAN DI SINI ---
    echo "Pilih Jumlah Percobaan Gagal Ping (Default: 3x):"
    echo "  1) 1 Kali"
    echo "  2) 2 Kali"
    echo "  3) 3 Kali"
    printf "Pilihan [1/2/3]: "
    read THRESHOLD_CHOICE
    
    case "$THRESHOLD_CHOICE" in
        1) FAIL_THRESHOLD=1 ;;
        2) FAIL_THRESHOLD=2 ;;
        *) FAIL_THRESHOLD=3 ;;
    esac
    # --- AKHIR PERUBAHAN ---

    # Simpan konfigurasi
    echo "BOT_TOKEN='${BOT_TOKEN}'" > "$CONFIG_FILE"
    echo "CHAT_ID='${CHAT_ID}'" >> "$CONFIG_FILE"
    echo "PING_TYPE='${PING_TYPE}'" >> "$CONFIG_FILE"
    echo "FAIL_THRESHOLD='${FAIL_THRESHOLD}'" >> "$CONFIG_FILE"
    echo -e "${GREEN} -> Konfigurasi berhasil disimpan.${NC}"

    # 3. Pemasangan Skrip & Service
    echo -e "${YELLOW}[3/4] Memasang skrip dan membuat service...${NC}"
    # Salin diri sendiri ke lokasi instalasi
    cp "$0" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"

    # Buat file service
    cat <<EOF > "$SERVICE_FILE"
#!/bin/sh /etc/rc.common
SERVICE_NAME="edu-monitor"
SERVICE_SCRIPT="$INSTALL_PATH"
LOG_FILE="$LOG_FILE"
START=99
STOP=10

start() {
    echo "Starting \$SERVICE_NAME"
    nohup "\$SERVICE_SCRIPT" --start-monitor >> "\$LOG_FILE" 2>&1 &
}

stop() {
    echo "Stopping \$SERVICE_NAME"
    # Menggunakan killall untuk menghentikan proses berdasarkan nama skrip
    killall -q \$(basename "\$SERVICE_SCRIPT")
}
EOF
    chmod +x "$SERVICE_FILE"
    echo -e "${GREEN} -> Service berhasil dibuat.${NC}"

    # 4. Aktivasi
    echo -e "${YELLOW}[4/4] Mengaktifkan dan memulai service...${NC}"
    "$SERVICE_FILE" enable > /dev/null 2>&1
    "$SERVICE_FILE" start
    echo -e "${GREEN} -> Service berhasil diaktifkan dan dijalankan.${NC}"

    # Hapus file installer
    rm -- "$0"

    echo ""
    echo -e "${YELLOW}=================================================${NC}"
    echo -e "${GREEN}🎉          INSTALASI SELESAI!           🎉${NC}"
    echo -e "${YELLOW}Sistem sekarang berjalan otomatis.${NC}"
    echo -e "${YELLOW}Log pemantauan bisa dilihat di: $LOG_FILE${NC}"
    echo -e "${YELLOW}=================================================${NC}"
}

# =============================================================================
# LOGIKA UTAMA
# =============================================================================

# Cek argumen yang diberikan saat skrip dijalankan
case "$1" in
    --start-monitor)
        # Jika argumennya --start-monitor, jalankan fungsi pemantauan
        start_monitoring
        ;;
    *)
        # Jika tidak ada argumen (atau argumen lain), jalankan fungsi instalasi
        run_installation
        ;;
esac
