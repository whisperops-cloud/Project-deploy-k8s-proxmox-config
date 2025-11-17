# ----------------------------
# Network configuration
# ----------------------------
ip_pves = [
  "172.16.0.110", # IP du nœud Proxmox 1
  "172.16.0.120", # IP du nœud Proxmox 2
  "172.16.0.130"  # IP du nœud Proxmox 3
]

# Adresse IP du nœud maître Proxmox (ex: premier nœud de la liste)
pve_master_ip = "172.16.0.110"


# ----------------------------
# SSH connection
# ----------------------------
# Nom d'utilisateur SSH (souvent "root")
ssh_user = "root"

# Chemin local vers la clé privée SSH (ex: ~/.ssh/id_ed25519)
ssh_private_key = "~/.ssh/id_ed25519"
