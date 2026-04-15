#!/bin/bash
#
# Build and push FutuOpenD Docker images to Docker Hub.
#
# Usage:
#   ./dockerbuild.sh              # builds & pushes ALL variants (ubuntu + rocky)
#   ./dockerbuild.sh ubuntu       # builds & pushes ubuntu only
#   ./dockerbuild.sh rocky        # builds & pushes rocky only
#   ./dockerbuild.sh centos       # alias for rocky (backward compatibility)
#   ./dockerbuild.sh --list       # list available variants
#   ./dockerbuild.sh --multiarch  # build multi-platform images (amd64 + arm64)
#
# Tags pushed to Docker Hub (shing1211/futuopend):
#   :latest                       — always points to ubuntu
#   :<version>-ubuntu
#   :<version>-rocky
#   :<version>-centos            — alias for :<version>-rocky
#   :ubuntu
#   :rocky
#   :centos                      — alias for :rocky
#
# Multi-arch tags (when using --multiarch):
#   :<version>-ubuntu-amd64
#   :<version>-ubuntu-arm64
#   :<version>-rocky-amd64
#   :<version>-rocky-arm64
#
# NOTE: FutuOpenD only provides x86_64 binaries. ARM builds use QEMU emulation.
#       For better performance on ARM devices, consider using box64:
#       https://github.com/ptitSeb/box64
#
set -euo pipefail

IMAGE="shing1211/futuopend"
VARIANT="${1:-all}"
VERSION="${2:-10.2.6208}"
PLATFORM="${3:-linux/amd64}"
MULTIARCH=false

check_docker_buildx() {
    if ! docker buildx version &>/dev/null; then
        echo "Error: docker buildx not installed." >&2
        echo "Install with: docker buildx install" >&2
        exit 1
    fi
}

setup_buildx() {
    if ! docker buildx inspect multiplatform &>/dev/null 2>&1; then
        docker buildx create --name multiplatform --driver docker-container --use
    else
        docker buildx use multiplatform
    fi
}

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
        -t "${IMAGE}:${tag_ver}" \
        -t "${IMAGE}:${variant}" \
        .

    echo "==>  Pushing  ${IMAGE}:${tag_ver}"
    docker push "${IMAGE}:${tag_ver}"

    echo "==>  Pushing  ${IMAGE}:${variant}"
    docker push "${IMAGE}:${variant}"
}

build_and_push_multiarch() {
    local variant="$1"
    local target="final-${variant}"
    local tag_ver="${VERSION}-${variant}"

    echo ""
    echo "==> ============================================"
    echo "==>  Multi-arch Building  FutuOpenD ${VERSION}  [${variant}]"
    echo "==>  Platforms: ${PLATFORM}"
    echo "==> ============================================"

    docker buildx build \
        --target "$target" \
        --build-arg FUTU_OPEND_VER="$VERSION" \
        --platform "${PLATFORM}" \
        -t "${IMAGE}:${tag_ver}-amd64" \
        -t "${IMAGE}:${tag_ver}-arm64" \
        -t "${IMAGE}:${variant}-amd64" \
        -t "${IMAGE}:${variant}-arm64" \
        --push \
        .
}

push_alias() {
    local src_tag="$1"
    local alias_tag="$2"
    docker tag "${IMAGE}:${src_tag}" "${IMAGE}:${alias_tag}"
    echo "==>  Pushing  ${IMAGE}:${alias_tag} (alias)"
    docker push "${IMAGE}:${alias_tag}"
}

case "$VARIANT" in
    --list)
        echo "Available variants:"
        echo "  ubuntu      — Ubuntu 24.04 LTS"
        echo "  rocky       — Rocky Linux 9"
        echo "  centos      — alias for rocky (backward compatibility)"
        echo "  all         — build both ubuntu + rocky (default)"
        echo "  --multiarch — build multi-platform images (amd64 + arm64)"
        echo ""
        echo "Platforms for --multiarch:"
        echo "  linux/amd64 (x86_64) - default, native"
        echo "  linux/arm64 (aarch64) - ARM 64-bit (Raspberry Pi 3/4/5)"
        echo ""
        echo "NOTE: FutuOpenD only provides x86_64 binaries. ARM builds"
        echo "      use QEMU emulation and may have reduced performance."
        echo "      For native ARM support, see: https://github.com/ptitSeb/box64"
        exit 0
        ;;
    --help|-h)
        echo "Usage: $0 [ubuntu|rocky|centos|all|--multiarch] [version] [platform]"
        echo "  version  defaults to 10.2.6208"
        echo "  platform defaults to linux/amd64 (for --multiarch mode)"
        echo "  centos is an alias for rocky (backward compatibility)"
        echo ""
        echo "Examples:"
        echo "  $0                    # build all variants (amd64 only)"
        echo "  $0 ubuntu             # build ubuntu variant"
        echo "  $0 --multiarch        # build multi-platform (amd64 + arm64)"
        echo "  $0 --multiarch ubuntu linux/arm64  # build arm64 only"
        exit 0
        ;;
    --multiarch)
        MULTIARCH=true
        VARIANT="${2:-all}"
        VERSION="${3:-10.2.6208}"
        PLATFORM="${4:-linux/amd64,linux/arm64}"
        ;;
