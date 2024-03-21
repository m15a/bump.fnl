# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1],
and this project adheres to [Semantic Versioning][2].

[1]: <https://keepachangelog.com/en/1.1.0/>
[2]: <https://semver.org/spec/v2.0.0.html>

## [0.3.0-dev] - ???

### Changed

- `compose` and `decompose`: `:label` entry has been replaced with
  `:prerelease` and `:build` entries in favor of SemVer standard.

## [0.2.0] - 2024-03-21 +0900

### Added

- Chained version bumping via command line options
- `--ANYLABEL` option to bump to pre-release version:
  `ANYLABEL` can be `dev`, `alpha`, or `anything`, which will be
  appended with prefix `-` after patch number.

## [0.1.0] - 2024-03-20 +0900

### Added

- Script to bump version string easily.

[0.3.0-dev]: <https://git.sr.ht/~m15a/bump.fnl/refs/HEAD>
[0.2.0]: <https://git.sr.ht/~m15a/bump.fnl/refs/v0.2.0>
[0.1.0]: <https://git.sr.ht/~m15a/bump.fnl/refs/v0.1.0>

<!-- vim: set tw=72 spell: -->
