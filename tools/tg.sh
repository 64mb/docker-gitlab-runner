#!/bin/bash

REPO_NAME=''
PIPELINE_URL=''
BRANCH=''
VERSION=''
META=''

while [[ $# -gt 0 ]]; do
  _KEY="${1}"
  case ${_KEY} in
  -r | --repo)
    REPO_NAME="${2}"
    shift
    shift
    ;;
  -b | --branch)
    BRANCH="${2}"
    shift
    shift
    ;;
  -u | --url)
    PIPELINE_URL="${2}"
    shift
    shift
    ;;
  -v | --version)
    VERSION="${2}"
    shift
    shift
    ;;
  -f | --file)
    FILE="${2}"
    shift
    shift
    ;;
  -m | --meta)
    META="${2}"
    shift
    shift
    ;;
  -d | --diff)
    DIFF="${2}"
    shift
    shift
    ;;
  *)
    STATUS_CODE="${1}"
    shift
    ;;
  esac
done

if [ -z "${TG_BOT_TOKEN}" ]; then
  echo "environment variable [TG_BOT_TOKEN] not found"
  exit 1
fi

if [ -z "${TG_CHAT_ID}" ]; then
  echo "environment variable [TG_CHAT_ID] not found"
  exit 1
fi

TG_TIME="10"
TG_URL="https://api.telegram.org/bot${TG_BOT_TOKEN}"

STATUS="✅"
if [ ! "${STATUS_CODE}" = "0" ]; then
  STATUS="❌"
fi

echo "tg notification:"
echo "  status: ${STATUS}"
echo "  chat_id: ${TG_CHAT_ID}"

TG_TEXT="ci/cd status:+${STATUS}%0A"
if [ ! -z "${REPO_NAME}" ]; then
  TG_TEXT="${TG_TEXT}%0Arepo:+${REPO_NAME}"
fi
if [ ! -z "${PIPELINE_URL}" ]; then
  TG_TEXT="${TG_TEXT}%0Aurl:+${PIPELINE_URL}"
fi
if [ ! -z "${BRANCH}" ]; then
  TG_TEXT="${TG_TEXT}%0Abranch:+${BRANCH}"
fi
if [ ! -z "${VERSION}" ]; then
  TG_TEXT="${TG_TEXT}%0Aversion:+${VERSION}"
fi

if [ ! "${STATUS_CODE}" = "0" ]; then
  if [ ! -z "${META}" ]; then
    TG_TEXT="${TG_TEXT}%0A%0A${META}"
  fi
  curl -s --fail --max-time ${TG_TIME} -X POST "${TG_URL}/sendMessage" \
    -d chat_id="${TG_CHAT_ID}" \
    -d disable_web_page_preview="1" \
    -d disable_notification="1" \
    -d text="${TG_TEXT}" >/dev/null || exit 1
  exit 0
fi

COMMITS=""

if [ ! -z "${DIFF}" ]; then
  if [ ! "$DIFF" = "." ]; then
    LAST_COMMIT=$(git log -1 --pretty=format:%h | grep '')

    echo "  last commit: ${LAST_COMMIT}"

    PREV_COMMIT=${DIFF}

    if [ -z "${PREV_COMMIT}" ]; then
      PREV_COMMIT=${LAST_COMMIT}
    fi

    echo "  prev commit: ${PREV_COMMIT}"

    COMMITS=$(git log --pretty=format:%s "${PREV_COMMIT}..")
  fi
fi

if [ ! -z "${COMMITS}" ]; then
  COMMITS=$(printf "${COMMITS}" | sed 's/^/ - /' | grep -v 'Merge branch')
  TG_TEXT="${TG_TEXT}%0A%0Achanges:%0A${COMMITS}"
fi

if [ ! -z "${META}" ]; then
  TG_TEXT="${TG_TEXT}%0A%0A$META"
fi

curl -s --fail --max-time ${TG_TIME} -X POST "${TG_URL}/sendMessage" \
  -d chat_id="${TG_CHAT_ID}" \
  -d disable_web_page_preview="1" \
  -d disable_notification="1" \
  -d text="${TG_TEXT}" >/dev/null || exit 1

if [ ! -z "${FILE}" ]; then
  curl -s --fail --max-time ${TG_TIME} -F document=@"${FILE}" "${TG_URL}/sendDocument?chat_id=${TG_CHAT_ID}&disable_notification=1" >/dev/null || exit 1
fi
