
# Sources

## Firefox
### https://github.com/mozilla-firefox/firefox
### (This commit corresponds to https://github.com/mozilla-firefox/firefox/releases/tag/FIREFOX-ANDROID_147_0_2_RELEASE)
readonly FIREFOX_COMMIT='a395b8ce89f74c9a50acf7493052282e26477e38'
readonly FIREFOX_VERSION='149.0.1'

readonly BROWSER_TV_VERSION="${FIREFOX_VERSION}"

## firefox-l10n
### https://github.com/mozilla-l10n/firefox-l10n
### NOTE: This repo is updated several times a day...
### so I think best approach here will be for us to just update it alongside new releases
readonly L10N_COMMIT='a3620ad68847cff83ebedaed974a7597ed79f1a4'

## microG
### https://github.com/microg/GmsCore
readonly GMSCORE_COMMIT='cbb8dcfbe8e6155ef6e2276636a94f902041485f'
readonly GMSCORE_VERSION='v0.3.12.250932'

## Phoenix
### https://gitlab.com/celenityy/Phoenix
readonly PHOENIX_COMMIT='964d320422c481ef5ff31c1a1ae0301e4e1c36e2'
readonly PHOENIX_VERSION='2026.01.21.1'

## WASI SDK
### https://github.com/WebAssembly/wasi-sdk
readonly WASI_COMMIT='935fe1acd2fcd7ea4aed2d5ee4527482862b6344'
readonly WASI_VERSION='20'

# Tools

## Android NDK
### https://developer.android.com/ndk/downloads
readonly ANDROID_NDK_REVISION='29.0.14206865' # r29

## Android SDK (Command-Line Tools)
### https://developer.android.com/tools/releases/cmdline-tools
### (for reference: https://searchfox.org/firefox-main/source/python/mozboot/mozboot/android.py)
readonly ANDROID_SDK_REVISION='13114758'

## Android SDK Build Tools
### https://developer.android.com/tools/releases/build-tools
readonly ANDROID_SDK_BUILD_TOOLS_VERSION='36.1.0'

## Android SDK Platform
### https://developer.android.com/tools/releases/platforms
readonly ANDROID_SDK_PLATFORM_VERSION='36.1'

### This is used for ex. setting microG's compile SDK and target SDK version
readonly ANDROID_SDK_TARGET='36'

## Bundletool
### https://github.com/google/bundletool
readonly BUNDLETOOL_VERSION='1.18.3'

## cbindgen
### https://docs.rs/crate/cbindgen/latest
readonly CBINDGEN_VERSION='0.29.2'

## Gradle (F-Droid)
### https://gitlab.com/fdroid/gradlew-fdroid
readonly GRADLE_COMMIT='e55f371891e02a45ee65d18cabc81aaf665c96d0'

## Rust
### https://releases.rs/
readonly RUST_MAJOR_VERSION='1.93'
readonly RUST_VERSION="${RUST_MAJOR_VERSION}.0"
#readonly RUST_MAJOR_VERSION='1.91.1'
#readonly RUST_VERSION="${RUST_MAJOR_VERSION}"

# For prebuilds
## https://gitlab.com/ironfox-oss/prebuilds
readonly IRONFOX_PREBUILDS_COMMIT='b76a3b2a8f3124e9297036e3b27802a47c0263a4'
readonly WASI_LINUX_IRONFOX_COMMIT='b76a3b2a8f3124e9297036e3b27802a47c0263a4'
readonly WASI_LINUX_IRONFOX_REVISION='4'
readonly WASI_OSX_IRONFOX_COMMIT='97f5fb17ea756670c452e832ae3fca80d0498a82'
readonly WASI_OSX_IRONFOX_REVISION='3'
