
# Set platform
if [[ "${OSTYPE}" == "darwin"* ]]; then
    export BROWSER_TV_PLATFORM='darwin'
else
    export BROWSER_TV_PLATFORM='linux'
fi

# Set OS
if [[ "${BROWSER_TV_PLATFORM}" == 'darwin' ]]; then
    export BROWSER_TV_OS='osx'
elif [[ "${BROWSER_TV_PLATFORM}" == 'linux' ]]; then
    if [[ -f "/etc/os-release" ]]; then
        source /etc/os-release
        if [[ -n "${ID}" ]]; then
            export BROWSER_TV_OS="${ID}"
        else
            export BROWSER_TV_OS='unknown'
        fi
    else
        export BROWSER_TV_OS='unknown'
    fi
else
    export BROWSER_TV_OS='unknown'
fi

# Set architecture
PLATFORM_ARCH=$(uname -m)
if [[ "${PLATFORM_ARCH}" == 'arm64' ]]; then
    export BROWSER_TV_PLATFORM_ARCH='aarch64'
else
    export BROWSER_TV_PLATFORM_ARCH='x86-64'
fi
