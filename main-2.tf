provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```


Файл конфигурации main.tf
```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.115.0"
    }
  }
}

provider "yandex" {
  token = "y0_AgAAAAAEOSJRAATuwQAAAAD4DOe6Hsa8lMrhTTqHtIxgS6CaJBEa0Mg"
  cloud_id = "Pb1gp6qjp3sreksmq9ju1"
  folder_id = "b1g3hhpc4sj7fmtmdccu"
  zone = "ru-central1-a"

}
resource "yandex_iam_service_account" "lamos" {
  name        = "lamos"
  description = "Сервисный аккаунт для управления группой ВМ."
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = "b1g3hhpc4sj7fmtmdccu"
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.lamos.id}"
}

resource "yandex_vpc_security_group" "vm_group_sg" {
  network_id = "${yandex_vpc_network.network-1.id}"
  ingress {
    protocol          = "ANY"
    description       = "Allow incoming traffic from members of the same security group"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }

  egress {
   protocol          = "ANY"
     description       = "Allow outgoing traffic to members of the same security group"
   v4_cidr_blocks    = ["0.0.0.0/0"]
   from_port         = 0
   to_port           = 65535
   predefined_target = "self_security_group"
  }
}


resource "yandex_compute_instance_group" "ig-1" {
  name                = "fixed-ig-with-balancer"
  folder_id           = "b1g3hhpc4sj7fmtmdccu"
  service_account_id  = "${yandex_iam_service_account.lamos.id}"
  deletion_protection = "false"
  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 2
      cores  = 2
      core_fraction = 20
    }

    boot_disk {
      initialize_params {
      image_id  = "fd81mpc969gbg44vndkv"
      size      = 5
      }
    }

    network_interface {
      nat = true
      network_id         = "${yandex_vpc_network.network-1.id}"
      subnet_ids         = ["${yandex_vpc_subnet.subnet-1.id}"]
      security_group_ids = ["${yandex_vpc_security_group.vm_group_sg.id}"]
    }

    metadata = {
      user-data   = "${file("./meta.yml")}"
    }
  }
  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  load_balancer {
    target_group_name        = "target-group"
    target_group_description = "Целевая группа Network Load Balancer"
  }
}

resource "yandex_lb_network_load_balancer" "lb-1" {
  name = "network-load-balancer-1"

  listener {
    name = "network-load-balancer-1-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.ig-1.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
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
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "load_balancer_public_ip" {
  description = "Public IP address of load balancer"
  value = "${yandex_lb_network_load_balancer.lb-1.listener.*.external_address_spec[0].*.address}"
}