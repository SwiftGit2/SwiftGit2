#!/bin/bash

# Returns the version # of xcodebuild
# eg. (4.6.3, 5.0, 5.0.1)
function xcode_version ()
{
    /usr/bin/xcodebuild -version 2> /dev/null | head -n 1 | awk '{ print $2 }'
}

# Returns the major version of xcodebuild
# eg. (4, 5, 6)
function xcode_major_version ()
{
    xcode_version | awk -F '.' '{ print $1 }'
}

function xcode_minor_version ()
{
    xcode_version | awk -F '.' '{ print $2 }'
}

# Returns the latest iOS SDK version available via xcodebuild.
function ios_sdk_version ()
{
    # The grep command produces output like the following, singling out the
    # SDKVersion of just the iPhone* SDKs:
    #
    #   iPhoneOS9.0.sdk - iOS 9.0 (iphoneos9.0)
    #   SDKVersion: 9.0
    #   --
    #   iPhoneSimulator9.0.sdk - Simulator - iOS 9.0 (iphonesimulator9.0)
    #   SDKVersion: 9.0

    /usr/bin/xcodebuild -version -sdk 2> /dev/null | grep -A 1 '^iPhone' | tail -n 1 |  awk '{ print $2 }'
}

function macos_sdk_version ()
{
    # The grep command produces output like the following, singling out the
    # SDKVersion of just the Mac SDKs:
    #
    #     MacOSX11.0.sdk - macOS 11.0 (macosx11.0)
    #     SDKVersion: 11.0
    #     ...
    /usr/bin/xcodebuild -version -sdk 2> /dev/null | grep -A 1 '^MacOSX' | tail -n 1 |  awk '{ print $2 }'
}

# Returns the path to the specified iOS SDK name
function sdk_path ()
{
    /usr/bin/xcodebuild -version -sdk 2> /dev/null | grep -i $1 | grep 'Path:' | awk '{ print $2 }'
}

# Prints the checked-out commit of the git checkout at $1 (a submodule under
# External/), or "unknown" outside a git checkout. The update_* scripts write
# this into a BUILT_FROM stamp next to their output and rebuild when it no
# longer matches, so bumping a submodule is enough to trigger a rebuild.
function source_rev ()
{
    git -C "$1" rev-parse HEAD 2> /dev/null || echo "unknown"
}

# Minimum macOS for the vendored static libraries. Without it they inherit the
# SDK's version (e.g. 27.0) and the linker warns -- and the binary may not run
# -- when the app targets an older macOS. 11.0 is the first arm64 macOS.
NATIVE_DEPLOYMENT_TARGET="11.0"
