terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = "y0_AgAAAAAEOSJRAATuwQAAAAD4DOe6Hsa8lMrhTTqHtIxgS6CaJBEa0Mg"
  cloud_id  = "Pb1gp6qjp3sreksmq9ju1"
  folder_id = "b1g3hhpc4sj7fmtmdccu"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "vm" {
  count       = 2
  name        = "vm${count.index}"
  platform_id = "standard-v1"

  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  boot_disk {
    initialize_params {
      image_id = "fd81mpc969gbg44vndkv"
      size     = 5
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }

  connection {
    type        = "ssh"
    user        = "denis"
    private_key = file("/home/denis/.ssh/id_rsa")
    host        = self.network_interface[0].nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }
}
resource "yandex_lb_target_group" "lb-target-group-1" {
  name      = "my-target-group"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[0].network_interface.0.ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[1].network_interface.0.ip_address
  }

}

resource "yandex_lb_network_load_balancer" "lb_network_load_balancer-1" {
  name = "my-network-load-balancer"

  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lb-target-group-1.id

    healthcheck {
      name = "http"
      tcp_options {
        port = 80
      }
    }
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = yandex_vpc_network.network-1.id
}

output "load_balancer_public_ip" {
  description = "Public IP address of load balancer"
  value       = yandex_lb_network_load_balancer.lb_network_load_balancer-1.listener.*.external_address_spec[0].*.address
}
