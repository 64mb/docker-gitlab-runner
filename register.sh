#!/bin/bash

if [ -z "${RUNNER_TAGS}" ]; then
  RUNNER_TAGS=""
fi

TOKEN=$(gitlab-runner register <<<${RUNNER_URL}$'\n'${RUNNER_TOKEN}$'\n'${RUNNER_DESCRIPTION}$'\n'${RUNNER_TAGS}$'\nshell\n' &&
  cat /etc/gitlab-runner/config.toml | grep 'token =' | sed 's|token = "||' | sed 's|"||' | sed 's| ||')

echo " "
echo "==========================="
echo "token:${TOKEN}"
echo "==========================="
