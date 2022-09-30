#!/bin/bash

IS_TLS='false'
SERVICE=''

while [[ $# -gt 0 ]]; do
  _KEY="${1}"
  case ${_KEY} in
  -d | --dir)
    DIRECTORY="${2}"
    shift
    shift
    ;;
  --tls)
    IS_TLS='true'
    shift
    ;;
  *)
    SERVICE="${1}"
    shift
    ;;
  esac
done

echo "docker commit check..." >&2

if [ ! -z "${DIRECTORY}" ]; then
  cd "${DIRECTORY}"
  echo "  directory: ${DIRECTORY}" >&2
fi

if [ -z "${SERVICE}" ]; then
  echo "  empty deploy service" >&2
  exit 1
fi

if [ -z "${DOCKER_HOST}" ]; then
  export DOCKER_HOST="tcp://${HOST}:23376"
  if [ -z "${DOCKER_HOST}" ]; then
    echo "  empty [DOCKER_HOST] or [HOST] variable" >&2
    exit 1
  fi
fi

if [ -z "${COMPOSE_PROJECT_NAME}" ]; then
  export COMPOSE_PROJECT_NAME="stack"
fi

if [ ${IS_TLS} = "true" ]; then
  if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=./.docker
  fi

  mkdir -p "${DOCKER_CERT_PATH}"

  if [ -z "${DOCKER_TLS_CA}" ]; then
    echo "  tls empty [DOCKER_TLS_CA] variable" >&2
    exit 1
  fi

  rm -rf ${DOCKER_CERT_PATH}/ca.pem
  echo "${DOCKER_TLS_CA}" >${DOCKER_CERT_PATH}/ca.pem
  chmod 444 ${DOCKER_CERT_PATH}/ca.pem

  if [ -z "${DOCKER_TLS_CERT}" ]; then
    echo "  tls empty [DOCKER_TLS_CERT] variable" >&2
    exit 1
  fi

  rm -rf ${DOCKER_CERT_PATH}/cert.pem
  echo "${DOCKER_TLS_CERT}" >${DOCKER_CERT_PATH}/cert.pem
  chmod 444 ${DOCKER_CERT_PATH}/cert.pem

  if [ -z "${DOCKER_TLS_KEY}" ]; then
    echo "  tls empty [DOCKER_TLS_KEY] variable" >&2
    exit 1
  fi

  rm -rf ${DOCKER_CERT_PATH}/key.pem
  echo "${DOCKER_TLS_KEY}" >${DOCKER_CERT_PATH}/key.pem
  chmod 444 ${DOCKER_CERT_PATH}/key.pem
fi

if [ -z "${COMPOSE_FILE}" ]; then
  COMPOSE_FILE="docker-compose.yml"
fi

if test -f docker-compose.production.yml; then
  COMPOSE_FILE="${COMPOSE_FILE}:docker-compose.production.yml"
fi
export COMPOSE_FILE="${COMPOSE_FILE}"

if [ ${IS_TLS} = "true" ]; then
  export DOCKER_TLS_VERIFY=true
  export DOCKER_CERT_PATH="${DOCKER_CERT_PATH}"
fi

export IMAGE_REGISTRY="check"

BLUE_GREEN='false'
BG_SEED=$(docker-compose config --services | grep "${SERVICE}" | head -n1)
if [ "${BG_SEED}" = "${SERVICE}_blue" ] || [ "${BG_SEED}" = "${SERVICE}_green" ]; then
  BLUE_GREEN='true'
  echo "  blue-green detected" >&2
fi

COMMIT="."

if [ "$BLUE_GREEN" = "true" ]; then
  SERVICE=$(docker ps --format='{{.Names}} {{.Status}}' | awk '{print $1}' | grep -o "${SERVICE}.*" | grep -E 'green|blue' | head -n1 | tr -d '\n' | tr -d '[:space:]')
fi

SEED=$(docker inspect --format='{{.Config.Image}}' "${SERVICE}" 2>/dev/null)

if [ ! -z "${SEED}" ]; then
  IFS='_'
  SEED=($SEED)
  unset IFS

  SEED=${SEED[-1]}
  SEED=$(echo "${SEED}" | grep -v '-' | grep -v '\.')

  COMMIT="${SEED}"
fi

if [ ! -z "${COMMIT}" ]; then
  echo "  image commit: ${COMMIT}" >&2
else
  echo "  image commit not found" >&2
fi

echo "${COMMIT}"

if [ ${IS_TLS} = "true" ]; then
  rm -rf "${DOCKER_CERT_PATH}"
fi
