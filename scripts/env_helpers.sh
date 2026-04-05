
# Set platform
if [[ "${OSTYPE}" == "darwin"* ]]; then
    readonly BROWSER_TV_PLATFORM='darwin'
else
    readonly BROWSER_TV_PLATFORM='linux'
fi
export BROWSER_TV_PLATFORM

# Set OS
if [[ "${BROWSER_TV_PLATFORM}" == 'darwin' ]]; then
    readonly BROWSER_TV_OS='osx'
elif [[ "${BROWSER_TV_PLATFORM}" == 'linux' ]]; then
    if [[ -f "/etc/os-release" ]]; then
        source /etc/os-release
        if [[ -n "${ID}" ]]; then
            readonly BROWSER_TV_OS="${ID}"
        else
            readonly BROWSER_TV_OS='unknown'
        fi
    else
        readonly BROWSER_TV_OS='unknown'
    fi
else
    readonly BROWSER_TV_OS='unknown'
fi
export BROWSER_TV_OS

# Set architecture
readonly PLATFORM_ARCH=$(uname -m)
if [[ "${PLATFORM_ARCH}" == 'arm64' ]]; then
    readonly BROWSER_TV_PLATFORM_ARCH='aarch64'
else
    readonly BROWSER_TV_PLATFORM_ARCH='x86-64'
fi
export BROWSER_TV_PLATFORM_ARCH
