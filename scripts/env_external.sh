# Browser TV external environment variables

## This is used for converting Browser TV-specific environment variables to ones used in external projects.

## CAUTION: Do NOT source this directly!
## Source 'env.sh' instead.

## CAUTION: Do NOT try to configure any of these environment variables directly!
## Use the Browser TV equivalent variables (at `env_common.sh`) instead.

# Compiler flags
readonly TARGET_CFLAGS="${BROWSER_TV_COMPILER_FLAGS}"
readonly TARGET_CXXFLAGS="${BROWSER_TV_COMPILER_FLAGS}"
export TARGET_CFLAGS
export TARGET_CXXFLAGS

# Gradle flags
readonly GRADLE_FLAGS="${BROWSER_TV_GRADLE_FLAGS}"
export GRADLE_FLAGS

# Rust flags
readonly CARGO_BUILD_RUSTDOCFLAGS="${BROWSER_TV_RUST_FLAGS}"
readonly RUSTDOCFLAGS="${BROWSER_TV_RUST_FLAGS}"
export CARGO_BUILD_RUSTDOCFLAGS
export RUSTDOCFLAGS

# Android SDK
readonly ANDROID_HOME="${BROWSER_TV_ANDROID_SDK}"
readonly ANDROID_SDK_ROOT="${BROWSER_TV_ANDROID_SDK}"
export ANDROID_HOME
export ANDROID_SDK_ROOT

# Android NDK
readonly ANDROID_NDK_HOME="${BROWSER_TV_ANDROID_NDK}"
readonly ANDROID_NDK_ROOT="${BROWSER_TV_ANDROID_NDK}"
export ANDROID_NDK_HOME
export ANDROID_NDK_ROOT

# Gradle cache
readonly CACHEDIR="${BROWSER_TV_GRADLE_CACHE}"
export CACHEDIR

# Gradle home
readonly GRADLE_USER_HOME="${BROWSER_TV_GRADLE_HOME}"
export GRADLE_USER_HOME

# Java home
readonly JAVA_HOME="${BROWSER_TV_JAVA_HOME}"
export JAVA_HOME

# llvm-profdata
readonly LLVM_PROFDATA="${BROWSER_TV_LLVM_PROFDATA}"
export LLVM_PROFDATA

# Mach
## https://firefox-source-docs.mozilla.org/mach/usage.html#user-settings
## https://searchfox.org/mozilla-central/rev/f008b9aa/python/mach/mach/telemetry.py#95
## https://searchfox.org/mozilla-central/rev/f008b9aa/python/mach/mach/telemetry.py#284
readonly DISABLE_TELEMETRY=1
readonly MACHRC="${BROWSER_TV_PATCHES}/machrc"
readonly MOZCONFIG="${BROWSER_TV_GECKO}/mozconfig"
export DISABLE_TELEMETRY
export MACHRC
export MOZCONFIG

# microG
readonly GRADLE_MICROG_VERSION_WITHOUT_GIT=1
export GRADLE_MICROG_VERSION_WITHOUT_GIT

# mozbuild
readonly MOZBUILD_STATE_PATH="${BROWSER_TV_MOZBUILD}"
export MOZBUILD_STATE_PATH

# No-op Taskcluster
## This should help ensure we don't fetch Mozilla artifacts/prebuilds
readonly TASKCLUSTER_PROXY_URL='https://noop.invalid'
readonly TASKCLUSTER_ROOT_URL='https://noop.invalid'
export TASKCLUSTER_PROXY_URL
export TASKCLUSTER_ROOT_URL

# Phoenix
readonly PHOENIX_ANDROID_ONLY=1
readonly PHOENIX_CURL_FLAGS="${BROWSER_TV_CURL_FLAGS}"
readonly PHOENIX_CURL_FLAGS_OVERRIDE=1
readonly PHOENIX_EXTENDED_ONLY=1
readonly PHOENIX_EXTRA_CFG=1
readonly PHOENIX_EXTRA_CFG_FILE="${BROWSER_TV_BUILD}/tmp/gecko/browser-tv-parsed.cfg"
readonly PHOENIX_EXTRA_CFG_OUTPUT_DIR="${BROWSER_TV_GECKO}/browser-tv/prefs"
readonly PHOENIX_EXTRA_EXTENDED_OUTPUT_FILENAME_ANDROID='browser-tv'
readonly PHOENIX_EXTRA_POLICIES_ANDROID=1
readonly PHOENIX_EXTRA_POLICIES_FILE_ANDROID="${BROWSER_TV_PATCHES}/build/gecko/policies.json"
readonly PHOENIX_EXTRA_POLICIES_OUTPUT_DIR_ANDROID="${BROWSER_TV_GECKO}/browser-tv/prefs"
readonly PHOENIX_PYENV_DIR="${BROWSER_TV_PYENV_DIR}"
readonly PHOENIX_PYTHON="${BROWSER_TV_PYTHON}"
readonly PHOENIX_SED="${BROWSER_TV_SED}"
readonly PHOENIX_SPECS=0
readonly PHOENIX_TAR="${BROWSER_TV_TAR}"
export PHOENIX_ANDROID_ONLY
export PHOENIX_CURL_FLAGS
export PHOENIX_CURL_FLAGS_OVERRIDE
export PHOENIX_EXTENDED_ONLY
export PHOENIX_EXTRA_CFG
export PHOENIX_EXTRA_CFG_FILE
export PHOENIX_EXTRA_CFG_OUTPUT_DIR
export PHOENIX_EXTRA_EXTENDED_OUTPUT_FILENAME_ANDROID
export PHOENIX_EXTRA_POLICIES_ANDROID
export PHOENIX_EXTRA_POLICIES_FILE_ANDROID
export PHOENIX_EXTRA_POLICIES_OUTPUT_DIR_ANDROID
export PHOENIX_PYENV_DIR
export PHOENIX_PYTHON
export PHOENIX_SED
export PHOENIX_SPECS
export PHOENIX_TAR

