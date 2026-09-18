#!/bin/bash
#
# Bump FutuOpenD version across both futuopend and futuopend-deploy in one shot.
#
# Usage:
#   ./scripts/bump-version.sh 10.12.7208              # dry-run (validates tarball, no changes)
#   ./scripts/bump-version.sh 10.12.7208 --commit     # actually write + commit + tag
#
# Prerequisites:
#   - Both repos must be cloned side-by-side: ../futuopend and ../futuopend-deploy
#   - Remote "origin" must be set on both
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHECK_VERSION="$SCRIPT_DIR/scripts/check-version.sh"
FUTUOPEND_DIR="$SCRIPT_DIR"
DEPLOY_DIR="$(cd "$SCRIPT_DIR/../futuopend-deploy" && pwd)"

DO_COMMIT=false

while [ $# -gt 0 ]; do
    case "$1" in
        --commit) DO_COMMIT=true ;;
        -h|--help)
            grep '^#' "$0" | head -15 | sed 's/^# //'
            exit 0
            ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *)  TARGET_VERSION="$1" ;;
    esac
    shift
done

if [ -z "${TARGET_VERSION:-}" ]; then
    echo "Usage: $0 <version> [--commit]" >&2
    echo "Example: $0 10.12.7208" >&2
    exit 1
fi

echo "==> Target version: $TARGET_VERSION"
echo ""

# ---------------------------------------------------------------------------
# Dry-run pass: validate tarball exists
# ---------------------------------------------------------------------------
echo "==> [1/3] Validating tarball on CDN..."
if ! "$CHECK_VERSION" --check "$TARGET_VERSION" > /dev/null 2>&1; then
    echo "==> ERROR: $TARGET_VERSION tarball not found on Futu's CDN." >&2
    echo "   Run './scripts/check-version.sh --check $TARGET_VERSION' for details." >&2
    exit 1
fi
echo "    Tarball found. Proceeding..."

# ---------------------------------------------------------------------------
# Update futuopend (Dockerfiles + checksums)
# ---------------------------------------------------------------------------
echo ""
echo "==> [2/3] Updating futuopend Dockerfiles + checksums..."
if [ "$DO_COMMIT" = true ]; then
    "$CHECK_VERSION" --update "$TARGET_VERSION"
else
    "$CHECK_VERSION" --dry-run --update "$TARGET_VERSION"
fi

# ---------------------------------------------------------------------------
# Patch futuopend-deploy
# ---------------------------------------------------------------------------
echo ""
echo "==> [3/3] Patching futuopend-deploy references..."

if [ ! -d "$DEPLOY_DIR/.git" ]; then
    echo "    Warning: $DEPLOY_DIR is not a git repo; skipping deploy patch." >&2
else
    CURRENT=$(grep 'ARG FUTU_OPEND_VER=' "$FUTUOPEND_DIR/Dockerfile.ubuntu" | head -1 | cut -d= -f2)
    if [ "$DO_COMMIT" = true ]; then
        "$CHECK_VERSION" --update "$TARGET_VERSION" --deploy "$DEPLOY_DIR" --commit
    else
        "$CHECK_VERSION" --dry-run --update "$TARGET_VERSION" --deploy "$DEPLOY_DIR"
    fi
fi

# ---------------------------------------------------------------------------
# Commit both repos
# ---------------------------------------------------------------------------
if [ "$DO_COMMIT" = true ]; then
    echo ""
    echo "==> Committing futuopend..."
    if [ -d "$FUTUOPEND_DIR/.git" ]; then
        (cd "$FUTUOPEND_DIR" && git add -A \
            && if ! git diff --cached --quiet; then \
                git commit -m "chore: bump FutuOpenD to $TARGET_VERSION" \
                         -m "Updated via bump-version.sh"; \
                git push origin main; \
               else echo "Nothing to commit in futuopend."; fi)
    fi

    echo ""
    echo "==> Committing futuopend-deploy..."
    if [ -d "$DEPLOY_DIR/.git" ]; then
        (cd "$DEPLOY_DIR" && git add -A \
            && if ! git diff --cached --quiet; then \
                git commit -m "chore(deps): update FutuOpenD to $TARGET_VERSION" \
                         -m "Updated via bump-version.sh"; \
                git push origin main; \
               else echo "Nothing to commit in futuopend-deploy."; fi)
    fi

    echo ""
    echo "==> Version $TARGET_VERSION bumped and pushed across both repos."
else
    echo ""
    echo "Dry-run complete. Run with --commit to apply changes."
fi
