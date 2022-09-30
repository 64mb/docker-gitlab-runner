#!/bin/bash

echo "runner: prepare config from environment..."

RUNNER_CONFIG="$(cat /home/gitlab-runner/config.toml)"

RUNNER_CONFIG=$(echo "${RUNNER_CONFIG}" | sed 's|{RUNNER_CONCURRENT_JOB_COUNT}|'${RUNNER_CONCURRENT_JOB_COUNT}'|')
RUNNER_CONFIG=$(echo "${RUNNER_CONFIG}" | sed 's|{RUNNER_NAME}|'${RUNNER_NAME}'|')
RUNNER_CONFIG=$(echo "${RUNNER_CONFIG}" | sed 's|{RUNNER_URL}|'${RUNNER_URL}'|')
RUNNER_CONFIG=$(echo "${RUNNER_CONFIG}" | sed 's|{RUNNER_TOKEN}|'${RUNNER_TOKEN}'|')

echo "${RUNNER_CONFIG}" >/etc/gitlab-runner/config.toml

gitlab-runner run --user=gitlab-runner --working-directory=/home/gitlab-runner
