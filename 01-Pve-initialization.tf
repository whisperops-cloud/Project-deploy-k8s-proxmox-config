resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/hosts.tpl", {
    ip_pves = var.ip_pves
  })
  filename = "${path.module}/inventory.ini"
}

resource "null_resource" "configure_pve" {
  triggers = {
    inventory_hash = sha1(local_file.ansible_inventory.content)
  }

  provisioner "local-exec" {
    command = <<EOT
ansible-playbook \
  -i ${path.module}/inventory.ini \
  playbooks/pve_setup.yaml \
  --private-key ${var.ssh_private_key} \
  -u ${var.ssh_user}
EOT
  }
}
