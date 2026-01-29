# Browser TV build target environment variables

## This is used for configuring the target build/architecture/type.

## CAUTION: Do NOT source this directly!
## Source 'env_target.sh' instead.

if [[ "${BROWSER_TV_TARGET_ARCH}" == 'arm64' ]]; then
    export BROWSER_TV_TARGET_ARCH_MOZ='arm64'
    export BROWSER_TV_TARGET_ABI='arm64-v8a'
    export BROWSER_TV_TARGET_PRETTY='ARM64'
    export BROWSER_TV_TARGET_RUST='arm64'
elif [[ "${BROWSER_TV_TARGET_ARCH}" == 'arm' ]]; then
    export BROWSER_TV_TARGET_ARCH_MOZ='arm'
    export BROWSER_TV_TARGET_ABI='armeabi-v7a'
    export BROWSER_TV_TARGET_PRETTY='ARM'
    export BROWSER_TV_TARGET_RUST='arm'
elif [[ "${BROWSER_TV_TARGET_ARCH}" == 'x86_64' ]]; then
    export BROWSER_TV_TARGET_ARCH_MOZ='x86_64'
    export BROWSER_TV_TARGET_ABI='x86_64'
    export BROWSER_TV_TARGET_PRETTY='x86_64'
    export BROWSER_TV_TARGET_RUST='x86_64'
elif [[ "${BROWSER_TV_TARGET_ARCH}" == 'bundle' ]]; then
    export BROWSER_TV_TARGET_ARCH_MOZ='bundle'
    export BROWSER_TV_TARGET_ABI='"arm64-v8a", "armeabi-v7a", "x86_64"'
    export BROWSER_TV_TARGET_PRETTY='Bundle'
    export BROWSER_TV_TARGET_RUST='arm64,arm,x86_64'
fi
