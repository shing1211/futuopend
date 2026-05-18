#!/bin/bash
#
# Check FutuOpenD version against available tarballs.
# Usage: ./scripts/check-version.sh              # check current version
#        ./scripts/check-version.sh 10.6.6608    # check specific version
#        ./scripts/check-version.sh --update     # bump to latest available
#
set -euo pipefail

IMAGE="shing1211/futuopend"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

get_current_version() {
    grep 'ARG FUTU_OPEND_VER=' "$SCRIPT_DIR/Dockerfile.ubuntu" | head -1 | cut -d= -f2
}

check_tarball() {
    local ver="$1"
    local variant="$2"
    local suffix
    case "$variant" in
        ubuntu) suffix="Ubuntu18.04" ;;
        rocky|centos) suffix="Centos7" ;;
        *) return 1 ;;
    esac
    local url="https://softwaredownload.futunn.com/Futu_OpenD_${ver}_${suffix}.tar.gz"
    local status
    status=$(curl -sfI "$url" | head -1) || true
    if echo "$status" | grep -q "200"; then
        return 0
    fi
    return 1
}

update_version() {
    local new_ver="$1"
    echo "==> Updating version to $new_ver in Dockerfiles..."
    sed -i "s/^ARG FUTU_OPEND_VER=.*$/ARG FUTU_OPEND_VER=$new_ver/" \
        "$SCRIPT_DIR/Dockerfile.ubuntu" \
        "$SCRIPT_DIR/Dockerfile.rocky"
    echo "==> Done. Version bumped to $new_ver"
}

CURRENT_VERSION=$(get_current_version)
TARGET_VERSION="${1:-$CURRENT_VERSION}"
DO_UPDATE=false

if [ "$1" = "--update" ]; then
    DO_UPDATE=true
    TARGET_VERSION="$CURRENT_VERSION"
fi

echo "Current version: $CURRENT_VERSION"
echo ""
echo "Checking tarballs for ${IMAGE}:${TARGET_VERSION}..."
echo ""

UBUNTU_OK=false
ROCKY_OK=false

if check_tarball "$TARGET_VERSION" ubuntu; then
    echo "  [OK] Ubuntu 18.04 tarball found"
    UBUNTU_OK=true
else
    echo "  [MISSING] Ubuntu 18.04 tarball"
fi

if check_tarball "$TARGET_VERSION" rocky; then
    echo "  [OK] CentOS 7 tarball found"
    ROCKY_OK=true
else
    echo "  [MISSING] CentOS 7 tarball"
fi

echo ""

if $UBUNTU_OK || $ROCKY_OK; then
    echo "Status: version $TARGET_VERSION is available"
    exit 0
else
    echo "Status: version $TARGET_VERSION tarballs NOT FOUND"
    echo "Hint: check https://softwaredownload.futunn.com for available versions"
    exit 1
fi
