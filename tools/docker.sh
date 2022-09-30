#!/bin/bash

export COMPOSE_PATH_SEPARATOR=':'
HEALTH_CHECK_TIMEOUT=60 # in sec

IS_NO_REGISTRY='false'
IS_LOCAL_REGISTRY='false'
IS_CLEAN='false'
IS_TLS='false'
IS_HEALTH_CHECK='false'
IS_NO_IMAGE_PREFIX='false'
VERSION='latest'
SERVICE=''

while [[ $# -gt 0 ]]; do
  _KEY="${1}"
  case ${_KEY} in
  -d | --dir)
    DIRECTORY="${2}"
    shift
    shift
    ;;
  -v | --version)
    VERSION="${2}"
    shift
    shift
    ;;
  --clean)
    IS_CLEAN='true'
    shift
    ;;
  --no-registry)
    IS_NO_REGISTRY='true'
    shift
    ;;
  --no-image-prefix)
    IS_NO_IMAGE_PREFIX='true'
    shift
    ;;
  --local-registry)
    IS_LOCAL_REGISTRY='true'
    shift
    ;;
  --health-check)
    IS_HEALTH_CHECK='true'
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

echo "docker deploy init..."

REGISTRY_PORT=5000
if test -f ./.tunnel.proxy; then
  REGISTRY_PORT=$(cat ./.tunnel.proxy)
  echo "override registry port from tunnel [.tunnel.proxy]: ${REGISTRY_PORT}"
fi

if [ ! -z "${DIRECTORY}" ]; then
  cd "${DIRECTORY}"
  echo "  directory: ${DIRECTORY}"
fi

if [ -z "${SERVICE}" ]; then
  echo "  empty deploy service"
  exit 1
fi

if [ -z "${DOCKER_HOST}" ]; then
  export DOCKER_HOST="tcp://${HOST}:23376"
  if [ -z "${DOCKER_HOST}" ]; then
    echo "  empty [DOCKER_HOST] or [HOST] variable"
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

if [ -z "${COMPOSE_FILE}" ]; then
  COMPOSE_FILE="docker-compose.yml"
fi

if test -f docker-compose.production.yml; then
  COMPOSE_FILE="docker-compose.production.yml"
fi
export COMPOSE_FILE="${COMPOSE_FILE}"

echo "  service: ${SERVICE}"
echo "  version: ${VERSION}"
export VERSION="${VERSION}"

# build service
IMAGE_PREFIX=''
IMAGE_LOCAL="${SERVICE}:${VERSION}"
if [ ${IS_NO_IMAGE_PREFIX} = "true" ]; then
  IMAGE_LOCAL="${CI_PROJECT_NAME}:${VERSION}"
fi

