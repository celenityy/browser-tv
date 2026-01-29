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

# Set-up our environment
bash -x $(dirname $0)/env.sh
source $(dirname $0)/env.sh

# Include version info
source "${BROWSER_TV_VERSIONS}"

function localize_maven {
    # Replace custom Maven repositories with mavenLocal()
    find ./* -name '*.gradle' -type f -exec python3 "${BROWSER_TV_SCRIPTS}/localize_maven.py" {} \;
    # Make gradlew scripts call our Gradle wrapper
    find ./* -name gradlew -type f | while read -r gradlew; do
        echo -e "#!/bin/sh\n${BROWSER_TV_GRADLE} \""'$@'"\"" >"${gradlew}"
        chmod 755 "${gradlew}"
    done
}

# Applies the overlay files in the given directory
# to the current directory
function apply_overlay() {
    source_dir="$1"
    find "${source_dir}" -type f| while read -r src; do
        target="${src#"${source_dir}"}"
        mkdir -vp "$(dirname "${target}")"
        cp -vrf "${src}" "${target}"
    done
}

if [ -z "${1+x}" ]; then
    echo_red_text "Usage: $0 arm|arm64|x86_64|bundle" >&1
    exit 1
fi

if [ ! -d "${BROWSER_TV_ANDROID_SDK}" ]; then
    echo_red_text "\$BROWSER_TV_ANDROID_SDK($BROWSER_TV_ANDROID_SDK) does not exist."
    exit 1
fi

if [ ! -d "${BROWSER_TV_ANDROID_NDK}" ]; then
    echo_red_text "\$BROWSER_TV_ANDROID_NDK($BROWSER_TV_ANDROID_NDK) does not exist."
    exit 1
fi

JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{sub("^$", "0", $2); print $1$2}')
[ "${JAVA_VER}" -ge 15 ] || {
    echo_red_text "Java 17 or newer must be set as default JDK"
    exit 1
}

if [[ -z "${FIREFOX_VERSION}" ]]; then
    echo_red_text "\$FIREFOX_VERSION is not set! Aborting..."
    exit 1
fi

if [[ -z "${BROWSER_TV_VERSION}" ]]; then
    echo_red_text "\$BROWSER_TV_VERSION is not set! Aborting..."
    exit 1
fi

if [[ -z "${BROWSER_TV_SB_GAPI_KEY_FILE+x}" ]]; then
    echo_red_text "BROWSER_TV_SB_GAPI_KEY_FILE environment variable has not been specified! Safe Browsing will not be supported in this build."
    read -p "Do you want to continue [y/N] " -n 1 -r
    echo ""
    if ! [[ $REPLY =~ ^[Yy]$ ]]; then
        echo_red_text "Aborting..."
        exit 1
    fi
fi

echo_green_text "Preparing to build Browser TV ${BROWSER_TV_VERSION}: ${BROWSER_TV_CHANNEL_PRETTY}"

# Create build directories
mkdir -vp "${BROWSER_TV_CARGO_HOME}"
mkdir -vp "${BROWSER_TV_GRADLE_CACHE}"
mkdir -vp "${BROWSER_TV_GRADLE_HOME}"
mkdir -vp "${BROWSER_TV_MOZBUILD}"
mkdir -vp "${BROWSER_TV_OUTPUTS_AAB}"
mkdir -vp "${BROWSER_TV_OUTPUTS_AAR}"
mkdir -vp "${BROWSER_TV_OUTPUTS_APK}"
mkdir -vp "${BROWSER_TV_OUTPUTS_APKS}"
mkdir -vp "${BROWSER_TV_OUTPUTS_LOGS}"

## Copy machrc config
cp -vf "${BROWSER_TV_PATCHES}/machrc" "${BROWSER_TV_MOZBUILD}/machrc"

## Copy Rust (cargo) config
cp -vf "${BROWSER_TV_PATCHES}/cargo/config.toml" "${BROWSER_TV_CARGO_HOME}/config.toml"

# Check patch files
source "${BROWSER_TV_SCRIPTS}/patches.sh"

pushd "${BROWSER_TV_GECKO}"
if ! check_patches; then
    echo "Patch validation failed. Please check the patch files and try again."
    exit 1
fi
popd

# Set-up Rust
curl ${BROWSER_TV_CURL_FLAGS} -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --no-update-default-toolchain --profile=minimal

# Set-up cargo
source "${BROWSER_TV_CARGO_ENV}"
rustup set profile minimal
rustup default "${RUST_VERSION}"
rustup target add thumbv7neon-linux-androideabi
rustup target add armv7-linux-androideabi
rustup target add aarch64-linux-android
rustup target add i686-linux-android
rustup target add x86_64-linux-android
cargo install --force --vers "${CBINDGEN_VERSION}" cbindgen

# Set-up pip
if [[ -d "${BROWSER_TV_PIP_DIR}" ]]; then
    rm -rf "${BROWSER_TV_PIP_DIR}"
fi
python3.9 -m venv "${BROWSER_TV_PIP_DIR}"

source "${BROWSER_TV_PIP_ENV}"
pip install --upgrade pip
pip install gyp-next

# Set up target parameters
case "$1" in
arm64)
    # APK for arm64-v8a
    BROWSER_TV_TARGET_ARCH='arm64'
    ;;
arm)
    # APK for armeabi-v7a
    BROWSER_TV_TARGET_ARCH='arm'
    ;;
x86_64)
    # APK for x86_64
    BROWSER_TV_TARGET_ARCH='x86_64'
    ;;
bundle)
    # AAB for arm64-v8a, armeabi-v7a, and x86_64
    BROWSER_TV_TARGET_ARCH='bundle'
    ;;
*)
    echo "Unknown build variant: '$1'" >&2
    exit 1
    ;;
esac

# Write env_target.sh
echo "Writing ${BROWSER_TV_ENV_TARGET}..."
cat > "${BROWSER_TV_ENV_TARGET}" << EOF
export BROWSER_TV_TARGET_ARCH="${BROWSER_TV_TARGET_ARCH}"

source "\${BROWSER_TV_ENV_TARGET_HELPERS}"
EOF

# Gecko
pushd "${BROWSER_TV_GECKO}"

# Apply patches
apply_patches

# Let it be Browser TV (part 2...)
"${BROWSER_TV_SED}" -i -e 's|"MOZ_APP_VENDOR", ".*"|"MOZ_APP_VENDOR", "celenity"|g' mobile/android/moz.configure
echo '' >>mobile/android/moz.configure
echo 'include("../../browser-tv/browser-tv.configure")' >>mobile/android/moz.configure
echo '' >>moz.build
echo 'DIRS += ["browser-tv"]' >>moz.build

# about: pages
echo '' >>mobile/android/installer/package-manifest.in
echo '@BINPATH@/chrome/browser@JAREXT@' >>mobile/android/installer/package-manifest.in
echo '@BINPATH@/chrome/browser.manifest' >>mobile/android/installer/package-manifest.in
echo '' >>mobile/android/installer/package-manifest.in
echo '@BINPATH@/defaults/autoconfig/browser-tv.cfg' >>mobile/android/installer/package-manifest.in
echo '@BINPATH@/defaults/policies.json' >>mobile/android/installer/package-manifest.in

# about:policies
mkdir -vp browser-tv/locales/en-US/browser/policies
cp -vf browser/locales/en-US/browser/aboutPolicies.ftl browser-tv/locales/en-US/browser/
cp -vf browser/locales/en-US/browser/policies/policies-descriptions.ftl browser-tv/locales/en-US/browser/policies/

# about:robots
mkdir -vp browser-tv/about/browser/robots
cp -vf browser/base/content/aboutRobots.css browser-tv/about/browser/robots/
cp -vf browser/base/content/aboutRobots.js browser-tv/about/browser/robots/
cp -vf browser/base/content/aboutRobots.xhtml browser-tv/about/browser/robots/
cp -vf browser/base/content/aboutRobots-icon.png browser-tv/about/browser/robots/
cp -vf browser/base/content/robot.ico browser-tv/about/browser/robots/
cp -vf browser/base/content/static-robot.png browser-tv/about/browser/robots/
cp -vf browser/locales/en-US/browser/aboutRobots.ftl browser-tv/locales/en-US/browser/

# Ensure we're building for release
"${BROWSER_TV_SED}" -i -e 's/variant=variant(.*)/variant=variant("release")/' mobile/android/gradle.configure

# Fix v125 aar output not including native libraries
"${BROWSER_TV_SED}" -i \
    -e "s/singleVariant('debug')/singleVariant('release')/" \
    mobile/android/geckoview/build.gradle

# Hack the timeout for
# geckoview:generateJNIWrappersForGeneratedWithGeckoBinariesDebug
"${BROWSER_TV_SED}" -i \
    -e 's/max_wait_seconds=600/max_wait_seconds=1800/' \
    mobile/android/gradle.py

# Break the dependency on older Rust
"${BROWSER_TV_SED}" -i -e "s|rust-version = .*|rust-version = \""${RUST_VERSION}\""|g" Cargo.toml
"${BROWSER_TV_SED}" -i -e "s|rust-version = .*|rust-version = \""${RUST_MAJOR_VERSION}\""|g" intl/icu_capi/Cargo.toml
"${BROWSER_TV_SED}" -i -e "s|rust-version = .*|rust-version = \""${RUST_MAJOR_VERSION}\""|g" intl/icu_segmenter_data/Cargo.toml

# Disable debug
"${BROWSER_TV_SED}" -i -e 's|debug-assertions = .*|debug-assertions = false|g' Cargo.toml
"${BROWSER_TV_SED}" -i -e 's|debug = .*|debug = false|g' gfx/harfbuzz/src/rust/Cargo.toml
"${BROWSER_TV_SED}" -i -e 's|debug = .*|debug = false|g' gfx/wr/Cargo.toml

# Enable overflow checks
"${BROWSER_TV_SED}" -i -e 's|overflow-checks = .*|overflow-checks = true|g' gfx/harfbuzz/src/rust/Cargo.toml

# Enable performance optimizations
"${BROWSER_TV_SED}" -i -e "s|lto = .*|lto = true|g" Cargo.toml
"${BROWSER_TV_SED}" -i -e "s|opt-level = .*|opt-level = 3|g" Cargo.toml
"${BROWSER_TV_SED}" -i -e "s|opt-level = .*|opt-level = 3|g" gfx/wr/Cargo.toml

# Disable Normandy (Experimentation)
"${BROWSER_TV_SED}" -i -e 's|"MOZ_NORMANDY", .*)|"MOZ_NORMANDY", False)|g' mobile/android/moz.configure

# Disable SSLKEYLOGGING
## https://bugzilla.mozilla.org/show_bug.cgi?id=1183318
## https://bugzilla.mozilla.org/show_bug.cgi?id=1915224
"${BROWSER_TV_SED}" -i -e 's|NSS_ALLOW_SSLKEYLOGFILE ?= .*|NSS_ALLOW_SSLKEYLOGFILE ?= 0|g' security/nss/lib/ssl/Makefile
echo '' >>security/moz.build
echo 'gyp_vars["enable_sslkeylogfile"] = 0' >>security/moz.build

# Disable telemetry
"${BROWSER_TV_SED}" -i -e 's|"MOZ_SERVICES_HEALTHREPORT", .*)|"MOZ_SERVICES_HEALTHREPORT", False)|g' mobile/android/moz.configure

# Ensure UA is always set to Firefox
"${BROWSER_TV_SED}" -i -e 's|"MOZ_APP_UA_NAME", ".*"|"MOZ_APP_UA_NAME", "Firefox"|g' mobile/android/moz.configure

# Include additional Remote Settings local dumps (+ add our own...)
"${BROWSER_TV_SED}" -i -e 's|"mobile/"|"0"|g' services/settings/dumps/blocklists/moz.build
"${BROWSER_TV_SED}" -i -e 's|"mobile/"|"0"|g' services/settings/dumps/security-state/moz.build
echo '' >>services/settings/dumps/main/moz.build
echo 'FINAL_TARGET_FILES.defaults.settings.main += [' >>services/settings/dumps/main/moz.build
echo '    "anti-tracking-url-decoration.json",' >>services/settings/dumps/main/moz.build
echo '    "cookie-banner-rules-list.json",' >>services/settings/dumps/main/moz.build
echo '    "hijack-blocklists.json",' >>services/settings/dumps/main/moz.build
echo '    "translations-models.json",' >>services/settings/dumps/main/moz.build
echo '    "translations-wasm.json",' >>services/settings/dumps/main/moz.build
echo '    "url-classifier-skip-urls.json",' >>services/settings/dumps/main/moz.build
echo '    "url-parser-default-unknown-schemes-interventions.json",' >>services/settings/dumps/main/moz.build
echo ']' >>services/settings/dumps/main/moz.build

# Remove unused about:telemetry assets
rm -vf toolkit/content/aboutTelemetry.css toolkit/content/aboutTelemetry.js toolkit/content/aboutTelemetry.xhtml

# Prevent registration of the Glean add-on ping scheduler
"${BROWSER_TV_SED}" -i 's|category update-timer amGleanDaily|# category update-timer amGleanDaily|' toolkit/mozapps/extensions/extensions.manifest

# Remove the Clear Key CDM
"${BROWSER_TV_SED}" -i 's|@BINPATH@/@DLL_PREFIX@clearkey|; @BINPATH@/@DLL_PREFIX@clearkey|' mobile/android/installer/package-manifest.in

# No-op RemoteSettingsCrashPull
"${BROWSER_TV_SED}" -i 's|crash-reports-ondemand||g' toolkit/components/crashes/RemoteSettingsCrashPull.sys.mjs
"${BROWSER_TV_SED}" -i -e 's/REMOTE_SETTINGS_CRASH_COLLECTION = ".*"/REMOTE_SETTINGS_CRASH_COLLECTION = ""/' toolkit/components/crashes/RemoteSettingsCrashPull.sys.mjs

# No-op Normandy (Experimentation)
"${BROWSER_TV_SED}" -i -e 's/REMOTE_SETTINGS_COLLECTION = ".*"/REMOTE_SETTINGS_COLLECTION = ""/' toolkit/components/normandy/lib/RecipeRunner.sys.mjs
"${BROWSER_TV_SED}" -i 's|normandy-recipes-capabilities||g' toolkit/components/normandy/lib/RecipeRunner.sys.mjs

# No-op Nimbus (Experimentation)
"${BROWSER_TV_SED}" -i 's|classpath "${ApplicationServicesConfig.groupId}:tooling-nimbus-gradle|// "${ApplicationServicesConfig.groupId}:tooling-nimbus-gradle|g' build.gradle
"${BROWSER_TV_SED}" -i -e 's/COLLECTION_ID_FALLBACK = ".*"/COLLECTION_ID_FALLBACK = ""/' toolkit/components/nimbus/ExperimentAPI.sys.mjs
"${BROWSER_TV_SED}" -i -e 's/COLLECTION_ID_FALLBACK = ".*"/COLLECTION_ID_FALLBACK = ""/' toolkit/components/nimbus/lib/RemoteSettingsExperimentLoader.sys.mjs
"${BROWSER_TV_SED}" -i -e 's/EXPERIMENTS_COLLECTION = ".*"/EXPERIMENTS_COLLECTION = ""/' toolkit/components/nimbus/lib/RemoteSettingsExperimentLoader.sys.mjs
"${BROWSER_TV_SED}" -i -e 's/SECURE_EXPERIMENTS_COLLECTION = ".*"/SECURE_EXPERIMENTS_COLLECTION = ""/' toolkit/components/nimbus/lib/RemoteSettingsExperimentLoader.sys.mjs
"${BROWSER_TV_SED}" -i -e 's/SECURE_EXPERIMENTS_COLLECTION_ID = ".*"/SECURE_EXPERIMENTS_COLLECTION_ID = ""/' toolkit/components/nimbus/lib/RemoteSettingsExperimentLoader.sys.mjs
"${BROWSER_TV_SED}" -i 's|nimbus-desktop-experiments||g' toolkit/components/nimbus/ExperimentAPI.sys.mjs
"${BROWSER_TV_SED}" -i 's|nimbus-desktop-experiments||g' toolkit/components/nimbus/lib/RemoteSettingsExperimentLoader.sys.mjs
"${BROWSER_TV_SED}" -i 's|nimbus-secure-experiments||g' toolkit/components/nimbus/lib/RemoteSettingsExperimentLoader.sys.mjs

# No-op telemetry (Gecko)
"${BROWSER_TV_SED}" -i -e '/enable_internal_pings:/s/true/false/' toolkit/components/glean/src/init/mod.rs
"${BROWSER_TV_SED}" -i -e '/upload_enabled =/s/true/false/' toolkit/components/glean/src/init/mod.rs
"${BROWSER_TV_SED}" -i -e '/use_core_mps:/s/true/false/' toolkit/components/glean/src/init/mod.rs
"${BROWSER_TV_SED}" -i -e 's/usageDeletionRequest.setEnabled(.*)/usageDeletionRequest.setEnabled(false)/' toolkit/components/telemetry/app/UsageReporting.sys.mjs
"${BROWSER_TV_SED}" -i -e 's|useTelemetry = .*|useTelemetry = false;|g' toolkit/components/telemetry/core/Telemetry.cpp
"${BROWSER_TV_SED}" -i '/# This must remain last./i gkrust_features += ["glean_disable_upload"]\n' toolkit/library/rust/gkrust-features.mozbuild

"${BROWSER_TV_SED}" -i -e 's|include_client_id: .*|include_client_id: false|g' toolkit/components/glean/pings.yaml
"${BROWSER_TV_SED}" -i -e 's|send_if_empty: .*|send_if_empty: false|g' toolkit/components/glean/pings.yaml
"${BROWSER_TV_SED}" -i -e 's|include_client_id: .*|include_client_id: false|g' toolkit/components/nimbus/pings.yaml
"${BROWSER_TV_SED}" -i -e 's|send_if_empty: .*|send_if_empty: false|g' toolkit/components/nimbus/pings.yaml

# Prevent DoH canary requests
"${BROWSER_TV_SED}" -i -e 's/GLOBAL_CANARY = ".*"/GLOBAL_CANARY = ""/' toolkit/components/doh/DoHHeuristics.sys.mjs
"${BROWSER_TV_SED}" -i -e 's/ZSCALER_CANARY = ".*"/ZSCALER_CANARY = ""/' toolkit/components/doh/DoHHeuristics.sys.mjs

# Prevent DoH remote config/rollout
"${BROWSER_TV_SED}" -i -e 's/RemoteSettings(".*"/RemoteSettings(""/' toolkit/components/doh/DoHConfig.sys.mjs
"${BROWSER_TV_SED}" -i -e 's/kConfigCollectionKey = ".*"/kConfigCollectionKey = ""/' toolkit/components/doh/DoHTestUtils.sys.mjs
"${BROWSER_TV_SED}" -i -e 's/kProviderCollectionKey = ".*"/kProviderCollectionKey = ""/' toolkit/components/doh/DoHTestUtils.sys.mjs
"${BROWSER_TV_SED}" -i 's|"doh-config"||g' toolkit/components/doh/DoHConfig.sys.mjs
"${BROWSER_TV_SED}" -i 's|"doh-providers"||g' toolkit/components/doh/DoHConfig.sys.mjs
"${BROWSER_TV_SED}" -i 's|"doh-config"||g' toolkit/components/doh/DoHTestUtils.sys.mjs
"${BROWSER_TV_SED}" -i 's|"doh-providers"||g' toolkit/components/doh/DoHTestUtils.sys.mjs

# Remove DoH config/rollout local dumps
"${BROWSER_TV_SED}" -i -e 's|"doh-config.json"|# "doh-config.json"|g' services/settings/static-dumps/main/moz.build
"${BROWSER_TV_SED}" -i -e 's|"doh-providers.json"|# "doh-providers.json"|g' services/settings/static-dumps/main/moz.build
rm -vf services/settings/static-dumps/main/doh-config.json services/settings/static-dumps/main/doh-providers.json

# Remove example dependencies
## Also see `gecko-remove-example-dependencies.patch`
"${BROWSER_TV_SED}" -i "s|include ':annotations', .*|include ':annotations'|g" settings.gradle
"${BROWSER_TV_SED}" -i "s|project(':messaging_example'|// project(':messaging_example'|g" settings.gradle
"${BROWSER_TV_SED}" -i "s|project(':port_messaging_example'|// project(':port_messaging_example'|g" settings.gradle
"${BROWSER_TV_SED}" -i -e 's#if (rootDir.toString().contains("android-components") || !project.key.startsWith("samples"))#if (!project.key.startsWith("samples"))#' mobile/android/shared-settings.gradle

# Remove Android Components
"${BROWSER_TV_SED}" -i "s|include ':android-components'|// include ':android-components'|g" settings.gradle
"${BROWSER_TV_SED}" -i "s|project(':android-components'|// project(':android-components'|g" settings.gradle

# Remove ExoPlayer
"${BROWSER_TV_SED}" -i "s|include ':exoplayer2'|// include ':exoplayer2'|g" settings.gradle
"${BROWSER_TV_SED}" -i "s|project(':exoplayer2'|// project(':exoplayer2'|g" settings.gradle

# Remove proprietary/tracking libraries
"${BROWSER_TV_SED}" -i 's|adjust|# adjust|g' gradle/libs.versions.toml
"${BROWSER_TV_SED}" -i 's|firebase-messaging|# firebase-messaging|g' gradle/libs.versions.toml
"${BROWSER_TV_SED}" -i 's|installreferrer|# installreferrer|g' gradle/libs.versions.toml
"${BROWSER_TV_SED}" -i 's|play-review|# play-review|g' gradle/libs.versions.toml
"${BROWSER_TV_SED}" -i 's|play-services|# play-services|g' gradle/libs.versions.toml
"${BROWSER_TV_SED}" -i 's|sentry|# sentry|g' gradle/libs.versions.toml

# Replace Google Play FIDO with microG
"${BROWSER_TV_SED}" -i 's|libs.play.services.fido|"org.microg.gms:play-services-fido:v0.0.0.250932"|g' mobile/android/geckoview/build.gradle

# Nuke undesired Mozilla endpoints
source "${BROWSER_TV_SCRIPTS}/noop_mozilla_endpoints.sh"

# Take back control of preferences
## This prevents GeckoView from overriding the follow prefs at runtime, which also means we don't have to worry about Nimbus overriding them, etc...
## The prefs will instead take the values we specify in the phoenix/ironfox .js files, and users will also be able to override them via the `about:config`
## This is ideal for features that aren't exposed by the UI, it gives more freedom/control back to users, and it's great to ensure things are always configured how we want them...
"${BROWSER_TV_SED}" -i \
    -e 's|"browser.safebrowsing.malware.enabled"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.phishing.enabled"|"z99.ignore.boolean"|' \
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

"${BROWSER_TV_SED}" -i \
    -e 's|"apz.allow_double_tap_zooming"|"z99.ignore.boolean"|' \
    -e 's|"browser.crashReports.requestedNeverShowAgain"|"z99.ignore.boolean"|' \
    -e 's|"browser.display.use_document_fonts"|"z99.ignore.integer"|' \
    -e 's|"devtools.debugger.remote-enabled"|"z99.ignore.boolean"|' \
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
    -e 's|"javascript.enabled"|"z99.ignore.boolean"|' \
    -e 's|"javascript.options.mem.gc_parallel_marking"|"z99.ignore.boolean"|' \
    -e 's|"javascript.options.use_fdlibm_for_sin_cos_tan"|"z99.ignore.boolean"|' \
    -e 's|"network.android_doh.autoselect_enabled"|"z99.ignore.boolean"|' \
    -e 's|"network.cookie.cookieBehavior.optInPartitioning"|"z99.ignore.boolean"|' \
    -e 's|"network.cookie.cookieBehavior.optInPartitioning.pbmode"|"z99.ignore.boolean"|' \
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
    -e 's|"security.pki.crlite_channel"|"z99.ignore.string"|' \
    -e 's|"security.tls.enable_kyber"|"z99.ignore.boolean"|' \
    -e 's|"toolkit.telemetry.user_characteristics_ping.current_version"|"z99.ignore.integer"|' \
    -e 's|"webgl.msaa-samples"|"z99.ignore.integer"|' \
    mobile/android/geckoview/src/main/java/org/mozilla/geckoview/GeckoRuntimeSettings.java

# Fail on use of prebuilt binary
"${BROWSER_TV_SED}" -i 's|https://|hxxps://|' mobile/android/gradle/plugins/nimbus-gradle-plugin/src/main/groovy/org/mozilla/appservices/tooling/nimbus/NimbusGradlePlugin.groovy
"${BROWSER_TV_SED}" -i 's|https://github.com|hxxps://github.com|' python/mozboot/mozboot/android.py

# Make the build system think we installed the emulator and an AVD
mkdir -vp "${BROWSER_TV_ANDROID_SDK}/emulator"
mkdir -vp "${BROWSER_TV_MOZBUILD}/android-device/avd"

# Do not check the "emulator" utility which is obviously absent in the empty directory we created above
"${BROWSER_TV_SED}" -i -e '/check_android_tools("emulator"/d' build/moz.configure/android-sdk.configure

# Do not define `browser.safebrowsing.features.` prefs by default
## These are unnecessary, add extra confusion and complexity, and don't appear to interact well with our other prefs/settings
"${BROWSER_TV_SED}" -i \
    -e 's|"browser.safebrowsing.features.cryptomining.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.fingerprinting.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.harmfuladdon.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.malware.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.phishing.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.trackingAnnotation.update"|"z99.ignore.boolean"|' \
    -e 's|"browser.safebrowsing.features.trackingProtection.update"|"z99.ignore.boolean"|' \
    mobile/android/app/geckoview-prefs.js

# Gecko prefs
echo '' >>mobile/android/app/geckoview-prefs.js
echo '#include ../../../browser-tv/prefs/browser-tv.js' >>mobile/android/app/geckoview-prefs.js

# Apply Gecko overlay
apply_overlay "${BROWSER_TV_GECKO_OVERLAY}/"

popd

#
# microG
#

pushd "${BROWSER_TV_GMSCORE}"

# Bump Android build tools
"${BROWSER_TV_SED}" -i -e "s|ext.androidBuildVersionTools = .*|ext.androidBuildVersionTools = '${ANDROID_BUILDTOOLS_VERSION}'|g" build.gradle

# Bump Android compile SDK
"${BROWSER_TV_SED}" -i -e "s|ext.androidCompileSdk = .*|ext.androidCompileSdk = ${ANDROID_SDK_TARGET}|g" build.gradle

# Bump Android minimum SDK
## (This matches what we're using for the browser itself, as well as Mozilla's various components/dependencies)
"${BROWSER_TV_SED}" -i -e 's|ext.androidMinSdk = .*|ext.androidMinSdk = 26|g' build.gradle

# Bump Android target SDK
"${BROWSER_TV_SED}" -i -e "s|ext.androidTargetSdk = .*|ext.androidTargetSdk = ${ANDROID_SDK_TARGET}|g" build.gradle

popd

#
# Prebuilds
#

if [[ "${BROWSER_TV_NO_PREBUILDS}" == 1 ]]; then
    pushd "${BROWSER_TV_IRONFOX_PREBUILDS}"
    echo "Preparing the prebuild build repository..."
    bash -x "${BROWSER_TV_IRONFOX_PREBUILDS}/scripts/prebuild.sh"
    popd
fi
