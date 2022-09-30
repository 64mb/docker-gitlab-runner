# 👔 gitlab_runner

Автоматический CI/CD контейнер по выполнению задач из GitLab. Расширен утилитами для работы внутри локальной сети для развертывания `docker`-контейнеров через NAT посредством построения SSH-туннелей

### Используемые технологии:

- Bash - основные скрипты автоматизации и построения туннелей

- NodeJS - прокси для `docker-registry` сервера для реализации поддержки SSL при работе через NAT. Исходный код `proxy/server.js`

### Описание утилит:

Расположение: `tools/`

- `docker_clean.sh` - утилита очистки устаревших `docker` образов на хост машине

- `docker_commit.sh` - утилита для автоматического получения версии развернутого образа для сервиса в `docker` на хост машине. Используется для дальнейшего принятия решения по пересборке образа 

- `docker.sh` - утилита автоматического развертывания сервиса на `docker` машине посредством `docker-compose`, поддерживается локальный режим работы, TLS шифрование, автоматическое `blue-green` развертывание и автоматическая очистка устаревших образов на машине для экономии места

- `env.sh` - утилита перезаписи переменных окружения по префиксу `--prefix`. Например, запуск с префиксом `MKD_` экспортирует значение переменной `MKD_DB` поверх переменной `DB`

- `init.sh` - утилита для печати пафосного логотипа CI/CD

- `port_free.sh` - утилита автоматического определения свободного порта для проксирования на хосте

- `ssh_keyscan.sh` - утилита автоматического сканирования подписей SSH соединения для хоста

- `tg.sh` - утилита отправки уведомлений и файлов в Telegram, посредством выполнения запроса через `curl`

- `tunnel.sh` - утилита автоматического построения SSH-тунеля до хоста с поддержкой проксирования портов с локальной машины. Доступна поддержка параметров постоянного подключения `--keep` и параметров для автоматического проксирования локального `docker-registry`, параметр `--registry`

- `version.sh` - утилита для вычислении версии образа/проекта, с учетом дополнительных параметров даты, префикса и `hash`-комита. Для автоматического извлечения номера версия поддерживаются только `npm`-проекты с наличием файла `package.json`


### Вспомогательные инструменты:

Расположение: `/`

- `ci.sh` - основная точка входа для утилит CI/CD

- `deploy.self.sh` - скрипт для развертывания самого runner\`а на `docker` машине

- `init.sh` - скрипт начальной инициализации ключей и сертификатов для доступа к GitLab и `docker-registry` при развертывании

- `register.sh` - запуск процесса регистрации runner\`а с учетом переменных окружения, в том числе в среде `docker`

- `run.sh` - запуск runner\`а в интерактивном режиме с учетом переменных окружения, в том числе в среде `docker`

- `tunnel.key.sh` - добавления SSH пользователя и ключа на хост машину для построения туннеля в будущем, хост передается первым аргументом

### Описание make команд

- `make runner-register` - регистрация нового runner`а в соответствии с environment переменными в режиме cli

- `make runner-cli` - запуск интерактивной оболочки runner`а в соответствии с environment переменными в режиме cli

- `make runner-deploy` - развертывание runner\`а в экосистеме `docker` в соответствии с environment переменными

- `make host=[HOST] tunnel-deploy` - автоматическое добавление SSH ключей для туннеля на хост машину, где `[HOST]` - домен ил IP адрес машины с SSH доступом

### Переменные среды 📐
 
| Переменная                    | Описание                                                                                              | Пример                 |
| ----------------------------- | ----------------------------------------------------------------------------------------------------- | ---------------------- |
| `COMPOSE_PROJECT_NAME`        | Идентификатор группы контейнеров для `docker-compose`                                                 | `dev`                   |
| `COMPOSE_PATH_SEPARATOR`      | Разделитель нескольких `compose` файлов                                                               | `:`                    |
| `COMPOSE_FILE`                | `compose` файлы для развертывания, переопределяются в порядке написания                               | `docker-compose.yml`   |
| `RUNNER_URL`                  | Адрес основного GitLab сервера для регистрации сборщика                                               | `https://gitlab` |
| `RUNNER_DESCRIPTION`          | Описание сборщика, будет отображаться в панели GitLab в общем списке                                  | `mkd`                  |
| `RUNNER_TAGS`                 | Теги, для фильтрации задач по сборщикам                                                               | `docker, ssh, windows` |
| `RUNNER_CONCURRENT_JOB_COUNT` | Не обязательная переменная, указывается кол-во одновременных задач доступных сборщику, 1 по умолчанию | `2`                    |
| `VERSION`                     | Идентификатор версии сборщика                                                                         | `1.0.0`                |
| `VERSION_PROXY`               | Идентификатор версии прокси для `docker-registry`                                                     | `1.1.0`                |
