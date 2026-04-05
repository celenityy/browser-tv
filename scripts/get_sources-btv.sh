#!/bin/bash

set -euo pipefail

# Set-up our environment
source $(dirname $0)/env.sh

# Include utilities
source "${BROWSER_TV_UTILS}"

if [[ -z "${BROWSER_TV_FROM_SOURCES+x}" ]]; then
    echo_red_text "ERROR: Do not call get_sources-btv.sh directly. Instead, use get_sources.sh." >&1
    exit 1
fi

readonly target="$1"
readonly mode="$2"

# Set-up target parameters
BROWSER_TV_GET_SOURCE_ANDROID_NDK=0
BROWSER_TV_GET_SOURCE_ANDROID_SDK=0
BROWSER_TV_GET_SOURCE_ANDROID_SDK_BUILD_TOOLS=0
BROWSER_TV_GET_SOURCE_ANDROID_SDK_PLATFORM=0
BROWSER_TV_GET_SOURCE_BUNDLETOOL=0
BROWSER_TV_GET_SOURCE_CBINDGEN=0
BROWSER_TV_GET_SOURCE_GECKO=0
BROWSER_TV_GET_SOURCE_GECKO_L10N=0
BROWSER_TV_GET_SOURCE_GRADLE=0
BROWSER_TV_GET_SOURCE_GYP=0
BROWSER_TV_GET_SOURCE_MICROG=0
BROWSER_TV_GET_SOURCE_PHOENIX=0
BROWSER_TV_GET_SOURCE_PIP=0
BROWSER_TV_GET_SOURCE_PREBUILDS=0
BROWSER_TV_GET_SOURCE_RUST=0

if [ "${target}" == 'android-ndk' ]; then
    # Get Android NDK
    BROWSER_TV_GET_SOURCE_ANDROID_NDK=1
elif [ "${target}" == 'android-sdk' ]; then
    # Get Android SDK
    BROWSER_TV_GET_SOURCE_ANDROID_SDK=1
elif [ "${target}" == 'android-sdk-build-tools' ]; then
    # Get Android SDK Build Tools
    BROWSER_TV_GET_SOURCE_ANDROID_SDK_BUILD_TOOLS=1
elif [ "${target}" == 'android-sdk-platform' ]; then
    # Get Android SDK Platform
    BROWSER_TV_GET_SOURCE_ANDROID_SDK_PLATFORM=1
elif [ "${target}" == 'bundletool' ]; then
    # Get + set-up Bundletool
    BROWSER_TV_GET_SOURCE_BUNDLETOOL=1
elif [ "${target}" == 'cbindgen' ]; then
    # Get cbindgen
    BROWSER_TV_GET_SOURCE_CBINDGEN=1
elif [ "${target}" == 'firefox' ]; then
    # Get Firefox (Gecko/mozilla-central)
    BROWSER_TV_GET_SOURCE_GECKO=1
elif [ "${target}" == 'firefox-l10n' ]; then
    # Get firefox-l10n
    BROWSER_TV_GET_SOURCE_GECKO_L10N=1
elif [ "${target}" == 'gradle' ]; then
    # Get + set-up Gradle
    BROWSER_TV_GET_SOURCE_GRADLE=1
elif [ "${target}" == 'gyp' ]; then
    # Get gyp-next
    BROWSER_TV_GET_SOURCE_GYP=1
elif [ "${target}" == 'microg' ]; then
    # Get microG
    BROWSER_TV_GET_SOURCE_MICROG=1
elif [ "${target}" == 'phoenix' ]; then
    # Get Phoenix
    BROWSER_TV_GET_SOURCE_PHOENIX=1
elif [ "${target}" == 'prebuilds' ]; then
    # Get IronFox prebuilds
    BROWSER_TV_GET_SOURCE_PREBUILDS=1
elif [ "${target}" == 'pip' ]; then
    # Get + set-up pip
    BROWSER_TV_GET_SOURCE_PIP=1
elif [ "${target}" == 'rust' ]; then
    # Get + set-up rust/cargo
    BROWSER_TV_GET_SOURCE_RUST=1