# Python
## https://docs.python.org/3/using/cmdline.html#environment-variables

## Disable JIT
readonly PYTHON_JIT=0
readonly PYTHON_PERF_JIT_SUPPORT=0
export PYTHON_JIT
export PYTHON_PERF_JIT_SUPPORT

## Disable remote debugging
readonly PYTHON_DISABLE_REMOTE_DEBUG=1
export PYTHON_DISABLE_REMOTE_DEBUG

## Enable performance optimizations
readonly PYTHONOPTIMIZE=1
export PYTHONOPTIMIZE

# Python (rust-android-gradle)
## https://github.com/mozilla/rust-android-gradle?tab=readme-ov-file#specifying-paths-to-sub-commands-python-cargo-and-rustc
readonly RUST_ANDROID_GRADLE_PYTHON_COMMAND="${BROWSER_TV_PYTHON}"
export RUST_ANDROID_GRADLE_PYTHON_COMMAND

# Rust (cargo)
readonly CARGO="${BROWSER_TV_CARGO}"
readonly CARGO_HOME="${BROWSER_TV_CARGO_HOME}"
readonly CARGO_INSTALL_ROOT="${BROWSER_TV_CARGO_HOME}"
readonly RUST_ANDROID_GRADLE_CARGO_COMMAND="${BROWSER_TV_CARGO}"
readonly RUST_ANDROID_GRADLE_RUSTC_COMMAND="${BROWSER_TV_RUSTC}"
readonly RUSTC="${BROWSER_TV_RUSTC}"
readonly RUSTDOC="${BROWSER_TV_RUSTDOC}"
export CARGO
export CARGO_HOME
export CARGO_INSTALL_ROOT
export RUST_ANDROID_GRADLE_CARGO_COMMAND
export RUST_ANDROID_GRADLE_RUSTC_COMMAND
export RUSTC
export RUSTDOC

## Disable debug
readonly CARGO_PROFILE_DEV_DEBUG='false'
readonly CARGO_PROFILE_DEV_DEBUG_ASSERTIONS='false'
readonly CARGO_PROFILE_RELEASE_DEBUG='false'
readonly CARGO_PROFILE_RELEASE_DEBUG_ASSERTIONS='false'
export CARGO_PROFILE_DEV_DEBUG
export CARGO_PROFILE_DEV_DEBUG_ASSERTIONS
export CARGO_PROFILE_RELEASE_DEBUG
export CARGO_PROFILE_RELEASE_DEBUG_ASSERTIONS

## Disable HTTP debugging
readonly CARGO_HTTP_DEBUG='false'
export CARGO_HTTP_DEBUG

## Disable incremental compilation
### (Ensures builds are fresh)
### https://doc.rust-lang.org/cargo/reference/profiles.html#incremental
readonly CARGO_BUILD_INCREMENTAL='false'
readonly CARGO_INCREMENTAL=0
export CARGO_BUILD_INCREMENTAL
export CARGO_INCREMENTAL

## Display progress bars
readonly CARGO_TERM_PROGRESS_WHEN="${BROWSER_TV_CARGO_PROGRESS_BAR}"
readonly CARGO_TERM_PROGRESS_WIDTH=80
export CARGO_TERM_PROGRESS_WHEN
export CARGO_TERM_PROGRESS_WIDTH

## Enable certificate revocation checks
readonly CARGO_HTTP_CHECK_REVOKE='true'
export CARGO_HTTP_CHECK_REVOKE

## Enable colored output
readonly CARGO_TERM_COLOR="${BROWSER_TV_CARGO_COLORED_OUTPUT}"
export CARGO_TERM_COLOR

## Enable HTTP2 multiplexing
### https://doc.rust-lang.org/cargo/reference/config.html#httpmultiplexing
readonly CARGO_HTTP_MULTIPLEXING='true'
export CARGO_HTTP_MULTIPLEXING

## Enable overflow checks
readonly CARGO_PROFILE_DEV_OVERFLOW_CHECKS='true'
readonly CARGO_PROFILE_RELEASE_OVERFLOW_CHECKS='true'
export CARGO_PROFILE_DEV_OVERFLOW_CHECKS
export CARGO_PROFILE_RELEASE_OVERFLOW_CHECKS

