#!/bin/bash

cat ./docker-compose.yml | sed -e 's/gitlab_runner:$/gitlab_runner-'${RUNNER_DESCRIPTION}':/' >./docker-compose.${RUNNER_DESCRIPTION}.yml

export COMPOSE_FILE=./docker-compose.${RUNNER_DESCRIPTION}.yml

./ci.sh docker --version ${1} gitlab_runner-${RUNNER_DESCRIPTION} --no-registry --tls
