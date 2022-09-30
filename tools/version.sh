#!/bin/bash

DIRECTORY='.'
IS_FORCE='false'
IS_NO_DATE='false'
IS_CLEAN='false'
IS_COMMIT='false'
MODE='npm'
PREFIX=''

while [[ $# -gt 0 ]]; do
  _KEY="${1}"
  case ${_KEY} in
  -d | --dir)
    DIRECTORY="${2}"
    shift
    shift
    ;;
  -m | --mode)
    MODE="${2}"
    shift
    shift
    ;;
  -p | --prefix)
    PREFIX="${2}"
    shift
    shift
    ;;
  --no-date)
    IS_NO_DATE='true'
    shift
    ;;
  --commit)
    IS_COMMIT='true'
    shift
    ;;
  --force)
    IS_FORCE='true'
    shift
    ;;
  --clean)
    IS_CLEAN='true'
    shift
    ;;
  esac
done

MODE_FINDED='false'

if [ ${MODE} = "npm" ]; then
  MODE_FINDED='true'
fi

if [ ! ${MODE_FINDED} = "true" ]; then
  echo "mode '${MODE}' not implemented" >&2
  exit 1
fi

# prepare end

VERSION=''

# npm mode use
if [ ${MODE} = "npm" ]; then
  if test -f "${DIRECTORY}/package.json"; then
    VERSION=$(cat ${DIRECTORY}/package.json | grep -E -o '"version": "[0-9]+\.[0-9]+\.[0-9]+"' | sed -e 's/[^0-9\w\.]//g')
  else
    VERSION='v'
  fi
fi
echo 'version: '${VERSION} >&2

if [ ${IS_NO_DATE} = "true" ]; then
  LABEL=${VERSION}
else
  DATE=$(git log -1 --format="%at" ${DIRECTORY} | xargs -I{} date -d @{} '+%Y-%m-%dT%H-%M-%S')

  if [ ${IS_FORCE} = "true" ]; then
    DATE=$(date '+%Y-%m-%dT%H-%M-%S')
  fi
  echo 'date: '${DATE} >&2
  LABEL=${VERSION}'_'${DATE}
fi

if [ ${IS_COMMIT} = "true" ]; then
  COMMIT=$(git log -1 --format="%h" ${DIRECTORY})
  echo 'commit: '${COMMIT} >&2

  LABEL=${LABEL}'_'${COMMIT}
fi

if [ ! -z "${PREFIX}" ]; then
  LABEL="${PREFIX}_${LABEL}"
fi

echo 'summary: '${LABEL} >&2

echo ${LABEL}

if [ ! ${IS_CLEAN} = "true" ]; then
  exit 0
else
  echo 'clean version label for build...' >&2
fi

# npm mode use
if [ ${MODE} = "npm" ]; then
  sed -i ${DIRECTORY}/package.json -e '3s|"version": "[0-9]*\.[0-9]*.[0-9]*"|"version": "1.0.0"|'
  sed -i ${DIRECTORY}/package-lock.json -e '3s|"version": "[0-9]*\.[0-9]*.[0-9]*"|"version": "1.0.0"|'
fi
