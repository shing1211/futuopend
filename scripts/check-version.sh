#!/bin/bash
#
# Check FutuOpenD version against available tarballs.
# Usage: ./scripts/check-version.sh                          # check current version
#        ./scripts/check-version.sh 10.10.7008              # check specific version
#        ./scripts/check-version.sh --update 10.11.7108     # bump Dockerfiles + checksums
#        ./scripts/check-version.sh --update                # bump to current (no-op if same)
#
set -euo pipefail

IMAGE="shing1211/futuopend"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHECKSUM_DIR="$SCRIPT_DIR/checksums"
CHECKSUM_FILE="$CHECKSUM_DIR/futuopend-sha256.txt"

CHECKSUM_HEADER="# FutuOpenD tarball SHA256 checksums.
# Format: <sha256>  <filename>
#
# Upstream (futunn.com) does not publish checksums; these are recorded from
# verified builds (trust-on-first-use). They detect CDN changes or tampering
# and silent upstream replacement, but not a compromised repository.
#
# Refresh with: ./scripts/check-version.sh --update <version>"

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

update_checksums() {
    local ver="$1"
    mkdir -p "$CHECKSUM_DIR"
    if [ ! -f "$CHECKSUM_FILE" ]; then
        printf '%s\n' "$CHECKSUM_HEADER" > "$CHECKSUM_FILE"
    fi
    local tmp
    tmp="$(mktemp -d)"
    local variant suffix name url hash
    for variant in ubuntu rocky; do
        case "$variant" in
            ubuntu) suffix="Ubuntu18.04" ;;
            rocky) suffix="Centos7" ;;
        esac
        name="Futu_OpenD_${ver}_${suffix}.tar.gz"
        url="https://softwaredownload.futunn.com/${name}"
        echo "==> Downloading ${name} to compute checksum..." >&2
        if ! curl -fsSL --retry 3 --retry-delay 5 "$url" -o "$tmp/$name"; then
            echo "==> Failed to download ${name}; existing checksum left unchanged" >&2
            continue
        fi
        hash="$(sha256sum "$tmp/$name" | cut -d' ' -f1)"
        if grep -q "  ${name}$" "$CHECKSUM_FILE"; then
            sed -i "s|^[0-9a-f]\{64\}  ${name}\$|${hash}  ${name}|" "$CHECKSUM_FILE"
        else
            printf '%s  %s\n' "$hash" "$name" >> "$CHECKSUM_FILE"
        fi
        echo "==> ${name}: ${hash}" >&2
    done
    rm -rf "$tmp"
    echo "==> Checksums updated in $CHECKSUM_FILE"
}

CURRENT_VERSION=$(get_current_version)
DO_UPDATE=false

if [ "${1:-}" = "--update" ]; then
    DO_UPDATE=true
    TARGET_VERSION="${2:-$CURRENT_VERSION}"
else
    TARGET_VERSION="${1:-$CURRENT_VERSION}"
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
    if $DO_UPDATE; then
        if [ "$TARGET_VERSION" = "$CURRENT_VERSION" ]; then
            echo "==> Already at $CURRENT_VERSION; nothing to update."
        else
            update_version "$TARGET_VERSION"
            update_checksums "$TARGET_VERSION"
        fi
    fi
    exit 0
else
    echo "Status: version $TARGET_VERSION tarballs NOT FOUND"
    echo "Hint: check https://softwaredownload.futunn.com for available versions"
    exit 1
fi