esac

if [[ "$MULTIARCH" == "true" ]]; then
    check_docker_buildx
    setup_buildx

    if [[ "$VARIANT" == "all" ]]; then
        echo "==> Building ALL variants for ${IMAGE} (multi-arch)"
        echo "==> Version: ${VERSION}"
        echo "==> Platforms: ${PLATFORM}"
        echo ""

        build_and_push_multiarch ubuntu
        build_and_push_multiarch rocky

        echo ""
        echo "==> Tagging :latest (ubuntu-amd64)"
        docker pull "${IMAGE}:${VERSION}-ubuntu-amd64" 2>/dev/null || true
        docker tag "${IMAGE}:${VERSION}-ubuntu-amd64" "${IMAGE}:latest"
        docker push "${IMAGE}:latest"

        echo ""
        echo "==> ============================================"
        echo "==>  All multi-arch images pushed:"
        echo "==>    ${IMAGE}:${VERSION}-ubuntu-amd64"
        echo "==>    ${IMAGE}:${VERSION}-ubuntu-arm64"
        echo "==>    ${IMAGE}:${VERSION}-rocky-amd64"
        echo "==>    ${VERSION}-rocky-arm64"
        echo "==>    ${IMAGE}:latest (ubuntu-amd64)"
        echo "==> ============================================"

    elif [[ "$VARIANT" == "ubuntu" || "$VARIANT" == "rocky" || "$VARIANT" == "centos" ]]; then
        echo "==> Building ${VARIANT} for ${IMAGE} (multi-arch)"
        echo "==> Version: ${VERSION}"
        echo "==> Platforms: ${PLATFORM}"
        build_and_push_multiarch "$VARIANT"
        echo ""
        echo "==> Done. Multi-arch images for ${VARIANT} pushed."

    else
        echo "Error: unknown variant '$VARIANT'. Run '$0 --list' to see options." >&2
        exit 1
    fi

elif [[ "$VARIANT" == "all" ]]; then
    echo "==> Building ALL variants for ${IMAGE}"
    echo "==> Version: ${VERSION}"
    echo ""

    echo "==> Pulling base images..."
    docker pull ubuntu:24.04
    docker pull rockylinux:9

    build_and_push ubuntu
    build_and_push rocky

    echo ""
    echo "==> Tagging :latest (ubuntu)"
    docker tag "${IMAGE}:${VERSION}-ubuntu" "${IMAGE}:latest"
    docker push "${IMAGE}:latest"

    echo ""
    echo "==> Creating :centos aliases..."
    push_alias "${VERSION}-rocky" "${VERSION}-centos"
    push_alias "rocky" "centos"

    echo ""
    echo "==> ============================================"
    echo "==>  All images pushed:"
    echo "==>    ${IMAGE}:${VERSION}-ubuntu"
    echo "==>    ${IMAGE}:${VERSION}-rocky"
    echo "==>    ${IMAGE}:${VERSION}-centos  (alias)"
    echo "==>    ${IMAGE}:latest"
    echo "==>    ${IMAGE}:ubuntu"
    echo "==>    ${IMAGE}:rocky"
    echo "==>    ${IMAGE}:centos  (alias)"
    echo "==> ============================================"

elif [[ "$VARIANT" == "ubuntu" ]]; then
    echo "==> Building ubuntu only"
    echo "==> Version: ${VERSION}"
    build_and_push ubuntu
    echo ""
    echo "==> Done. ${IMAGE}:${VERSION}-ubuntu & ${IMAGE}:ubuntu pushed."

elif [[ "$VARIANT" == "rocky" || "$VARIANT" == "centos" ]]; then
    echo "==> Building rocky only"
    echo "==> Version: ${VERSION}"
    build_and_push rocky
    push_alias "${VERSION}-rocky" "${VERSION}-centos"
    push_alias "rocky" "centos"
    echo ""
    echo "==> Done. ${IMAGE}:${VERSION}-rocky, ${IMAGE}:rocky, and :centos aliases pushed."

else
    echo "Error: unknown variant '$VARIANT'. Run '$0 --list' to see options." >&2
    exit 1
fi
