
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

## JDK 17 (Temurin)
### https://github.com/adoptium/temurin17-binaries
### (This commit corresponds to https://github.com/adoptium/temurin17-binaries/releases/tag/jdk-17.0.18%2B8)
### (Required by GeckoView)
readonly JDK_17_REVISION='8'
readonly JDK_17_SHA512SUM_LINUX_ARM64='ce632aab5965d60cde210bcfd6bb3a41f956e51eb87f4ca28a523c5614fcf9a18a8fe89fb1ee2424a40d7bf39afb3a3c69aaec60a0871f81c66622d5355febfa'
readonly JDK_17_SHA512SUM_LINUX_X86_64='fb40a864b5bc43f037f0209729c2319ef15f58a3830970ceff44f4e1cfe6fc4dcac0628d6afe6713acecffd1bc357325b6026185f3efeb9dcc767c2437c61dbc'
readonly JDK_17_SHA512SUM_OSX_ARM64='91b1d64b9865fa62466e52f9fd3a2bdb0ddf62d3a678f4fa4f471ba621aea17c51a35f29e86091deaddcc3afa0a14b658487b4f919b64a259bde0df8563a8aae'
readonly JDK_17_SHA512SUM_OSX_X86_64='f214734251b6662737e08fd8bdb3a351466ff10eb776a2f338e3ccea93d7f01d2578acd1f716aa9a08d152b3c0cd4d2487ae35acee395ade4ab3507cfadbe018'
readonly JDK_17_VERSION='17.0.18'

## Python
### https://github.com/astral-sh/python-build-standalone
readonly PYTHON_GIT_RELEASE='20260325'
readonly PYTHON_SHA512SUM_LINUX_ARM64='34e0b5590237dc189010816eff3de209ef139ea2274c1d472220876625b4462a825233cfc5aa2f089ee15103fbdeb91afc540fd32b923226618512ec596f16ab'
readonly PYTHON_SHA512SUM_LINUX_X86_64='d77b5cd60fefbadf9b67fcea3ee5cbc33df01b65d545b6ae4ee8deaaf42ec74b711da15a268dd7f22b5b4cb5c3d29843df043ccac47fdb170ad72de31ddda97b'
readonly PYTHON_SHA512SUM_OSX_ARM64='ef160ff28f8b70b2a701085a8bfaf180e7479b8e64fbf0a3a15e0623c6534306c7a7db6933e80a129e70a7cbe8b7c6e199dd5cba4886754b2b1b211a98043528'
readonly PYTHON_SHA512SUM_OSX_X86_64='ce39bcd0dd9f42ccac2c345febf79bda9520ac613ef225a8c07eab58fee39e88eaa223bc0e8bf3f15377044535889d56599f5e0837d121160c5670676556cd0d'
readonly PYTHON_VERSION='3.14.3'

## uv
### https://github.com/astral-sh/uv
readonly UV_SHA512SUM_LINUX_ARM64='4840da890a4e19f8196592d2a13f569f7895dedab1ce2722c2ba58172480b9adbf9247ebfb610ec92622d94741079951548ca1cdaa263d65b9af77c16769eaa0'
readonly UV_SHA512SUM_LINUX_X86_64='ebc3c78a2869f8e4de0d38e46070b7ddd097959a098a52a7a1e2128815e4d8a33ab23c5aae78de7637c0510f43c30056659f3ee63b20605b84138bbcb2285a8e'
readonly UV_SHA512SUM_OSX_ARM64='edea00f594b31c583687bc6457103256ef610b7dfd2aab52e866a2faf0394b2df6089208aa470b2782e626265f7861319817ef59181fd29e371f1406de3de7bc'
readonly UV_SHA512SUM_OSX_X86_64='d69c0367aa65020808cfeeaf25e6a2b55ae9dd404d83f70e704d1b1c0ea222f65137d7ba9e1cd4d22cc2e0a33ddfc92170d31f1a6f8f756d1daa97c9f4528fb2'
readonly UV_VERSION='0.11.3'

## Rust
### https://releases.rs/
# readonly RUST_MAJOR_VERSION='1.94'
# readonly RUST_VERSION="${RUST_MAJOR_VERSION}.0"
readonly RUST_MAJOR_VERSION='1.94.1'
readonly RUST_VERSION="${RUST_MAJOR_VERSION}"

## rustup
### https://github.com/rust-lang/rustup/tags
readonly RUSTUP_COMMIT='28d1352dbcb436d3111c3594b9e1588e94950464'
readonly RUSTUP_SHA512SUM='cd9fd64eabc989f19a6a16e9cd2caabe935082e2715b9308150f86d3839c99eb9a7e42a7ef6730c6d956d870638ee89a04dd9e7e14fe243cc165967b7f2918da'
readonly RUSTUP_VERSION='1.29.0'

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
