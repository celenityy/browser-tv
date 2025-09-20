#!/bin/bash
#
#    Fennec build scripts
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

set -e

# Include version info
source "$rootdir/scripts/versions.sh"

function localize_maven {
    # Replace custom Maven repositories with mavenLocal()
    find ./* -name '*.gradle' -type f -exec python3 "$rootdir/scripts/localize_maven.py" {} \;
    # Make gradlew scripts call our Gradle wrapper
    find ./* -name gradlew -type f | while read -r gradlew; do
        echo -e '#!/bin/sh\ngradle "$@"' >"$gradlew"
        chmod 755 "$gradlew"
    done
}

# Applies the overlay files in the given directory
# to the current directory
function apply_overlay() {
    source_dir="$1"
    find "$source_dir" -type f| while read -r src; do
        target="${src#"$source_dir"}"
        mkdir -vp "$(dirname "$target")"
        cp -vrf "$src" "$target"
    done
}

if [ -z "$1" ]; then
    echo "Usage: $0 arm|arm64|x86_64|bundle" >&1
    exit 1
fi

if [[ -n ${FDROID_BUILD+x} ]]; then
    source "$(dirname "$0")/setup-android-sdk.sh"
fi

# shellcheck disable=SC2154
if [[ "$env_source" != "true" ]]; then
    echo "Use 'source scripts/env_local.sh' before calling prebuild or build"
    exit 1
fi

if [ ! -d "$ANDROID_HOME" ]; then
    echo "\$ANDROID_HOME($ANDROID_HOME) does not exist."
    exit 1
fi

if [ ! -d "$ANDROID_NDK" ]; then
    echo "\$ANDROID_NDK($ANDROID_NDK) does not exist."
    exit 1
fi

JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{sub("^$", "0", $2); print $1$2}')
[ "$JAVA_VER" -ge 15 ] || {
    echo "Java 17 or newer must be set as default JDK"
    exit 1
}

if [[ -z "$FIREFOX_VERSION" ]]; then
    echo "\$FIREFOX_VERSION is not set! Aborting..."
    exit 1
fi

if [[ -z "${SB_GAPI_KEY_FILE}" ]]; then
    echo "SB_GAPI_KEY_FILE environment variable has not been specified! Safe Browsing will not be supported in this build."
    read -p "Do you want to continue [y/N] " -n 1 -r
    echo ""
    if ! [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting..."
        exit 1
    fi
fi

# Set platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM=darwin
else
    PLATFORM=linux
fi

# Set architecture
PLATFORM_ARCH=$(uname -m)
if [[ "$PLATFORM_ARCH" == "arm64" ]]; then
    PLATFORM_ARCHITECTURE=aarch64
else
    PLATFORM_ARCHITECTURE=x86-64
fi

# Create build directory
mkdir -vp "$rootdir/build"

# Check patch files
source "$rootdir/scripts/patches.sh"

pushd "$mozilla_release"
if ! check_patches; then
    echo "Patch validation failed. Please check the patch files and try again."
    exit 1
fi
popd

if [[ -n ${FDROID_BUILD+x} ]]; then
    # Set up Rust
    # shellcheck disable=SC2154
    "$rustup"/rustup-init.sh -y --no-update-default-toolchain
else
    curl --doh-cert-status --no-insecure --no-proxy-insecure --no-sessionid --no-ssl --no-ssl-allow-beast --no-ssl-auto-client-cert --no-ssl-no-revoke --no-ssl-revoke-best-effort --proto -all,https --proto-default https --proto-redir -all,https --show-error -sSf https://sh.rustup.rs | sh -s -- -y --no-update-default-toolchain
fi

if [[ "$PLATFORM" == "darwin" ]]; then
    libclang="$ANDROID_NDK/toolchains/llvm/prebuilt/$PLATFORM-x86_64/lib"
else
    libclang="$ANDROID_NDK/toolchains/llvm/prebuilt/$PLATFORM-x86_64/musl/lib"
fi
echo "...libclang dir set to ${libclang}"

# shellcheck disable=SC1090,SC1091
source "$CARGO_HOME/env"
rustup default "$RUST_VERSION"
rustup target add thumbv7neon-linux-androideabi
rustup target add armv7-linux-androideabi
rustup target add aarch64-linux-android
rustup target add i686-linux-android
rustup target add x86_64-linux-android
cargo install --vers "$CBINDGEN_VERSION" cbindgen

# Set up target parameters
case "$1" in
arm)
    # APK for armeabi-v7a
    abi='"armeabi-v7a"'
    target=arm-linux-androideabi
    llvmtarget="ARM"
    rusttarget=arm
    ;;
x86_64)
    # APK for x86_64
    abi='"x86_64"'
    target=x86_64-linux-android
    llvmtarget="X86_64"
    rusttarget=x86_64
    ;;
arm64)
    # APK for arm64-v8a
    abi='"arm64-v8a"'
    target=aarch64-linux-android
    llvmtarget="AArch64"
    rusttarget=arm64
    ;;
bundle)
    # AAB for both armeabi-v7a and arm64-v8a
    abi='"arm64-v8a", "armeabi-v7a", "x86_64"'
    target=''
    llvmtarget="AArch64;ARM;X86_64"
    rusttarget='arm64,arm,x86_64'
    ;;
*)
    echo "Unknown build variant: '$1'" >&2
    exit 1
    ;;
esac

# WASI SDK
# shellcheck disable=SC2154
if [[ -n ${FDROID_BUILD+x} ]]; then
    pushd "$wasi"
    patch -p1 --no-backup-if-mismatch --quiet <"$mozilla_release/taskcluster/scripts/misc/wasi-sdk.patch"

    # Break the dependency on older cmake
    $SED -i -e 's|cmake_minimum_required(VERSION .*)|cmake_minimum_required(VERSION 3.5.0)|g' wasi-sdk.cmake

    popd

    export wasi_install=$wasi/build/install/wasi
else
    export wasi_install=$wasi
fi

# Gecko
pushd "$mozilla_release"

# Let it be Browser (part 2...)
mkdir -vp mobile/android/branding/browser-tv/content
mkdir -vp mobile/android/branding/browser-tv/locales/en-US
$SED -i -e 's/Fennec/Browser TV/g; s/Firefox/Browser TV/g' build/moz.configure/init.configure
$SED -i -e 's|"MOZ_APP_VENDOR", ".*"|"MOZ_APP_VENDOR", "celenity"|g' mobile/android/moz.configure
echo '' >>mobile/android/moz.configure
echo 'include("browser-tv.configure")' >>mobile/android/moz.configure

# Apply patches
apply_patches

# Ensure we're building for release
$SED -i -e 's/variant=variant(.*)/variant=variant("release")/' mobile/android/gradle.configure

# Fix v125 aar output not including native libraries
$SED -i \
    -e "s/singleVariant('debug')/singleVariant('release')/" \
    mobile/android/geckoview/build.gradle

# Hack the timeout for
# geckoview:generateJNIWrappersForGeneratedWithGeckoBinariesDebug
$SED -i \
    -e 's/max_wait_seconds=600/max_wait_seconds=1800/' \
    mobile/android/gradle.py

# Break the dependency on older Rust
$SED -i -e "s|rust-version = .*|rust-version = \""${RUST_VERSION}\""|g" Cargo.toml
$SED -i -e "s|rust-version = .*|rust-version = \""${RUST_MAJOR_VERSION}\""|g" intl/icu_capi/Cargo.toml
$SED -i -e "s|rust-version = .*|rust-version = \""${RUST_MAJOR_VERSION}\""|g" intl/icu_segmenter_data/Cargo.toml

# Disable debug
$SED -i -e 's|debug-assertions = .*|debug-assertions = false|g' Cargo.toml
$SED -i -e 's|debug = .*|debug = false|g' gfx/harfbuzz/src/rust/Cargo.toml

# Remove the `NETWORK_ACCESS_STATE` permission (GeckoView)
$SED -i -e 's|<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>|<!-- <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" /> -->|' mobile/android/geckoview/src/main/AndroidManifest.xml

# Disable Normandy (Experimentation)
$SED -i -e 's|"MOZ_NORMANDY", .*)|"MOZ_NORMANDY", False)|g' mobile/android/moz.configure

# Disable SSLKEYLOGGING
## https://bugzilla.mozilla.org/show_bug.cgi?id=1183318
## https://bugzilla.mozilla.org/show_bug.cgi?id=1915224
$SED -i -e 's|NSS_ALLOW_SSLKEYLOGFILE ?= .*|NSS_ALLOW_SSLKEYLOGFILE ?= 0|g' security/nss/lib/ssl/Makefile
echo '' >>security/moz.build
echo 'gyp_vars["enable_sslkeylogfile"] = 0' >>security/moz.build

# Disable telemetry
$SED -i -e 's|"MOZ_SERVICES_HEALTHREPORT", .*)|"MOZ_SERVICES_HEALTHREPORT", False)|g' mobile/android/moz.configure

# Disable crash reporting (GeckoView)
$SED -i -e '/MOZ_CRASHREPORTER/s/true/false/' mobile/android/geckoview/build.gradle

# Disable debug (GeckoView)
$SED -i -e '/DEBUG_BUILD/s/true/false/' mobile/android/geckoview/build.gradle

# Set flag for 'official' builds to ensure we're not enabling debug/dev settings
# https://gitlab.torproject.org/tpo/applications/tor-browser/-/issues/27623
# We're also setting the "MOZILLA_OFFICIAL" env variable below
$SED -i -e '/MOZILLA_OFFICIAL/s/false/true/' mobile/android/geckoview/build.gradle

# Target release
$SED -i -e '/RELEASE_OR_BETA/s/false/true/' mobile/android/geckoview/build.gradle
$SED -i -e '/NIGHTLY_BUILD/s/true/false/' mobile/android/geckoview/build.gradle

# Ensure UA is always set to Firefox
$SED -i -e 's|"MOZ_APP_UA_NAME", ".*"|"MOZ_APP_UA_NAME", "Firefox"|g' mobile/android/moz.configure

# Include additional Remote Settings local dumps (+ add our own...)
$SED -i -e 's|"mobile/"|"0"|g' services/settings/dumps/blocklists/moz.build
$SED -i -e 's|"mobile/"|"0"|g' services/settings/dumps/security-state/moz.build
echo '' >>services/settings/dumps/main/moz.build
echo 'FINAL_TARGET_FILES.defaults.settings.main += [' >>services/settings/dumps/main/moz.build
echo '    "anti-tracking-url-decoration.json",' >>services/settings/dumps/main/moz.build
echo '    "browser-fingerprinting-protection-overrides.json",' >>services/settings/dumps/main/moz.build
echo '    "cookie-banner-rules-list.json",' >>services/settings/dumps/main/moz.build
echo '    "hijack-blocklists.json",' >>services/settings/dumps/main/moz.build
echo '    "translations-models.json",' >>services/settings/dumps/main/moz.build
echo '    "translations-wasm.json",' >>services/settings/dumps/main/moz.build
echo '    "url-classifier-skip-urls.json",' >>services/settings/dumps/main/moz.build
echo '    "url-parser-default-unknown-schemes-interventions.json",' >>services/settings/dumps/main/moz.build
echo ']' >>services/settings/dumps/main/moz.build

# No-op RemoteSettingsCrashPull
$SED -i 's|crash-reports-ondemand||g' toolkit/components/crashes/RemoteSettingsCrashPull.sys.mjs
$SED -i -e 's/REMOTE_SETTINGS_CRASH_COLLECTION = ".*"/REMOTE_SETTINGS_CRASH_COLLECTION = ""/' toolkit/components/crashes/RemoteSettingsCrashPull.sys.mjs

# No-op Normandy (Experimentation)
$SED -i -e 's/REMOTE_SETTINGS_COLLECTION = ".*"/REMOTE_SETTINGS_COLLECTION = ""/' toolkit/components/normandy/lib/RecipeRunner.sys.mjs
$SED -i 's|normandy-recipes-capabilities||g' toolkit/components/normandy/lib/RecipeRunner.sys.mjs

# No-op telemetry (Gecko)
$SED -i -e '/enable_internal_pings:/s/true/false/' toolkit/components/glean/src/init/mod.rs
$SED -i -e '/upload_enabled =/s/true/false/' toolkit/components/glean/src/init/mod.rs
$SED -i -e '/use_core_mps:/s/true/false/' toolkit/components/glean/src/init/mod.rs
$SED -i 's|localhost||g' toolkit/components/telemetry/pings/BackgroundTask_pingsender.sys.mjs
$SED -i 's|localhost||g' toolkit/components/telemetry/pingsender/pingsender.cpp
$SED -i -e 's/usageDeletionRequest.setEnabled(.*)/usageDeletionRequest.setEnabled(false)/' toolkit/components/telemetry/app/UsageReporting.sys.mjs
$SED -i -e 's|useTelemetry = .*|useTelemetry = false;|g' toolkit/components/telemetry/core/Telemetry.cpp
$SED -i '/# This must remain last./i gkrust_features += ["glean_disable_upload"]\n' toolkit/library/rust/gkrust-features.mozbuild

$SED -i -e 's|include_client_id: .*|include_client_id: false|g' toolkit/components/glean/pings.yaml
$SED -i -e 's|send_if_empty: .*|send_if_empty: false|g' toolkit/components/glean/pings.yaml
$SED -i -e 's|include_client_id: .*|include_client_id: false|g' toolkit/components/nimbus/pings.yaml
$SED -i -e 's|send_if_empty: .*|send_if_empty: false|g' toolkit/components/nimbus/pings.yaml

# Prevent DoH canary requests
$SED -i -e 's/GLOBAL_CANARY = ".*"/GLOBAL_CANARY = ""/' toolkit/components/doh/DoHHeuristics.sys.mjs
$SED -i -e 's/ZSCALER_CANARY = ".*"/ZSCALER_CANARY = ""/' toolkit/components/doh/DoHHeuristics.sys.mjs

# Remove example dependencies
## Also see `gecko-remove-example-dependencies.patch`
$SED -i "s|include ':annotations', .*|include ':annotations'|g" settings.gradle
$SED -i "s|project(':messaging_example'|// project(':messaging_example'|g" settings.gradle
$SED -i "s|project(':port_messaging_example'|// project(':port_messaging_example'|g" settings.gradle
$SED -i -e 's#if (rootDir.toString().contains("android-components") || !project.key.startsWith("samples"))#if (!project.key.startsWith("samples"))#' mobile/android/shared-settings.gradle

# Remove Android Components
$SED -i "s|include ':android-components'|// include ':android-components'|g" settings.gradle
$SED -i "s|project(':android-components'|// project(':android-components'|g" settings.gradle

# Remove ExoPlayer
$SED -i "s|include ':exoplayer2'|// include ':exoplayer2'|g" settings.gradle
$SED -i "s|project(':exoplayer2'|// project(':exoplayer2'|g" settings.gradle

# Remove proprietary/tracking libraries
$SED -i 's|adjust|# adjust|g' gradle/libs.versions.toml
$SED -i 's|firebase-messaging|# firebase-messaging|g' gradle/libs.versions.toml
$SED -i 's|installreferrer|# installreferrer|g' gradle/libs.versions.toml
$SED -i 's|play-review|# play-review|g' gradle/libs.versions.toml
$SED -i 's|play-services|# play-services|g' gradle/libs.versions.toml
$SED -i 's|thirdparty-sentry|# thirdparty-sentry|g' gradle/libs.versions.toml
$SED -i 's|sentry|# sentry|g' gradle/libs.versions.toml

$SED -i 's|-include "adjust-keeps.cfg"|# -include "adjust-keeps.cfg"|g' mobile/android/config/proguard/proguard.cfg
$SED -i 's|-include "play-services-keeps.cfg"|# -include "play-services-keeps.cfg"|g' mobile/android/config/proguard/proguard.cfg
$SED -i 's|-include "proguard-leanplum.cfg"|# -include "proguard-leanplum.cfg"|g' mobile/android/config/proguard/proguard.cfg
rm -vf mobile/android/config/proguard/adjust-keeps.cfg
rm -vf mobile/android/config/proguard/play-services-keeps.cfg
rm -vf mobile/android/config/proguard/proguard-leanplum.cfg

# Replace Google Play FIDO with microG
$SED -i 's|libs.play.services.fido|"org.microg.gms:play-services-fido:v0.0.0.250932"|g' mobile/android/geckoview/build.gradle

# Nuke undesired Mozilla endpoints
source "$rootdir/scripts/noop_mozilla_endpoints.sh"

# Take back control of preferences
## This prevents GeckoView from overriding the follow prefs at runtime, which also means we don't have to worry about Nimbus overriding them, etc...
## The prefs will instead take the values we specify in the phoenix/ironfox .js files, and users will also be able to override them via the `about:config`
## This is ideal for features that aren't exposed by the UI, it gives more freedom/control back to users, and it's great to ensure things are always configured how we want them...
$SED -i \
    -e 's|"browser.safebrowsing.provider."|"z99.ignore.string."|' \
    -e 's|"cookiebanners.service.detectOnly"|"z99.ignore.boolean"|' \
    -e 's|"cookiebanners.service.enableGlobalRules"|"z99.ignore.boolean"|' \
    -e 's|"cookiebanners.service.enableGlobalRules.subFrames"|"z99.ignore.boolean"|' \
    -e 's|"cookiebanners.service.mode"|"z99.ignore.integer"|' \
    -e 's|"network.cookie.cookieBehavior"|"z99.ignore.integer"|' \
    -e 's|"network.cookie.cookieBehavior.pbmode"|"z99.ignore.integer"|' \
    -e 's|"privacy.annotate_channels.strict_list.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.bounceTrackingProtection.mode"|"z99.ignore.integer"|' \
    -e 's|"privacy.purge_trackers.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.query_stripping.allow_list"|"z99.ignore.string"|' \
    -e 's|"privacy.query_stripping.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.query_stripping.enabled.pbmode"|"z99.ignore.boolean"|' \
    -e 's|"privacy.query_stripping.strip_list"|"z99.ignore.string"|' \
    -e 's|"privacy.socialtracking.block_cookies.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.trackingprotection.annotate_channels"|"z99.ignore.boolean"|' \
    -e 's|"privacy.trackingprotection.cryptomining.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.trackingprotection.emailtracking.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.trackingprotection.emailtracking.pbmode.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.trackingprotection.fingerprinting.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.trackingprotection.socialtracking.enabled"|"z99.ignore.boolean"|' \
    -e 's|"urlclassifier.features.cryptomining.blacklistTables"|"z99.ignore.string"|' \
    -e 's|"urlclassifier.features.emailtracking.blocklistTables"|"z99.ignore.string"|' \
    -e 's|"urlclassifier.features.fingerprinting.blacklistTables"|"z99.ignore.string"|' \
    -e 's|"urlclassifier.features.socialtracking.annotate.blacklistTables"|"z99.ignore.string"|' \
    -e 's|"urlclassifier.malwareTable"|"z99.ignore.string"|' \
    -e 's|"urlclassifier.phishTable"|"z99.ignore.string"|' \
    -e 's|"urlclassifier.trackingTable"|"z99.ignore.string"|' \
    mobile/android/geckoview/src/main/java/org/mozilla/geckoview/ContentBlocking.java

$SED -i \
    -e 's|"apz.allow_double_tap_zooming"|"z99.ignore.boolean"|' \
    -e 's|"browser.crashReports.requestedNeverShowAgain"|"z99.ignore.boolean"|' \
    -e 's|"browser.display.use_document_fonts"|"z99.ignore.integer"|' \
    -e 's|"docshell.shistory.sameDocumentNavigationOverridesLoadType"|"z99.ignore.boolean"|' \
    -e 's|"docshell.shistory.sameDocumentNavigationOverridesLoadType.forceDisable"|"z99.ignore.string"|' \
    -e 's|"dom.ipc.processCount"|"z99.ignore.integer"|' \
    -e 's|"dom.manifest.enabled"|"z99.ignore.boolean"|' \
    -e 's|"extensions.webapi.enabled"|"z99.ignore.boolean"|' \
    -e 's|"extensions.webextensions.crash.threshold"|"z99.ignore.integer"|' \
    -e 's|"extensions.webextensions.crash.timeframe"|"z99.ignore.long"|' \
    -e 's|"extensions.webextensions.remote"|"z99.ignore.boolean"|' \
    -e 's|"fission.autostart"|"z99.ignore.boolean"|' \
    -e 's|"fission.disableSessionHistoryInParent"|"z99.ignore.boolean"|' \
    -e 's|"fission.webContentIsolationStrategy"|"z99.ignore.integer"|' \
    -e 's|"formhelper.autozoom"|"z99.ignore.boolean"|' \
    -e 's|"general.aboutConfig.enable"|"z99.ignore.boolean"|' \
    -e 's|"javascript.options.mem.gc_parallel_marking"|"z99.ignore.boolean"|' \
    -e 's|"javascript.options.use_fdlibm_for_sin_cos_tan"|"z99.ignore.boolean"|' \
    -e 's|"network.cookie.cookieBehavior.optInPartitioning"|"z99.ignore.boolean"|' \
    -e 's|"network.cookie.cookieBehavior.optInPartitioning.pbmode"|"z99.ignore.boolean"|' \
    -e 's|"network.android_doh.autoselect_enabled"|"z99.ignore.boolean"|' \
    -e 's|"network.fetchpriority.enabled"|"z99.ignore.boolean"|' \
    -e 's|"network.http.http3.enable_kyber"|"z99.ignore.boolean"|' \
    -e 's|"network.http.largeKeepaliveFactor"|"z99.ignore.integer"|' \
    -e 's|"network.security.ports.banned"|"z99.ignore.string"|' \
    -e 's|"privacy.baselineFingerprintingProtection"|"z99.ignore.boolean"|' \
    -e 's|"privacy.baselineFingerprintingProtection.overrides"|"z99.ignore.string"|' \
    -e 's|"privacy.fingerprintingProtection"|"z99.ignore.boolean"|' \
    -e 's|"privacy.fingerprintingProtection.overrides"|"z99.ignore.string"|' \
    -e 's|"privacy.fingerprintingProtection.pbmode"|"z99.ignore.boolean"|' \
    -e 's|"privacy.globalprivacycontrol.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.globalprivacycontrol.functionality.enabled"|"z99.ignore.boolean"|' \
    -e 's|"privacy.globalprivacycontrol.pbmode.enabled"|"z99.ignore.boolean"|' \
    -e 's|"security.pki.certificate_transparency.mode"|"z99.ignore.integer"|' \
    -e 's|"security.tls.enable_kyber"|"z99.ignore.boolean"|' \
    -e 's|"toolkit.telemetry.user_characteristics_ping.current_version"|"z99.ignore.integer"|' \
    -e 's|"webgl.msaa-samples"|"z99.ignore.integer"|' \
    mobile/android/geckoview/src/main/java/org/mozilla/geckoview/GeckoRuntimeSettings.java

# shellcheck disable=SC2154
if [[ -n ${FDROID_BUILD+x} ]]; then
    # Patch the LLVM source code
    # Search clang- in https://android.googlesource.com/platform/ndk/+/refs/tags/ndk-r28b/ndk/toolchains.py
    LLVM_SVN='530567'
    python3 "$toolchain_utils/llvm_tools/patch_manager.py" \
        --svn_version $LLVM_SVN \
        --patch_metadata_file "$llvm_android/patches/PATCHES.json" \
        --src_path "$llvm"

    # Bundletool
    pushd "$bundletool"
    localize_maven
    popd
fi
{
    echo 'ac_add_options --disable-address-sanitizer-reporter'
    echo 'ac_add_options --disable-android-debuggable'
    echo 'ac_add_options --disable-artifact-builds'
    echo 'ac_add_options --disable-backgroundtasks'
    echo 'ac_add_options --disable-callgrind'
    echo 'ac_add_options --disable-crashreporter'
    echo 'ac_add_options --disable-debug'
    echo 'ac_add_options --disable-debug-js-modules'
    echo 'ac_add_options --disable-debug-symbols'
    echo 'ac_add_options --disable-default-browser-agent'
    echo 'ac_add_options --disable-dtrace'
    echo 'ac_add_options --disable-dump-painting'
    echo 'ac_add_options --disable-execution-tracing'
    echo 'ac_add_options --disable-extensions-webidl-bindings'
    echo 'ac_add_options --disable-ffmpeg'
    echo 'ac_add_options --disable-gecko-profiler'
    echo 'ac_add_options --disable-geckodriver'
    echo 'ac_add_options --disable-gtest-in-build'
    echo 'ac_add_options --disable-instruments'
    echo 'ac_add_options --disable-jitdump'
    echo 'ac_add_options --disable-js-shell'
    echo 'ac_add_options --disable-layout-debugger'
    echo 'ac_add_options --disable-logrefcnt'
    echo 'ac_add_options --disable-negotiateauth'
    echo 'ac_add_options --disable-nodejs'
    echo 'ac_add_options --disable-parental-controls'
    echo 'ac_add_options --disable-phc'
    echo 'ac_add_options --disable-pref-extensions'
    echo 'ac_add_options --disable-profiling'
    echo 'ac_add_options --disable-real-time-tracing'
    echo 'ac_add_options --disable-reflow-perf'
    echo 'ac_add_options --disable-rust-debug'
    echo 'ac_add_options --disable-rust-tests'
    echo 'ac_add_options --disable-simulator'
    echo 'ac_add_options --disable-spidermonkey-telemetry'
    echo 'ac_add_options --disable-system-extension-dirs'
    echo 'ac_add_options --disable-system-policies'
    echo 'ac_add_options --disable-tests'
    echo 'ac_add_options --disable-uniffi-fixtures'
    echo 'ac_add_options --disable-unverified-updates'
    echo 'ac_add_options --disable-updater'
    echo 'ac_add_options --disable-vtune'
    echo 'ac_add_options --disable-wasm-codegen-debug'
    echo 'ac_add_options --disable-webdriver'
    echo 'ac_add_options --disable-webrender-debugger'
    echo 'ac_add_options --disable-webspeechtestbackend'
    echo 'ac_add_options --disable-wmf'
    echo 'ac_add_options --enable-application="mobile/android"'
    echo 'ac_add_options --enable-disk-remnant-avoidance'
    echo 'ac_add_options --enable-geckoview-lite'
    echo 'ac_add_options --enable-hardening'
    echo 'ac_add_options --enable-install-strip'
    echo 'ac_add_options --enable-minify=properties'
    echo 'ac_add_options --enable-mobile-optimize'
    echo 'ac_add_options --enable-optimize'
    echo 'ac_add_options --enable-proxy-bypass-protection'
    echo 'ac_add_options --enable-release'
    echo 'ac_add_options --enable-replace-malloc'
    echo 'ac_add_options --enable-rust-simd'
    echo 'ac_add_options --enable-strip'
    echo 'ac_add_options --enable-update-channel="release"'
    echo 'ac_add_options --with-app-basename="Browser TV"'
    echo 'ac_add_options --with-app-name="browser-tv"'
    echo 'ac_add_options --with-branding="mobile/android/branding/browser-tv"'
    echo 'ac_add_options --with-crashreporter-url="data;"'
    echo 'ac_add_options --with-distribution-id="dev.celenity"'
    echo "ac_add_options --with-java-bin-path=\"$JAVA_HOME/bin\""

    if [[ -n "${target}" ]]; then
        echo "ac_add_options --target=$target"
    fi

    echo "ac_add_options --with-android-ndk=\"$ANDROID_NDK\""
    echo "ac_add_options --with-android-sdk=\"$ANDROID_HOME\""
    echo "ac_add_options --with-gradle=$(command -v gradle)"
    echo "ac_add_options --with-libclang-path=\"$libclang\""
    echo "ac_add_options --with-wasi-sysroot=\"$wasi_install/share/wasi-sysroot\""
    echo 'ac_add_options --without-adjust-sdk-keyfile'
    echo 'ac_add_options --without-android-googlevr-sdk'
    echo 'ac_add_options --without-bing-api-keyfile'
    echo 'ac_add_options --without-google-location-service-api-keyfile'
    echo 'ac_add_options --without-mozilla-api-keyfile'
    echo 'ac_add_options --without-leanplum-sdk-keyfile'
    echo 'ac_add_options --without-pocket-api-keyfile'

    if [[ -n ${SB_GAPI_KEY_FILE+x} ]]; then
        echo "ac_add_options --with-google-safebrowsing-api-keyfile=${SB_GAPI_KEY_FILE}"
    fi

    echo "ac_add_options ANDROID_BUNDLETOOL_PATH=\"$BUILDDIR/bundletool.jar\""
    echo "ac_add_options WASM_CC=\"$wasi_install/bin/clang\""
    echo "ac_add_options WASM_CXX=\"$wasi_install/bin/clang++\""
    echo "ac_add_options CC=\"$ANDROID_NDK/toolchains/llvm/prebuilt/$PLATFORM-x86_64/bin/clang\""
    echo "ac_add_options CXX=\"$ANDROID_NDK/toolchains/llvm/prebuilt/$PLATFORM-x86_64/bin/clang++\""
    echo "ac_add_options STRIP=\"$ANDROID_NDK/toolchains/llvm/prebuilt/$PLATFORM-x86_64/bin/llvm-strip\""
    echo 'ac_add_options MOZ_APP_BASENAME="Browser TV"'
    echo 'ac_add_options MOZ_APP_DISPLAYNAME="Browser TV"'
    echo 'ac_add_options MOZ_APP_NAME="browser-tv"'
    echo 'ac_add_options MOZ_APP_REMOTINGNAME="browser-tv"'
    echo 'ac_add_options MOZ_ARTIFACT_BUILDS='
    echo 'ac_add_options MOZ_CALLGRIND='
    echo 'ac_add_options MOZ_CRASHREPORTER_URL="data;"'
    echo 'ac_add_options MOZ_DEBUG_FLAGS='
    echo 'ac_add_options MOZ_EXECUTION_TRACING='
    echo 'ac_add_options MOZ_INCLUDE_SOURCE_INFO=1'
    echo 'ac_add_options MOZ_INSTRUMENTS='
    echo 'ac_add_options MOZ_LTO=1'
    echo 'ac_add_options MOZ_PACKAGE_JSSHELL='
    echo 'ac_add_options MOZ_PHC='
    echo 'ac_add_options MOZ_PROFILING='
    echo 'ac_add_options MOZ_REQUIRE_SIGNING='
    echo 'ac_add_options MOZ_RUST_SIMD=1'
    echo 'ac_add_options MOZ_SECURITY_HARDENING=1'
    echo 'ac_add_options MOZ_TELEMETRY_REPORTING='
    echo 'ac_add_options MOZ_VTUNE='
    echo 'ac_add_options MOZILLA_OFFICIAL=1'
    echo 'ac_add_options NODEJS='
    echo 'ac_add_options RUSTC_OPT_LEVEL=2'
    echo 'mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj'
    echo "export ANDROID_BUNDLETOOL_PATH=\"$BUILDDIR/bundletool.jar\""
    echo 'export MOZ_APP_BASENAME="Browser TV"'
    echo 'export MOZ_APP_DISPLAYNAME="Browser TV"'
    echo 'export MOZ_APP_NAME="browser-tv"'
    echo 'export MOZ_APP_REMOTINGNAME="browser-tv"'
    echo 'export MOZ_ARTIFACT_BUILDS='
    echo 'export MOZ_CALLGRIND='
    echo 'export MOZ_CRASHREPORTER_URL="data;"'
    echo 'export MOZ_EXECUTION_TRACING='
    echo 'export MOZ_INCLUDE_SOURCE_INFO=1'
    echo 'export MOZ_INSTRUMENTS='
    echo 'export MOZ_LTO=1'
    echo 'export MOZ_PACKAGE_JSSHELL='
    echo 'export MOZ_PGO=1'
    echo 'export MOZ_PHC='
    echo 'export MOZ_PROFILING='
    echo 'export MOZ_REQUIRE_SIGNING='
    echo 'export MOZ_RUST_SIMD=1'
    echo 'export MOZ_SECURITY_HARDENING=1'
    echo 'export MOZ_TELEMETRY_REPORTING='
    echo 'export MOZ_VTUNE='
    echo 'export MOZILLA_OFFICIAL=1'
    echo 'export RUSTC_OPT_LEVEL=2'
} >>mozconfig

# Fail on use of prebuilt binary
$SED -i 's|https://github.com|hxxps://github.com|' python/mozboot/mozboot/android.py

# Make the build system think we installed the emulator and an AVD
mkdir -vp "$ANDROID_HOME/emulator"
mkdir -vp "$HOME/.mozbuild/android-device/avd"

# Do not check the "emulator" utility which is obviously absent in the empty directory we created above
$SED -i -e '/check_android_tools("emulator"/d' build/moz.configure/android-sdk.configure

# Do not define `browser.safebrowsing.features.` prefs by default
## These are unnecessary, add extra confusion and complexity, and don't appear to interact well with our other prefs/settings
$SED -i \
    -e 's|"browser.safebrowsing.features.cryptomining.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.fingerprinting.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.malware.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.phishing.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.trackingAnnotation.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.trackingProtection.update"|"z99.ignore.boolean"|' \
    mobile/android/app/geckoview-prefs.js

{
    cat "$patches/preferences/phoenix.js"
    cat "$patches/preferences/phoenix-extended.js"
    cat "$patches/preferences/browser.js"

    if [[ -n ${BROWSER_UBO_ASSETS_URL+x} ]]; then
        # Set uBlock Origin to use our custom/enhanced config by default
        echo "pref(\"browser.browser.uBO.assetsBootstrapLocation\", \"${BROWSER_UBO_ASSETS_URL}\");"
    fi
} >>mobile/android/app/geckoview-prefs.js

{
    cat "$patches/preferences/pdf.js"
} >>toolkit/components/pdfjs/PdfJsOverridePrefs.js

# Apply Gecko overlay
apply_overlay "$patches/gecko-overlay/"

popd
