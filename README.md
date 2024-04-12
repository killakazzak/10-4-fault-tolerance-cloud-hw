# Домашнее задание к занятию "`Отказоустойчивость в облаке`" - `Тен Денис`

### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Документация сетевого балансировщика нагрузки](https://cloud.yandex.ru/docs/network-load-balancer/quickstart)

 ---

## Задание 1 

Возьмите за основу [решение к заданию 1 из занятия «Подъём инфраструктуры в Яндекс Облаке»](https://github.com/netology-code/sdvps-homeworks/blob/main/7-03.md#задание-1).

1. Теперь вместо одной виртуальной машины сделайте terraform playbook, который:

- создаст 2 идентичные виртуальные машины. Используйте аргумент [count](https://www.terraform.io/docs/language/meta-arguments/count.html) для создания таких ресурсов;
- создаст [таргет-группу](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_target_group). Поместите в неё созданные на шаге 1 виртуальные машины;
- создаст [сетевой балансировщик нагрузки](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_network_load_balancer), который слушает на порту 80, отправляет трафик на порт 80 виртуальных машин и http healthcheck на порт 80 виртуальных машин.

Рекомендуем изучить [документацию сетевого балансировщика нагрузки](https://cloud.yandex.ru/docs/network-load-balancer/quickstart) для того, чтобы было понятно, что вы сделали.

2. Установите на созданные виртуальные машины пакет Nginx любым удобным способом и запустите Nginx веб-сервер на порту 80.

3. Перейдите в веб-консоль Yandex Cloud и убедитесь, что: 

- созданный балансировщик находится в статусе Active,
- обе виртуальные машины в целевой группе находятся в состоянии healthy.

4. Сделайте запрос на 80 порт на внешний IP-адрес балансировщика и убедитесь, что вы получаете ответ в виде дефолтной страницы Nginx.

*В качестве результата пришлите:*

*1. Terraform Playbook.*

*2. Скриншот статуса балансировщика и целевой группы.*

*3. Скриншот страницы, которая открылась при запросе IP-адреса балансировщика.*

## Решение Задание 1 

Установка terraform

```bash
cd /usr/local/src && wget https://hashicorp-releases.yandexcloud.net/terraform/1.8.0/terraform_1.8.0_linux_amd64.zip  && unzip terraform_1.8.0_linux_amd64.zip && cp terraform /usr/local/bin/
```
Проверка установки terraform

```bash
terraform --version
```
![image](https://github.com/killakazzak/10-4-fault-tolerance-cloud-hw/assets/32342205/1cd3b044-d82f-4100-9889-2d50e5630bbf)


Создание конфигурационного файла main.tf
```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
token = "y0_AgAAAAAEOSJRAATuwQAAAAD4DOe6Hsa8lMrhTTqHtIxgS6CaJBEa0Mg"
cloud_id = "Pb1gp6qjp3sreksmq9ju1"
folder_id = "b1g3hhpc4sj7fmtmdccu"
zone = "ru-central1-a"
}

resource "yandex_compute_instance" "vm" {
  count         = 2
  name          = "vm${count.index}"
  platform_id   = "standard-v1"

  metadata = {
    user-data   = "${file("./metadata.yml")}"
  }

  boot_disk {
    initialize_params {
      image_id  = "fd81mpc969gbg44vndkv"
      size      = 5
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat = true
  }

  resources {
    core_fraction = 5
    cores = 2
    memory = 2
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
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    address   = "${yandex_compute_instance.vm[0].network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    address   = "${yandex_compute_instance.vm[1].network_interface.0.ip_address}"
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
    target_group_id = "${yandex_lb_target_group.lb-target-group-1.id}"

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
  name = "subnet1"
    zone = "ru-central1-a"
    v4_cidr_blocks = ["192.168.10.0/24"]
    network_id = "${yandex_vpc_network.network-1.id}"
}

output "load_balancer_ip" {
  value = "yandex_lb_network_load_balancer.lb_network_load_balancer-1.network_interface.0.ipv4_address"
}


```
Проверка конфигурации terraform

```
terraform init
terraform validate

```
![image](https://github.com/killakazzak/10-4-fault-tolerance-cloud-hw/assets/32342205/f6e974c5-d942-4cbc-b268-fbc3e772e490)

![image](https://github.com/killakazzak/10-4-fault-tolerance-cloud-hw/assets/32342205/ef5110d7-f7bc-454b-af51-93993d2b201b)


```
terraform plan
```
```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.vm[0] will be created
  + resource "yandex_compute_instance" "vm" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                ---
                users:
                  - name: denis
                    groups: sudo
                    shell: /bin/bash
                    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
                    ssh-authorized-keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCn2HRe+qye95mzFDXwneCdGgzCBs1XTJH1t4XmGc4+DMOqjuP7zak+sEW7SB/K61v5cI163ULqjHKXq+3hQN5Nznf7P0oSlGPcby9/934pvO87nNaMBo5rdA0CWzNi9b4fNhv3ipMsNyYN1mIi9meuOFiwhMTMKP9UoWfylJK19/2be0shT6XHnoRrnCdq2Jn41lkb5+NoqT8voLtiILCLVUoK0t1TKRhH+nKZh/zPPSBO33vvFcnn/UC3X/FA3rf80MsjUgp3UkrclIXDo1ttRiIREhKY6GmbkIrJz4a6CQRXL1aZPBg5n3tgbjys4JdprjO5Cc8mDBUvs3p8L+c0Sp8gHHkVc2ZMBN2HCLd/LPO9b8PF8ZU/bafknTV4zF6Y/lK+f/lZz7dIpx/1UTe4ZBkO0Zm7naVbqjYZm1xdJj2MnY/HGr34li/0IaeNC3nHiuHrGIwn0jmok1NfAo4ELXxQ/OgMfN5UItyFpATVesgUNgFIdpkT4i0UzQCB0bU= denis@rocky8-server.dit.local
            EOT
        }
      + name                      = "vm0"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd81mpc969gbg44vndkv"
              + name        = (known after apply)
              + size        = 5
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + resources {
          + core_fraction = 5
          + cores         = 2
          + memory        = 2
        }
    }

  # yandex_compute_instance.vm[1] will be created
  + resource "yandex_compute_instance" "vm" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                ---
                users:
                  - name: denis
                    groups: sudo
                    shell: /bin/bash
                    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
                    ssh-authorized-keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCn2HRe+qye95mzFDXwneCdGgzCBs1XTJH1t4XmGc4+DMOqjuP7zak+sEW7SB/K61v5cI163ULqjHKXq+3hQN5Nznf7P0oSlGPcby9/934pvO87nNaMBo5rdA0CWzNi9b4fNhv3ipMsNyYN1mIi9meuOFiwhMTMKP9UoWfylJK19/2be0shT6XHnoRrnCdq2Jn41lkb5+NoqT8voLtiILCLVUoK0t1TKRhH+nKZh/zPPSBO33vvFcnn/UC3X/FA3rf80MsjUgp3UkrclIXDo1ttRiIREhKY6GmbkIrJz4a6CQRXL1aZPBg5n3tgbjys4JdprjO5Cc8mDBUvs3p8L+c0Sp8gHHkVc2ZMBN2HCLd/LPO9b8PF8ZU/bafknTV4zF6Y/lK+f/lZz7dIpx/1UTe4ZBkO0Zm7naVbqjYZm1xdJj2MnY/HGr34li/0IaeNC3nHiuHrGIwn0jmok1NfAo4ELXxQ/OgMfN5UItyFpATVesgUNgFIdpkT4i0UzQCB0bU= denis@rocky8-server.dit.local
            EOT
        }
      + name                      = "vm1"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd81mpc969gbg44vndkv"
              + name        = (known after apply)
              + size        = 5
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + resources {
          + core_fraction = 5
          + cores         = 2
          + memory        = 2
        }
    }

  # yandex_lb_network_load_balancer.lb_network_load_balancer-1 will be created
  + resource "yandex_lb_network_load_balancer" "lb_network_load_balancer-1" {
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "my-network-load-balancer"
      + region_id           = (known after apply)
      + type                = "external"

      + attached_target_group {
          + target_group_id = (known after apply)

          + healthcheck {
              + healthy_threshold   = 2
              + interval            = 2
              + name                = "http"
              + timeout             = 1
              + unhealthy_threshold = 2

              + tcp_options {
                  + port = 80
                }
            }
        }

      + listener {
          + name        = "my-listener"
          + port        = 80
          + protocol    = (known after apply)
          + target_port = (known after apply)

          + external_address_spec {
              + address    = (known after apply)
              + ip_version = "ipv4"
            }
        }
    }

  # yandex_lb_target_group.lb-target-group-1 will be created
  + resource "yandex_lb_target_group" "lb-target-group-1" {
      + created_at = (known after apply)
      + folder_id  = (known after apply)
      + id         = (known after apply)
      + name       = "my-target-group"
      + region_id  = "ru-central1"

      + target {
          + address   = (known after apply)
          + subnet_id = (known after apply)
        }
      + target {
          + address   = (known after apply)
          + subnet_id = (known after apply)
        }
    }

  # yandex_vpc_network.network-1 will be created
  + resource "yandex_vpc_network" "network-1" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "network1"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet-1 will be created
  + resource "yandex_vpc_subnet" "subnet-1" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet1"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.10.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

Plan: 6 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + load_balancer_ip = "yandex_lb_network_load_balancer.lb_network_load_balancer-1.network_interface.0.ipv4_address"

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```
Применяем конфигурацию
```
terraform apply
```
![image](https://github.com/killakazzak/10-4-fault-tolerance-cloud-hw/assets/32342205/04b6744d-4d1c-4ac4-99a3-fd6eacab4b99)

![image](https://github.com/killakazzak/10-4-fault-tolerance-cloud-hw/assets/32342205/ac3c7741-1c86-436e-ae44-7c394dcef528)


---

## Задания со звёздочкой*
Эти задания дополнительные. Выполнять их не обязательно. На зачёт это не повлияет. Вы можете их выполнить, если хотите глубже разобраться в материале.

---

## Решение Задание 2*

1. Теперь вместо создания виртуальных машин создайте [группу виртуальных машин с балансировщиком нагрузки](https://cloud.yandex.ru/docs/compute/operations/instance-groups/create-with-balancer).

2. Nginx нужно будет поставить тоже автоматизированно. Для этого вам нужно будет подложить файл установки Nginx в user-data-ключ [метадаты](https://cloud.yandex.ru/docs/compute/concepts/vm-metadata) виртуальной машины.

- [Пример файла установки Nginx](https://github.com/nar3k/yc-public-tasks/blob/master/terraform/metadata.yaml).
- [Как подставлять файл в метадату виртуальной машины.](https://github.com/nar3k/yc-public-tasks/blob/a6c50a5e1d82f27e6d7f3897972adb872299f14a/terraform/main.tf#L38)

3. Перейдите в веб-консоль Yandex Cloud и убедитесь, что: 

- созданный балансировщик находится в статусе Active,
- обе виртуальные машины в целевой группе находятся в состоянии healthy.

4. Сделайте запрос на 80 порт на внешний IP-адрес балансировщика и убедитесь, что вы получаете ответ в виде дефолтной страницы Nginx.

*В качестве результата пришлите*

*1. Terraform Playbook.*

*2. Скриншот статуса балансировщика и целевой группы.*

*3. Скриншот страницы, которая открылась при запросе IP-адреса балансировщика.*
