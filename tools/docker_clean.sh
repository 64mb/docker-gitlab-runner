#!/bin/bash

IS_REGISTRY='false'
IS_TLS='false'
OTHER=''

while [[ $# -gt 0 ]]; do
  _KEY="${1}"
  case ${_KEY} in
  --registry)
    IS_REGISTRY='true'
    shift
    ;;
  --tls)
    IS_TLS='true'
    shift
    ;;
  *)
    OTHER="${1}"
    shift
    ;;
  esac
done

echo "docker clean init..."

if [ -z "${DOCKER_HOST}" ]; then
  export DOCKER_HOST="tcp://${HOST}:23376"
  if [ -z "${DOCKER_HOST}" ]; then
    echo "  empty [DOCKER_HOST] or [HOST] variable"
    exit 1
  fi
fi

if [ ${IS_TLS} = "true" ]; then
  if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=./.docker
  fi

  mkdir -p "${DOCKER_CERT_PATH}"

  if [ -z "${DOCKER_TLS_CA}" ]; then
    echo "  tls empty [DOCKER_TLS_CA] variable"
    exit 1
  fi

  rm -rf ${DOCKER_CERT_PATH}/ca.pem
  echo "${DOCKER_TLS_CA}" >${DOCKER_CERT_PATH}/ca.pem
  chmod 444 ${DOCKER_CERT_PATH}/ca.pem

  if [ -z "${DOCKER_TLS_CERT}" ]; then
    echo "  tls empty [DOCKER_TLS_CERT] variable"
    exit 1
  fi

  rm -rf ${DOCKER_CERT_PATH}/cert.pem
  echo "${DOCKER_TLS_CERT}" >${DOCKER_CERT_PATH}/cert.pem
  chmod 444 ${DOCKER_CERT_PATH}/cert.pem

  if [ -z "${DOCKER_TLS_KEY}" ]; then
    echo "  tls empty [DOCKER_TLS_KEY] variable"
    exit 1
  fi

  rm -rf ${DOCKER_CERT_PATH}/key.pem
  echo "${DOCKER_TLS_KEY}" >${DOCKER_CERT_PATH}/key.pem
  chmod 444 ${DOCKER_CERT_PATH}/key.pem
fi

echo "  clean images"
# week until ago

# docker rmi $(docker images -f "dangling=true" -q -f "until 168h")
docker image prune --force --filter "dangling=true" --filter "until=168h"
docker image prune -a --force --filter "until=168h"
if [ ${IS_REGISTRY} = "true" ]; then
  DOCKER_HOST='' DOCKER_TLS_VERIFY='' docker image prune --force --filter "dangling=true" --filter "until=168h"
  DOCKER_HOST='' DOCKER_TLS_VERIFY='' docker image prune -a --force --filter "until=168h"
fi

if [ ${IS_TLS} = "true" ]; then
  rm -rf "${DOCKER_CERT_PATH}"
fi
