#!/bin/bash

set -euo pipefail

# Set-up our environment
if [[ -z "${BROWSER_TV_SET_ENVS+x}" ]]; then
    bash -x $(dirname $0)/env.sh
fi
source $(dirname $0)/env.sh

if [ -z "${1+x}" ]; then
    echo_red_text "Usage: $0 arm|arm64|x86_64|bundle" >&1
    exit 1
fi

readonly target=$(echo "${1}" | "${BROWSER_TV_AWK}" '{print tolower($0)}')

# Build Browser TV
readonly BROWSER_TV_FROM_BUILD=1
export BROWSER_TV_FROM_BUILD
if [ "${BROWSER_TV_LOG_BUILD}" == 1 ]; then
    readonly BUILD_LOG_FILE="${BROWSER_TV_LOG_DIR}/build-${target}.log"

    # If the log file already exists, remove it
    if [ -f "${BUILD_LOG_FILE}" ]; then
        rm "${BUILD_LOG_FILE}"
    fi

    # Ensure our log directory exists
    mkdir -vp "${BROWSER_TV_LOG_DIR}"

    bash -x "${BROWSER_TV_SCRIPTS}/build-btv.sh" "${target}" > >(tee -a "${BUILD_LOG_FILE}") 2>&1
else
    bash -x "${BROWSER_TV_SCRIPTS}/build-btv.sh" "${target}"
fi
