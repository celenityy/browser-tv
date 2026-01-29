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

echo_red_text() {
	echo -e "\033[31m$1\033[0m"
}

echo_green_text() {
	echo -e "\033[32m$1\033[0m"
}

if [ -z "${1+x}" ]; then
    echo_red_text "Usage: $0 apk|bundle" >&1
    exit 1
fi

build_type="$1"

if [ "${build_type}" != "apk" ] && [ "${build_type}" != "bundle" ]; then
    echo_red_text "Unknown build type: '${build_type}'" >&1
    echo_red_text "Usage: $0 apk|bundle" >&1
    exit 1
fi

# Set-up our environment
bash -x $(dirname $0)/env.sh
source $(dirname $0)/env.sh

# Configure our build target
source "${BROWSER_TV_ENV_TARGET}"

source "${BROWSER_TV_CARGO_ENV}"
source "${BROWSER_TV_PIP_ENV}"

# Include version info
source "${BROWSER_TV_VERSIONS}"

# Prepare build environment...
## (These need to be performed here instead of in `prebuild.sh`, so that we can account for if users decide to
### change the variables, without them needing to re-run the entire prebuild script...)
echo_green_text "Preparing your build environment..."

## Set Gecko environment-specific Gradle properties
if [[ -f "${BROWSER_TV_GECKO}/local.properties" ]]; then
    rm -f "${BROWSER_TV_GECKO}/local.properties"
fi
cp -f "${BROWSER_TV_PATCHES}/build/gecko/local.properties" "${BROWSER_TV_GECKO}/local.properties"
"${BROWSER_TV_SED}" -i "s|{BROWSER_TV_GECKO}|${BROWSER_TV_GECKO}|" "${BROWSER_TV_GECKO}/local.properties"

## Set LLVM build targets
if [[ -f "${BROWSER_TV_BUILD}/targets_to_build" ]]; then
    rm -f "${BROWSER_TV_BUILD}/targets_to_build"
fi
cp -f "${BROWSER_TV_PATCHES}/build/llvm/targets_to_build_${BROWSER_TV_TARGET_ARCH}" "${BROWSER_TV_BUILD}/targets_to_build"

## Set our Gecko prefs
if [[ -f "${BROWSER_TV_GECKO}/browser-tv/prefs/browser-tv.cfg" ]]; then
    rm -f "${BROWSER_TV_GECKO}/browser-tv/prefs/browser-tv.cfg"
fi

cp -f "${BROWSER_TV_PATCHES}/build/gecko/browser-tv.cfg" "${BROWSER_TV_GECKO}/browser-tv/prefs/browser-tv.cfg"
"${BROWSER_TV_SED}" -i "s|{BROWSER_TV_VERSION}|${BROWSER_TV_VERSION}|" "${BROWSER_TV_GECKO}/browser-tv/prefs/browser-tv.cfg"

# Begin the build...
echo_green_text "Building Browser TV ${BROWSER_TV_VERSION}: ${BROWSER_TV_CHANNEL_PRETTY} (${BROWSER_TV_TARGET_PRETTY})"

if [[ "${BROWSER_TV_NO_PREBUILDS}" == 1 ]]; then
    # Build our prebuilt libraries from source
    pushd "${BROWSER_TV_IRONFOX_PREBUILDS}"
    bash -x "${BROWSER_TV_IRONFOX_PREBUILDS}/scripts/build.sh"
    popd
fi

# Build microG libraries
pushd "${BROWSER_TV_GMSCORE}"
"${BROWSER_TV_GRADLE}" "${BROWSER_TV_GRADLE_FLAGS}" -Dhttps.protocols=TLSv1.3 -x javaDocReleaseGeneration \
    :play-services-ads-identifier:publishToMavenLocal \
    :play-services-base:publishToMavenLocal \
    :play-services-basement:publishToMavenLocal \
    :play-services-fido:publishToMavenLocal \
    :play-services-tasks:publishToMavenLocal
popd

# Gecko (Firefox)
pushd "${BROWSER_TV_GECKO}"

