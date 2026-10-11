#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/scripts"
cp "$REPO_ROOT/scripts/auto_configure.sh" "$TMP_DIR/scripts/auto_configure.sh"

assert_java_image() {
    local version="$1" expected="$2"
    printf 'MC_VERSION=%s\n' "$version" > "$TMP_DIR/.env"
    (cd "$TMP_DIR" && MC_VERSION="$version" ./scripts/auto_configure.sh >/dev/null)
    if ! grep -qx "MC_IMAGE_TAG=$expected" "$TMP_DIR/.env"; then
        echo "Expected Minecraft $version to select $expected" >&2
        cat "$TMP_DIR/.env" >&2
        exit 1
    fi
}

assert_java_image "1.20.4" "java17"
assert_java_image "1.21.1" "java21"
assert_java_image "26.1.2" "java25"
echo "auto_configure Java image tests passed"
