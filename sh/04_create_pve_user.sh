#!/bin/bash

############################################################
# SCRIPT DE CREATION D'UN UTILISATEUR ADMINISTRATEUR PROXMOX
# 
# - Crée un utilisateur Proxmox VE (adminpve) en tant qu'administrateur
# - Génère un token API sans séparation de privilèges
# - Stocke le token dans /home/adminlocal/keyvault/
#
# Auteurs : Jerome Quandalle
############################################################


### --- VARIABLES --- ###

PVE_USER="adminpve@pve"
PVE_USERNAME="adminpve"
PVE_REALM="pve"
PVE_PASSWORD="Ch@nge-me!!"
PVE_ROLE="Administrator"
TOKEN_NAME="admintoken"
TOKEN_DIR="/home/adminpam/keyvault"
TOKEN_PATH="${TOKEN_DIR}/${TOKEN_NAME}.token"

### --- FONCTIONS UTILES --- ###

create_pve_user() {
    echo "[+] Création de l'utilisateur PVE : $PVE_USER"
    pveum user add "$PVE_USER" --password "$PVE_PASSWORD"
    pveum acl modify / --user "$PVE_USER" --role "$PVE_ROLE"
}

generate_api_token() {
    echo "[+] Création du dossier de stockage : $TOKEN_DIR"
    mkdir -p "$TOKEN_DIR"
    chown "adminpam":"$PAM_USER" "$TOKEN_DIR"
    chmod 700 "$TOKEN_DIR"

    
    echo "[+] Création du token API pour $PVE_USER (nom: $TOKEN_NAME)"
    pveum user token add "$PVE_USER" "$TOKEN_NAME" --privsep=0 >> $TOKEN_PATH
    
    echo "[✓] Token enregistré dans : $TOKEN_PATH"
}



### --- EXECUTION --- ###
echo "=== DÉBUT DU SCRIPT DE CONFIGURATION PROXMOX ==="
create_pve_user
generate_api_token
echo "=== FIN DU SCRIPT === ✅"
### --- END --- ###
