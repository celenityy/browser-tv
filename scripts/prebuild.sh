#!/bin/bash

set -euo pipefail

# Set-up our environment
if [[ -z "${BROWSER_TV_SET_ENVS+x}" ]]; then
    bash -x $(dirname $0)/env.sh
fi
source $(dirname $0)/env.sh

# Prepare to build Browser TV
readonly BROWSER_TV_FROM_PREBUILD=1
export BROWSER_TV_FROM_PREBUILD
if [ "${BROWSER_TV_LOG_PREBUILD}" == 1 ]; then
    readonly PREBUILD_LOG_FILE="${BROWSER_TV_LOG_DIR}/prebuild.log"

    # If the log file already exists, remove it
    if [ -f "${PREBUILD_LOG_FILE}" ]; then
        rm "${PREBUILD_LOG_FILE}"
    fi

    # Ensure our log directory exists
    mkdir -vp "${BROWSER_TV_LOG_DIR}"

    bash -x "${BROWSER_TV_SCRIPTS}/prebuild-btv.sh" > >(tee -a "${PREBUILD_LOG_FILE}") 2>&1
else
    bash -x "${BROWSER_TV_SCRIPTS}/prebuild-btv.sh"
fi
