#!/bin/bash
set -euo pipefail

######################################################################
# 🔐 SCRIPT DE DURCISSEMENT PROXMOX & SSH
# - SSH : passe au sshd_config fourni (/tmp/conf/sshd_config)
# - GUI Proxmox : 8006 → $NEW_GUI_PORT
# - Fail2ban activé + logs stockés dans /home/adminpam/keyvault/
# Auteur : Jérôme Quandalle
######################################################################

### === CONFIGURATION === ###
NEW_GUI_PORT="64086"
SSH_CONFIG="/etc/ssh/sshd_config"
DATE_TAG=$(date +%Y%m%d%H%M%S)

LOG_DIR="/home/adminpam/keyvault"
FINAL_LOG="${LOG_DIR}/port_de_connexion.log"

PVE_FILES_TO_PATCH=(
    "/usr/share/perl5/PVE/Firewall.pm"
    "/usr/share/perl5/PVE/Cluster/Setup.pm"
    "/usr/share/perl5/PVE/APIServer/AnyEvent.pm"
    "/usr/share/perl5/PVE/API2/LXC.pm"
    "/usr/share/perl5/PVE/API2/Qemu.pm"
    "/usr/share/perl5/PVE/APIClient/LWP.pm"
    "/usr/share/perl5/PVE/CLI/pct.pm"
    "/usr/share/perl5/PVE/CLI/qm.pm"
    "/usr/share/perl5/PVE/Service/pveproxy.pm"
)

### === VÉRIFICATION ROOT === ###
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en root."
    exit 1
fi

### === LOGGING === ###
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.bak-${DATE_TAG}"
        log "📦 Backup : $file → ${file}.bak-${DATE_TAG}"
    fi
}

### === CONFIGURATION SSH === ###
secure_ssh_port() {
    log "🔧 Configuration SSH : remplacement du sshd_config"

    backup_file "$SSH_CONFIG"

    if [[ ! -f /tmp/conf/sshd_config ]]; then
        log "❌ ERREUR : /tmp/conf/sshd_config est manquant."
        exit 1
    fi

    cp /tmp/conf/sshd_config "$SSH_CONFIG"
    systemctl restart sshd
    log "✅ SSH configuré et redémarré"
}

### === MODIFICATION DU PORT GUI PROXMOX === ###
change_pve_gui_port() {
    log "🌐 Changement du port GUI Proxmox → $NEW_GUI_PORT"

    for file in "${PVE_FILES_TO_PATCH[@]}"; do
        backup_file "$file"
        sed -i "s|8006|${NEW_GUI_PORT}|g" "$file"
    done

    systemctl restart pveproxy pvedaemon
    log "✅ Proxmox GUI maintenant sur : https://<host>:${NEW_GUI_PORT}"
}

### === FAIL2BAN === ###
install_and_configure_fail2ban() {
    log "🛡 Installation & Configuration fail2ban"

    apt-get update -y
    apt-get install -y fail2ban

    [[ -f /tmp/conf/jail.local ]] && cp /tmp/conf/jail.local /etc/fail2ban/jail.local && chmod 640 /etc/fail2ban/jail.local
    [[ -f /tmp/conf/fail2ban-filter-proxmox.conf ]] && cp /tmp/conf/fail2ban-filter-proxmox.conf /etc/fail2ban/filter.d/proxmox.conf && chmod 644 /etc/fail2ban/filter.d/proxmox.conf

    systemctl daemon-reload
    systemctl enable --now fail2ban
    systemctl restart fail2ban
    log "✅ Fail2ban actif et configuré"
}

### === LOG FINAL === ###
write_final_log() {
    mkdir -p "$LOG_DIR"
    chown adminpam:adminpam "$LOG_DIR"
    chmod 700 "$LOG_DIR"

    cat <<EOF > "$FINAL_LOG"
┌────────────────────────────────────────────────────────┐
│        🔐 CONFIGURATION DE SÉCURITÉ APPLIQUÉE           │
├────────────────────────────────────────────────────────┤
│   🕒 Date : $(date '+%Y-%m-%d %H:%M:%S')
│   ✅ Fail2ban activé
│   ✅ Proxmox GUI → Port : ${NEW_GUI_PORT}
│
│   📂 Log stocké dans : $FINAL_LOG
└────────────────────────────────────────────────────────┘

⚠️ Pense à mettre à jour les règles firewall si nécessaire.
EOF

    chown adminpam:adminpam "$FINAL_LOG"
    chmod 600 "$FINAL_LOG"
    log "📝 Journal créé : $FINAL_LOG"
}

### === BANNIÈRE === ###
cat <<'EOF'
███████╗███████╗ ██████╗██╗   ██╗██████╗ ███████╗     █████╗  ██████╗ ██████╗███████╗███████╗███████╗
██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██╔════╝    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
███████╗█████╗  ██║     ██║   ██║██████╔╝█████╗      ███████║██║     ██║     █████╗  ███████╗███████╗
╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██╔══╝      ██╔══██║██║     ██║     ██╔══╝  ╚════██║╚════██║
███████║███████╗╚██████╗╚██████╔╝██║  ██║███████╗    ██║  ██║╚██████╗╚██████╗███████╗███████║███████║
╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝
      🔒 DURCISSEMENT DES PORTS SSH & GUI PROXMOX

EOF
echo

### === EXÉCUTION === ###
log "🚀 Démarrage"
secure_ssh_port
install_and_configure_fail2ban
change_pve_gui_port
write_final_log
log "✅ Terminé avec succès"


