if [ ! ${IS_NO_REGISTRY} = "true" ]; then
  echo "  build service: ${SERVICE}"

  if [ ! ${IS_NO_IMAGE_PREFIX} = "true" ]; then
    if [ ! -z "${CI_PROJECT_NAME}" ]; then
      IMAGE_PREFIX=$(echo ${SERVICE} | sed -e "s|${CI_PROJECT_NAME}||g" | sed -e 's|^_||g')
    fi
  fi

  if [ ! -z "${IMAGE_PREFIX}" ]; then
    IMAGE_PREFIX="/${IMAGE_PREFIX}"
  fi

  if [ -z "${CI_REGISTRY}" ]; then
    echo "registry empty... exit"
    exit 1
  fi

  echo "  registry url: ${CI_REGISTRY}"
  DOCKER_HOST='' DOCKER_TLS_VERIFY='' docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY} || exit 1

  IMAGE_REGISTRY="${CI_REGISTRY_IMAGE}${IMAGE_PREFIX}:${VERSION}"
  IMAGE_EXIST=$(DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect ${IMAGE_REGISTRY} >/dev/null && echo 'true' || echo 'false')

  echo "  image local: ${IMAGE_LOCAL}"
  echo "  image registry: ${IMAGE_REGISTRY}"

  if [ "$IMAGE_EXIST" = "true" ]; then
    echo "  image already existed: ${IMAGE_LOCAL}"
  else
    COMPOSE_FILE_BUILD="${COMPOSE_FILE}"
    if test -f docker-compose.build.yml; then
      COMPOSE_FILE_BUILD="${COMPOSE_FILE_BUILD}:docker-compose.build.yml"
    fi

    if ! DOCKER_HOST='' \
      DOCKER_TLS_VERIFY='' \
      DOCKER_CERT_PATH='' \
      COMPOSE_FILE="${COMPOSE_FILE_BUILD}" \
      IMAGE_REGISTRY="${IMAGE_REGISTRY}" \
      docker-compose config --services | grep -q "${SERVICE}"; then
      echo "service for build not found... exit"
      exit 1
    fi

    DOCKER_HOST='' DOCKER_TLS_VERIFY='' DOCKER_CERT_PATH='' \
      COMPOSE_FILE="${COMPOSE_FILE_BUILD}" \
      IMAGE_REGISTRY="${IMAGE_REGISTRY}" \
      docker-compose build ${SERVICE} &&
      DOCKER_HOST='' DOCKER_TLS_VERIFY='' DOCKER_CERT_PATH='' docker tag ${IMAGE_LOCAL} ${IMAGE_REGISTRY} &&
      DOCKER_HOST='' DOCKER_TLS_VERIFY='' DOCKER_CERT_PATH='' docker push ${IMAGE_REGISTRY} ||
      exit 1
  fi

  if [ "${IS_LOCAL_REGISTRY}" = "true" ]; then
    echo "  registry local mode"
  else
    IMAGE_REGISTRY=$(echo "${IMAGE_REGISTRY}" | sed "s|${CI_REGISTRY}|${CI_REGISTRY}:${REGISTRY_PORT}|")
    echo "  registry proxy mode"
  fi
  export IMAGE_REGISTRY="${IMAGE_REGISTRY}"
else
  export IMAGE_REGISTRY="${IMAGE_LOCAL}"
fi

if [ ${IS_TLS} = "true" ]; then
  export DOCKER_TLS_VERIFY=true
  export DOCKER_CERT_PATH="${DOCKER_CERT_PATH}"
else
  export DOCKER_TLS_VERIFY=''
  export DOCKER_CERT_PATH=''
fi

# deploy service
if [ ${IS_NO_REGISTRY} = "true" ]; then
  BUILD=''
else
  BUILD='--no-build'
  if [ ! "${IS_LOCAL_REGISTRY}" = "true" ]; then
    echo "  registry proxy login"
    docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} "${CI_REGISTRY}:${REGISTRY_PORT}" || exit 1
  fi
fi

BLUE_GREEN='false'
BG_SEED=$(docker-compose config --services | grep "${SERVICE}_green" | head -n1)
if [ -z "${BG_SEED}" ]; then
  BG_SEED=$(docker-compose config --services | grep "${SERVICE}_blue" | head -n1)
fi
if [ "${BG_SEED}" = "${SERVICE}_blue" ] || [ "${BG_SEED}" = "${SERVICE}_green" ]; then
  BLUE_GREEN='true'
  echo "  blue-green detected"
fi

if [ ! "$BLUE_GREEN" = "true" ]; then
  echo "  up service: ${SERVICE}"
  docker-compose pull ${SERVICE} ||
    docker-compose pull ${SERVICE} ||
    docker-compose pull ${SERVICE} ||
    docker-compose pull ${SERVICE} ||
    exit 1
  docker-compose up -d ${BUILD} ${SERVICE} || exit 1

  # health_check
  if [ "$IS_HEALTH_CHECK" = "true" ]; then
    echo ""
    printf "  health check service..."

    H_ITER=0
    while [ ${H_ITER} -lt ${HEALTH_CHECK_TIMEOUT} ]; do
      sleep 1
      HEALTH=$(docker ps | grep "${SERVICE}" | grep "(healthy)")
      if [ ! -z "$HEALTH" ]; then
        H_ITER=86400
      else
        H_ITER=$(($H_ITER + 1))
        printf "."
      fi
    done

    echo ""

    if [ "${H_ITER}" = "${HEALTH_CHECK_TIMEOUT}" ]; then
      docker-compose stop "${SERVICE}"
      echo "  health check error"
      echo "  exit..."
      exit 1
    else
      echo "  health check success"
    fi
  fi

  echo "  up service done"
