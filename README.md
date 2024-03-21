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

## Description

This is a [Fennel] script to bump version string in command line.
You can use it in command line as shown in [Synopsis](#synopsis).
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
(bump/prerelease version ?label)
```

Append pre-release `?label` (default: `dev`) to the `version` string.

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

Strip pre-release label from the `version` string.

#### Example

```fennel
(assert (= "1.2.1" (bump/release "1.2.1-dev")))
```

### Function: compose

```fennel
(compose {:label label :major major :minor minor :patch patch})
```

Compose version string from a table that contains:

- `major`: major version,
- `minor`: minor version,
- `patch`: patch version, and
- `label`: suffix label that implies pre-release version (optional).

#### Example

```fennel
(assert (= "0.1.0-dev"
           (compose {:major 0 :minor 1 :patch 0 :label :dev})))
```

### Function: decompose

```fennel
(decompose version)
```

Decompose `version` string to a table containing its components.

See [`compose`](#function-compose) for components' detail.

#### Example

```fennel
(let [decomposed (decompose "0.1.0-dev")]
  (assert (= 0 decomposed.major))
  (assert (= 1 decomposed.minor))
  (assert (= 0 decomposed.patch))
  (assert (= :dev decomposed.label)))
```

---

Copyright (c) 2024 NACAMURA Mitsuhiro

License: [BSD 3-clause](./LICENSE)

<!-- Generated with Fnldoc 1.1.0-dev-943d87c
     https://sr.ht/~m15a/fnldoc/ -->
