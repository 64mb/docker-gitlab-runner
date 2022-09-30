#!/bin/bash

MODE='open'
PORT=22
TIMEOUT=600 # 10 min in sec

PROXY=''
USER='tunnel'

IS_KEEP='false'

REGISTRY='registry.git'
REGISTRY_PORT=5000
REGISTRY_CERT_FOLDER=/etc/docker/certs.d

while [[ $# -gt 0 ]]; do
  _KEY="${1}"
  case ${_KEY} in
  -p | --port)
    PORT="${2}"
    shift
    shift
    ;;
  -u | --user)
    USER="${2}"
    shift
    shift
    ;;
  -t | --timeout)
    TIMEOUT="${2}"
    shift
    shift
    ;;
  --proxy)
    PROXY="${2}"
    shift
    shift
    ;;
  --registry)
    PROXY="-R ${REGISTRY}:0:registry_proxy:443"
    shift
    ;;
  --open)
    MODE='open'
    shift
    ;;
  --close)
    MODE='close'
    shift
    ;;
  --keep)
    IS_KEEP='true'
    shift
    ;;
  *)
    CONNECTION="${1}"
    shift
    ;;
  esac
done

if [ -z "${CONNECTION}" ]; then
  if [ ! -z "${HOST}" ]; then
    CONNECTION="${HOST}"
  fi
fi

if ! echo "${CONNECTION}" | grep -q '@'; then
  CONNECTION="${USER}@${CONNECTION}"
fi

if [ -z "${CONNECTION}" ]; then
  echo "connection string is empty"
  exit 1
fi

if [ ! ${MODE} = "close" ]; then
  if [ -z "${PROXY}" ]; then
    echo "proxy string or mode is empty"
    exit 1
  fi
fi

if ! test -f ./.ssh-agent; then
  AGENT=$(ssh-agent -s)
  eval ${AGENT}
  ssh-add /usr/local/ssh/tunnel.id_rsa
  echo "${AGENT}" >./.ssh-agent
else
  eval $(cat ./.ssh-agent)
fi

if [ ! -z "${SSH_PRIVATE_KEY}" ]; then
  echo "${SSH_PRIVATE_KEY}" | tr -d '\r' | ssh-add "-"
fi

if test -f ./.tunnel.port; then
  PORT=$(cat ./.tunnel.port)
fi

if [ ${MODE} = "close" ]; then
  if test -f ./.tunnel; then
    if [ -z "${PROXY}" ]; then
      PROXY=$(cat ./.tunnel)
    fi
  else
    echo "tunnel already closed... skip"
    exit 0
  fi

  pkill -f "ssh -fNTM ${PROXY} ${CONNECTION} -p ${PORT} -o StrictHostKeyChecking no" 1>&2 2>/dev/null
  rm -rf ./.tunnel
  if test -f ./.tunnel.port; then
    rm -rf ./.tunnel.port
  fi
  echo "tunnel closed"

  if test -f ./.tunnel.proxy; then
    REGISTRY_PORT=$(cat ./.tunnel.proxy)
    if echo "${PROXY}" | grep -qE "${REGISTRY}"; then
      echo "tunnel detect docker registry, remove cert for port..."

      ssh ${CONNECTION} -p ${PORT} -o 'StrictHostKeyChecking no' "rm -rf \"${REGISTRY_CERT_FOLDER}/${REGISTRY}:${REGISTRY_PORT}\"" 1>&2 2>/dev/null
    fi
    rm -rf ./.tunnel.proxy
    echo "tunnel proxy cleared"
  fi
else
  echo "tunnel connection: ${CONNECTION}"
  echo "tunnel port: ${PORT}"
  echo "tunnel open process..."

  PORT_PROXY_FREE=''

  # detect zero port for free port mechanism
  if echo "${PROXY}" | grep -qE ':0:'; then
    echo "tunnel detect zero port in proxy, search free port..."

    Ddev_TOOL=$(dirname "$(readlink -f "$0")")

    PORT_PROXY_FREE=$(ssh ${CONNECTION} -p ${PORT} -o 'StrictHostKeyChecking no' "bash -s" 2>/dev/null <${Ddev_TOOL}/port_free.sh)
    PROXY=$(echo "${PROXY}" | sed 's|:0:|:'${PORT_PROXY_FREE}':|')
    if [ -z "${PORT_PROXY_FREE}" ]; then
      echo "tunnel error get free port proxy, exit..."
      exit 1
    fi

    echo "tunnel free port: ${PORT_PROXY_FREE}"

    # detect registry
    if echo "${PROXY}" | grep -qE "${REGISTRY}"; then
      echo "tunnel detect docker registry, update cert for port..."

      ssh ${CONNECTION} -p ${PORT} -o 'StrictHostKeyChecking no' "bash -c 'test -d \"${REGISTRY_CERT_FOLDER}/${REGISTRY}:${PORT_PROXY_FREE}\" || ln -s ${REGISTRY_CERT_FOLDER}/${REGISTRY}:${REGISTRY_PORT} ${REGISTRY_CERT_FOLDER}/${REGISTRY}:${PORT_PROXY_FREE}'" 1>&2 2>/dev/null || exit 1
    fi
  fi

  ssh -fNTM ${PROXY} ${CONNECTION} -p ${PORT} -o 'StrictHostKeyChecking no' || exit 1

  # save proxy port for docker ci
  if [ ! -z "${PORT_PROXY_FREE}" ]; then
    echo "${PORT_PROXY_FREE}" >./.tunnel.proxy
  fi

  if [ "${IS_KEEP}" = "true" ]; then
    echo "-" >./.tunnel.keep
  fi

  if [ ! ${PORT} = "22" ]; then
    echo "${PORT}" >./.tunnel.port
  fi

  echo "${PROXY}" >./.tunnel
  echo "tunnel established"
fi

echo ""
