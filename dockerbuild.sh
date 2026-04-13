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
        -t "${IMAGE}:${tag_ver}" \
        -t "${IMAGE}:${variant}" \
        .

    echo "==>  Pushing  ${IMAGE}:${tag_ver}"
    docker push "${IMAGE}:${tag_ver}"

    echo "==>  Pushing  ${IMAGE}:${variant}"
    docker push "${IMAGE}:${variant}"
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
        echo "  ubuntu  — Ubuntu 24.04 LTS"
        echo "  rocky  — Rocky Linux 9"
        echo "  centos — alias for rocky (backward compatibility)"
        echo "  all    — build both ubuntu + rocky (default)"
        exit 0
        ;;
    --help|-h)
        echo "Usage: $0 [ubuntu|rocky|centos|all] [version]"
        echo "  version defaults to 10.2.6208"
        echo "  centos is an alias for rocky (backward compatibility)"
        exit 0
        ;;
esac

if [[ "$VARIANT" == "all" ]]; then
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
