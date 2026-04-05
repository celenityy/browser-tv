
# Sources

## Firefox
### https://github.com/mozilla-firefox/firefox
### (This commit corresponds to https://github.com/mozilla-firefox/firefox/releases/tag/FIREFOX-ANDROID_149_0_1_RELEASE)
readonly FIREFOX_COMMIT='a395b8ce89f74c9a50acf7493052282e26477e38'
readonly FIREFOX_SHA512SUM='870a09a7a5615400b128e33c84f71cd0dfa5d10b78d3282613386d43b7215b3f0755ce754e8e21ad13d7f1b8bdf1d4af42463635e99e8e95cb799c58c35f1650'
readonly FIREFOX_VERSION='149.0.1'

readonly BROWSER_TV_VERSION="${FIREFOX_VERSION}"

## firefox-l10n
### https://github.com/mozilla-l10n/firefox-l10n
### NOTE: This repo is updated several times a day...
### so I think best approach here will be for us to just update it alongside new releases
readonly L10N_COMMIT='440d24a5ca656bbc55795fdca79e64497f2f07f2'
readonly L10N_SHA512SUM='3a2361292e05b87c5bef166fa7cd09f5634c79da6eb2a6ca1a7c9c283f82208455bf4bc61f3fb5732a17f03f28181a9d1ac2146b340627a578c5a97efe394d95'

## microG
### Version: v0.3.13.250932
### https://github.com/microg/GmsCore
readonly GMSCORE_COMMIT='3ba21336181c846630242124176737c05b3e8b6f'
readonly GMSCORE_SHA512SUM='c2c5e8c17a17b159550d696d97440b02bd8fb455f8ac9cbdbc81e05fb1dfcef36d564ed034c35c9d1dc58822354f5b72589c7c42826242b8b21c893f5c7c46ac'

## Phoenix
### https://gitlab.com/celenityy/Phoenix
readonly PHOENIX_COMMIT='9a7e49256837ce1928265734be1ea110c76b8aa4'
readonly PHOENIX_SHA512SUM='4f89e53d23275a70621bad771047462195d668b9da3e5eda7191a09401681826416bd9a803e1b3dedfe70415d68d1bb7bde19c1396edae6f76847d11ecba4dbb'
readonly PHOENIX_VERSION='2026.03.31.1'

## WASI SDK
### https://github.com/WebAssembly/wasi-sdk
readonly WASI_VERSION='20'

# Tools

## Android NDK
### https://developer.android.com/ndk/downloads
readonly ANDROID_NDK_REVISION='29.0.14206865'
readonly ANDROID_NDK_SHA512SUM_LINUX='b55819895a7fa3a0bc7ed411fb55ed15ad9e415b0122a81a4e026c9b696cd266cb4beebb2008cf1d6cac88d38187d52818734f87de793de303653eccb4ca68da'
readonly ANDROID_NDK_SHA512SUM_OSX='4091bc97a03266b869380874cb2d67a35dc74f9bc5f1cde30a3545547355e4ec4f3ebd79a17a19f9228d045f7a176d1e987ce4f787d81a02a044aa909f5ef5cb'
readonly ANDROID_NDK_VERSION='r29'

## Android SDK (Command-Line Tools)
### https://developer.android.com/tools/releases/cmdline-tools
### (for reference: https://searchfox.org/firefox-main/source/python/mozboot/mozboot/android.py)
readonly ANDROID_SDK_REVISION='13114758'
readonly ANDROID_SDK_SHA512SUM_LINUX='8e4bce8fb1a9a2b83454ab9ea642caa08adc69d93df345238a9c110a29aeb3dd4211ce9464de6d5ce41182c77ad2ff8c1941ed8a0b1f40d267fdfc8a31f461dc'
readonly ANDROID_SDK_SHA512SUM_OSX='375e0594493ade7ab613bacdfbc751c5f004db213b02c6202ac28f4b6174ed9fc5d514b189bbfafd3d9d8c8d7d81b3fb312c0454b79e53ab9d139b90790d2a96'

