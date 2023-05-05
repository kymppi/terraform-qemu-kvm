variable "libvirt_image_pool" {
  type        = string
  description = "The name of the libvirt storage pool to use for the images, you can list them with virsh pool-list"
  default     = "default"
}

variable "kubernetes_master" {
  type = object({
    count = number
    ips   = list(string)
  })

  default = {
    count = 1
    ips   = ["192.168.122.200"]
  }

  validation {
    condition     = var.kubernetes_master.count <= length(var.kubernetes_master.ips)
    error_message = "Not enough IP addresses for master nodes"
  }

  validation {
    condition     = var.kubernetes_master.count >= 1
    error_message = "At least one master node is required"
  }

  validation {
    condition     = length(var.kubernetes_master.ips) >= 1
    error_message = "At least one IP address is required"
  }
}
