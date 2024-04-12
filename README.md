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
```tf
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
count = 2
name = "vm${count.index}"
platform_id = "standart-v1"
boot_disk {
initializate_params {
  image_id = "fd81mpc969gbg44vndkv"
  size = 5
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
}

resource "yandex_vpc_network" "network-1" {
name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
name "subnet1"
  zone = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id = "${yandex_vpc_network.network-1.id}"
}

```
Проверка конфигурации terraform

```
terraform init
terraform validate
```

![image](https://github.com/killakazzak/10-4-fault-tolerance-cloud-hw/assets/32342205/c89aaff0-1365-4242-982b-0d5e00b4bd35)
![image](https://github.com/killakazzak/10-4-fault-tolerance-cloud-hw/assets/32342205/a570c7a1-5040-44ee-86a0-6d4ac21fe4e1)



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
