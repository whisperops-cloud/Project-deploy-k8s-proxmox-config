#!/bin/bash
set -euo pipefail

########################################
#  Proxmox No-Subscription Patch + UI  #
########################################

# Vérification root
if [[ "$EUID" -ne 0 ]]; then
    echo "Ce script doit être exécuté en root."
    exit 1
fi

# Bannière
cat <<'EOF'

██████╗ ██████╗  ██████╗ ██╗  ██╗███╗   ███╗ ██████╗ ██╗  ██╗
██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝████╗ ████║██╔═══██╗╚██╗██╔╝
██████╔╝██████╔╝██║   ██║ ╚███╔╝ ██╔████╔██║██║   ██║ ╚███╔╝
██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗ ██║╚██╔╝██║██║   ██║ ██╔██╗
██║     ██║  ██║╚██████╔╝██╔╝ ██╗██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝
              ⚙ NO-SUB FIX & CUSTOM UI ⚙

EOF

# Fonction de log
log() {
    echo -e "[\033[1;34m$(date +'%Y-%m-%d %H:%M:%S')\033[0m] $*"
}
########################################
# Patch du thème web Proxmox
########################################

patch_proxmox_web() {
    log "Installation du thème 'PVE Discord Dark'..."
    bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh) install

    log "Redémarrage de pveproxy.service..."
    systemctl restart pveproxy.service

    log "Interface Web patchée avec succès."
}


########################################
#   Mise à jour des sources apt
########################################

patch_proxmox_repository() {

log "Préparation des dépôts No-Subscription..."

ARCHIVE_DIR="/root/archive_no_sub"
mkdir -p "$ARCHIVE_DIR"

declare -a LISTS=(
    "/etc/apt/sources.list.d/ceph.list"
    "/etc/apt/sources.list.d/pve-enterprise.list"
)

for f in "${LISTS[@]}"; do
    if [[ -f "$f" ]]; then
        mv -v "$f" "$ARCHIVE_DIR/"
    fi
done

if ls /tmp/conf/*.sources >/dev/null 2>&1; then
    mv -v /tmp/conf/*.sources /etc/apt/sources.list.d/
else
    log "Aucun fichier .sources trouvé dans /tmp — Rien à copier."
fi

log "Dépôts No-Subscription appliqués."

}

########################################
#   Mise à jour du système
########################################

update_proxmox_system() {

log "Mise à jour des index APT..."
apt update -y

log "Mise à niveau complète du système..."
apt upgrade -y

log "Système à jour."

}

########################################
#   Patch UI Web
########################################

patch_proxmox_repository
update_proxmox_system
patch_proxmox_web

log "Terminé. Proxmox est maintenant en mode No-Sub + Dark UI."
