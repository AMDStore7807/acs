#!/bin/bash
set -e  # Berhenti kalau ada error fatal

# ============================================================
#  Warna & Log
# ============================================================
BLUE='\033[38;5;110m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
LOG_FILE="/var/log/beatcom-restart.log"
mkdir -p /var/log
exec > >(tee -a "$LOG_FILE") 2>&1

local_ip=$(hostname -I | awk '{print $1}')

# ============================================================
#  BEATCOM Banner
# ============================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}=========== BBBBB  EEEEE     AAA    TTTTT  CCCC  OOO   M   M ===============${NC}"   
echo -e "${BLUE}========== B    B E         AAAAA     T   C     O   O  MM MM ===============${NC}" 
echo -e "${BLUE}=========  BBBBB  EEEE     AA   AA    T   C     O   O  M M M ===============${NC}"
echo -e "${BLUE}========== B    B E       AAAAAAAA    T   C     O   O  M   M ===============${NC}"
echo -e "${BLUE}=========== BBBBB  EEEEE  AA     AA   T    CCCC  OOO   M   M ===============${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}====================  GenieACS Restart Utility by BEATCOM ==================${NC}"
echo -e "${BLUE}============================================================================${NC}"

# ============================================================
#  Konfirmasi
# ============================================================
echo -e "${BLUE}Apakah anda ingin melanjutkan proses restart semua service? (y/n)${NC}"
read confirmation
if [ "$confirmation" != "y" ]; then
    echo -e "${RED}Dibatalkan. Tidak ada perubahan.${NC}"
    exit 1
fi

for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Melanjutkan dalam $i detik... Tekan Ctrl+C untuk membatalkan."
done

# ============================================================
#  Cek & Jalankan MongoDB
# ============================================================
echo -e "${BLUE}================== Mengecek MongoDB ==================${NC}"
if ! systemctl is-active --quiet mongod; then
    echo -e "${RED}MongoDB tidak aktif. Menyalakan...${NC}"
    systemctl start mongod
    sleep 2
    if systemctl is-active --quiet mongod; then
        echo -e "${GREEN}MongoDB berhasil dijalankan.${NC}"
    else
        echo -e "${RED}Gagal menjalankan MongoDB. Periksa dengan: journalctl -u mongod -xe${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}MongoDB sudah aktif.${NC}"
fi

# ============================================================
#  Restart Semua Service GenieACS
# ============================================================
SERVICES=(
  "genieacs-cwmp"
  "genieacs-nbi"
  "genieacs-fs"
  "genieacs-ui"
)

echo -e "${BLUE}================== Merestart GenieACS ==================${NC}"
for SERVICE in "${SERVICES[@]}"; do
    if systemctl list-units --type=service | grep -q "$SERVICE"; then
        echo -e "${BLUE}Restarting $SERVICE...${NC}"
        systemctl restart "$SERVICE"
        sleep 1
        if systemctl is-active --quiet "$SERVICE"; then
            echo -e "${GREEN}$SERVICE berjalan dengan baik.${NC}"
        else
            echo -e "${RED}$SERVICE gagal dijalankan. Cek: journalctl -u $SERVICE -xe${NC}"
        fi
    else
        echo -e "${RED}Service $SERVICE tidak ditemukan di systemd. Lewati...${NC}"
    fi
done

# ============================================================
#  Selesai
# ============================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}================ Semua Service Sudah Diperiksa & Dijalankan ================${NC}"
echo -e "${GREEN}=========== Akses UI: http://$local_ip:3000 ===============================${NC}"
echo -e "${GREEN}================ Log tersimpan di: $LOG_FILE ==============================${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}=================== BEATCOM Maintenance Utility ===========================${NC}"
echo -e "${BLUE}============================================================================${NC}"