## Enable performance optimizations
readonly CARGO_PROFILE_DEV_LTO='true'
readonly CARGO_PROFILE_DEV_OPT_LEVEL=3
readonly CARGO_PROFILE_RELEASE_LTO='true'
readonly CARGO_PROFILE_RELEASE_OPT_LEVEL=3
export CARGO_PROFILE_DEV_LTO
export CARGO_PROFILE_DEV_OPT_LEVEL
export CARGO_PROFILE_RELEASE_LTO
export CARGO_PROFILE_RELEASE_OPT_LEVEL

## Strip debug info
readonly CARGO_PROFILE_DEV_STRIP='debuginfo'
readonly CARGO_PROFILE_RELEASE_STRIP='debuginfo'
export CARGO_PROFILE_DEV_STRIP
export CARGO_PROFILE_RELEASE_STRIP

# rustup
readonly RUSTUP_HOME="${BROWSER_TV_RUSTUP_HOME}"
export RUSTUP_HOME

## Display progress bars
readonly RUSTUP_TERM_PROGRESS_WHEN="${BROWSER_TV_RUSTUP_PROGRESS_BAR}"
export RUSTUP_TERM_PROGRESS_WHEN

## Enable colored output
readonly RUSTUP_TERM_COLOR="${BROWSER_TV_RUSTUP_COLORED_OUTPUT}"
export RUSTUP_TERM_COLOR

# UV
## https://docs.astral.sh/uv/reference/environment/

## Cache directory
readonly UV_CACHE_DIR="${BROWSER_TV_UV_LOCAL}/cache"
export UV_CACHE_DIR

## Disable cache
readonly UV_NO_CACHE=1
export UV_NO_CACHE

## Disable the system CA root store
readonly UV_SYSTEM_CERTS='false'
export UV_SYSTEM_CERTS

## Exclude development dependencies
readonly UV_NO_DEV=1
export UV_NO_DEV

## Executables directory
readonly UV_PYTHON_BIN_DIR="${BROWSER_TV_UV_LOCAL}/bin"
readonly UV_PYTHON_INSTALL_BIN=1
export UV_PYTHON_BIN_DIR
export UV_PYTHON_INSTALL_BIN

## Ignore configuration files
readonly UV_NO_CONFIG=1
export UV_NO_CONFIG

## Ignore env files
readonly UV_NO_ENV_FILE=1
export UV_NO_ENV_FILE

## Location
readonly UV_INSTALL_DIR="${BROWSER_TV_UV_DIR}"
export UV_INSTALL_DIR

## Prevent automatic downloads/updates
readonly UV_DISABLE_UPDATE=1
readonly UV_PYTHON_DOWNLOADS='manual'
export UV_DISABLE_UPDATE
export UV_PYTHON_DOWNLOADS

## Prevent modifying the system PATH
readonly INSTALLER_NO_MODIFY_PATH=1
readonly UV_NO_MODIFY_PATH=1
readonly UV_UNMANAGED_INSTALL="${BROWSER_TV_UV_DIR}"
export INSTALLER_NO_MODIFY_PATH
export UV_NO_MODIFY_PATH
export UV_UNMANAGED_INSTALL

## Prevent using the system Python
readonly UV_MANAGED_PYTHON=1
readonly UV_SYSTEM_PYTHON='false'
export UV_MANAGED_PYTHON
export UV_SYSTEM_PYTHON

## Python
readonly UV_PYTHON_CACHE_DIR="${BROWSER_TV_UV_LOCAL}/python-cache"
readonly UV_PYTHON_INSTALL_MIRROR="file://${BROWSER_TV_PYTHON_DIR}"
readonly UV_PYTHON_INSTALL_DIR="${BROWSER_TV_UV_LOCAL}/python"
export UV_PYTHON_CACHE_DIR
export UV_PYTHON_INSTALL_MIRROR
export UV_PYTHON_INSTALL_DIR

## Python environment
readonly UV_PROJECT_ENVIRONMENT="${BROWSER_TV_PYENV_DIR}"
readonly VIRTUAL_ENV="${BROWSER_TV_PYENV_DIR}"
export UV_PROJECT_ENVIRONMENT
export VIRTUAL_ENV

## Tools directory
readonly UV_TOOL_BIN_DIR="${BROWSER_TV_UV_LOCAL}/tools/bin"
readonly UV_TOOL_DIR="${BROWSER_TV_UV_LOCAL}/tools"
export UV_TOOL_BIN_DIR
export UV_TOOL_DIR

# Include version info
source "${BROWSER_TV_VERSIONS}"

## Pin Python version
readonly UV_PYTHON_CPYTHON_BUILD="${PYTHON_GIT_RELEASE}"
export UV_PYTHON_CPYTHON_BUILD

## Set Rust version
readonly RUSTUP_TOOLCHAIN="${RUST_VERSION}"
export RUSTUP_TOOLCHAIN

## Set Rustup version
export RUSTUP_VERSION