elif [ "${target}" == 'all' ]; then
    # If no argument is specified (or argument is set to "all"), just get everything
    BROWSER_TV_GET_SOURCE_ANDROID_NDK=1
    BROWSER_TV_GET_SOURCE_ANDROID_SDK=1
    BROWSER_TV_GET_SOURCE_ANDROID_SDK_BUILD_TOOLS=1
    BROWSER_TV_GET_SOURCE_ANDROID_SDK_PLATFORM=1
    BROWSER_TV_GET_SOURCE_BUNDLETOOL=1
    BROWSER_TV_GET_SOURCE_CBINDGEN=1
    BROWSER_TV_GET_SOURCE_GECKO=1
    BROWSER_TV_GET_SOURCE_GECKO_L10N=1
    BROWSER_TV_GET_SOURCE_GRADLE=1
    BROWSER_TV_GET_SOURCE_GYP=1
    BROWSER_TV_GET_SOURCE_MICROG=1
    BROWSER_TV_GET_SOURCE_PHOENIX=1
    BROWSER_TV_GET_SOURCE_PIP=1
    BROWSER_TV_GET_SOURCE_PREBUILDS=1
    BROWSER_TV_GET_SOURCE_RUST=1
else
    echo_red_text "ERROR: Invalid target: ${target}\n You must enter one of the following:"
    echo 'All: all (Default)'
    echo 'Android NDK: android-ndk'
    echo 'Android SDK: android-sdk'
    echo 'Android SDK Build Tools: android-sdk-build-tools'
    echo 'Android SDK Platform: android-sdk-platform'
    echo 'Bundletool: bundletool'
    echo 'cbindgen: cbindgen'
    echo 'Firefox (Gecko/mozilla-central): firefox'
    echo 'firefox-l10n (l10n-central): firefox-l10n'
    echo 'Gradle: gradle'
    echo 'GYP: gyp'
    echo 'microG: microg'
    echo 'Phoenix: phoenix'
    echo 'pip: pip'
    echo 'Prebuilds: prebuilds'
    echo 'Rust: rust'
    exit 1
fi
readonly BROWSER_TV_GET_SOURCE_ANDROID_NDK
readonly BROWSER_TV_GET_SOURCE_ANDROID_SDK
readonly BROWSER_TV_GET_SOURCE_ANDROID_SDK_BUILD_TOOLS
readonly BROWSER_TV_GET_SOURCE_ANDROID_SDK_PLATFORM
readonly BROWSER_TV_GET_SOURCE_BUNDLETOOL
readonly BROWSER_TV_GET_SOURCE_CBINDGEN
readonly BROWSER_TV_GET_SOURCE_GECKO
readonly BROWSER_TV_GET_SOURCE_GECKO_L10N
readonly BROWSER_TV_GET_SOURCE_GRADLE
readonly BROWSER_TV_GET_SOURCE_GYP
readonly BROWSER_TV_GET_SOURCE_MICROG
readonly BROWSER_TV_GET_SOURCE_PHOENIX
readonly BROWSER_TV_GET_SOURCE_PIP
readonly BROWSER_TV_GET_SOURCE_PREBUILDS
readonly BROWSER_TV_GET_SOURCE_RUST

# Include version info
source "${BROWSER_TV_VERSIONS}"

function clone_repo() {
    local readonly url="$1"
    local readonly path="$2"
    local readonly revision="$3"

    if [[ "${url}" == "" ]]; then
        echo "URL missing for clone"
        exit 1
    fi

    if [[ "${path}" == "" ]]; then
        echo "Path is required for cloning '${url}'"
        exit 1
    fi

    if [[ "${revision}" == "" ]]; then
        echo "Revision is required for cloning '${url}'"
        exit 1
    fi

    if [[ -f "${path}" ]]; then
        echo "'${path}' exists and is not a directory"
        exit 1
    fi

    if [[ -d "${path}" ]]; then
        echo "'${path}' already exists"
        read -p "Do you want to re-clone this repository? [y/N] " -n 1 -r
        echo
        if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
            echo "Removing ${path}..."
            rm -rf "${path}"
        else
            return 0
        fi
    fi

    echo "Cloning ${url}::${revision}"
    git clone --revision="${revision}" --depth=1 "${url}" "${path}"
}

