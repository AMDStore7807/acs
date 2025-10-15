#!/bin/bash
set -e  # Stop script jika ada error fatal

# Warna
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Log file
LOG_FILE="/var/log/beatcom-install.log"
mkdir -p /var/log
exec > >(tee -a "$LOG_FILE") 2>&1  # Semua output ke terminal + file log

local_ip=$(hostname -I | awk '{print $1}')


# ============================================================
# BEATCOM Banner
# ============================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}=========== BBBBB  EEEEE     AAA    TTTTT  CCCC  OOO   M   M ===============${NC}"   
echo -e "${BLUE}========== B    B E         AAAAA     T   C     O   O  MM MM ===============${NC}" 
echo -e "${BLUE}=========  BBBBB  EEEE     AA   AA    T   C     O   O  M M M ===============${NC}"
echo -e "${BLUE}========== B    B E       AAAAAAAA    T   C     O   O  M   M ===============${NC}"
echo -e "${BLUE}=========== BBBBB  EEEEE  AA     AA   T    CCCC  OOO   M   M ===============${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}========================= . Info 081-947-215-703 ========================== ${NC}"
echo -e "${BLUE}============================================================================${NC}"

# ============================================================
# Mode Pilihan
# ============================================================
echo -e "${BLUE}Pilih mode instalasi:${NC}"
echo "1. Default Mode"
echo "2. Dark Mode"
read -p "Masukkan pilihan (1/2): " mode_choice

if [ "$mode_choice" == "2" ]; then
    MODE="dark"
    echo -e "${BLUE}Mode terpilih: Dark Mode${NC}"
else
    MODE="default"
    echo -e "${BLUE}Mode terpilih: Default Mode${NC}"
fi

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Apakah anda ingin melanjutkan instalasi? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${RED}Install dibatalkan. Tidak ada perubahan dalam sistem anda.${NC}"
    exit 1
fi

for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Melanjutkan dalam $i detik... Tekan Ctrl+C untuk membatalkan."
done

# ============================================================
# Cek & Install NodeJS
# ============================================================
check_node_version() {
    if command -v node > /dev/null 2>&1; then
        NODE_VERSION=$(node -v | cut -d 'v' -f 2)
        NODE_MAJOR_VERSION=$(echo $NODE_VERSION | cut -d '.' -f 1)
        NODE_MINOR_VERSION=$(echo $NODE_VERSION | cut -d '.' -f 2)

        if [ "$NODE_MAJOR_VERSION" -lt 12 ] || { [ "$NODE_MAJOR_VERSION" -eq 12 ] && [ "$NODE_MINOR_VERSION" -lt 13 ]; } || [ "$NODE_MAJOR_VERSION" -gt 22 ]; then
            return 1
        else
            return 0
        fi
    else
        return 1
    fi
}

if ! check_node_version; then
    echo -e "${BLUE}================== Menginstall NodeJS ==================${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    echo -e "${BLUE}================== Sukses Install NodeJS ==================${NC}"
else
    NODE_VERSION=$(node -v)
    echo -e "${BLUE}NodeJS sudah terinstall versi ${NODE_VERSION}${NC}"
fi

# ============================================================
# Install MongoDB (universal, semua Linux)
# ============================================================
if ! systemctl is-active --quiet mongod; then
    echo -e "${BLUE}================== Menginstall MongoDB 6.0 ==================${NC}"
    curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    apt-get update
    apt-get install -y mongodb-org
    systemctl enable --now mongod
    echo -e "${BLUE}================== MongoDB Berhasil Terinstall ==================${NC}"
else
    echo -e "${BLUE}MongoDB sudah aktif.${NC}"
fi

# ============================================================
# Install GenieACS
# ============================================================
if ! systemctl is-active --quiet genieacs-cwmp; then
    echo -e "${BLUE}================== Menginstall GenieACS ==================${NC}"
    npm install -g genieacs@1.2.13
    useradd --system --no-create-home --user-group genieacs || true
    mkdir -p /opt/genieacs/ext /var/log/genieacs
    chown -R genieacs:genieacs /opt/genieacs /var/log/genieacs

cat << EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret_from_beatcom
EOF

    chmod 600 /opt/genieacs/genieacs.env
    chown genieacs:genieacs /opt/genieacs/genieacs.env

    for svc in cwmp nbi fs ui; do
        cat << EOF > /etc/systemd/system/genieacs-$svc.service
[Unit]
Description=GenieACS $svc
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-$svc

[Install]
WantedBy=multi-user.target
EOF
    done

    systemctl daemon-reload
    systemctl enable --now genieacs-{cwmp,fs,nbi,ui}
    echo -e "${BLUE}================== GenieACS Berhasil Terinstall ==================${NC}"
else
    echo -e "${BLUE}GenieACS sudah aktif.${NC}"
fi

# ============================================================
# Atur Firewall
# ============================================================
echo -e "${BLUE}================== Mengatur Firewall ==================${NC}"
if ! ufw status | grep -q "Status: active"; then
    echo -e "${BLUE}Mengaktifkan UFW...${NC}"
    ufw --force enable
fi
ufw allow 22/tcp
ufw allow 7547/tcp
ufw allow 7557/tcp
ufw allow 7567/tcp
ufw allow 3000/tcp
echo -e "${BLUE}Firewall aktif dengan port 22, 7547, 7557, 7567, 3000.${NC}"

# ============================================================
# Darkmode CSS Inject
# ============================================================
# Terapkan tema darkmode jika dipilih
if [ "$INSTALL_MODE" == "dark" ]; then
    echo -e "${BLUE}================== Mengaktifkan Darkmode untuk UI ==================${NC}"
    UI_PATH="/usr/lib/node_modules/genieacs/dist/public"

    # Buat backup CSS asli
    if [ -f "$UI_PATH/style.css" ]; then
        cp "$UI_PATH/style.css" "$UI_PATH/style.css.bak"
    fi

    # Tambahkan CSS darkmode sederhana
    cat << 'EOF' > "$UI_PATH/style-dark.css"
body {
    background-color: #121212 !important;
    color: #e0e0e0 !important;
}
.navbar, .sidebar, .panel, .table {
    background-color: #1e1e1e !important;
    color: #ffffff !important;
}
a, .btn {
    color: #90caf9 !important;
}
EOF

    # Sisipkan referensi CSS dark ke index.html jika belum ada
    INDEX_HTML="$UI_PATH/index.html"
    if ! grep -q "style-dark.css" "$INDEX_HTML"; then
        sed -i '/<\/head>/i <link rel="stylesheet" href="style-dark.css">' "$INDEX_HTML"
        echo -e "${BLUE}Darkmode CSS disisipkan ke index.html${NC}"
    else
        echo -e "${BLUE}Darkmode sudah ada di index.html, dilewati...${NC}"
    fi

    echo -e "${BLUE}================== Darkmode Berhasil Diterapkan! ==================${NC}"
fi


# ============================================================
# Selesai & Info Akses
# ============================================================
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}========== GenieACS UI akses port 3000 : http://$local_ip:3000 =============${NC}"
echo -e "${BLUE}=================== Informasi: Whatsapp 085150614774 =======================${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}============= Install selesai! Log tersimpan di: ${LOG_FILE} ===============${NC}"
echo -e "${BLUE}================ Untuk melihat log: cat ${LOG_FILE} ========================${NC}"
echo -e "${BLUE}================== Instalasi Selesai, GENIEACS Siap Jalan! =================${NC}"
echo -e "${BLUE}============================================================================${NC}"