else
  echo "  blue-green up service: ${SERVICE}"

  BG_SEED=$(docker ps --format='{{.Names}} {{.Status}}')
  BG_COLOR_OLD=$(echo "${BG_SEED}" | grep "(healthy)" | awk '{print $1}' | grep -o "${SERVICE}.*" | grep -o -E 'green|blue' | tail -n1 | tr -d '\n' | tr -d '[:space:]')

  BG_COLOR='blue'
  if [ -z "${BG_COLOR_OLD}" ]; then
    echo "  b-g color current not found"
    echo "  b-g color set to blue"
  fi

  if [ "${BG_COLOR_OLD}" = "blue" ]; then
    BG_COLOR=green
  fi

  if [ "${BG_COLOR_OLD}" = "green" ]; then
    BG_COLOR=blue
  fi

  if [ "${BG_COLOR}" = "${BG_COLOR_OLD}" ]; then
    echo "  b-g color is equal... exit"
    exit 1
  fi

  echo ""

  docker-compose pull "${SERVICE}_${BG_COLOR}" ||
    docker-compose pull "${SERVICE}_${BG_COLOR}" ||
    docker-compose pull "${SERVICE}_${BG_COLOR}" ||
    docker-compose pull "${SERVICE}_${BG_COLOR}" ||
    exit 1
  docker-compose up -d ${BUILD} "${SERVICE}_${BG_COLOR}" || exit 1

  echo ""
  printf "  b-g health check service..."

  H_ITER=0
  while [ ${H_ITER} -lt ${HEALTH_CHECK_TIMEOUT} ]; do
    sleep 1
    HEALTH=$(docker ps | grep "${SERVICE}_${BG_COLOR}" | grep "(healthy)")
    if [ ! -z "$HEALTH" ]; then
      H_ITER=86400
    else
      H_ITER=$(($H_ITER + 1))
      printf "."
    fi
  done

  echo ""

  if [ "${H_ITER}" = "${HEALTH_CHECK_TIMEOUT}" ]; then
    docker-compose stop "${SERVICE}_${BG_COLOR}"
    echo "  b-g health check error"
    echo "  b-g old color if it was, still running"
    echo "  exit..."
    exit 1
  else
    echo "  b-g health check success"
  fi

  if [ ! -z "${BG_COLOR_OLD}" ]; then
    echo "  b-g stop old service: ${SERVICE}_${BG_COLOR_OLD}"
    docker-compose stop "${SERVICE}_${BG_COLOR_OLD}" || exit 1
  fi

  echo "  b-g up service done"
fi

if [ ${IS_CLEAN} = "true" ]; then
  echo "  clean images"
  # week until ago

  # docker rmi $(docker images -f "dangling=true" -q -f "until 168h")
  docker image prune --force --filter "dangling=true" --filter "until=168h"
  docker image prune -a --force --filter "until=168h"
  if [ ! ${IS_NO_REGISTRY} = "true" ]; then
    DOCKER_HOST='' DOCKER_TLS_VERIFY='' docker image prune --force --filter "dangling=true" --filter "until=168h"
    DOCKER_HOST='' DOCKER_TLS_VERIFY='' docker image prune -a --force --filter "until=168h"
  fi
fi

if [ ${IS_TLS} = "true" ]; then
  rm -rf "${DOCKER_CERT_PATH}"
fi
