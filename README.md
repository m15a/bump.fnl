# Bump.fnl (0.5.0)

bump.fnl - bump version and changelog.

<https://sr.ht/~m15a/bump.fnl>

[![ci]][status]

[ci]: https://builds.sr.ht/~m15a/bump.fnl/commits/main/ci.yml.svg
[status]: https://builds.sr.ht/~m15a/bump.fnl/commits/main/ci.yml

## Synopsis

    $ bump 1.2.3-dev # Drop pre-release label by default.
    1.2.3

    $ bump 1.2.3-dev --major # or -M
    2.0.0-dev

    $ bump 1.2.3-dev --minor # or -m
    1.3.0-dev

    $ bump 1.2.3-dev --patch # or -p
    1.2.4-dev

    $ bump 1.2.3 --dev
    1.2.4-dev

    $ bump 1.2.3 --any-string
    1.2.4-any-string

    $ bump bump.fnl && git diff

```diff
diff --git a/bump.fnl b/bump.fnl
index cefa8b4..c477853 100755
--- a/bump.fnl
+++ b/bump.fnl
@@ -95,7 +95,7 @@
 
 ;;;; ## API documentation
 
-(local version :0.4.0-dev)
+(local version :0.4.0)
 
 (local {: view : dofile} (require :fennel))
 
```

    $ bump CHANGELOG.md && git diff

```diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index a5a8b31..92c350a 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -8,7 +8,7 @@ and this project adheres to [Semantic Versioning][2].
 [1]: https://keepachangelog.com/en/1.1.0/
 [2]: https://semver.org/spec/v2.0.0.html
 
-## [0.4.0-dev] - ???
+## [0.4.0] - 2024-03-26 +0900
 
 ## [0.3.1] - 2024-03-22 +0900
 
@@ -57,7 +57,7 @@ and this project adheres to [Semantic Versioning][2].
 
 - Script to bump version string easily.
 
-[0.4.0-dev]: https://git.sr.ht/~m15a/bump.fnl/refs/HEAD
+[0.4.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.4.0
 [0.3.1]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.3.1
 [0.3.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.3.0
 [0.2.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.2.0
```

## Description

