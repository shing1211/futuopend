#!/bin/bash
#
# Check FutuOpenD version against available tarballs, with optional update support.
#
# Usage:
#   ./scripts/check-version.sh                          # check current version
#   ./scripts/check-version.sh 10.11.7108              # check specific version
#   ./scripts/check-version.sh --discover               # discover next available version
#   ./scripts/check-version.sh --update 10.11.7108     # update Dockerfiles + checksums
#   ./scripts/check-version.sh --update 10.11.7108 --deploy ../futuopend-deploy
#                                                  # also patch futuopend-deploy files
#   ./scripts/check-version.sh --update 10.11.7108 --deploy ../futuopend-deploy --commit
#                                                  # also commit both repos
#   ./scripts/check-version.sh --update --deploy ../futuopend-deploy --commit
#                                                  # update to newest available
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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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

update_version_in_dockerfiles() {
    local new_ver="$1"
    echo "==> Updating version to $new_ver in Dockerfiles..."
    sed -i "s/^ARG FUTU_OPEND_VER=.*$/ARG FUTU_OPEND_VER=$new_ver/" \
        "$SCRIPT_DIR/Dockerfile.ubuntu" \
        "$SCRIPT_DIR/Dockerfile.rocky"
    echo "==> Dockerfiles updated."
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
            echo "==> Failed to download ${name}; existing checksum left unchanged." >&2
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

# ---------------------------------------------------------------------------
# Deploy-repo patching
# ---------------------------------------------------------------------------

# Files in futuopend-deploy that reference the OpenD version.
DEPLOY_VERSION_FILES=(
    "README.md"
    "docs/configuration.md"
    "docs/image-variants.md"
    "FutuOpenD.xml.template"
)

patch_deploy_repo() {
    local old_ver="$1"
    local new_ver="$2"
    local deploy_path="$3"

    echo "==> Patching futuopend-deploy ($deploy_path)..."
    for rel_path in "${DEPLOY_VERSION_FILES[@]}"; do
        local file="$deploy_path/$rel_path"
        if [ ! -f "$file" ]; then
            echo "    [SKIP] $file does not exist"
            continue
        fi
        if grep -q "$old_ver" "$file" 2>/dev/null; then
            local before after
            before=$(grep -c "$old_ver" "$file" || echo "0")
            sed -i "s/${old_ver}/${new_ver}/g" "$file"
            after=$(grep -c "$old_ver" "$file" || echo "0")
            local changed=$((before - after))
            echo "    [OK]   $rel_path ($changed occurrences)"
        else
            echo "    [SKIP] $rel_path (no occurrence)"
        fi
    done
}

# ---------------------------------------------------------------------------
# Git commits
# ---------------------------------------------------------------------------

git_commit_if_dirty() {
    local repo_path="$1"
    local message="$2"
    (cd "$repo_path" && git add -A)
    if ! (cd "$repo_path" && git diff --cached --quiet); then
        (cd "$repo_path" && git commit -m "$message")
        echo "==> Committed: $message"
        return 0
    else
        echo "==> Nothing to commit in $repo_path"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Version discovery (brute-force loop)
# ---------------------------------------------------------------------------

discover_next_version() {
    local current="$1"
    echo "==> Discovering next version after $current..." >&2

    # Parse version components: major.minor.patch
    IFS='.' read -r maj min pat <<< "$current"
    local next_pat=$((10#$pat + 1))
    local candidate="${maj}.${min}.${next_pat}"

    while true; do
        echo "    checking $candidate..." >&2
        if check_tarball "$candidate" ubuntu; then
            echo "==> Found: $candidate" >&2
            echo "$candidate"
            return 0
        fi
        next_pat=$((next_pat + 1))
        candidate="${maj}.${min}.${next_pat}"
        # Safety: if we somehow get into an infinite loop (e.g. Futu jumps major version)
        # we stop at 999
        if [ "$next_pat" -gt 999 ]; then
            echo "==> Safety limit reached; no new version found." >&2
            return 1
        fi
    done
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

MODE="check"          # check | update | discover
TARGET_VERSION=""
DEPLOY_PATH=""
DO_COMMIT=false
DRY_RUN=false

while [ $# -gt 0 ]; do
    case "$1" in
        --check)
            MODE="check"
            if [ -n "${2:-}" ] && [[ "$2" != --* ]]; then
                TARGET_VERSION="$2"; shift
            fi
            ;;
        --update)
            MODE="update"
            if [ -n "${2:-}" ] && [[ "$2" != --* ]]; then
                TARGET_VERSION="$2"; shift
            fi
            ;;
        --discover)
            MODE="discover"
            ;;
        --deploy)
            DEPLOY_PATH="$2"; shift
            ;;
        --commit)
            DO_COMMIT=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            grep '^#' "$0" | head -20 | sed 's/^# //'
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            TARGET_VERSION="$1"
            ;;
    esac
    shift
done

if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] No changes will be written."
    echo ""