build_gecko() {
    unset MOZ_CHROME_MULTILOCALE

    echo_green_text "Running ${BROWSER_TV_MACH} configure..."
    "${BROWSER_TV_MACH}" configure
    echo_green_text "Running ${BROWSER_TV_MACH} clobber..."
    "${BROWSER_TV_MACH}" clobber
    echo_green_text "Running ${BROWSER_TV_MACH} build..."
    "${BROWSER_TV_MACH}" build
    echo_green_text "Running ${BROWSER_TV_MACH} package..."
    "${BROWSER_TV_MACH}" package
    echo_green_text "Running ${BROWSER_TV_MACH} package-multi-locale..."
    "${BROWSER_TV_MACH}" package-multi-locale --locales ${BROWSER_TV_GECKO_LOCALES}

    export MOZ_CHROME_MULTILOCALE="${BROWSER_TV_GECKO_LOCALES}"

    echo_green_text "Running '${BROWSER_TV_GRADLE}' '${BROWSER_TV_GRADLE_FLAGS}' -Pofficial -x javadocRelease :geckoview:publishReleasePublicationToMavenLocal..."
    "${BROWSER_TV_GRADLE}" "${BROWSER_TV_GRADLE_FLAGS}" -Pofficial -x javadocRelease :geckoview:publishReleasePublicationToMavenLocal

    if [ "${BROWSER_TV_TARGET_ARCH_MOZ}" != "bundle" ]; then
        # Create GeckoView AAR archives
        MOZ_AUTOMATION=1 "${BROWSER_TV_MACH}" android archive-geckoview
        unset MOZ_AUTOMATION
        if [[ "${BROWSER_TV_TARGET_ARCH_MOZ}" == 'arm' ]]; then
            cp -vf "${BROWSER_TV_GV_AAR_ARM}" "${BROWSER_TV_OUTPUTS_GV_AAR_ARM}"
        elif [[ "${BROWSER_TV_TARGET_ARCH_MOZ}" == 'arm64' ]]; then
            cp -vf "${BROWSER_TV_GV_AAR_ARM64}" "${BROWSER_TV_OUTPUTS_GV_AAR_ARM64}"
        elif [[ "${BROWSER_TV_TARGET_ARCH_MOZ}" == 'x86_64' ]]; then
            cp -vf "${BROWSER_TV_GV_AAR_X86_64}" "${BROWSER_TV_OUTPUTS_GV_AAR_X86_64}"
        fi
    fi
}

if [ "${build_type}" == "bundle" ]; then
    unset BROWSER_TV_TARGET_ARCH_MOZ

    # Write env_build.sh (for setting build date)
    if [[ -f "${BROWSER_TV_ENV_BUILD}" ]]; then
        rm "${BROWSER_TV_ENV_BUILD}"
    fi
    BUILD_DATE="$("${BROWSER_TV_DATE}" -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "Writing ${BROWSER_TV_ENV_BUILD}..."
    cat > "${BROWSER_TV_ENV_BUILD}" << EOF
    export BTV_BUILD_DATE="${BUILD_DATE}"
EOF

    # Set build date (to ensure MOZ_BUILDID is consistent across all builds)
    source "${BROWSER_TV_ENV_BUILD}"
    export MOZ_BUILD_DATE="$("${BROWSER_TV_DATE}" -d "${BTV_BUILD_DATE}" "+%Y%m%d%H%M%S")"

    # 1. Build ARM64
    export BROWSER_TV_TARGET_ARCH_MOZ='arm64'
    build_gecko

    # 2. Build ARM
    export BROWSER_TV_TARGET_ARCH_MOZ='arm'
    build_gecko

    # 3. Build x86_64
    export BROWSER_TV_TARGET_ARCH_MOZ='x86_64'
    build_gecko

    # 4. Finally, build our bundle
    export BROWSER_TV_TARGET_ARCH_MOZ='bundle'
    export MOZ_ANDROID_FAT_AAR_ARCHITECTURES='arm64-v8a,armeabi-v7a,x86_64'
    export MOZ_ANDROID_FAT_AAR_ARM64_V8A="${IRONFOX_OUTPUTS_GV_AAR_ARM}"
    export MOZ_ANDROID_FAT_AAR_ARMEABI_V7A="${IRONFOX_OUTPUTS_GV_AAR_ARM64}"
    export MOZ_ANDROID_FAT_AAR_X86_64="${IRONFOX_OUTPUTS_GV_AAR_X86_64}"
    "${BROWSER_TV_MACH}" configure
    "${BROWSER_TV_MACH}" build android-fat-aar-artifact
else
    build_gecko
fi

popd

pushd "${BROWSER_TV_ROOT}/app"
if [[ "$build_type" == "apk" ]]; then
    "${BROWSER_TV_GRADLE}" "${BROWSER_TV_GRADLE_FLAGS}" :app:assembleRelease
elif [[ "$build_type" == "bundle" ]]; then
    "${BROWSER_TV_GRADLE}" "${BROWSER_TV_GRADLE_FLAGS}" :app:bundleRelease -Paab
fi
popd
