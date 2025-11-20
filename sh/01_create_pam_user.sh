#!/bin/bash

set -euo pipefail

######################################################################
# 🛠️  SCRIPT DE CRÉATION D'UN UTILISATEUR ADMINISTRATEUR PROXMOX     #
# - Crée un utilisateur PAM local                                     #
# - Génère une paire de clés SSH RSA 4096 bits                        #
# - Affecte les rôles d'administrateur sur l'interface Proxmox        #
# - Auteur : Jérôme Quandalle                                         #
######################################################################

# === Configuration ===
PAM_USER="adminpam"
PAM_PASSWORD="Ch@nge-me!!"
PAM_MAIL="jerome.quandalle@gmail.com"

# === Fonction de log ===
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# === Création d'un utilisateur PAM local avec rôle administrateur Proxmox ===
create_pam_user() {
    log "🔧 Création de l'utilisateur PAM local : $PAM_USER"

    if id "$PAM_USER" &>/dev/null; then
        log "⚠️  L'utilisateur $PAM_USER existe déjà. Passage de la création."
    else
        useradd -m "$PAM_USER"
        echo "$PAM_USER:$PAM_PASSWORD" | chpasswd
        echo "$PAM_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$PAM_USER"
        chmod 440 "/etc/sudoers.d/$PAM_USER"
        log "✅ Utilisateur PAM créé et ajouté aux sudoers."
    fi

    apt update -y && apt install -y sudo

    # Ajout manuel dans la conf Proxmox
    if ! grep -q "$PAM_USER@pam" /etc/pve/user.cfg; then
        echo "user:$PAM_USER@pam:1:0:::$PAM_MAIL::" >> /etc/pve/user.cfg
        echo "acl:1:/:$PAM_USER@pam:Administrator:" >> /etc/pve/user.cfg
        log "✅ Utilisateur ajouté à la configuration Proxmox avec rôle Administrator."
    else
        log "ℹ️  Utilisateur déjà présent dans /etc/pve/user.cfg"
    fi
}

# === Génération d'une paire de clés SSH RSA pour l'utilisateur ===
generate_ssh_key_for_user() {
    local USERNAME="$1"
    local USER_HOME SSH_DIR KEY_PATH AUTHORIZED

    # Vérifie l'existence de l'utilisateur
    if ! id "$USERNAME" &>/dev/null; then
        log "❌ Utilisateur '$USERNAME' introuvable."
        return 1
    fi

    USER_HOME=$(eval echo "~$USERNAME")
    SSH_DIR="$USER_HOME/.ssh"
    KEY_PATH="$SSH_DIR/id_rsa"
    AUTHORIZED="$SSH_DIR/authorized_keys"

    log "🔐 Génération de la clé SSH pour l'utilisateur : $USERNAME"

    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    chown "$USERNAME:$USERNAME" "$SSH_DIR"

    # Génère la clé uniquement si elle n'existe pas
    if [[ -f "$KEY_PATH" ]]; then
        log "⚠️  La clé SSH existe déjà pour $USERNAME. Aucun changement effectué."
    else
        ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "$USERNAME@$(hostname)" <<< y >/dev/null 2>&1
        log "✅ Clé SSH générée."
    fi

    # Ajout de la clé publique root dans authorized_keys (optionnel)
    if [[ -f /root/.ssh/authorized_keys ]]; then
        cat /root/.ssh/authorized_keys >> "$AUTHORIZED"
    fi

    # Permissions
    chown "$USERNAME:$USERNAME" "$KEY_PATH" "$KEY_PATH.pub" "$AUTHORIZED"
    chmod 600 "$KEY_PATH"
    chmod 644 "$KEY_PATH.pub" "$AUTHORIZED"

    log "📁 Clés installées pour $USERNAME :"
    log "    - Privée : $KEY_PATH"
    log "    - Publique : ${KEY_PATH}.pub"
}

# === EXÉCUTION ===
echo
cat <<'EOF'

██████╗  █████╗ ███╗   ███╗     █████╗ ██████╗ ███╗   ███╗██╗███╗   ██╗
██╔══██╗██╔══██╗████╗ ████║    ██╔══██╗██╔══██╗████╗ ████║██║████╗  ██║
██████╔╝███████║██╔████╔██║    ███████║██║  ██║██╔████╔██║██║██╔██╗ ██║
██╔═══╝ ██╔══██║██║╚██╔╝██║    ██╔══██║██║  ██║██║╚██╔╝██║██║██║╚██╗██║
██║     ██║  ██║██║ ╚═╝ ██║    ██║  ██║██████╔╝██║ ╚═╝ ██║██║██║ ╚████
        👤 UTILISATEUR ADMIN PAM PROXMOX + CLÉ SSH
EOF
echo

log "🚀 Démarrage du script"
create_pam_user
generate_ssh_key_for_user "$PAM_USER"
log "✅ Script terminé avec succès."
