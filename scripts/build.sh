#!/bin/bash
#
#    Browser TV build scripts
#    Copyright (C) 2025-2026  celenity
#
#    Based on: IronFox build scripts
#    Copyright (C) 2024-2026  Akash Yadav, celenity
#
#    Which were originally based on: Fennec (Mull) build scripts
#    Copyright (C) 2020-2024  Matías Zúñiga, Andrew Nayenko, Tavi
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

set -euo pipefail

# Set-up our environment
if [[ -z "${BROWSER_TV_SET_ENVS+x}" ]]; then
    bash -x $(dirname $0)/env.sh
fi
source $(dirname $0)/env.sh

# Include utilities
source "${BROWSER_TV_UTILS}"

if [ -z "${1+x}" ]; then
    echo_red_text "Usage: $0 arm|arm64|x86_64|bundle" >&1
    exit 1
fi

# Set-up target parameters
case "$1" in
arm64)
    # arm64-v8a
    export BROWSER_TV_TARGET_ARCH='arm64'
    export BROWSER_TV_TARGET_ABI='arm64-v8a'
    export BROWSER_TV_TARGET_PRETTY='ARM64'
    BROWSER_TV_TARGET_RUST='arm64'
    ;;
arm)
    # armeabi-v7a
    export BROWSER_TV_TARGET_ARCH='arm'
    export BROWSER_TV_TARGET_ABI='armeabi-v7a'
    export BROWSER_TV_TARGET_PRETTY='ARM'
    BROWSER_TV_TARGET_RUST='arm'
    ;;
x86_64)
    # x86_64
    export BROWSER_TV_TARGET_ARCH='x86_64'
    export BROWSER_TV_TARGET_ABI='x86_64'
    export BROWSER_TV_TARGET_PRETTY='x86_64'
    BROWSER_TV_TARGET_RUST='x86_64'
    ;;
bundle)
    # arm64-v8a, armeabi-v7a, and x86_64
    export BROWSER_TV_TARGET_ARCH='bundle'
    export BROWSER_TV_TARGET_ABI='arm64-v8a", "armeabi-v7a", "x86_64'
    export BROWSER_TV_TARGET_PRETTY='Bundle'
    BROWSER_TV_TARGET_RUST='arm64,arm,x86_64'
    ;;
*)
    echo_red_text "Unknown build variant: '$1'" >&2
    exit 1
    ;;
esac

if [ ! -d "${BROWSER_TV_ANDROID_SDK}" ]; then
    echo_red_text "\$BROWSER_TV_ANDROID_SDK($BROWSER_TV_ANDROID_SDK) does not exist."
    exit 1
fi

if [ ! -d "${BROWSER_TV_ANDROID_NDK}" ]; then
    echo_red_text "\$BROWSER_TV_ANDROID_NDK($BROWSER_TV_ANDROID_NDK) does not exist."
    exit 1
fi

