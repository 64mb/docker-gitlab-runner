FROM gitlab/gitlab-runner:alpine-v14.3.2

ENV TZ Asia/Yekaterinburg
RUN apk --update --no-cache add tzdata && cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apk --update --no-cache add \
  sudo \
  bash \
  zip \
  samba-client \
  make \
  unzip \
  curl \
  ca-certificates \
  docker-cli \
  nodejs \
  nodejs-npm \
  docker-compose
# remove default 1.25 version, need 1.27 with `extend` directive support
# 19.10.2021 build from source not needed else, 1.27 from the box

# docker-compose
# RUN apk --update --no-cache add \
#   python3-dev \
#   py-pip \
#   libffi-dev \
#   openssl-dev \
#   gcc \
#   libc-dev \
#   rust \
#   cargo

# RUN pip3 install docker-compose


RUN npm install -g npm@latest

COPY ./cert/gitlab.crt /etc/gitlab-runner/certs/ca.crt
COPY ./cert/gitlab.crt /usr/local/share/ca-certificates/gitlab.crt
COPY ./cert/gitlab.registry.crt /usr/local/share/ca-certificates/registry.gitlab.crt

RUN update-ca-certificates

COPY --chown=gitlab-runner:nogroup ./key/id_rsa /usr/local/ssh/tunnel.id_rsa
COPY --chown=gitlab-runner:nogroup ./key/id_rsa.pub /usr/local/ssh/tunnel.id_rsa.pub
RUN chmod 400 /usr/local/ssh/tunnel.id_rsa
RUN chmod 400 /usr/local/ssh/tunnel.id_rsa.pub

COPY --chown=gitlab-runner:nogroup ./register.sh /usr/local/bin/register
COPY --chown=gitlab-runner:nogroup ./run.sh /usr/local/bin/gitlab-runner-run
COPY --chown=gitlab-runner:nogroup ./config.toml /home/gitlab-runner/config.toml

COPY --chown=gitlab-runner:nogroup ./ci.sh /usr/local/bin/ci
COPY --chown=gitlab-runner:nogroup ./tools /usr/local/bin/tools

RUN addgroup gitlab-runner users
RUN addgroup -g 998 docker
RUN addgroup gitlab-runner docker

WORKDIR /home/gitlab-runner

ENTRYPOINT [ "/bin/bash" ]
# bash script
CMD [ "gitlab-runner-run" ]