function download() {
    local readonly url="$1"
    local readonly filepath="$2"

    if [[ "${url}" == "" ]]; then
        echo "URL is required (file: '${filepath}')"
        exit 1
    fi

    if [ -f "${filepath}" ]; then
        echo "${filepath} already exists."
        read -p "Do you want to re-download? [y/N] " -n 1 -r
        echo
        if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
            echo "Removing ${filepath}..."
            rm -f "${filepath}"
        else
            return 0
        fi
    fi

    mkdir -vp "$(dirname "${filepath}")"

    echo "Downloading ${url}"
    curl ${BROWSER_TV_CURL_FLAGS} -sSL "${url}" -o "${filepath}"
}

# Extract zip removing top level directory
function extract_rmtoplevel() {
    local readonly archive_path="$1"
    local readonly to_name="$2"
    local readonly extract_to="${BROWSER_TV_EXTERNAL}/${to_name}"

    if ! [[ -f "${archive_path}" ]]; then
        echo "Archive '${archive_path}' does not exist!"
    fi

    # Create temporary directory for extraction
    local readonly temp_dir=$(mktemp -d)

    # Extract based on file extension
    case "${archive_path}" in
        *.zip)
            unzip -q "${archive_path}" -d "${temp_dir}"
            ;;
        *.tar.gz)
            "${BROWSER_TV_TAR}" xzf "${archive_path}" -C "${temp_dir}"
            ;;
        *.tar.xz)
            "${BROWSER_TV_TAR}" xJf "${archive_path}" -C "${temp_dir}"
            ;;
        *.tar.zst)
            "${BROWSER_TV_TAR}" --zstd -xvf "${archive_path}" -C "${temp_dir}"
            ;;
        *)
            echo "Unsupported archive format: ${archive_path}"
            rm -rf "${temp_dir}"
            exit 1
            ;;
    esac

    local readonly top_dir=$(ls "${temp_dir}")
    local readonly to_parent=$(dirname "${extract_to}")

    rm -rf "${extract_to}"
    mkdir -vp "${to_parent}"
    mv "${temp_dir}/${top_dir}" "${to_parent}/${to_name}"

    rm -rf "${temp_dir}"
}

function download_and_extract() {
    local readonly repo_name="$1"
    local readonly url="$2"

    if [[ "${url}" =~ \.tar\.xz$ ]]; then
        local readonly extension=".tar.xz"
    elif [[ "${url}" =~ \.tar\.gz$ ]]; then
        local readonly extension=".tar.gz"
    elif [[ "${url}" =~ \.tar\.zst$ ]]; then
        local readonly extension=".tar.zst"
    else
        local readonly extension=".zip"
    fi

    local readonly repo_archive="${BROWSER_TV_DOWNLOADS}/${repo_name}${extension}"

    download "${url}" "${repo_archive}"

    if [ ! -f "${repo_archive}" ]; then
        echo "Source archive for ${repo_name} does not exist."
        exit 1
    fi

    echo "Extracting ${repo_archive}"
    extract_rmtoplevel "${repo_archive}" "${repo_name}"
    echo
}

# Get Android NDK
function get_android_ndk() {
    if  [ ! -d "${BROWSER_TV_ANDROID_SDK}" ]; then
        echo_red_text "ERROR: You tried to download the Android NDK, but you don't have the Android SDK set-up yet."
        exit 1
    fi

    echo_red_text 'Downloading the Android NDK...'

    ${BROWSER_TV_ANDROID_SDKMANAGER} "ndk;${ANDROID_NDK_REVISION}"

    echo_green_text "SUCCESS: Set-up Android NDK at ${BROWSER_TV_ANDROID_NDK}"
}

# Get + set-up Android SDK
function get_android_sdk() {
    echo_red_text 'Downloading the Android SDK...'
    download_and_extract "android-cmdline-tools" "https://dl.google.com/android/repository/commandlinetools-${ANDROID_SDK_PLATFORM}-${ANDROID_SDK_REVISION}_latest.zip"
    mkdir -p "${BROWSER_TV_ANDROID_SDK}/cmdline-tools"
    mv "${BROWSER_TV_EXTERNAL}/android-cmdline-tools" "${BROWSER_TV_ANDROID_SDK}/cmdline-tools/latest"

    # Accept Android SDK licenses
    { yes || true; } | ${BROWSER_TV_ANDROID_SDKMANAGER} --sdk_root="${BROWSER_TV_ANDROID_SDK}" --licenses

    echo_green_text "SUCCESS: Set-up Android SDK at ${BROWSER_TV_ANDROID_SDK}"
}

