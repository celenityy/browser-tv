# Browser TV external environment variables

## This is used for converting Browser TV-specific environment variables to ones used in external projects.

## CAUTION: Do NOT source this directly!
## Source 'env.sh' instead.

## CAUTION: Do NOT try to configure any of these environment variables directly!
## Use the Browser TV equivalent variables (at `env_common.sh`) instead.

# Compiler flags
export TARGET_CFLAGS="${BROWSER_TV_COMPILER_FLAGS}"
export TARGET_CXXFLAGS="${BROWSER_TV_COMPILER_FLAGS}"

# Gradle flags
export GRADLE_FLAGS="${BROWSER_TV_GRADLE_FLAGS}"

# Rust flags
export CARGO_BUILD_RUSTDOCFLAGS="${BROWSER_TV_RUST_FLAGS}"
export RUSTDOCFLAGS="${BROWSER_TV_RUST_FLAGS}"

# Android SDK
export ANDROID_HOME="${BROWSER_TV_ANDROID_SDK}"
export ANDROID_SDK_ROOT="${BROWSER_TV_ANDROID_SDK}"

# Android NDK
export ANDROID_NDK_HOME="${BROWSER_TV_ANDROID_NDK}"
export ANDROID_NDK_ROOT="${BROWSER_TV_ANDROID_NDK}"

# Gradle cache
export CACHEDIR="${BROWSER_TV_GRADLE_CACHE}"

# Gradle home
export GRADLE_USER_HOME="${BROWSER_TV_GRADLE_HOME}"

# Java home
export JAVA_HOME="${BROWSER_TV_JAVA_HOME}"

# llvm-profdata
export LLVM_PROFDATA="${BROWSER_TV_LLVM_PROFDATA}"

# Mach
## https://firefox-source-docs.mozilla.org/mach/usage.html#user-settings
## https://searchfox.org/mozilla-central/rev/f008b9aa/python/mach/mach/telemetry.py#95
## https://searchfox.org/mozilla-central/rev/f008b9aa/python/mach/mach/telemetry.py#284
export DISABLE_TELEMETRY=1
export MACHRC="${BROWSER_TV_PATCHES}/machrc"
export MOZCONFIG="${BROWSER_TV_GECKO}/mozconfig"

# microG
export GRADLE_MICROG_VERSION_WITHOUT_GIT=1

# mozbuild
export MOZBUILD_STATE_PATH="${BROWSER_TV_MOZBUILD}"

# No-op Taskcluster
## This should help ensure we don't fetch Mozilla artifacts/prebuilds
export TASKCLUSTER_PROXY_URL='https://noop.invalid'
export TASKCLUSTER_ROOT_URL='https://noop.invalid'

# Phoenix
export PHOENIX_ANDROID_ONLY=1
export PHOENIX_CURL_FLAGS="${BROWSER_TV_CURL_FLAGS}"
export PHOENIX_CURL_FLAGS_OVERRIDE=1
export PHOENIX_EXTENDED_ONLY=1
export PHOENIX_EXTRA_CFG=1
export PHOENIX_EXTRA_CFG_FILE="${BROWSER_TV_BUILD}/tmp/gecko/browser-tv-parsed.cfg"
export PHOENIX_EXTRA_CFG_OUTPUT_DIR="${BROWSER_TV_GECKO}/browser-tv/prefs"
export PHOENIX_EXTRA_EXTENDED_OUTPUT_FILENAME_ANDROID='browser-tv'
export PHOENIX_EXTRA_POLICIES_ANDROID=1
export PHOENIX_EXTRA_POLICIES_FILE_ANDROID="${BROWSER_TV_PATCHES}/build/gecko/policies.json"
export PHOENIX_EXTRA_POLICIES_OUTPUT_DIR_ANDROID="${BROWSER_TV_GECKO}/browser-tv/prefs"
export PHOENIX_PYENV_DIR="${BROWSER_TV_PYENV_DIR}"
export PHOENIX_PYTHON="${BROWSER_TV_PYTHON}"
export PHOENIX_SED="${BROWSER_TV_SED}"
export PHOENIX_TAR="${BROWSER_TV_TAR}"
export PHOENIX_SPECS=0

