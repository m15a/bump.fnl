#!/usr/bin/env bash

# Utility to automatically bump version in bump.fnl and CHANGELOG.md.

# Suppose you have already edited version in bump.fnl and then
# run this script, which will modify CHANGELOG.md and bump.fnl accordingly.
# Arguments to this script is passed to ./bump.fnl.

set -euo pipefail

CURRENT_VERSION="$(fennel -e '(let [{: version} (require :bump)] version)')"
NEXT_VERSION="$(./bump.fnl --bump "$CURRENT_VERSION" "$@")"

if echo "$CURRENT_VERSION" | grep -q dev
then
    CURRENT_REF=HEAD
else
    CURRENT_REF="v$CURRENT_VERSION"
fi

if echo "$NEXT_VERSION" | grep -q dev
then
    NEXT_DATE='???'
    NEXT_REF=HEAD
else
    NEXT_DATE="$(date +"%Y-%m-%d %z")"
    NEXT_REF="v$NEXT_VERSION"
fi

sed -Ei bump.fnl \
    -e "s@(local version :)$CURRENT_VERSION@\1$NEXT_VERSION@"

if echo "$CURRENT_VERSION" | grep -q dev
then
    sed -Ei CHANGELOG.md \
        -e "s@^## \[$CURRENT_VERSION] - \?\?\?@## [$NEXT_VERSION] - $NEXT_DATE@" \
        -e "s@^\[$CURRENT_VERSION]: <(.+)$CURRENT_REF>@[$NEXT_VERSION]: <\1$NEXT_REF>@"
else
    sed -Ei CHANGELOG.md \
        -e "s@^(\[2]: .*)@\1\n\n## [$NEXT_VERSION] - $NEXT_DATE@" \
        -e "s@^(\[$CURRENT_VERSION]: <(.+)$CURRENT_REF>)@[$NEXT_VERSION]: <\2$NEXT_REF>\n\1@"
fi