# Get Android SDK Build Tools
function get_android_sdk_build_tools() {
    if  [ ! -d "${BROWSER_TV_ANDROID_SDK}" ]; then
        echo_red_text "ERROR: You tried to download Android SDK Build Tools, but you don't have the Android SDK set-up yet."
        exit 1
    fi

    echo_red_text 'Downloading Android SDK Build Tools...'

    ${BROWSER_TV_ANDROID_SDKMANAGER} "build-tools;${ANDROID_SDK_BUILD_TOOLS_VERSION}"

    echo_green_text "SUCCESS: Set-up Android SDK Build Tools"
}

# Get Android SDK Platform
function get_android_sdk_platform() {
    if  [ ! -d "${BROWSER_TV_ANDROID_SDK}" ]; then
        echo_red_text "ERROR: You tried to download the Android SDK Platform, but you don't have the Android SDK set-up yet."
        exit 1
    fi

    if [[ -d "${BROWSER_TV_ANDROID_SDK}/platforms/android-${ANDROID_SDK_PLATFORM_VERSION}" ]]; then
        echo_red_text "Android SDK Platform is already installed at ${BROWSER_TV_ANDROID_SDK}/platforms/android-${ANDROID_SDK_PLATFORM_VERSION}"
        read -p "Do you want to re-download it? [y/N] " -n 1 -r
        echo
        if [[ "${REPLY}" =~ ^[Nn]$ ]]; then
            return 0
        else
            rm -rf "${BROWSER_TV_ANDROID_SDK}/platforms/android-${ANDROID_SDK_PLATFORM_VERSION}"
        fi
    fi

    echo_red_text 'Downloading Android SDK Platform...'

    ${BROWSER_TV_ANDROID_SDKMANAGER} "platforms;android-${ANDROID_SDK_PLATFORM_VERSION}"

    echo_green_text "SUCCESS: Set-up Android SDK Platform (latest) at ${IRONFOX_ANDROID_SDK}/platforms/android-${ANDROID_SDK_PLATFORM_VERSION}"
}

# Get + set-up Bundletool
function get_bundletool() {
    echo_red_text 'Downloading Bundletool...'
    if [[ "${BROWSER_TV_NO_PREBUILDS}" == "1" ]]; then
        download_and_extract 'bundletool' "https://github.com/google/bundletool/archive/${BUNDLETOOL_REPO_COMMIT}.tar.gz" "${BROWSER_TV_BUNDLETOOL_DIR}"
    else
        download "https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar" "${BROWSER_TV_BUNDLETOOL_JAR}"
    fi

    echo_green_text "SUCCESS: Set-up Bundletool at ${BROWSER_TV_BUNDLETOOL_DIR}"
}

# Get cbindgen
function get_cbindgen() {
    if  [ ! -d "${BROWSER_TV_CARGO_HOME}" ] || [ ! -f "${BROWSER_TV_CARGO_ENV}" ]; then
        echo_red_text "ERROR: You tried to download cbindgen, but you don't have a Rust environment set-up yet."
        exit 1
    fi

    if [[ -d "${BROWSER_TV_CARGO_HOME}/bin/cbindgen" ]]; then
        echo_red_text "cbindgen is already installed at ${BROWSER_TV_CARGO_HOME}/bin/cbindgen."
        read -p "Do you want to re-download it? [y/N] " -n 1 -r
        echo
        if [[ "${REPLY}" =~ ^[Nn]$ ]]; then
            return 0
        fi
    fi

    source "${BROWSER_TV_CARGO_ENV}"
    echo_red_text 'Installing cbindgen...'
    cargo +"${RUST_VERSION}" install --locked --force --vers "${CBINDGEN_VERSION}" cbindgen
    echo_green_text "SUCCESS: Set-up cbindgen at ${BROWSER_TV_CARGO_HOME}/bin/cbindgen"
}

# Get Firefox (Gecko/mozilla-central)
function get_firefox() {
    echo_red_text 'Downloading Firefox...'
    clone_repo "https://github.com/mozilla-firefox/firefox.git" "${BROWSER_TV_GECKO}" "${FIREFOX_COMMIT}"

    echo_green_text "SUCCESS: Set-up Firefox at ${BROWSER_TV_GECKO}"
}

