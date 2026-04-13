#!/bin/bash
#
# Build and push FutuOpenD Docker images to Docker Hub.
#
# Usage:
#   ./dockerbuild.sh              # builds & pushes ALL variants (ubuntu + centos)
#   ./dockerbuild.sh ubuntu        # builds & pushes ubuntu only
#   ./dockerbuild.sh centos        # builds & pushes centos only
#   ./dockerbuild.sh --list        # list available variants
#
# Tags pushed to Docker Hub (shing1211/futuopend):
#   :latest                       — always points to ubuntu
#   :<version>-ubuntu
#   :<version>-centos
#   :ubuntu
#   :centos
#
set -euo pipefail

IMAGE="shing1211/futuopend"
VARIANT="${1:-all}"
VERSION="${2:-10.2.6208}"

build_and_push() {
    local variant="$1"
    local target="final-${variant}"
    local tag_ver="${VERSION}-${variant}"

    echo ""
    echo "==> ============================================"
    echo "==>  Building  FutuOpenD ${VERSION}  [${variant}]"
    echo "==> ============================================"

    docker build \
        --target "$target" \
        --build-arg FUTU_OPEND_VER="$VERSION" \
        --build-arg BASE_IMG="$variant" \
        -t "${IMAGE}:${tag_ver}" \
        -t "${IMAGE}:${variant}" \
        .

    echo "==>  Pushing  ${IMAGE}:${tag_ver}"
    docker push "${IMAGE}:${tag_ver}"

    echo "==>  Pushing  ${IMAGE}:${variant}"
    docker push "${IMAGE}:${variant}"
}

case "$VARIANT" in
    --list)
        echo "Available variants:"
        echo "  ubuntu  — Ubuntu 22.04"
        echo "  centos  — Rocky Linux 9"
        echo "  all     — build both (default)"
        exit 0
        ;;
    --help|-h)
        echo "Usage: $0 [ubuntu|centos|all] [version]"
        echo "  version defaults to 10.2.6208"
        exit 0
        ;;
esac

if [[ "$VARIANT" == "all" ]]; then
    echo "==> Building ALL variants for ${IMAGE}"
    echo "==> Version: ${VERSION}"
    echo ""

    echo "==> Pulling base images..."
    docker pull ubuntu:22.04
    docker pull rockylinux:9

    build_and_push ubuntu
    build_and_push centos

    echo ""
    echo "==> Tagging :latest (ubuntu)"
    docker tag "${IMAGE}:${VERSION}-ubuntu" "${IMAGE}:latest"
    docker push "${IMAGE}:latest"

    echo ""
    echo "==> ============================================"
    echo "==>  All images pushed:"
    echo "==>    ${IMAGE}:${VERSION}-ubuntu"
    echo "==>    ${IMAGE}:${VERSION}-centos"
    echo "==>    ${IMAGE}:latest"
    echo "==>    ${IMAGE}:ubuntu"
    echo "==>    ${IMAGE}:centos"
    echo "==> ============================================"

elif [[ "$VARIANT" == "ubuntu" || "$VARIANT" == "centos" ]]; then
    echo "==> Building ${VARIANT} only"
    echo "==> Version: ${VERSION}"
    build_and_push "$VARIANT"
    echo ""
    echo "==> Done. ${IMAGE}:${VERSION}-${VARIANT} & ${IMAGE}:${VARIANT} pushed."

else
    echo "Error: unknown variant '$VARIANT'. Run '$0 --list' to see options." >&2
    exit 1
fi
