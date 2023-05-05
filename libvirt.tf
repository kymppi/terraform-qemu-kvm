# Defining VM Volume
resource "libvirt_volume" "debian11-qcow2" {
  name   = "debian11.qcow2"
  pool   = var.libvirt_image_pool
  source = "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "kubernetes-master" {
  name           = "kubernetes-master-${count.index}.qcow2"
  base_volume_id = libvirt_volume.debian11-qcow2.id
  count          = var.kubernetes_master.count
}

# get user data info
data "template_file" "kubernetes_master_cloud_init" {
  template = file("${path.module}/cloud_init.cfg")
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "kubernetes_master_common_init" {
  name      = "kubernetes_master_common_init-${count.index}.iso"
  pool      = var.libvirt_image_pool
  user_data = data.template_file.kubernetes_master_cloud_init.rendered
  count     = var.kubernetes_master.count
}

resource "libvirt_domain" "kubernetes-master" {
  count = var.kubernetes_master.count

  name   = "kubernetes_master-${count.index}"
  memory = "2048"
  vcpu   = 2

  network_interface {
    network_name   = "default" # List networks with virsh net-list
    hostname       = "kubernetes_master-${count.index}"
    wait_for_lease = true
    addresses      = [var.kubernetes_master.ips[count.index]]
  }

  disk {
    volume_id = libvirt_volume.kubernetes-master[count.index].id
  }

  cloudinit = libvirt_cloudinit_disk.kubernetes_master_common_init[count.index].id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Output Kubernetes Master IPs next to the VM names
output "kubernetes_master_ips" {
  value = {
    for vm in libvirt_domain.kubernetes-master :
    vm.name => vm.network_interface.0.addresses.0
  }
}
