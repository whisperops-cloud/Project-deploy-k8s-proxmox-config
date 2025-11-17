variable "ip_pves" {
  description = "Liste des adresses IP des nœuds Proxmox VE"
  type        = list(string)
}

variable "pve_master_ip" {
  description = "Adresse IP du nœud maître Proxmox (utilisé comme point principal)"
  type        = string
}

variable "ssh_user" {
  description = "Nom d'utilisateur SSH utilisé pour l'accès aux nœuds Proxmox"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = "Chemin vers la clé privée SSH pour se connecter aux nœuds Proxmox"
  type        = string
}

