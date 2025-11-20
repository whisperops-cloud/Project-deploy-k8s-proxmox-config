#!/bin/sh
# Variables communes
TEMPLATE_DIR="/root/cloud-version"
STORAGE_POOL="ceph-templates"
BRIDGE="vmbr0"
CORES=2
MEMORY=2048
DISK_SIZE="25G"
CLOUDINIT_DISK="${STORAGE_POOL}:cloudinit"
# Création de répertoires et de l'arborescence de travail
mkdir -p "$TEMPLATE_DIR"
cd "$TEMPLATE_DIR"
# Fonction pour créer un template
create_template_BIOS() {
    local id=$1
    local name=$2
    local url=$3
    local img_file=$(basename "$url")
    echo "Création du template $name"
    mkdir -p "$name"
    cd "$name"
    wget "$url"
    qm create "$id" --name "$name" --net0 virtio,bridge="$BRIDGE" --scsihw virtio-scsi-single
    qm set "$id" --scsi0 "${STORAGE_POOL}:0,iothread=1,backup=off,format=qcow2,import-from=${TEMPLATE_DIR}/${name}/${img_file}"
    qm disk resize "$id" scsi0 "$DISK_SIZE"
    qm set "$id" --boot order=scsi0
    qm set "$id" --cpu host --cores "$CORES" --memory "$MEMORY"
    qm set "$id" --ide2 "$CLOUDINIT_DISK"
    qm set "$id" --tags "templates"
    qm set "$id" --agent enabled=1
    qm template "$id"
    cd ..
    echo "Fin de création du template $name"
}

create_template_UEFI() {

    local id=$1
    local name=$2
    local url=$3
    local img_file=$(basename "$url")

    echo "Création du template UEFI $name"

    mkdir -p "$name"
    cd "$name"

    # Télécharger l'image cloud
    wget -N "$url"

    # Créer la VM (sans disque encore)
    qm create "$id" \
        --name "$name" \
        --net0 virtio,bridge="$BRIDGE" \
        --cpu host \
        --cores "$CORES" \
        --memory "$MEMORY" \
        --scsihw virtio-scsi-pci \
        --bios ovmf

    # Importer le disque principal qcow2
    qm importdisk "$id" "${TEMPLATE_DIR}/${name}/${img_file}" "$STORAGE_POOL" --format qcow2

    # Attacher le disque importé en SCSI
    qm set "$id" --scsi0 "$STORAGE_POOL":vm-"$id"-disk-0,backup=off,iothread=1

    # Ajouter le disque Cloud-Init
    qm set "$id" --ide2 "$CLOUDINIT_DISK",media=cdrom

    # Ajouter le disque EFI (256M c’est standard)
    qm set "$id" --efidisk0 "$STORAGE_POOL":0,size=256M

    # Boot sur SCSI
    qm set "$id" --boot order=scsi0

    # Activer l'agent QEMU et les tags
    qm set "$id" --agent enabled=1
    qm set "$id" --tags "templates"

    # Convertir en template
    qm template "$id"

    cd ..
    echo "Fin de création du template UEFI $name"
}


# Templates 
# create_template 9018 "template-ubuntu-18" "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
# create_template 9020 "template-ubuntu-20" "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
# create_template 9022 "template-ubuntu-22" "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
# create_template 9024 "template-ubuntu-24" "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
# create_template 9013 "template-debian-13" "https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2"
# create_template 9010 "template-debian-10" "https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2"
# create_template 9011 "template-debian-11" "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2"
# create_template 9012 "template-debian-12" "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
# create_template 9008 "template-alma-8" "https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-8.10-20240819.x86_64.qcow2"
create_template_UEFI 9009 "template-alma-9" "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
create_template_UEFI 9010 "template-alma-10" "https://repo.almalinux.org/almalinux/10/cloud/x86_64/images/AlmaLinux-10-GenericCloud-latest.x86_64.qcow2"
# create_template 9023 "template-amazon-23" "https://cdn.amazonlinux.com/al2023/os-images/2023.7.20250512.0/kvm/al2023-kvm-2023.7.20250512.0-kernel-6.1-x86_64.xfs.gpt.qcow2"
create_template_UEFI 9099 "template-rocky-9" "https://download.rockylinux.org/pub/rocky/9.6/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
create_template_UEFI 9100 "template-rocky-10" "https://download.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2"


# PoOlS
pvesh create /pools --poolid zone-templates --comment "Templates here"
pvesh create /pools --poolid zone-kubernetes --comment "K8s VM"
pvesh create /pools --poolid zone-application --comment "Other stack"

pvesh set /pools/zone-templates --vm 9013
pvesh set /pools/zone-templates --vm 9009
pvesh set /pools/zone-templates --vm 9022

# Bannière
cat <<'EOF'

██████╗ ██████╗  ██████╗ ██╗  ██╗███╗   ███╗ ██████╗ ██╗  ██╗    ██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗    ██████╗     ██████╗ ██╗   ██╗███╗   ██╗
██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝████╗ ████║██╔═══██╗╚██╗██╔╝    ██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝    ╚════██╗    ██╔══██╗██║   ██║████╗  ██║
██████╔╝██████╔╝██║   ██║ ╚███╔╝ ██╔████╔██║██║   ██║ ╚███╔╝     ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝      █████╔╝    ██████╔╝██║   ██║██╔██╗ ██║
██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗ ██║╚██╔╝██║██║   ██║ ██╔██╗     ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝      ██╔═══╝     ██╔══██╗██║   ██║██║╚██╗██║
██║     ██║  ██║╚██████╔╝██╔╝ ██╗██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗    ██║  ██║███████╗██║  ██║██████╔╝   ██║       ███████╗    ██║  ██║╚██████╔╝██║ ╚████║
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝       ╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                                                                                                     
             ⚙ Installation completed ⚙

EOF



# =============================================================================
# 🎉 HAPPY END – Proxmox Ready2Run Complete
# =============================================================================

clear

echo
echo "────────────────────────────────────────────────────────"
echo "  ✅  Configuration Proxmox finalisée avec succès"
echo "────────────────────────────────────────────────────────"
echo
echo "Résumé des opérations effectuées :"
echo
echo " • Dépôts configurés en mode 'no-subscription'"
echo " • Utilisateurs administratifs créés : adminpam et adminpve"
echo " • Token d'accès généré pour l'automatisation (adminpve)"
echo " • Sécurisation du système :"
echo "     - Modification des ports par défaut"
echo "     - Mise en place et configuration de Fail2ban"
echo " • Pools créés :"
echo "     - 'kubernetes' pour les futurs nodes"
echo "     - 'templates' pour les images de base"
echo " • Templates cloud/VM importés et prêts à l'emploi"
echo
echo "────────────────────────────────────────────────────────"
echo "  🎯 Le nœud est désormais prêt pour le déploiement"
echo "      Kubernetes | Ceph | LXC | Automatisation CI/CD"
echo "────────────────────────────────────────────────────────"
echo
echo "💡 Prochaine étape : Déployer les clusters. À toi de jouer."
echo
echo "Fin du script."
echo



echo "Fin de création du paramétrage de bases de  proxmox"

