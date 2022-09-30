#!/bin/bash

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