readonly JAVA_VER=$("${BROWSER_TV_JAVA}" -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{sub("^$", "0", $2); print $1$2}')
[ "${JAVA_VER}" -ge 15 ] || {
    echo_red_text "Java 17 or newer must be set as default JDK"
    exit 1
}

if [[ -z "${BROWSER_TV_SB_GAPI_KEY_FILE+x}" ]]; then
    echo_red_text 'BROWSER_TV_SB_GAPI_KEY_FILE environment variable has not been specified! Safe Browsing will not be supported in this build.'
    read -p 'Do you want to continue [y/N] ' -n 1 -r
    echo ''
    if ! [[ "${REPLY}" =~ ^[Yy]$ ]]; then
        echo_red_text 'Aborting...'
        exit 1
    fi
fi

source "${BROWSER_TV_CARGO_ENV}"
source "${BROWSER_TV_PYENV}"

# Include version info
source "${BROWSER_TV_VERSIONS}"

if [[ -z "${FIREFOX_VERSION}" ]]; then
    echo_red_text "\$FIREFOX_VERSION is not set! Aborting..."
    exit 1
fi

if [[ -z "${BROWSER_TV_VERSION}" ]]; then
    echo_red_text "\$BROWSER_TV_VERSION is not set! Aborting..."
    exit 1
fi

# Set timezone to UTC for consistency
unset TZ
export TZ="UTC"

function set_build_env() {
    echo_red_text 'Setting build environment variables...'

    # Write env_build.sh
    if [[ -f "${BROWSER_TV_ENV_BUILD}" ]]; then
        rm "${BROWSER_TV_ENV_BUILD}"
    fi

    local readonly EPOCH_NS="$("${BROWSER_TV_DATE}" "+%s%N")"
    local readonly BTV_LOCAL_VERSION_STAMP="${EPOCH_NS}"

    if [ "${IRONFOX_TARGET_ARCH}" == 'bundle' ]; then
        # Set build date for bundle builds, to avoid conflicts and ensure that MOZ_BUILDID is consistent across all builds
        local readonly BUILD_DATE="$("${BROWSER_TV_DATE}" -u +"%Y-%m-%dT%H:%M:%SZ")"
        cat > "${BROWSER_TV_ENV_BUILD}" << EOF
export BTV_BUILD_DATE="${BUILD_DATE}"
export BTV_EPOCH_NS="${BTV_LOCAL_VERSION_STAMP}"
export BROWSER_TV_TARGET_ARCH="${BROWSER_TV_TARGET_ARCH}"
EOF
    else
        echo "Writing ${BROWSER_TV_ENV_BUILD}..."
        cat > "${BROWSER_TV_ENV_BUILD}" << EOF
export BTV_EPOCH_NS="${BTV_LOCAL_VERSION_STAMP}"
export BROWSER_TV_TARGET_ARCH="${BROWSER_TV_TARGET_ARCH}"
EOF
    fi

    source "${BROWSER_TV_ENV_BUILD}"

    if [ "${BROWSER_TV_TARGET_ARCH}" == 'bundle' ]; then
        export MOZ_BUILD_DATE="$("${BROWSER_TV_DATE}" -d "${BTV_BUILD_DATE}" "+%Y%m%d%H%M%S")"
    fi

    # Set versions for our local dependency substitutions
    readonly BTV_LOCAL_AC_VERSION_BASE="${FIREFOX_VERSION}-${BTV_EPOCH_NS}"
    readonly BTV_LOCAL_AS_VERSION_BASE="${APPSERVICES_VERSION}-${BTV_EPOCH_NS}"

    readonly BTV_LOCAL_AC_VERSION="0.0.1-local-${BTV_LOCAL_AC_VERSION_BASE}-SNAPSHOT"
    readonly BTV_LOCAL_AC_VERSION_GRADLE="-${BTV_LOCAL_AC_VERSION_BASE}-SNAPSHOT"
    readonly BTV_LOCAL_AS_VERSION="0.0.1-SNAPSHOT-${BTV_LOCAL_AS_VERSION_BASE}-SNAPSHOT"
    readonly BTV_LOCAL_AS_VERSION_GRADLE="${BTV_LOCAL_AS_VERSION_BASE}-SNAPSHOT"

    echo_green_text 'SUCCESS: Set build environment variables'
}

function prep_as() {
    # Application Services
    echo_red_text 'Preparing Application Services...'

    if [[ -f "${BROWSER_TV_AS}/local.properties" ]]; then
        rm -f "${BROWSER_TV_AS}/local.properties"
    fi
    cp -f "${BROWSER_TV_PATCHES}/build/application-services/local.properties" "${BROWSER_TV_AS}/local.properties"
    "${IRONFOX_SED}" -i "s|{BROWSER_TV_PLATFORM}|${BROWSER_TV_PLATFORM}|" "${BROWSER_TV_AS}/local.properties"
    "${IRONFOX_SED}" -i "s|{BROWSER_TV_PLATFORM_ARCH}|${BROWSER_TV_PLATFORM_ARCH}|" "${BROWSER_TV_AS}/local.properties"
    "${IRONFOX_SED}" -i "s|{BROWSER_TV_TARGET_RUST}|${BROWSER_TV_TARGET_RUST}|" "${BROWSER_TV_AS}/local.properties"

    # Substitute our builds of Android Components
    "${BROWSER_TV_SED}" -i -e "/^android-components = \"/c\\android-components = \"${BTV_LOCAL_AC_VERSION}\"" "${BROWSER_TV_AS}/gradle/libs.versions.toml"

    echo_green_text 'SUCCESS: Prepared Application Services'
}

function prep_gecko_prefs() {
    # Prepare our Gecko preferences
    if [[ -f "${BROWSER_TV_BUILD}/tmp/gecko/browser-tv-parsed.cfg" ]]; then
        rm -f "${BROWSER_TV_BUILD}/tmp/gecko/browser-tv-parsed.cfg"
    fi

    cp -f "${BROWSER_TV_PATCHES}/build/gecko/browser-tv.cfg" "${BROWSER_TV_BUILD}/tmp/gecko/browser-tv-parsed.cfg"
    "${BROWSER_TV_SED}" -i "s|{BROWSER_TV_VERSION}|${BROWSER_TV_VERSION}|" "${BROWSER_TV_BUILD}/tmp/gecko/browser-tv-parsed.cfg"
}

function prep_gecko() {
    # Gecko
    echo_red_text 'Preparing Gecko...'

    if [[ -f "${BROWSER_TV_GECKO}/local.properties" ]]; then
        rm -f "${BROWSER_TV_GECKO}/local.properties"
    fi
    cp -f "${BROWSER_TV_PATCHES}/build/gecko/local.properties" "${BROWSER_TV_GECKO}/local.properties"
    "${BROWSER_TV_SED}" -i "s|{BROWSER_TV_GECKO}|${BROWSER_TV_GECKO}|" "${BROWSER_TV_GECKO}/local.properties"

    # Substitute our local versions of Android Components and Application Services
    "${BROWSER_TV_SED}" -i -e "s|val VERSION = .*|val VERSION = \""${BTV_LOCAL_AS_VERSION}\""|g" "${BROWSER_TV_AC}/plugins/dependencies/src/main/java/ApplicationServices.kt"
    "${BROWSER_TV_SED}" -i "s|{BTV_LOCAL_AC_VERSION}|${BTV_LOCAL_AC_VERSION}|" "${BROWSER_TV_GECKO}/local.properties"
    "${BROWSER_TV_SED}" -i "s|{BTV_LOCAL_AS_VERSION}|${BTV_LOCAL_AS_VERSION}|" "${BROWSER_TV_GECKO}/local.properties"

    # Configure release channel
    if [[ "${BROWSER_TV_RELEASE}" == 1 ]]; then
        BROWSER_TV_NAME='Browser TV'
    else
        BROWSER_TV_NAME='Browser TV Nightly'
    fi

    if [[ -f "${BROWSER_TV_GECKO}/toolkit/content/neterror/supportpages/connection-not-secure.html" ]]; then
        rm -f "${BROWSER_TV_GECKO}/toolkit/content/neterror/supportpages/connection-not-secure.html"
    fi
    cp -f "${BROWSER_TV_BUILD}/tmp/gecko/toolkit/content/neterror/supportpages/connection-not-secure.html" "${BROWSER_TV_GECKO}/toolkit/content/neterror/supportpages/connection-not-secure.html"
    "${BROWSER_TV_SED}" -i "s/{BROWSER_TV_NAME}/${BROWSER_TV_NAME}/" "${BROWSER_TV_GECKO}/toolkit/content/neterror/supportpages/connection-not-secure.html"

    if [[ -f "${BROWSER_TV_GECKO}/toolkit/content/neterror/supportpages/time-errors.html" ]]; then
        rm -f "${BROWSER_TV_GECKO}/toolkit/content/neterror/supportpages/time-errors.html"
    fi
    cp -f "${BROWSER_TV_BUILD}/tmp/gecko/toolkit/content/neterror/supportpages/time-errors.html" "${BROWSER_TV_GECKO}/toolkit/content/neterror/supportpages/time-errors.html"
    "${BROWSER_TV_SED}" -i "s/{BROWSER_TV_NAME}/${BROWSER_TV_NAME}/" "${BROWSER_TV_GECKO}/toolkit/content/neterror/supportpages/time-errors.html"

    echo_green_text 'SUCCESS: Prepared Gecko'
}

function prep_phoenix() {
    # Phoenix
    echo_red_text 'Preparing Phoenix...'

    # Ensure our cfg file doesn't already exist in mozilla-central
    if [[ -f "${BROWSER_TV_GECKO}/browser-tv/prefs/browser-tv.cfg" ]]; then
        rm -f "${BROWSER_TV_GECKO}/browser-tv/prefs/browser-tv.cfg"
    fi

    # Ensure our policies file doesn't already exist in mozilla-central
    if [[ -f "${BROWSER_TV_GECKO}/browser-tv/prefs/policies.json" ]]; then
        rm -f "${BROWSER_TV_GECKO}/browser-tv/prefs/policies.json"
    fi

    echo_green_text 'SUCCESS: Prepared Phoenix'
}

function prep_llvm() {
    # LLVM
    echo_red_text 'Preparing LLVM...'

    # Set LLVM build targets
    if [[ -f "${BROWSER_TV_BUILD}/targets_to_build" ]]; then
        rm -f "${BROWSER_TV_BUILD}/targets_to_build"
    fi
    cp -f "${BROWSER_TV_PATCHES}/build/llvm/targets_to_build_${BROWSER_TV_TARGET_ARCH}" "${BROWSER_TV_BUILD}/targets_to_build"

    echo_green_text 'SUCCESS: Prepared LLVM'
}

function clean_gradle() {
    # This is used for cleaning Gradle to ensure builds are fresh
    "${BROWSER_TV_GRADLE}" ${BROWSER_TV_GRADLE_FLAGS} clean
}

function build_bundletool() {
    # Bundletool
    echo_red_text 'Building Bundletool...'

    pushd "${BROWSER_TV_BUNDLETOOL_DIR}"
    clean_gradle
    "${BROWSER_TV_GRADLE}" assemble
    popd

    cp -f "${BROWSER_TV_BUNDLETOOL_DIR}/build/libs/bundletool.jar" "${BROWSER_TV_BUNDLETOOL_JAR}"

    echo_green_text 'SUCCESS: Built Bundletool'
}

function build_llvm() {
    # LLVM
    echo_red_text 'Building LLVM...'

    pushd "${llvm}"
    llvmtarget=$(cat "${BROWSER_TV_BUILD}/targets_to_build")
    echo_green_text "building llvm for ${llvmtarget}"
    cmake -S llvm -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=out -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ -DLLVM_ENABLE_PROJECTS="clang" -DLLVM_TARGETS_TO_BUILD="$llvmtarget" \
        -DLLVM_USE_LINKER=lld -DLLVM_BINUTILS_INCDIR=/usr/include -DLLVM_ENABLE_PLUGINS=FORCE_ON \
        -DLLVM_DEFAULT_TARGET_TRIPLE="x86_64-unknown-linux-gnu"
    cmake --build build -j"$(nproc)"
    cmake --build build --target install -j"$(nproc)"
    popd

    echo_green_text 'SUCCESS: Built LLVM'
}

function build_phoenix() {
    # Build Phoenix...
    echo_red_text 'Building Phoenix...'

    pushd "${BROWSER_TV_PHOENIX}"
    bash -x "${BROWSER_TV_PHOENIX}/scripts/build.sh"
    popd

    echo_green_text 'SUCCESS: Built Phoenix'
}

function build_prebuilds() {
    # Build our prebuilt libraries from source
    echo_red_text 'Building prebuilt libraries...'

    pushd "${BROWSER_TV_PREBUILDS}"
    bash -x "${BROWSER_TV_PREBUILDS}/scripts/build.sh"
    popd

    echo_green_text 'SUCCESS: Built prebuilt libraries'
}

function build_microg() {
    # microG
    echo_red_text 'Building microG...'

    pushd "${BROWSER_TV_GMSCORE}"
    clean_gradle

    "${BROWSER_TV_GRADLE}" ${BROWSER_TV_GRADLE_FLAGS} -Dhttps.protocols=TLSv1.3 -x javaDocReleaseGeneration \
        :play-services-base:publishToMavenLocal \
        :play-services-basement:publishToMavenLocal \
        :play-services-fido:publishToMavenLocal \
        :play-services-tasks:publishToMavenLocal
    popd

    echo_green_text 'SUCCESS: Built microG'
}

function build_gecko_ind() {
    # Build Gecko
    unset BROWSER_TV_MACH_BUILD
    unset MOZ_CHROME_MULTILOCALE
    export BROWSER_TV_MACH_BUILD=1

    pushd "${BROWSER_TV_GECKO}"
    "${BROWSER_TV_MACH}" configure
    "${BROWSER_TV_MACH}" build
    popd
}

function package_gecko() {
    # Package Gecko
    unset BROWSER_TV_MACH_BUILD
    export BROWSER_TV_MACH_BUILD=0
    pushd "${BROWSER_TV_GECKO}"
    "${BROWSER_TV_MACH}" configure

    # We don't want to clean Gradle here on bundle builds, because doing so will cause it to clean after each architecture is built...
    if [ "${BROWSER_TV_TARGET_ARCH}" != 'bundle' ]; then
        "${BROWSER_TV_MACH}" gradle geckoview:clean
    fi

    echo_green_text "Running ${BROWSER_TV_MACH} package..."
    "${BROWSER_TV_MACH}" package

    echo_green_text "Running ${BROWSER_TV_MACH} package-multi-locale..."
    "${BROWSER_TV_MACH}" package-multi-locale --locales ${BROWSER_TV_LOCALES}

    export MOZ_CHROME_MULTILOCALE="${BROWSER_TV_LOCALES}"

    # Package GeckoView
    ## (MOZ_AUTOMATION is set here to create the AAR zips)
    echo_green_text "Running ${BROWSER_TV_MACH} android archive-geckoview..."
    MOZ_AUTOMATION=1 "${BROWSER_TV_MACH}" android archive-geckoview
    unset MOZ_AUTOMATION
    popd
}

# Create our fat GeckoView AAR...
function create_fat_aar() {
    # Fat AAR
    unset BROWSER_TV_MACH_BUILD
    export BROWSER_TV_MACH_BUILD=0

    pushd "${BROWSER_TV_GECKO}"
    "${BROWSER_TV_MACH}" configure
    "${BROWSER_TV_MACH}" build android-fat-aar-artifact
    popd
}

function build_gecko_arm64() {
    # ARM64
    unset BROWSER_TV_MACH_TARGET_BUNDLE_ARM64
    export BROWSER_TV_MACH_TARGET_BUNDLE_ARM64=1

    pushd "${BROWSER_TV_GECKO}"
    echo_red_text 'Building Gecko(View) - ARM64...'
    build_gecko_ind
    echo_green_text 'SUCCESS: Built Gecko(View) - ARM64'

    echo_red_text 'Packaging Gecko(View) - ARM64...'
    package_gecko
    echo_green_text 'SUCCESS: Packaged Gecko(View) - ARM64'
    popd

    cp -vf "${BROWSER_TV_GV_AAR_ARM64}" "${BROWSER_TV_OUTPUTS_GV_AAR_ARM64}"

    unset BROWSER_TV_MACH_TARGET_BUNDLE_ARM64
    export BROWSER_TV_MACH_TARGET_BUNDLE_ARM64=0
}

function build_gecko_arm() {
    # ARM
    unset BROWSER_TV_MACH_TARGET_BUNDLE_ARM
    export BROWSER_TV_MACH_TARGET_BUNDLE_ARM=1

    pushd "${BROWSER_TV_GECKO}"
    echo_red_text 'Building Gecko(View) - ARM...'
    build_gecko_ind
    echo_green_text 'SUCCESS: Built Gecko(View) - ARM'

    echo_red_text 'Packaging Gecko - ARM...'
    package_gecko
    echo_green_text 'SUCCESS: Packaged Gecko(View) - ARM'
    popd

    cp -vf "${BROWSER_TV_GV_AAR_ARM}" "${BROWSER_TV_OUTPUTS_GV_AAR_ARM}"

    unset BROWSER_TV_MACH_TARGET_BUNDLE_ARM
    export BROWSER_TV_MACH_TARGET_BUNDLE_ARM=0
}

function build_gecko_x86_64() {
    # x86_64
    unset BROWSER_TV_MACH_TARGET_BUNDLE_X86_64
    export BROWSER_TV_MACH_TARGET_BUNDLE_X86_64=1

    pushd "${BROWSER_TV_GECKO}"
    echo_red_text 'Building Gecko(View) - x86_64...'
    build_gecko_ind
    echo_green_text 'SUCCESS: Built Gecko(View) - x86_64'

    echo_red_text 'Packaging Gecko(View) - x86_64...'
    package_gecko
    echo_green_text 'SUCCESS: Packaged Gecko(View) - x86_64'
    unset BROWSER_TV_MACH_TARGET_BUNDLE_X86_64
    export BROWSER_TV_MACH_TARGET_BUNDLE_X86_64=0
    "${BROWSER_TV_MACH}" configure
    popd

    cp -vf "${BROWSER_TV_GV_AAR_X86_64}" "${BROWSER_TV_OUTPUTS_GV_AAR_X86_64}"

    unset BROWSER_TV_MACH_TARGET_BUNDLE_X86_64
    export BROWSER_TV_MACH_TARGET_BUNDLE_X86_64=0
}

function build_gecko_bundle() {
    # Bundle
    export MOZ_ANDROID_FAT_AAR_ARCHITECTURES='arm64-v8a,armeabi-v7a,x86_64'
    export MOZ_ANDROID_FAT_AAR_ARM64_V8A="${BROWSER_TV_OUTPUTS_GV_AAR_ARM64}"
    export MOZ_ANDROID_FAT_AAR_ARMEABI_V7A="${BROWSER_TV_OUTPUTS_GV_AAR_ARM}"
    export MOZ_ANDROID_FAT_AAR_X86_64="${BROWSER_TV_OUTPUTS_GV_AAR_X86_64}"

    pushd "${BROWSER_TV_GECKO}"
    echo_red_text 'Creating GeckoView fat AAR...'
    create_fat_aar
    echo_green_text 'SUCCESS: Created GeckoView fat AAR'

    echo_red_text 'Building Gecko(View) - Bundle...'
    build_gecko_ind
    echo_green_text 'SUCCESS: Built Gecko(View) - Bundle'

    echo_red_text 'Packaging Gecko(View) - Bundle...'
    package_gecko
    echo_green_text 'SUCCESS: Packaged Gecko(View) - Bundle'
    popd
}

function clobber_gecko_arm64() {
    # Clobber Gecko (ARM64)
    unset BROWSER_TV_MACH_TARGET_BUNDLE_ARM64
    export BROWSER_TV_MACH_TARGET_BUNDLE_ARM64=1

    pushd "${BROWSER_TV_GECKO}"
    "${BROWSER_TV_MACH}" configure
    "${BROWSER_TV_MACH}" clobber
    unset BROWSER_TV_MACH_TARGET_BUNDLE_ARM64
    export BROWSER_TV_MACH_TARGET_BUNDLE_ARM64=0
    "${BROWSER_TV_MACH}" configure
    popd
}

function clobber_gecko_arm() {
    # Clobber Gecko (ARM)
    unset BROWSER_TV_MACH_TARGET_BUNDLE_ARM
    export BROWSER_TV_MACH_TARGET_BUNDLE_ARM=1

    pushd "${BROWSER_TV_GECKO}"
    "${BROWSER_TV_MACH}" configure
    "${BROWSER_TV_MACH}" clobber
    unset BROWSER_TV_MACH_TARGET_BUNDLE_ARM
    export BROWSER_TV_MACH_TARGET_BUNDLE_ARM=0
    "${BROWSER_TV_MACH}" configure
    popd
}

function clobber_gecko_x86_64() {
    # Clobber Gecko (x86_64)
    unset BROWSER_TV_MACH_TARGET_BUNDLE_X86_64
    export BROWSER_TV_MACH_TARGET_BUNDLE_X86_64=1

    pushd "${BROWSER_TV_GECKO}"
    "${BROWSER_TV_MACH}" configure
    "${BROWSER_TV_MACH}" clobber
    unset BROWSER_TV_MACH_TARGET_BUNDLE_X86_64
    export BROWSER_TV_MACH_TARGET_BUNDLE_X86_64=0
    "${BROWSER_TV_MACH}" configure
    popd
}

function clobber_gecko() {
    "${BROWSER_TV_MACH}" configure
    "${BROWSER_TV_MACH}" clobber
    if [ "${BROWSER_TV_TARGET_ARCH}" == 'bundle' ]; then
        clobber_gecko_arm64
        clobber_gecko_arm
        clobber_gecko_x86_64
    fi
}

function build_gecko() {
    # Gecko (Firefox)
    echo_red_text 'Building Gecko(View)...'
    unset BROWSER_TV_MACH_TARGET_GECKO
    export BROWSER_TV_MACH_TARGET_GECKO=1

    pushd "${BROWSER_TV_GECKO}"
    "${BROWSER_TV_MACH}" configure

    # Always clobber to ensure that builds are fresh
    clobber_gecko

    if [ "${BROWSER_TV_TARGET_ARCH}" != 'bundle' ]; then
        if [ "${BROWSER_TV_TARGET_ARCH}" == 'arm64' ]; then
            # Build ARM64
            build_gecko_arm64
        elif [ "${BROWSER_TV_TARGET_ARCH}" == 'arm' ]; then
            # Build ARM
            build_gecko_arm
        elif [ "${BROWSER_TV_TARGET_ARCH}" == 'x86_64' ]; then
            # Build x86_64
            build_gecko_x86_64
        elif [ "${BROWSER_TV_TARGET_ARCH}" == 'bundle' ]; then
            # Create our bundle + fat AAR...
            build_gecko_bundle
        fi
    elif [ "${BROWSER_TV_TARGET_ARCH}" == 'bundle' ]; then
        # 1. Build ARM64
        build_gecko_arm64

        # 2. Build ARM
        build_gecko_arm

        # 3. Build x86_64
        build_gecko_x86_64

        # 4. Finally, create our bundle + fat AAR...
        build_gecko_bundle
    fi
    unset BROWSER_TV_MACH_TARGET_GECKO
    export BROWSER_TV_MACH_TARGET_GECKO=0
    "${BROWSER_TV_MACH}" configure
    popd

    echo_green_text 'SUCCESS: Built Gecko(View)'
}

function build_ac_core() {
    # Android Components
    echo_red_text 'Building Android Components (Core)...'
    unset BROWSER_TV_MACH_BUILD
    unset BROWSER_TV_MACH_TARGET_AC
    export BROWSER_TV_MACH_BUILD=1
    export BROWSER_TV_MACH_TARGET_AC=1

    # Ensure the CI env variable is not set here - otherwise this will cause build failure in Application Services, thanks to us removing MARS and friends
    unset CI

    pushd "${BROWSER_TV_GECKO}"
    "${BROWSER_TV_MACH}" configure

    # Always clean Gradle to ensure builds are fresh
    "${BROWSER_TV_MACH}" gradle -p mobile/android/android-components clean

    # Build concept-fetch
    ## (Needed by Application Services)
    "${BROWSER_TV_MACH}" gradle -Plocal=${BTV_LOCAL_AC_VERSION_GRADLE} -p mobile/android/android-components :components:concept-fetch:publishToMavenLocal

    unset BROWSER_TV_MACH_TARGET_AC
    export BROWSER_TV_MACH_TARGET_AC=0
    "${BROWSER_TV_MACH}" configure
    popd

    echo_green_text 'SUCCESS: Built Android Components (Core)'
}

function build_as() {
    # Application Services
    echo_red_text 'Building Application Services...'

    pushd "${BROWSER_TV_AS}"
    clean_gradle

    # When 'CI' environment variable is set to a non-zero value, the 'libs/verify-ci-android-environment.sh' script
    # skips building the libraries as they are expected to be already downloaded in a CI environment
    # However, we want build those libraries always, so we unset CI before invoking the script
    unset CI

    bash -x "${BROWSER_TV_AS}/libs/verify-android-environment.sh"

    # Build Application Services
    "${BROWSER_TV_GRADLE}" ${BROWSER_TV_GRADLE_FLAGS} publish -Plocal=${BTV_LOCAL_AS_VERSION_GRADLE}

    popd

    echo_green_text 'SUCCESS: Built Application Services'
}

function build_ac() {
    # Android Components
    echo_red_text 'Building Android Components...'
    unset BROWSER_TV_MACH_BUILD
    unset BROWSER_TV_MACH_TARGET_AC
    export BROWSER_TV_MACH_BUILD=1
    export BROWSER_TV_MACH_TARGET_AC=1

    pushd "${BROWSER_TV_GECKO}"
    "${BROWSER_TV_MACH}" configure

    # Build Android Components
    "${BROWSER_TV_MACH}" gradle -Plocal=${BTV_LOCAL_AC_VERSION_GRADLE} -p mobile/android/android-components publishToMavenLocal
    unset BROWSER_TV_MACH_TARGET_AC
    export BROWSER_TV_MACH_TARGET_AC=0
    "${BROWSER_TV_MACH}" configure
    popd

    echo_green_text 'SUCCESS: Built Android Components'
}

function build_browser_tv() {
    # Browser TV
    echo_red_text 'Building Browser TV...'

    pushd "${BROWSER_TV_ROOT}/app"
    clean_gradle

    "${BROWSER_TV_GRADLE}" "${BROWSER_TV_GRADLE_FLAGS}" :app:assembleRelease
    if [[ "${BROWSER_TV_TARGET_ARCH}" == "bundle" ]]; then
        "${BROWSER_TV_GRADLE}" "${BROWSER_TV_GRADLE_FLAGS}" :app:bundleRelease -Paab
    fi
    popd

    echo_green_text 'SUCCESS: Built Browser TV'
}

# Prepare build environment...
## (These need to be performed here instead of in `prebuild.sh`, so that we can account for if users decide to
### change the variables, without them needing to re-run the entire prebuild script...)
echo_red_text 'Preparing your build environment...'

set_build_env
# prep_as
prep_gecko
prep_gecko_prefs
prep_phoenix
prep_llvm

echo_green_text 'SUCCESS: Prepared build environment'

# Begin the build...
echo_red_text "Building Browser TV ${BROWSER_TV_VERSION}: ${BROWSER_TV_CHANNEL_PRETTY} (${BROWSER_TV_TARGET_PRETTY})..."

if [[ "${BROWSER_TV_NO_PREBUILDS}" == 1 ]]; then
    # build_llvm
    build_bundletool
    build_prebuilds
fi

build_microg
build_phoenix
build_gecko
# build_ac_core
# build_as
# build_ac
build_browser_tv

echo_green_text "SUCCESS: Built Browser TV ${BROWSER_TV_VERSION}: ${BROWSER_TV_CHANNEL_PRETTY} (${BROWSER_TV_TARGET_PRETTY})"

