#!/bin/bash

echo ""

echo "gitlab settings prepare..."

if [ ! -z "${GITLAB_CRT}" ]; then
  echo "${GITLAB_CRT}" >./cert/gitlab.crt
fi

if [ ! -z "${GITLAB_REGISTRY_CRT}" ]; then
  echo "${GITLAB_REGISTRY_CRT}" >./cert/gitlab.registry.crt
fi

if [ ! -z "${GITLAB_REGISTRY_KEY}" ]; then
  echo "${GITLAB_REGISTRY_KEY}" >./cert/gitlab.registry.key
fi

if [ ! -f "./cert/gitlab.crt" ]; then
  echo "  gitlab certificate is empty... exit"
  exit 1
fi

if [ ! -f "./cert/gitlab.registry.crt" ]; then
  echo "  gitlab registry certificate is empty... exit"
  exit 1
fi

if [ ! -f "./cert/gitlab.registry.key" ]; then
  echo "  gitlab registry key is empty... exit"
  exit 1
fi

echo "ssh tunnel settings prepare..."

if [ ! -z "${TUNNEL_SSH_PRIVATE_KEY}" ]; then
  echo "${TUNNEL_SSH_PRIVATE_KEY}" >./key/id_rsa
  chmod 400 ./key/id_rsa
fi

if [ ! -z "${TUNNEL_SSH_PUBLIC_KEY}" ]; then
  echo "${TUNNEL_SSH_PUBLIC_KEY}" >./key/id_rsa.pub
  chmod 400 ./key/id_rsa.pub
fi

if [ ! -f "./key/id_rsa" ]; then
  echo "  tunnel ssh private key is empty... exit"
  exit 1
fi

if [ ! -f "./key/id_rsa.pub" ]; then
  echo "  tunnel ssh public key is empty... exit"
  exit 1
fi
