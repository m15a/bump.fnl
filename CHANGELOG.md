# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1],
and this project adheres to [Semantic Versioning][2].

[1]: https://keepachangelog.com/en/1.1.0/
[2]: https://semver.org/spec/v2.0.0.html

## [0.5.3-dev] - ???

## [0.5.2] - 2024-03-30 +0900

### Fixed

- Nix: failed patchShebangs [27f0779].

[27f0779]: https://git.sr.ht/~m15a/bump.fnl/commit/27f0779

## [0.5.1] - 2024-03-29 +0900

### Fixed

- Nix: infinite recursion in app derivation [00ef077].

[00ef077]: https://git.sr.ht/~m15a/bump.fnl/commit/00ef077

## [0.5.0] - 2024-03-29 +0900

### Changed

- Compile to Lua executable [#8]:
  To run CLI, `./bin/bump ...` instead of `./bump.fnl --bump ...`.

### Packaging

- Add `docker/Dockerfile` [#9]: `make docker-image` and run
  `docker run -t --rm -v $PWD:/work bump.fnl ARG...`.
- Add Nix package [#10]: in the overlay, the package can be found at
  attribute `pkgs.bumpfnl`. To try it one time, run
  `nix run sourcehut:~m15a/bump.fnl -- --help`

[#8]: https://todo.sr.ht/~m15a/bump.fnl/8
[#9]: https://todo.sr.ht/~m15a/bump.fnl/9
[#10]: https://todo.sr.ht/~m15a/bump.fnl/10

## [0.4.1] - 2024-03-28 +0900

### Fixed

- Stop bumping when old and new versions are the same [b642de3].
- Bumping strategy inference [588af18]
- `parse`, `gparse`: pick up version tags (e.g., `v1.2.3`) [9c801c0].

[b642de3]: https://git.sr.ht/~m15a/bump.fnl/commit/b642de3
[588af18]: https://git.sr.ht/~m15a/bump.fnl/commit/588af18
[9c801c0]: https://git.sr.ht/~m15a/bump.fnl/commit/9c801c0

## [0.4.0] - 2024-03-26 +0900

### Added

- **Experimental**: Support to bump changelog file [#4]

### Fixed

- `compose`, `bump/prerelease`: raise error when `:prerelease` or
  `:build` entry is not string or number [1fbba60].

[1fbba60]: https://git.sr.ht/~m15a/bump.fnl/commit/1fbba60

## [0.3.1] - 2024-03-22 +0900

### Fixed

- `bump.bash`: incorrect link generation [0aac0c0]

[0aac0c0]: https://git.sr.ht/~m15a/bump.fnl/commit/0aac0c0

## [0.3.0] - 2024-03-22 +0900

### Changed

- `compose` and `decompose`: `:label` entry has been replaced with
  `:prerelease` and `:build` entries in favor of SemVer standard [#5].

[#5]: https://todo.sr.ht/~m15a/bump.fnl/5

### Added

- Support to bump version string in Fennel script file [#4]
- Version comparators conforming to SemVer [db7828b]
- Functions `parse` and `gparse` to find version(s) in string [01efb5c]
- Predicates `release?` and `prerelease?` [6e5013b]

[#4]: https://todo.sr.ht/~m15a/bump.fnl/4
[db7828b]: https://git.sr.ht/~m15a/bump.fnl/commit/db7828b
[01efb5c]: https://git.sr.ht/~m15a/bump.fnl/commit/01efb5c
[6e5013b]: https://git.sr.ht/~m15a/bump.fnl/commit/6e5013b

## [0.2.0] - 2024-03-21 +0900

### Added

- Chained version bumping via command line options [#3]
- `--ANYLABEL` option to bump to pre-release version [#1]:
  `ANYLABEL` can be `dev`, `alpha`, or `anything`, which will be
  appended with prefix `-` after patch number.

[#3]: https://todo.sr.ht/~m15a/bump.fnl/3
[#1]: https://todo.sr.ht/~m15a/bump.fnl/1

## [0.1.0] - 2024-03-20 +0900

### Added

- Script to bump version string easily.

[0.5.3-dev]: https://git.sr.ht/~m15a/bump.fnl/refs/HEAD
[0.5.2]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.5.2
[0.5.1]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.5.1
[0.5.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.5.0
[0.4.1]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.4.1
[0.4.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.4.0
[0.3.1]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.3.1
[0.3.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.3.0
[0.2.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.2.0
[0.1.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.1.0

<!-- vim: set tw=72 spell: -->
