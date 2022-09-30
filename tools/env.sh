#!/bin/bash

IS_OVERRIDE='false'
IS_NO_STRIP_PREFIX='false'
VAR=''
PREFIX=''
DIRECTORY=''
FILE=''

while [[ $# -gt 0 ]]; do
  _KEY="${1}"
  case ${_KEY} in
  -d | --dir)
    DIRECTORY="${2}"
    shift
    shift
    ;;
  -f | --file)
    FILE="${2}"
    shift
    shift
    ;;
  -p | --prefix)
    PREFIX="${2}"
    shift
    shift
    ;;
  --override)
    IS_OVERRIDE='true'
    shift
    ;;
  --no-strip-prefix)
    IS_NO_STRIP_PREFIX='true'
    shift
    ;;
  *)
    VAR="${1}"
    shift
    ;;
  esac
done

echo 'environment variable export...' >&2

VARIABLES=$(export)

SEARCH_SEED=''

if [ ! -z "${PREFIX}" ]; then
  if echo "${PREFIX}" | grep -qE '_$'; then
    SEARCH_SEED=${PREFIX}
  else
    SEARCH_SEED="${PREFIX}_"
  fi
  echo "  prefix: ${PREFIX}" >&2
fi

if [ ! -z "${VAR}" ]; then
  SEARCH_SEED=${VAR}
  echo "  var: ${VAR}" >&2
fi

if [ -z "${SEARCH_SEED}" ]; then
  echo "prefix or variable seed is empty... exit" >&2
  exit 1
fi

if [ ! ${IS_OVERRIDE} = "true" ]; then
  if [ -z "${DIRECTORY}" ]; then
    if [ -z "${FILE}" ]; then
      FILE=.env
    fi
    printf '' >"${FILE}"
    echo "  export to file: ${FILE}" >&2
  else
    mkdir -p "${DIRECTORY}"
    echo "  export to dir: ${DIRECTORY}" >&2
  fi
fi

for VARIABLE in ${VARIABLES}; do
  VARIABLE=$(echo ${VARIABLE} | grep -o -E ".+=" | tr -d '=')

  if [ -z "${VARIABLE+x}" ]; then
    continue
  fi

  if echo "${VARIABLE}" | grep -qE '^'${SEARCH_SEED}; then
    if [ ! -z "${PREFIX}" ]; then
      if [ ! ${IS_NO_STRIP_PREFIX} = "true" ]; then
        VAR_OUT=$(echo ${VARIABLE} | sed -e 's/'"${SEARCH_SEED}"'//g' | tr -d '\n')
      else
        VAR_OUT=$(echo ${VARIABLE})
      fi
    else
      VAR_OUT=$(echo ${VARIABLE})
    fi

    VALUE=$(echo "${!VARIABLE}" | sed -e 's/$/\\n/g' | tr -d '\n')

    if [ ${IS_OVERRIDE} = "true" ]; then
      echo "  define environment [${VAR_OUT}] from [${VARIABLE}]" >&2
      echo "export ${VAR_OUT}=$'${VALUE::-2}'"
    else
      VALUE=$(echo ${VALUE} | tr -d '\\n')
      if [ -z "${DIRECTORY}" ]; then
        if [ ! -z "${VAR}" ]; then
          echo "${VALUE}" >"${FILE}"
          exit 0
        else
          echo "${VAR_OUT}='${VALUE}'" >>"${FILE}"
        fi
      else
        eval VALUE='$'$VARIABLE
        echo "${VALUE}" >"${DIRECTORY}/${VAR_OUT}"
      fi
    fi
  fi
done

if [ ${IS_OVERRIDE} = "true" ]; then
  echo 'execute generated exports to override environment [eval $(ci env --override...)]' >&2
fi

echo "" >&2
