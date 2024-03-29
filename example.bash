#!/usr/bin/env bash

# This script will bump version in bump.fnl and CHANGELOG.md
# (and optionally README.md).
# Arguments to this script are passed to executable ./bin/bump,
# which will be built from Fennel sources.
#
# Say, you want to bump major version, then try
#
#     $ ./example.bash --major
#
# and see what changed by `git show`.

set -euo pipefail

make build

files=(bump.fnl CHANGELOG.md nix/versions.json)
for file in "${files[@]}"
do
    ./bin/bump "$file" "$@"
done
git add "${files[@]}"

if type -fP fnldoc
then
    make readme
    git add README.md
fi

version="$(fennel -e '(. (require :bump) :version)')"
is_release="$(fennel -e '(let [b (require :bump)] (b.release? b.version))')"
if [[ "$is_release" = "true" ]]
then
    git commit -m "release: $version"
    git tag "v$version"
else
    git commit -m "prerelease: $version"
fi
