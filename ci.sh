#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
DIR="${DIR}/tools"

TOOL="${1}"
ARGS="${@:2}"
CODE=0

case ${TOOL} in
tg)
  ${DIR}/tg.sh ${ARGS}
  CODE=$?
  shift
  shift
  ;;
version)
  ${DIR}/version.sh ${ARGS}
  CODE=$?
  shift
  shift
  ;;
tunnel)
  ${DIR}/tunnel.sh ${ARGS}
  CODE=$?
  shift
  shift
  ;;
docker)
  ${DIR}/docker.sh ${ARGS}
  CODE=$?
  if ! test -f ./.tunnel.keep; then
    ${DIR}/tunnel.sh --close
  fi
  shift
  shift
  ;;
docker-commit)
  ${DIR}/docker_commit.sh ${ARGS}
  CODE=$?
  shift
  shift
  ;;
docker-clean)
  ${DIR}/docker_clean.sh ${ARGS}
  CODE=$?
  shift
  shift
  ;;
ssh-keyscan)
  ${DIR}/ssh_keyscan.sh ${ARGS}
  CODE=$?
  shift
  shift
  ;;
env)
  ${DIR}/env.sh ${ARGS}
  CODE=$?
  shift
  shift
  ;;
init)
  ${DIR}/init.sh ${ARGS}
  CODE=$?
  shift
  shift
  ;;
*)
  echo 'unknown tool name in first argument' >&2
  echo $'available tools:' >&2
  echo '- tg' >&2
  echo '- version' >&2
  echo '- tunnel' >&2
  echo '- docker' >&2
  echo '- docker-commit' >&2
  echo '- ssh-keyscan' >&2
  echo '- env' >&2
  echo '- init' >&2
  shift
  ;;
esac

exit ${CODE}
