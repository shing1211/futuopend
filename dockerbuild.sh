#!/bin/bash
#
# Build and push FutuOpenD Docker images.
# Usage: ./dockerbuild.sh [ubuntu|centos] [version]
#   e.g.: ./dockerbuild.sh ubuntu 10.2.6208
#
set -euo pipefail

BASE_IMG="${1:-ubuntu}"
VERSION="${2:-10.2.6208}"
IMAGE="shing1211/futuopend"

if [[ "$BASE_IMG" != "ubuntu" && "$BASE_IMG" != "centos" ]]; then
    echo "Error: BASE_IMG must be 'ubuntu' or 'centos', got '$BASE_IMG'" >&2
    exit 1
fi

TARGET="final-${BASE_IMG}"

echo "==> Building FutuOpenD ${VERSION} (${BASE_IMG}) as ${IMAGE}:${VERSION}-${BASE_IMG}"
docker build \
    --target "$TARGET" \
    --build-arg FUTU_OPEND_VER="$VERSION" \
    --build-arg BASE_IMG="$BASE_IMG" \
    -t "${IMAGE}:${VERSION}-${BASE_IMG}" \
    -t "${IMAGE}:${BASE_IMG}" \
    .

echo "==> Pushing ${IMAGE}:${VERSION}-${BASE_IMG}"
docker push "${IMAGE}:${VERSION}-${BASE_IMG}"

echo "==> Pushing ${IMAGE}:${BASE_IMG}"
docker push "${IMAGE}:${BASE_IMG}"

echo "==> Done. Image: ${IMAGE}:${VERSION}-${BASE_IMG}"
