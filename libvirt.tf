# Defining VM Volume
resource "libvirt_volume" "debian11-terraform-qcow2" {
  name   = "debian11.qcow2"
  pool   = "default" # List storage pools using virsh pool-list
  source = "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2"
  format = "qcow2"
}

# get user data info
data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  pool      = "default" # List storage pools using virsh pool-list
  user_data = data.template_file.user_data.rendered
}

# Define KVM domain to create
resource "libvirt_domain" "debian11-terraform" {
  name   = "debian11-terraform"
  memory = "2048"
  vcpu   = 2

  network_interface {
    network_name   = "default" # List networks with virsh net-list
    hostname       = "debian11-terraform-1"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.debian11-terraform-qcow2.id
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

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

# Output Server IP
output "ip" {
  value = libvirt_domain.debian11-terraform.network_interface.0.addresses.0
}