fi

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

CURRENT_VERSION=$(get_current_version)

if [ "$MODE" = "discover" ]; then
    discovered=$(discover_next_version "$CURRENT_VERSION")
    if [ -z "$discovered" ]; then
        echo "No newer version found."
        exit 1
    fi
    echo "$discovered"
    exit 0
fi

# Default TARGET_VERSION to current if still empty
TARGET_VERSION="${TARGET_VERSION:-$CURRENT_VERSION}"

echo "Current version: $CURRENT_VERSION"
echo "Target version:  $TARGET_VERSION"
echo ""

if [ "$TARGET_VERSION" = "$CURRENT_VERSION" ] && [ "$MODE" = "update" ]; then
    echo "Already at $CURRENT_VERSION; nothing to update."
    exit 0
fi

# ---------------------------------------------------------------------------
# Check
# ---------------------------------------------------------------------------

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

if ! $UBUNTU_OK && ! $ROCKY_OK; then
    echo "Status: version $TARGET_VERSION tarballs NOT FOUND"
    echo "Hint: check https://softwaredownload.futunn.com for available versions"
    exit 1
fi

echo "Status: version $TARGET_VERSION is available"

# ---------------------------------------------------------------------------
# Update (only proceeds if MODE=update)
# ---------------------------------------------------------------------------

if [ "$MODE" != "update" ]; then
    exit 0
fi

if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would update Dockerfiles to $TARGET_VERSION"
    [ -n "$DEPLOY_PATH" ] && echo "[DRY RUN] Would patch $DEPLOY_PATH"
    [ "$DO_COMMIT" = true ] && echo "[DRY RUN] Would commit both repos"
    exit 0
fi

# 1. Update Dockerfiles
update_version_in_dockerfiles "$TARGET_VERSION"

# 2. Update checksums (downloads tarballs, computes SHA256)
update_checksums "$TARGET_VERSION"

# 3. Commit futuopend
if [ "$DO_COMMIT" = true ]; then
    git_commit_if_dirty "$SCRIPT_DIR" \
        "chore: bump FutuOpenD to $TARGET_VERSION" \
        || true
fi

# 4. Patch futuopend-deploy if path provided
if [ -n "$DEPLOY_PATH" ]; then
    if [ ! -d "$DEPLOY_PATH/.git" ]; then
        echo "==> Warning: $DEPLOY_PATH is not a git repo; skipping deploy patch."
    else
        patch_deploy_repo "$CURRENT_VERSION" "$TARGET_VERSION" "$DEPLOY_PATH"
        if [ "$DO_COMMIT" = true ]; then
            git_commit_if_dirty "$DEPLOY_PATH" \
                "chore(deps): update FutuOpenD to $TARGET_VERSION" \
                || true
        fi
    fi
fi

echo ""
echo "==> Version bump to $TARGET_VERSION complete."
