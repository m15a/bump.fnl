#!/usr/bin/env bash

# Run this script, which will modify bump.fnl, CHANGELOG.md, and README.md
# accordingly.
#
# Arguments to this script are passed to ./bump.fnl. Say, you want to bump
# major version, then try
#
#     $ ./bump.bash --major
#
# and see what changed by `git show`.

set -euo pipefail

./bump.fnl --bump bump.fnl "$@"
./bump.fnl --bump CHANGELOG.md "$@"

make

git add bump.fnl README.md CHANGELOG.md

version="$(fennel -e '(. (require :bump) :version)')"
is_release="$(fennel -e '(let [b (require :bump)] (b.release? b.version))')"
if [[ "$is_release" = "true" ]]
then
    git commit -m "release: $version"
    git tag "v$version"
else
    git commit -m "prerelease: $version"
fi
