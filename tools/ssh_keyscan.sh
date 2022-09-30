#!/bin/bash

HOSTS=${1}

if [ -z "${HOSTS}" ]; then
  echo "empty host... exit"
  exit 0
fi

echo "ssh key scan for [HOSTS]..."

for HOST_SEED in ${HOSTS}; do
  IFS=':'
  SEED=($HOST_SEED)
  unset IFS

  HOST=${SEED[0]}

  if [ ! -z "${SEED[1]}" ]; then
    HOST=${SEED[1]}
  fi

  SSH_FINGERPRINT=$(ssh-keyscan -t rsa ${HOST} 2>&1)
  if ! grep "${SSH_FINGERPRINT}" ~/.ssh/known_hosts >/dev/null; then
    echo "${SSH_FINGERPRINT}" >>~/.ssh/known_hosts
    echo "${HOST}: fingerprint added to ~/.ssh/known_hosts"
  else
    echo "${HOST}: fingerprint already exist"
  fi
done

chmod 644 ~/.ssh/known_hosts