## Android SDK Build Tools
### https://developer.android.com/tools/releases/build-tools
readonly ANDROID_SDK_BUILD_TOOLS_VERSION='r36.1'
readonly ANDROID_SDK_BUILD_TOOLS_VERSION_STRING='36.1.0'
readonly ANDROID_SDK_BUILD_TOOLS_SHA512SUM_LINUX='32a1eea273980a96745ae5e0b141720e5f91c6c6f83f42da4244fad36025d7750521fdf678a7d332afe5946057b498264343c2533ba524967d84347af9cd7ce5'
readonly ANDROID_SDK_BUILD_TOOLS_SHA512SUM_OSX='07a78d5f4658c6809220012fc27560cfd8aefcbd29a6414aa309fc54d6df7751b7b1e59964e3942ff9b91030c2611639e2b7d7eb2f77aba1ab0933c015e7c802'

## Android SDK Platform
### https://developer.android.com/tools/releases/platforms
readonly ANDROID_SDK_PLATFORM_VERSION='36.1'

### This is used for ex. setting microG's compile SDK and target SDK version
readonly ANDROID_SDK_TARGET='36'

## Bundletool
### https://github.com/google/bundletool
readonly BUNDLETOOL_REPO_COMMIT='586a43a450712a1067f3d92cf7574dee68226302'
readonly BUNDLETOOL_REPO_SHA512SUM='a72040449b3bd51a29bb562d8686b0338d630be12a5a590a88a753111b887d30f7b32ab256a556157271ed0071fc54b81205efcfd1ef93ccb8142fe41a741345'
readonly BUNDLETOOL_SHA512SUM='50feda5f3f00931bad943a37b7cfc33d8ea53b33bd9bfa83832f612da6e99b72146206695ae25df5044030e305e1d718c833ad51c12b944079c263bba3cbffa0'
readonly BUNDLETOOL_VERSION='1.18.3'

## cbindgen
### https://docs.rs/crate/cbindgen/latest
readonly CBINDGEN_VERSION='0.29.2'

## Gradle (F-Droid)
### https://gitlab.com/fdroid/gradlew-fdroid
readonly GRADLE_COMMIT='996b7829f40f33317d33c1b6ddcffcf976bd6181'
readonly GRADLE_SHA512SUM='0498fff4a729aa2458f2627635507c6e9a9bd3d1e914ac375e10b3b3061654e7f7544461c91a8db0882bfc1d09090d135eada40ee72f37ff9975e0f1116c3d9d'

## Rust
### https://releases.rs/
# readonly RUST_MAJOR_VERSION='1.94'
# readonly RUST_VERSION="${RUST_MAJOR_VERSION}.0"
readonly RUST_MAJOR_VERSION='1.94.1'
readonly RUST_VERSION="${RUST_MAJOR_VERSION}"

# For prebuilds
## https://gitlab.com/ironfox-oss/prebuilds
readonly IRONFOX_PREBUILDS_COMMIT='241af63561e4b4c9cf14d67d585f498a53bbf501'
readonly IRONFOX_PREBUILDS_SHA512SUM='12780ab9fb64eb1884753efe3332b135b1c4511087e693932ffc8832143d8c162b3ac8bb7c8bbf06aa30caf2667fa101ffa9c38595a7fe99aecda292e27f4247'
readonly WASI_LINUX_IRONFOX_COMMIT='b76a3b2a8f3124e9297036e3b27802a47c0263a4'
readonly WASI_LINUX_IRONFOX_REVISION='4'
readonly WASI_LINUX_IRONFOX_SHA512SUM='98d81e0f47229184fe767fb47906685eec6dd34ad425030e08d1eea42ddec1ebef678530e70dfc954aa2d0904ac44d38a869334c098b0baf9fff1b87233ff31e'
readonly WASI_OSX_IRONFOX_COMMIT='97f5fb17ea756670c452e832ae3fca80d0498a82'
readonly WASI_OSX_IRONFOX_REVISION='3'
readonly WASI_OSX_IRONFOX_SHA512SUM='eb0697f42c9838080fcf23fa0d9c230016212a15725e62e2fafed896751a9fcf8adf508461cf9118c02bff1bcd0791ae1113f13d0cca96de3b8f03244df25a30'
