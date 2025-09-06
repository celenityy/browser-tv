#!/bin/bash
# shellcheck disable=SC2034

# Sources
FIREFOX_VERSION="142.0.1"
BROWSER_VERSION="${FIREFOX_VERSION}"
FIREFOX_RELEASE_TAG="FIREFOX-ANDROID_${FIREFOX_VERSION//./_}_RELEASE"
#FIREFOX_RELEASE_TAG="FIREFOX-ANDROID_${FIREFOX_VERSION//./_}_BUILD1"
FIREFOX_RELEASE_PATH="releases/${FIREFOX_VERSION}"
WASI_TAG="wasi-sdk-20"
GMSCORE_TAG="v0.3.9.250932"
PHOENIX_TAG="2025.08.06.1"
APPSERVICES_BRANCH="release-v142"

# Tools
BUNDLETOOL_TAG="1.18.1"
RUST_MAJOR_VERSION="1.89"
RUST_VERSION="${RUST_MAJOR_VERSION}.0"
CBINDGEN_VERSION="0.29.0"

# Configuration
ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_SH="${ROOTDIR}/scripts/env_local.sh"
BUILDDIR="${ROOTDIR}/build"
PATCHDIR="${ROOTDIR}/patches"
GECKODIR="${ROOTDIR}/gecko"
APPSERVICESDIR="${ROOTDIR}/application-services"
BUNDLETOOLDIR="$BUILDDIR/bundletool"
GMSCOREDIR="${ROOTDIR}/gmscore"
WASISDKDIR="${ROOTDIR}/wasi-sdk"
ANDROID_COMPONENTS="${GECKODIR}/mobile/android/android-components"
BROWSERTV="${ROOTDIR}/browser"

# Use GNU Sed on macOS instead of the built-in sed, due to differences in syntax
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED=gsed
else
    SED=sed
fi
