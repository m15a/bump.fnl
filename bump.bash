#!/usr/bin/env bash

# Utility to automatically bump version in bump.fnl and CHANGELOG.md.

# Run this script, which will modify CHANGELOG.md and bump.fnl accordingly.
# Arguments to this script are passed to ./bump.fnl. Say, you want to bump
# major version, then try
#
#     $ ./bump.bash --major
#
# and see what changed by `git show`.

set -euo pipefail

PRERELEASE_LABEL=dev
CURRENT_VERSION="$(fennel -e '(. (require :bump) :version)')"
NEXT_VERSION="$(./bump.fnl --bump "$CURRENT_VERSION" "$@")"

is_prerelease() {
    echo "$1" | grep -q "$PRERELEASE_LABEL"
}

if is_prerelease "$CURRENT_VERSION"
then
    CURRENT_REF=HEAD
else
    CURRENT_REF="v$CURRENT_VERSION"
fi

if is_prerelease "$NEXT_VERSION"
then
    NEXT_DATE='???'
    NEXT_REF=HEAD
else
    NEXT_DATE="$(date +"%Y-%m-%d %z")"
    NEXT_REF="v$NEXT_VERSION"
fi

sed -Ei bump.fnl \
    -e "s@(local version :)$CURRENT_VERSION@\1$NEXT_VERSION@"

if is_prerelease "$CURRENT_VERSION"
then
    sed -Ei CHANGELOG.md \
        -e "s@^## \[$CURRENT_VERSION] - \?\?\?@## [$NEXT_VERSION] - $NEXT_DATE@" \
        -e "s@^\[$CURRENT_VERSION]: (.+)$CURRENT_REF@[$NEXT_VERSION]: \1$NEXT_REF@"
else
    sed -Ei CHANGELOG.md \
        -e "s@^(\[2]: .*)@\1\n\n## [$NEXT_VERSION] - $NEXT_DATE@" \
        -e "s@^(\[$CURRENT_VERSION]: (.+)$CURRENT_REF)@[$NEXT_VERSION]: \2$NEXT_REF\n\1@"
fi

make
git add bump.fnl README.md CHANGELOG.md

if is_prerelease "$NEXT_VERSION"
then
    git commit -m "prerelease: $NEXT_VERSION"
else
    git commit -m "release: $NEXT_VERSION"
    git tag "v$NEXT_VERSION"
fi