# Get firefox-l10n
function get_firefox_l10n() {
    echo_red_text 'Downloading firefox-l10n...'
    clone_repo "https://github.com/mozilla-l10n/firefox-l10n.git" "${BROWSER_TV_L10N_CENTRAL}" "${L10N_COMMIT}"
    echo_green_text "SUCCESS: Set-up firefox-l10n at ${BROWSER_TV_L10N_CENTRAL}"
}

# Get + set-up F-Droid's Gradle script
function get_gradle() {
    echo_red_text "Downloading F-Droid's Gradle script..."
    download "https://gitlab.com/fdroid/gradlew-fdroid/-/raw/${GRADLE_COMMIT}/gradlew.py" "${BROWSER_TV_GRADLE_PY}"
}

# Get GYP
function get_gyp() {
    if  [ ! -f "${BROWSER_TV_PYENV}" ]; then
        echo_red_text "ERROR: You tried to download GYP, but you don't have a Python environment set-up yet."
        exit 1
    fi

    if [[ -d "${BROWSER_TV_PYENV_DIR}/bin/gyp" ]]; then
        echo_red_text "GYP is already installed at ${BROWSER_TV_PYENV_DIR}/bin/gyp"
        read -p "Do you want to re-download it? [y/N] " -n 1 -r
        echo
        if [[ "${REPLY}" =~ ^[Nn]$ ]]; then
            return 0
        else
            source "${BROWSER_TV_PYENV}"
            "${BROWSER_TV_PIP}" uninstall gyp-next
        fi
    fi

    source "${BROWSER_TV_PYENV}"
    echo_red_text 'Installing GYP...'
    "${BROWSER_TV_PIP}" install gyp-next
    echo_green_text "SUCCESS: Set-up GYP at ${BROWSER_TV_PYENV_DIR}/bin/gyp"
}

# Get microG
function get_microg() {
    echo_red_text 'Downloading microG...'
    clone_repo "https://github.com/microg/GmsCore.git" "${BROWSER_TV_GMSCORE}" "${GMSCORE_COMMIT}"
    echo_green_text "SUCCESS: Set-up microG at ${BROWSER_TV_GMSCORE}"
}

# Get Phoenix
function get_phoenix() {
    echo_red_text 'Downloading Phoenix...'
    download_and_extract 'phoenix' "https://gitlab.com/celenityy/Phoenix/-/archive/${PHOENIX_COMMIT}/Phoenix-${PHOENIX_COMMIT}.tar.gz" "${BROWSER_TV_PHOENIX}"
    echo_green_text "SUCCESS: Set-up Phoenix at ${BROWSER_TV_PHOENIX}"
}

# Get + set-up pip
function get_pip() {
    # Set-up Python environment
    if [[ -d "${BROWSER_TV_PYENV_DIR}" ]]; then
        rm -rf "${BROWSER_TV_PYENV_DIR}"
    fi
    python -m venv "${BROWSER_TV_PYENV_DIR}"
    source "${BROWSER_TV_PYENV}"

    # Update pip
    echo_red_text 'Updating pip...'
    "${BROWSER_TV_PIP}" install --upgrade pip
    echo_green_text "SUCCESS: Set-up pip"
}