# Python (rust-android-gradle)
## https://github.com/mozilla/rust-android-gradle?tab=readme-ov-file#specifying-paths-to-sub-commands-python-cargo-and-rustc
export RUST_ANDROID_GRADLE_PYTHON_COMMAND="${BROWSER_TV_PYTHON}"

# Rust (cargo)
export CARGO="${BROWSER_TV_CARGO}"
export CARGO_HOME="${BROWSER_TV_CARGO_HOME}"
export CARGO_INSTALL_ROOT="${BROWSER_TV_CARGO_HOME}"
export RUST_ANDROID_GRADLE_CARGO_COMMAND="${BROWSER_TV_CARGO}"
export RUST_ANDROID_GRADLE_RUSTC_COMMAND="${BROWSER_TV_RUSTC}"
export RUSTC="${BROWSER_TV_RUSTC}"
export RUSTDOC="${BROWSER_TV_RUSTDOC}"

## Always clean old files
### https://doc.rust-lang.org/cargo/reference/config.html#cacheauto-clean-frequency
export CARGO_CACHE_AUTO_CLEAN_FREQUENCY='always'

## Disable caching compiler version information
export CARGO_CACHE_RUSTC_INFO=0

## Disable debug
export CARGO_PROFILE_DEV_DEBUG=false
export CARGO_PROFILE_DEV_DEBUG_ASSERTIONS=false
export CARGO_PROFILE_RELEASE_DEBUG=false
export CARGO_PROFILE_RELEASE_DEBUG_ASSERTIONS=false

## Disable HTTP debugging
export CARGO_HTTP_DEBUG=false

## Disable incremental compilation
### https://doc.rust-lang.org/cargo/reference/profiles.html#incremental
export CARGO_INCREMENTAL=0

## Display progress bars
export CARGO_TERM_PROGRESS_WHEN="${BROWSER_TV_CARGO_PROGRESS_BAR}"
export CARGO_TERM_PROGRESS_WIDTH=80

## Enable certificate revocation checks
export CARGO_HTTP_CHECK_REVOKE=true

## Enable colored output
export CARGO_TERM_COLOR="${BROWSER_TV_CARGO_COLORED_OUTPUT}"

## Enable HTTP2 multiplexing
### https://doc.rust-lang.org/cargo/reference/config.html#httpmultiplexing
export CARGO_HTTP_MULTIPLEXING=true

## Enable overflow checks
export CARGO_PROFILE_DEV_OVERFLOW_CHECKS=true
export CARGO_PROFILE_RELEASE_OVERFLOW_CHECKS=true

## Enable performance optimizations
export CARGO_PROFILE_DEV_LTO=true
export CARGO_PROFILE_DEV_OPT_LEVEL=3
export CARGO_PROFILE_RELEASE_LTO=true
export CARGO_PROFILE_RELEASE_OPT_LEVEL=3

## Remove user agent
### https://doc.rust-lang.org/cargo/reference/config.html#httpuser-agent
export CARGO_HTTP_USER_AGENT=''

## Strip debug info
export CARGO_PROFILE_DEV_STRIP='debuginfo'
export CARGO_PROFILE_RELEASE_STRIP='debuginfo'

# rustup
export RUSTUP_HOME="${BROWSER_TV_RUSTUP_HOME}"

## Display progress bars
export RUSTUP_TERM_PROGRESS_WHEN="${BROWSER_TV_RUSTUP_PROGRESS_BAR}"

## Enable colored output
export RUSTUP_TERM_COLOR="${BROWSER_TV_RUSTUP_COLORED_OUTPUT}"
