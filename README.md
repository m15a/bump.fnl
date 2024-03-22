# Bump.fnl (0.3.0-dev)

bump.fnl - a tiny helper for version bumping.

<https://sr.ht/~m15a/bump.fnl>

## Synopsis

    $ ./bump.fnl --bump 1.2.3-dev # Drop pre-release label by default.
    1.2.3

    $ ./bump.fnl --bump 1.2.3-dev --major # or -M
    2.0.0-dev

    $ ./bump.fnl --bump 1.2.3-dev --minor # or -m
    1.3.0-dev

    $ ./bump.fnl --bump 1.2.3-dev --patch # or -p
    1.2.4-dev

    $ ./bump.fnl --bump 1.2.3 --dev
    1.2.4-dev

    $ ./bump.fnl --bump 1.2.3 --any-string
    1.2.4-any-string

    $ ./bump.fnl --bump 1.2.3 --chain --minor --minor
    1.4.0-chain

    $ ./bump.fnl --bump bump.fnl --major
    $ grep 'local version' bump.fnl
    (local version :2.0.0-dev)

## Description

This is a [Fennel] script to bump version string. You can use it in
command line as shown in [Synopsis](#synopsis); it can bump version
of command line argument string, or version string contained in a file.
See an example usage [`./bump.bash`](./bump.bash).

It also can be used as a library to compose, decompose, or bump version
string. See [API documentation](#api-documentation) for more
details.

[Fennel]: https://fennel-lang.org/


## API documentation

**Table of contents**

- Function: [bump/major](#function-bumpmajor)
- Function: [bump/minor](#function-bumpminor)
- Function: [bump/patch](#function-bumppatch)
- Function: [bump/prerelease](#function-bumpprerelease)
- Function: [bump/release](#function-bumprelease)
- Function: [compose](#function-compose)
- Function: [decompose](#function-decompose)
- Function: [version?](#function-version)

### Function: bump/major

```fennel
(bump/major version)
```

Bump major version number in the `version` string.

#### Example

```fennel
(assert (= "1.0.0" (bump/major "0.9.28")))
```

### Function: bump/minor

```fennel
(bump/minor version)
```

Bump minor version number in the `version` string.

#### Example

```fennel
(assert (= "0.3.0-dev" (bump/minor "0.2.3-dev")))
```

### Function: bump/patch

```fennel
(bump/patch version)
```

Bump patch version number in the `version` string.

#### Example

```fennel
(assert (= "0.6.1-alpha" (bump/patch "0.6.0-alpha")))
```

### Function: bump/prerelease

```fennel
(bump/prerelease version ?prerelease)
```

Append `?prerelease` label (default: `dev`) to the `version` string.

Besides, it increments patch version number. If you like to increment
other than patch number, compose it with any other `bump/*` function.

#### Example

```fennel
(assert (= "1.2.1-dev" (bump/prerelease "1.2.0")))
(assert (= "1.2.1-alpha" (bump/prerelease "1.2.0" :alpha)))

(assert (= "1.2.0-dev" (-> "1.1.4"
                           bump/prerelease
                           bump/minor)))
```

### Function: bump/release

```fennel
(bump/release version)
```

Strip pre-release and/or build label(s) from the `version` string.

#### Example

```fennel
(assert (= "1.2.1" (bump/release "1.2.1-dev+001")))
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

#### Examples

```fennel
(assert (= "0.1.0-dev"
           (compose {:major 0 :minor 1 :patch 0
                     :prerelease :dev})))
(assert (= "0.1.0+rc1"
           (compose {:major 0 :minor 1 :patch 0
                     :build :rc1})))
(assert (= "0.1.0-test-case+exp.1"
           (compose {:major 0 :minor 1 :patch 0
                     :prerelease :test-case :build :exp.1})))
```

### Function: decompose

```fennel
(decompose version)
```

Decompose `version` string to a table containing its components.

See [`compose`](#function-compose) for components' detail.

#### Examples

```fennel
(let [decomposed (decompose "0.1.0-dev")]
  (assert (= 0 decomposed.major))
  (assert (= 1 decomposed.minor))
  (assert (= 0 decomposed.patch))
  (assert (= :dev decomposed.prerelease)))

(let [decomposed (decompose "0.1.0-dev-1+0.0.1")]
  (assert (= 0 decomposed.major))
  (assert (= 1 decomposed.minor))
  (assert (= 0 decomposed.patch))
  (assert (= :dev-1 decomposed.prerelease))
  (assert (= :0.0.1 decomposed.build)))

(let [(ok? msg) (pcall decompose "0.0.1+a+b")]
  (assert (and (= false ok?)
               (= "expected one build tag, found many: 0.0.1+a+b" msg))))

(let [(ok? msg) (pcall decompose "0.0.1=dev")]
  (assert (and (= false ok?)
               (= "invalid pre-release label and/or build tag: 0.0.1=dev" msg))))
```

### Function: version?

```fennel
(version? x)
```

If `x` is a version string, return `true`; otherwise return `false`.

#### Examples

```fennel
(assert (= true (version? "1.2.3-dev+111")))
(assert (= false (version? "pineapple")))
(assert (= false (version? {:major 1 :minor 2 :patch 3})))
```

---

Copyright (c) 2024 NACAMURA Mitsuhiro

License: [BSD 3-clause](./LICENSE)

<!-- Generated with Fnldoc 1.1.0-dev-943d87c
     https://sr.ht/~m15a/fnldoc/ -->