# Get IronFox prebuilds
function get_prebuilds() {
    if [[ "${BROWSER_TV_NO_PREBUILDS}" == "1" ]]; then
        echo_red_text 'Downloading the IronFox prebuilds repository...'
        clone_repo "https://gitlab.com/ironfox-oss/prebuilds.git" "${BROWSER_TV_IRONFOX_PREBUILDS}" "${IRONFOX_PREBUILDS_COMMIT}"

        pushd "${BROWSER_TV_IRONFOX_PREBUILDS}"
        echo_red_text 'Downloading prebuild sources...'
        bash "${BROWSER_TV_IRONFOX_PREBUILDS}/scripts/get_sources.sh"
        popd

        echo_green_text "SUCCESS: Set-up the IronFox prebuilds repository at ${BROWSER_TV_IRONFOX_PREBUILDS}"
    else
        # Get WebAssembly SDK
        echo_red_text 'Downloading prebuilt wasi-sdk...'
        if [[ "${BROWSER_TV_OS}" == 'osx' ]]; then
            download_and_extract "wasi-sdk" "https://gitlab.com/ironfox-oss/prebuilds/-/raw/${WASI_OSX_IRONFOX_COMMIT}/wasi-sdk/${WASI_VERSION}/${PREBUILT_PLATFORM}/wasi-sdk-${WASI_VERSION}-${WASI_OSX_IRONFOX_REVISION}-${PREBUILT_PLATFORM}.tar.xz"
        else
            download_and_extract "wasi-sdk" "https://gitlab.com/ironfox-oss/prebuilds/-/raw/${WASI_LINUX_IRONFOX_COMMIT}/wasi-sdk/${WASI_VERSION}/${PREBUILT_PLATFORM}/wasi-sdk-${WASI_VERSION}-${WASI_LINUX_IRONFOX_REVISION}-${PREBUILT_PLATFORM}.tar.xz"
        fi
        echo_green_text "SUCCESS: Set-up the prebuilt wasi-sdk at ${BROWSER_TV_WASI}"
    fi
}

# Get + set-up rust/cargo
function get_rust() {
    if [[ -d "${BROWSER_TV_CARGO_HOME}" ]]; then
        echo_red_text "The Rust environment is already set-up at ${BROWSER_TV_CARGO_HOME}"
        read -p "Do you want to re-create it? [y/N] " -n 1 -r
        echo
        if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
            rm -rf "${BROWSER_TV_CARGO_HOME}" "${BROWSER_TV_RUSTUP_HOME}"
        fi
    fi

    curl ${BROWSER_TV_CURL_FLAGS} -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --no-update-default-toolchain --profile=minimal

    echo_red_text 'Creating Rust environment...'
    source "${BROWSER_TV_CARGO_ENV}"
    rustup set profile minimal
    rustup default "${RUST_VERSION}"
    rustup override set "${RUST_VERSION}"
    rustup target add aarch64-linux-android
    rustup target add armv7-linux-androideabi
    rustup target add thumbv7neon-linux-androideabi
    rustup target add x86_64-linux-android

    echo_green_text "SUCCESS: Set-up Rust environment at ${BROWSER_TV_CARGO_HOME}"
}

# This needs to run before we get Android NDK
if [ "${BROWSER_TV_GET_SOURCE_ANDROID_SDK}" == 1 ]; then
    get_android_sdk
fi

if [ "${BROWSER_TV_GET_SOURCE_ANDROID_NDK}" == 1 ]; then
    get_android_ndk
fi

if [ "${BROWSER_TV_GET_SOURCE_ANDROID_SDK_BUILD_TOOLS}" == 1 ]; then
    get_android_sdk_build_tools
fi

if [ "${BROWSER_TV_GET_SOURCE_ANDROID_SDK_PLATFORM}" == 1 ]; then
    get_android_sdk_platform
fi

if [ "${BROWSER_TV_GET_SOURCE_BUNDLETOOL}" == 1 ]; then
    get_bundletool
fi

# This needs to run before we get cbindgen
if [ "${BROWSER_TV_GET_SOURCE_RUST}" == 1 ]; then
    get_rust
fi

if [ "${BROWSER_TV_GET_SOURCE_CBINDGEN}" == 1 ]; then
    get_cbindgen
fi

if [ "${BROWSER_TV_GET_SOURCE_GECKO}" == 1 ]; then
    get_firefox
fi

if [ "${BROWSER_TV_GET_SOURCE_GECKO_L10N}" == 1 ]; then
    get_firefox_l10n
fi

if [ "${BROWSER_TV_GET_SOURCE_GRADLE}" == 1 ]; then
    get_gradle
fi

# This needs to be run before we get gyp
if [ "${BROWSER_TV_GET_SOURCE_PIP}" == 1 ]; then
    get_pip
fi

if [ "${BROWSER_TV_GET_SOURCE_GYP}" == 1 ]; then
    get_gyp
fi

if [ "${BROWSER_TV_GET_SOURCE_MICROG}" == 1 ]; then
    get_microg
fi

if [ "${BROWSER_TV_GET_SOURCE_PHOENIX}" == 1 ]; then
    get_phoenix
fi

if [ "${BROWSER_TV_GET_SOURCE_PREBUILDS}" == 1 ]; then
    get_prebuilds
fi