`bump.fnl` bumps version string and changelog. You can use it in
command line as shown in [Synopsis](#synopsis): it can

- bump command line argument version string,
- bump version string contained in any file, or
- edit Markdown changelog according to intended version bumping
  (**experimental feature**).

See an example usage [`./example.bash`](./example.bash).

It is also a library for general-purpose [SemVer] version string
manipulation. It provides functions to

- compose and decompose version string from/to table containing
  major, minor, patch numbers, prerelease label, and build meta tag;
- compare and query version strings;
- bump version string; and
- parse text to search for version strings.

See [API documentation](#api-documentation) for more details.

[SemVer]: https://semver.org/

### Requirements

- [PUC Lua] 5.1+ or [LuaJIT]: runtime dependency.
- [Fennel] 1.4.2+: only for compiling to Lua script or using as a library.
  Not tested but it might even work with older versions.
- [GNU make]: only for compilation.

[PUC Lua]: https://www.lua.org/
[LuaJIT]: https://luajit.org/
[Fennel]: https://fennel-lang.org/
[GNU make]: https://www.gnu.org/software/make/

### Installation

Run `make` and then you will find a Lua executable script `bin/bump`.
Install it anywhere:

    $ make install PREFIX=$YOUR_FAVORITE_PATH

To use it as a library, copy [`./bump.fnl`](./bump.fnl) to your favorite
path. Make sure that it is on Fennel search path, or add it to
environment variable `$FENNEL_PATH`.

#### Docker

Run `make docker-image` and then you will get `bump.fnl:latest` image.
You might want to make a wrapper shell script:

```sh
#!/bin/sh
exec docker run -t --rm -v $PWD:/work bump.fnl "$@"
```

#### Nix

To try `bump.fnl` one time, run

    $ nix run sourcehut:~m15a/bump.fnl -- --help

To use it as an overlay,

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    bumpfnl.url = "sourcehut:~m15a/bumpfnl/main";
    ...
  };
  ...
  outputs = inputs @ { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            ...
            inputs.bumpfnl.overlays.default
          ];
        };
      in
      {
        devShells.default = {
          buildInputs = [
            ...
            pkgs.bumpfnl
          ];
        };
      });
}
```


## API documentation

**Table of contents**

- Function: [bump/major](#function-bumpmajor)
- Function: [bump/minor](#function-bumpminor)
- Function: [bump/patch](#function-bumppatch)
- Function: [bump/prerelease](#function-bumpprerelease)
- Function: [bump/release](#function-bumprelease)
- Function: [compose](#function-compose)
- Function: [decompose](#function-decompose)
- Function: [gparse](#function-gparse)
- Function: [parse](#function-parse)
- Function: [prerelease?](#function-prerelease)
- Function: [release?](#function-release)
- Function: [version<](#function-version)
- Function: [version<=](#function-version-1)
- Function: [version<>](#function-version-1)
- Function: [version=](#function-version-1)
- Function: [version>](#function-version-1)
- Function: [version>=](#function-version-1)
- Function: [version?](#function-version-1)

### Function: bump/major

```fennel
(bump/major version)
```

Bump major version number in the `version` string.

#### Example

```fennel
(bump/major "0.9.28") ;=> "1.0.0"
```

### Function: bump/minor

```fennel
(bump/minor version)
```

Bump minor version number in the `version` string.

#### Example

```fennel
(bump/minor "0.9.28") ;=> "0.10.0"
```

### Function: bump/patch

```fennel
(bump/patch version)
```

Bump patch version number in the `version` string.

#### Example

```fennel
(bump/patch "0.9.28") ;=> "0.9.29"
```

### Function: bump/prerelease

```fennel
(bump/prerelease version ?prerelease)
```

Append `?prerelease` label (default: `dev`) to the `version` string.

Besides, it strips build tag and increments patch version number.
If you like to increment other than patch number, compose it with any other
`bump/*` function.

#### Examples

```fennel
(bump/prerelease "1.2.0") ;=> "1.2.1-dev"
(bump/prerelease "1.2.0" :alpha) ;=> "1.2.1-alpha"

(-> "1.1.4"
    bump/prerelease
    bump/minor)
;=> "1.2.0-dev"
```

### Function: bump/release

```fennel
(bump/release version)
```

Strip pre-release and/or build label(s) from the `version` string.

#### Example

```fennel
(bump/release "1.2.1-dev+001") ;=> "1.2.1"
```

### Function: compose

```fennel
(compose {:build build :major major :minor minor :patch patch :prerelease prerelease})
```

Compose version string from a table that contains:

- `major`: major version,
- `minor`: minor version,
- `patch`: patch version, and
- `prerelease`: suffix label that implies pre-release version (optional).
- `build`: suffix label that attaches build meta information (optional).

#### Example

```fennel
(compose {:major 0 :minor 1 :patch 0 :prerelease :dev})
;=> "0.1.0-dev"
```

### Function: decompose

```fennel
(decompose version)
```

Decompose `version` string to a table containing its components.

See [`compose`](#function-compose) for components' detail.

#### Examples

```fennel
(decompose "1.1.0-rc.1")
;=> {:major 1 :minor 1 :patch 0 :prerelease :rc.1}

(decompose "0.3.1-dev+001")
;=> {:major 0 :minor 3 :patch 1 :prerelease :dev :build :001}
```

### Function: gparse

```fennel
(gparse text)
```

Return an iterator that returns version strings in the `text` one by one.

#### Example

```fennel
(let [text "4.5.6.7 1.2.3+m 4.3.2a v1.2.3 1.2.3-dev+a2"]
  (doto (icollect [v (gparse text)] v)
    table.sort))
;=> ["1.2.3" "1.2.3+m" "1.2.3-dev+a2"]
```

### Function: parse

```fennel
(parse text ?init)
```

Return the first version string found in the `text`.

Version string in version tag (e.g., `v1.2.3`) will also be picked up.
Optional `?init` specifies where to start the search (default: 1).

#### Examples

```fennel
(parse " v1.0.0 1.0.0-alpha 1.0.1") ;=> "1.0.0"
(parse "1.0.0 2.0.0" 2) ;=> "2.0.0"
```

### Function: prerelease?

```fennel
(prerelease? x)
```

If `x` is a prerelease version string, return `true`; otherwise `false`.

#### Examples

```fennel
(prerelease? "1.0.0+sha.a1bf00a") ;=> false
(prerelease? "1.0.0-alpha") ;=> true
```

### Function: release?

```fennel
(release? x)
```

If `x` is a release version string, return `true`; otherwise `false`.

#### Examples

```fennel
(release? "1.0.0+sha.a1bf00a") ;=> true
(release? "1.0.0-alpha") ;=> false
```

### Function: version<

```fennel
(version< left right)
```

Return `true` if `left` version is older than `right`; otherwise `false`.

#### Examples

```fennel
(version< :1.0.0-alpha :1.0.0-alpha.1) ;=> true
(version< :1.0.0-alpha.1 :1.0.0-alpha.beta) ;=> true
(version< :1.0.0-alpha.beta :1.0.0-beta) ;=> true
(version< :1.0.0-beta.2 :1.0.0-beta.11) ;=> true
(version< :1.0.0-beta.11 :1.0.0-rc.1) ;=> true
(version< :1.0.0-rc.1 :1.0.0) ;=> true
```

### Function: version<=

```fennel
(version<= left right)
```

Return `true` if `left` version is older than or equal to `right`.

Otherwise `false`.

### Function: version<>

```fennel
(version<> left right)
```

Return `true` if `left` and `right` versions have different precedence.

Otherwise `false`. Note that build tags are ignored for version comparison.

#### Example

```fennel
(version<> :1.0.0-alpha+001 :1.0.0-alpha+100) ;=> false
```

### Function: version=

```fennel
(version= left right)
```

Return `true` if `left` and `right` versions have the same precedence.

Otherwise `false`. Note that build tags are ignored for version comparison.

#### Example

```fennel
(version= :1.0.0-alpha+001 :1.0.0-alpha+010) ;=> true
```

### Function: version>

```fennel
(version> left right)
```

Return `true` if `left` version is newer than `right`; otherwise `false`.

### Function: version>=

```fennel
(version>= left right)
```

Return `true` if `left` version is newer than or equal to `right`.

Otherwise `false`.

### Function: version?

```fennel
(version? x)
```

If `x` is a version string, return `true`; otherwise return `false`.

#### Examples

```fennel
(version? "1.2.3-dev+111") ;=> true
(version? {:major 1 :minor 2 :patch 3}) ;=> false
```

---

Copyright (c) 2024 NACAMURA Mitsuhiro

License: [BSD 3-clause](./LICENSE)

<!-- Generated with Fnldoc 1.1.0-dev-943d87c
     https://sr.ht/~m15a/fnldoc/ -->
