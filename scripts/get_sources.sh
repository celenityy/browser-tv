#!/bin/bash

set -euo pipefail

# Set-up our environment
if [[ -z "${BROWSER_TV_SET_ENVS+x}" ]]; then
    bash -x $(dirname $0)/env.sh
fi
source $(dirname $0)/env.sh

# Set up target parameters
if [[ -z "${1+x}" ]]; then
    readonly target='all'
else
    readonly target=$(echo "${1}" | "${BROWSER_TV_AWK}" '{print tolower($0)}')
fi

# Get sources
readonly BROWSER_TV_FROM_SOURCES=1
export BROWSER_TV_FROM_SOURCES
if [ "${BROWSER_TV_LOG_SOURCES}" == 1 ]; then
    readonly SOURCES_LOG_FILE="${BROWSER_TV_LOG_DIR}/get_sources.log"

    # If the log file already exists, remove it
    if [ -f "${SOURCES_LOG_FILE}" ]; then
        rm "${SOURCES_LOG_FILE}"
    fi

    # Ensure our log directory exists
    mkdir -vp "${BROWSER_TV_LOG_DIR}"

    bash -x "${BROWSER_TV_SCRIPTS}/get_sources-btv.sh" "${target}" > >(tee -a "${SOURCES_LOG_FILE}") 2>&1
else
    bash -x "${BROWSER_TV_SCRIPTS}/get_sources-btv.sh" "${target}"
fi
