#!/bin/bash

# augment path to help it find cmake via homebrew
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_DIR=$(dirname "$0")
source "${SCRIPT_DIR}/xcode_functions.sh"

function setup_build_environment ()
{
    pushd "$SCRIPT_DIR/.." > /dev/null
    ROOT_PATH="$PWD"
    popd > /dev/null

    CLANG="/usr/bin/xcrun clang"
    CC="${CLANG}"
    CPP="${CLANG} -E"

    # We need to clear this so that cmake doesn't have a conniption
    MACOSX_DEPLOYMENT_TARGET=""

    XCODE_MAJOR_VERSION=$(xcode_major_version)

    CAN_BUILD_64BIT="0"

    # If IPHONEOS_DEPLOYMENT_TARGET has not been specified
    # setup reasonable defaults to allow running of a build script
    # directly (ie not from an Xcode proj)
    if [ -z "${IPHONEOS_DEPLOYMENT_TARGET}" ]
    then
        IPHONEOS_DEPLOYMENT_TARGET="6.0"
    fi

    # Determine if we can be building 64-bit binaries
    if [ "${XCODE_MAJOR_VERSION}" -ge "5" ] && [ $(echo ${IPHONEOS_DEPLOYMENT_TARGET} '>=' 6.0 | bc -l) == "1" ]
    then
        CAN_BUILD_64BIT="1"
    fi

    ARCHS=""
    if [ "${CAN_BUILD_64BIT}" -eq "1" ]
    then
        # For some stupid reason cmake needs simulator
        # builds to be first
        ARCHS="x86_64 ${ARCHS} arm64"
    else
        ARCHS="i386 ${ARCHS} armv7 armv7s"
    fi
}

function build_all_archs ()
{
    setup_build_environment

    local setup=$1
    local build_arch=$2
    local finish_build=$3

    # run the prepare function
    eval $setup

    echo "Building for ${ARCHS}"

    for ARCH in ${ARCHS}
    do
        PLATFORMS=""
        if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ] || [ "${ARCH}" == "arm64" ]
        then
            PLATFORMS="${PLATFORMS} iphonesimulator"
        fi

        if [ "${ARCH}" == "arm64" ]
        then
            PLATFORMS="${PLATFORMS} iphoneos"
        fi

        SDKVERSION=$(ios_sdk_version)

        if [ "${ARCH}" == "arm64" ]
        then
            HOST="aarch64-apple-darwin"
        else
            HOST="${ARCH}-apple-darwin"
        fi

        echo "Building ${ARCH} for ${PLATFORMS}"

        for PLATFORM in ${PLATFORMS}
        do
            SDKNAME="${PLATFORM}${SDKVERSION}"
            SDKROOT="$(sdk_path ${SDKNAME})"

            echo "Building ${LIBRARY_NAME} for ${SDKNAME} ${ARCH} on ${PLATFORM}"
            echo "Please stand by..."

            # run the per arch build command
            eval $build_arch
        done
    done

    # finish the build (usually lipo)
    eval $finish_build
}
