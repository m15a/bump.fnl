#!/usr/bin/env bash

# This script will bump version in bump.fnl and CHANGELOG.md
# (and optionally README.md).
# Arguments to this script are passed to ./bump.fnl.
# Say, you want to bump major version, then try
#
#     $ ./example.bash --major
#
# and see what changed by `git show`.

set -euo pipefail

./bump.fnl --bump bump.fnl "$@"
./bump.fnl --bump CHANGELOG.md "$@"

type -fP fnldoc && make readme

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
