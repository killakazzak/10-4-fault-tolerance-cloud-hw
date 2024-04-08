# Домашнее задание к занятию "`GitLab`" - `Тен Денис`


### Задание 1

**Что нужно сделать:**

1. Разверните GitLab локально, используя Vagrantfile и инструкцию, описанные в [этом репозитории](https://github.com/netology-code/sdvps-materials/tree/main/gitlab).   
2. Создайте новый проект и пустой репозиторий в нём.
3. Зарегистрируйте gitlab-runner для этого проекта и запустите его в режиме Docker. Раннер можно регистрировать и запускать на той же виртуальной машине, на которой запущен GitLab.

В качестве ответа в репозиторий шаблона с решением добавьте скриншоты с настройками раннера в проекте.

---

### Решение Задание 1

#### Установка Virtualbox
```
echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" | sudo tee -a /etc/apt/sources.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
sudo apt update
sudo apt install virtualbox
vboxmanage --version
```
![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/8c9480c9-bcc7-4e68-b8c5-e8dea537f963)

#### Установка Vagrant
```
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
vagrant --version
```
![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/8540f4d8-6f00-4e69-a3d7-9047085100d7)

#### Установка Gitlab

Модифицированный [Vagranfile](https://github.com/killakazzak/8-2-sdvps-materials-hw/blob/main/gitlab/Vagrantfile)

```
echo '192.168.56.10    gitlab.localdomain gitlab' >> /etc/hosts
VAGRANT_EXPERIMENTAL="disks" vagrant up
```
#### Создание проекта с репозиторием

![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/69e6ecc4-2c84-4e84-a40d-27c079e76af6)


#### Регистрация Gitlab runner

```
 docker run -ti --rm --name gitlab-runner \
     --network host \
     -v /srv/gitlab-runner/config:/etc/gitlab-runner \
     -v /var/run/docker.sock:/var/run/docker.sock \
     gitlab/gitlab-runner:latest register
```
Меняем конфигурацию gitlab runner
```
vim /srv/gitlab-runner/config/config.toml
```
```
concurrent = 1
check_interval = 0
connection_max_age = "15m0s"
shutdown_timeout = 0

[session_server]
  session_timeout = 1800


[[runners]]
  name = "ubuntu-client.dit.local"
  url = "http://gitlab.localdomain:8090/"
  id = 3
  token = "4A4Cu_xkySsy2wWxK_aC"
  token_obtained_at = 2024-03-15T14:53:33Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "docker"
  [runners.cache]
    MaxUploadedArchiveSize = 0
  [runners.docker]
    tls_verify = false
    image = "go.1.17"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
    extra_hosts = ["gitlab.localdomain:10.159.86.32"]
    shm_size = 0
    network_mtu = 0
```
#### Запуск gitlab runner

```
 docker run -d --name gitlab-runner --restart always \
     --network host \
     -v /srv/gitlab-runner/config:/etc/gitlab-runner \
     -v /var/run/docker.sock:/var/run/docker.sock \
     gitlab/gitlab-runner:latest
```
![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/e7b91872-f6e2-421c-84d1-99f8ac894d2d)
#### Проверка
```
docker ps -a
```
![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/472b3f2f-1d77-430c-ae64-cb7226f1c023)

![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/c0eb867b-d861-452b-86d1-9d7b86212510)
![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/11f6b0be-dcc0-4728-8f19-69024c0af8d5)


### Задание 2

**Что нужно сделать:**

1. Запушьте [репозиторий](https://github.com/netology-code/sdvps-materials/tree/main/gitlab) на GitLab, изменив origin. Это изучалось на занятии по Git.
2. Создайте .gitlab-ci.yml, описав в нём все необходимые, на ваш взгляд, этапы.

В качестве ответа в шаблон с решением добавьте: 
   
 * файл gitlab-ci.yml для своего проекта или вставьте код в соответствующее поле в шаблоне; 
 * скриншоты с успешно собранными сборками.
 
### Решение Задание 2

```
git remote add my_origin_2 http://gitlab.localdomain:8090/my_group/my_project_2.git
git remote set-url my_origin_2 http://lamos:glpat-CLj1agRTX8Lv5vSXaJgb@gitlab.localdomain:8090/my_group/my_project_2.git
cd /git/sdvps-materials/
git push my_origin_2
```
![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/d9da5983-f9bc-45a6-89c1-a7b1c23859fe)

```
vim /git/sdvps-materials/.gitlab-ci.yml
```
```
stages:
  - test
  - build

test:
  stage: test
  image: golang:1.17
  script: 
   - go test .

build:
  stage: build
  image: docker:latest
  script:
   - docker build .
```


![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/3f3371f4-8ede-434b-98e3-f3fb9e58c73b)

![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/e3939e0b-6a52-4ff2-8451-299c6a627743)


## Дополнительные задания* (со звёздочкой)

Их выполнение необязательное и не влияет на получение зачёта по домашнему заданию. Можете их решить, если хотите лучше разобраться в материале.

---

### Задание 3*

Измените CI так, чтобы:

 - этап сборки запускался сразу, не дожидаясь результатов тестов;
 - тесты запускались только при изменении файлов с расширением *.go.

В качестве ответа добавьте в шаблон с решением файл gitlab-ci.yml своего проекта или вставьте код в соответсвующее поле в шаблоне.

### Решение Задание 3*

#### Модифицируем CI

```
vim /git/sdvps-materials/.gitlab-ci.yml
stages:
  - build
  - test

build:
  stage: build
  image: docker:latest
  script:
    - docker build .

test:
  stage: test
  image: golang:1.17
  script:
    - |
      if [[ $CI_COMMIT_REF_NAME == "main" ]] && [[ $CI_PIPELINE_SOURCE == "push" || $CI_PIPELINE_SOURCE == "web" ]]; then
        if [[ ! -z $(git diff-tree --no-commit-id --name-only -r $CI_COMMIT_SHA -- '*.go') ]]; then
          go test .
        else
          echo "No Go files were changed. Skipping tests."
        fi
      else
        echo "Skipping tests as it's not a main branch push or web pipeline event."
      fi
```

### Проверка

![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/e2191978-5c03-40e2-8145-4b10161b1768)

#### Без изменения Go файлов
![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/43f6cd94-2bcb-41c7-8211-b496153c0d47)
#### C изменениями Go файлов
![image](https://github.com/killakazzak/8-3-gitlab-hw/assets/32342205/2a3c0497-53ef-4a21-9c7a-802b3a3ac48d)







