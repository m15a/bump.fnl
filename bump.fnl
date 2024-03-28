#!/usr/bin/env fennel

;;;; bump.fnl - bump version and changelog.
;;;;
;;;; <https://sr.ht/~m15a/bump.fnl>
;;;;
;;;; [![ci]][status]
;;;;
;;;; [ci]: https://builds.sr.ht/~m15a/bump.fnl/commits/main/ci.yml.svg
;;;; [status]: https://builds.sr.ht/~m15a/bump.fnl/commits/main/ci.yml

;;;; ## Synopsis
;;;;
;;;;     $ bump 1.2.3-dev # Drop pre-release label by default.
;;;;     1.2.3
;;;;
;;;;     $ bump 1.2.3-dev --major # or -M
;;;;     2.0.0-dev
;;;;
;;;;     $ bump 1.2.3-dev --minor # or -m
;;;;     1.3.0-dev
;;;;
;;;;     $ bump 1.2.3-dev --patch # or -p
;;;;     1.2.4-dev
;;;;
;;;;     $ bump 1.2.3 --dev
;;;;     1.2.4-dev
;;;;
;;;;     $ bump 1.2.3 --any-string
;;;;     1.2.4-any-string
;;;;
;;;;     $ bump bump.fnl && git diff
;;;;
;;;; ```diff
;;;; diff --git a/bump.fnl b/bump.fnl
;;;; index cefa8b4..c477853 100755
;;;; --- a/bump.fnl
;;;; +++ b/bump.fnl
;;;; @@ -95,7 +95,7 @@
;;;;  
;;;;  ;;;; ## API documentation
;;;;  
;;;; -(local version :0.4.0-dev)
;;;; +(local version :0.4.0)
;;;;  
;;;;  (local {: view : dofile} (require :fennel))
;;;;  
;;;; ```
;;;;
;;;;     $ bump CHANGELOG.md && git diff
;;;;
;;;; ```diff
;;;; diff --git a/CHANGELOG.md b/CHANGELOG.md
;;;; index a5a8b31..92c350a 100644
;;;; --- a/CHANGELOG.md
;;;; +++ b/CHANGELOG.md
;;;; @@ -8,7 +8,7 @@ and this project adheres to [Semantic Versioning][2].
;;;;  [1]: https://keepachangelog.com/en/1.1.0/
;;;;  [2]: https://semver.org/spec/v2.0.0.html
;;;;  
;;;; -## [0.4.0-dev] - ???
;;;; +## [0.4.0] - 2024-03-26 +0900
;;;;  
;;;;  ## [0.3.1] - 2024-03-22 +0900
;;;;  
;;;; @@ -57,7 +57,7 @@ and this project adheres to [Semantic Versioning][2].
;;;;  
;;;;  - Script to bump version string easily.
;;;;  
;;;; -[0.4.0-dev]: https://git.sr.ht/~m15a/bump.fnl/refs/HEAD
;;;; +[0.4.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.4.0
;;;;  [0.3.1]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.3.1
;;;;  [0.3.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.3.0
;;;;  [0.2.0]: https://git.sr.ht/~m15a/bump.fnl/refs/v0.2.0
;;;; ```

;;;; ## Description
;;;;
;;;; `bump.fnl` bumps version string and changelog. You can use it in
;;;; command line as shown in [Synopsis](#synopsis): it can
;;;;
;;;; - bump command line argument version string,
;;;; - bump version string contained in any file, or
;;;; - edit Markdown changelog according to intended version bumping
;;;;   (**experimental feature**).
;;;;
;;;; See an example usage [`./example.bash`](./example.bash).
;;;;
;;;; It is also a library for general-purpose [SemVer] version string
;;;; manipulation. It provides functions to
;;;;
;;;; - compose and decompose version string from/to table containing
;;;;   major, minor, patch numbers, prerelease label, and build meta tag;
;;;; - compare and query version strings;
;;;; - bump version string; and
;;;; - parse text to search for version strings.
;;;;
;;;; See [API documentation](#api-documentation) for more details.
;;;;
;;;; [SemVer]: https://semver.org/
;;;;
;;;; ### Requirements
;;;;
;;;; - [PUC Lua] 5.1+ or [LuaJIT]: runtime dependency.
;;;; - [Fennel] 1.4.2+: only for compiling to Lua script or using as a library.
;;;;   Not tested but it might even work with older versions.
;;;; - [GNU make]: only for compilation.
;;;;
;;;; [PUC Lua]: https://www.lua.org/
;;;; [LuaJIT]: https://luajit.org/
;;;; [Fennel]: https://fennel-lang.org/
;;;; [GNU make]: https://www.gnu.org/software/make/
;;;;
;;;; ### Installation
;;;;
;;;; Run `make` and then you will find a Lua executable script `bin/bump`.
;;;; Install it anywhere:
;;;;
;;;;     $ make install PREFIX=$YOUR_FAVORITE_PATH
;;;;
;;;; To use it as a library, copy [`./bump.fnl`](./bump.fnl) to your favorite
;;;; path. Make sure that it is on Fennel search path, or add it to
;;;; environment variable `$FENNEL_PATH`.

;;; BSD 3-Clause License
;;;
;;; Copyright (c) 2024 NACAMURA Mitsuhiro
;;; 
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;; 
;;; 1. Redistributions of source code must retain the above copyright notice,
;;;    this list of conditions and the following disclaimer.
;;; 
;;; 2. Redistributions in binary form must reproduce the above copyright notice,
;;;    this list of conditions and the following disclaimer in the documentation
;;;    and/or other materials provided with the distribution.
;;; 
;;; 3. Neither the name of the copyright holder nor the names of its
;;;    contributors may be used to endorse or promote products derived from
;;;    this software without specific prior written permission.
;;; 
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

;;;; ## API documentation

(local version :0.5.0-dev)

(local {: view} (require :fennel))

(fn decompose [version]
  "Decompose `version` string to a table containing its components.

See `compose' for components' detail.

# Examples

```fennel
(decompose \"1.1.0-rc.1\")
;=> {:major 1 :minor 1 :patch 0 :prerelease :rc.1}

(decompose \"0.3.1-dev+001\")
;=> {:major 0 :minor 3 :patch 1 :prerelease :dev :build :001}
```"
  (when (not= :string (type version))
    (error (.. "version string expected, got " (view version))))
  (let [v {:major (tonumber (version:match "^%d+"))
           :minor (tonumber (version:match "^%d+%.(%d+)"))
           :patch (tonumber (version:match "^%d+%.%d+%.(%d+)"))
           :prerelease (version:match "^%d+%.%d+%.%d+%-([%w][%-%.%w]*)")
           :build
           (or
             (version:match "^%d+%.%d+%.%d+%-[%w][%-%.%w]*%+([%w][%-%+%.%w]*)")
             (version:match "^%d+%.%d+%.%d+%+([%w][%-%+%.%w]*)"))}
        label (let [rest (version:match "^%d+%.%d+%.%d+(.*)$")]
                (if (= "" rest) nil rest))]
    (if (and label (not v.prerelease) (not v.build))
        (error (.. "invalid pre-release label and/or build tag: " version))
        (and label v.prerelease v.build
             (not= label (.. "-" v.prerelease "+" v.build)))
        (error (.. "invalid pre-release label and/or build tag: " version))
        (and label v.prerelease (not v.build)
             (not= label (.. "-" v.prerelease)))
        (error (.. "invalid pre-release label: " version))
        (and label (not v.prerelease) v.build
             (not= label (.. "+" v.build)))
        (error (.. "invalid build tag: " version))
        (and v.build (string.match v.build "%+"))
        (error (.. "expected one build tag, found many: " version))
        (and v.major v.minor v.patch)
        v
        (error (.. "version missing some component(s): " version)))))

(fn compose [{: major : minor : patch : prerelease : build}]
  "Compose version string from a table that contains:

- `major`: major version,
- `minor`: minor version,
- `patch`: patch version, and
- `prerelease`: suffix label that implies pre-release version (optional).
- `build`: suffix label that attaches build meta information (optional).

# Example

```fennel
(compose {:major 0 :minor 1 :patch 0 :prerelease :dev})
;=> \"0.1.0-dev\"
```"
  (let [major* (tonumber major)
        minor* (tonumber minor)
        patch* (tonumber patch)
        prerelease* (when (not= nil prerelease)
                      (case (type prerelease)
                        :string prerelease
                        :number (tostring prerelease)))
        build* (when (not= nil build)
                 (case (type build)
                   :string build
                   :number (tostring build)))]
    (when (not (and major* minor* patch*
                    (or (= nil prerelease) prerelease*)
                    (or (= nil build) build*)))
      (error (.. "invalid version component(s): "
                 (view {: major : minor : patch : prerelease : build}))))
    (let [version-core (.. major* "." minor* "." patch*)]
      (if (and prerelease* build*)
          (.. version-core "-" prerelease* "+" build*)
          prerelease*
          (.. version-core "-" prerelease*)
          build*
          (.. version-core "+" build*)
          version-core))))

(fn version? [x]
  "If `x` is a version string, return `true`; otherwise return `false`.

# Examples

```fennel
(version? \"1.2.3-dev+111\") ;=> true
(version? {:major 1 :minor 2 :patch 3}) ;=> false
```"
  (case (type x)
    :string (pick-values 1 (pcall decompose x))
    _ false))

(fn release? [x]
  "If `x` is a release version string, return `true`; otherwise `false`.

# Examples

```fennel
(release? \"1.0.0+sha.a1bf00a\") ;=> true
(release? \"1.0.0-alpha\") ;=> false
```"
  (case-try (type x)
    :string (pcall decompose x)
    (true v) (if v.prerelease false true)
    (catch _ false)))

(fn prerelease? [x]
  "If `x` is a prerelease version string, return `true`; otherwise `false`.

# Examples

```fennel
(prerelease? \"1.0.0+sha.a1bf00a\") ;=> false
(prerelease? \"1.0.0-alpha\") ;=> true
```"
  (case-try (type x)
    :string (pcall decompose x)
    (true v) (if v.prerelease true false)
    (catch _ false)))

(fn prerelease< [left right]
  "Return `true` if `left` pre-release label is older than `right`.

Otherwise return `false`. This is very complicated.
See [SemVer spec](https://semver.org/#spec-item-11)."
  (let [left-ids (icollect [id (left:gmatch "[^%.]+")] id)
        right-ids (icollect [id (right:gmatch "[^%.]+")] id)
        n (math.min (length left-ids) (length right-ids))]
    (var answer nil)
    (for [i 1 n &until (not= nil answer)]
      (let [lid (. left-ids i) rid (. right-ids i)]
        (case (values (tonumber lid) (tonumber rid))
          (m n) (if (< m n) (set answer true)
                    (> m n) (set answer false))
          (m ?n) (set answer true)
          (?m n) (set answer false)
          _ (if (< lid rid) (set answer true)
                (> lid rid) (set answer false)))))
    (if (not= nil answer) answer
        (. right-ids (+ n 1)) true
        false)))

(fn version< [left right]
  "Return `true` if `left` version is older than `right`; otherwise `false`.

# Examples

```fennel
(version< :1.0.0-alpha :1.0.0-alpha.1) ;=> true
(version< :1.0.0-alpha.1 :1.0.0-alpha.beta) ;=> true
(version< :1.0.0-alpha.beta :1.0.0-beta) ;=> true
(version< :1.0.0-beta.2 :1.0.0-beta.11) ;=> true
(version< :1.0.0-beta.11 :1.0.0-rc.1) ;=> true
(version< :1.0.0-rc.1 :1.0.0) ;=> true
```"
  (let [left (decompose left)
        right (decompose right)]
    (if (< left.major right.major) true
        (> left.major right.major) false
        (< left.minor right.minor) true
        (> left.minor right.minor) false
        (< left.patch right.patch) true
        (> left.patch right.patch) false
        (and left.prerelease (not right.prerelease)) true
        (not left.prerelease) false
        (prerelease< left.prerelease right.prerelease))))

(fn version<= [left right]
  "Return `true` if `left` version is older than or equal to `right`.

Otherwise `false`."
  (not (version< right left)))

(fn version> [left right]
  "Return `true` if `left` version is newer than `right`; otherwise `false`."
  (version< right left))

(fn version>= [left right]
  "Return `true` if `left` version is newer than or equal to `right`.

Otherwise `false`."
  (not (version< left right)))

(fn version<> [left right]
  "Return `true` if `left` and `right` versions have different precedence.

Otherwise `false`. Note that build tags are ignored for version comparison.

# Example

```fennel
(version<> :1.0.0-alpha+001 :1.0.0-alpha+100) ;=> false
```"
  (or (version< left right) (version< right left)))

(fn version= [left right]
  "Return `true` if `left` and `right` versions have the same precedence.

Otherwise `false`. Note that build tags are ignored for version comparison.

# Example

```fennel
(version= :1.0.0-alpha+001 :1.0.0-alpha+010) ;=> true
```"
  (not (or (version< left right) (version< right left))))

(fn bump/major [version]
  "Bump major version number in the `version` string.

# Example

```fennel
(bump/major \"0.9.28\") ;=> \"1.0.0\"
```"
  (let [version (decompose version)]
    (compose (doto version
               (tset :major (+ version.major 1))
               (tset :minor 0)
               (tset :patch 0)))))

(fn bump/minor [version]
  "Bump minor version number in the `version` string.

# Example

```fennel
(bump/minor \"0.9.28\") ;=> \"0.10.0\"
```"
  (let [version (decompose version)]
    (compose (doto version
               (tset :minor (+ version.minor 1))
               (tset :patch 0)))))

(fn bump/patch [version]
  "Bump patch version number in the `version` string.

# Example

```fennel
(bump/patch \"0.9.28\") ;=> \"0.9.29\"
```"
  (let [version (decompose version)]
    (compose (doto version
               (tset :patch (+ version.patch 1))))))

(fn bump/release [version]
  "Strip pre-release and/or build label(s) from the `version` string.

# Example

```fennel
(bump/release \"1.2.1-dev+001\") ;=> \"1.2.1\"
```"
  (compose (doto (decompose version)
             (tset :prerelease nil)
             (tset :build nil))))

(fn bump/prerelease [version ?prerelease]
  "Append `?prerelease` label (default: `dev`) to the `version` string.

Besides, it strips build tag and increments patch version number.
If you like to increment other than patch number, compose it with any other
`bump/*` function.

# Examples

```fennel
(bump/prerelease \"1.2.0\") ;=> \"1.2.1-dev\"
(bump/prerelease \"1.2.0\" :alpha) ;=> \"1.2.1-alpha\"

(-> \"1.1.4\"
    bump/prerelease
    bump/minor)
;=> \"1.2.0-dev\"
```"
  (let [version (decompose version)
        prerelease (if (= nil ?prerelease)
                       :dev
                       (case (type ?prerelease)
                         :string ?prerelease
                         :number (tostring ?prerelease)))]
    (when (not (and prerelease (< 0 (length prerelease))))
      (error (.. "invalid pre-release label: " (view ?prerelease))))
    (compose (doto version
               (tset :patch (+ version.patch 1))
               (tset :prerelease prerelease)
               (tset :build nil)))))

(fn parse [text ?init]
  "Return the first version string found in the `text`.

Version string in version tag (e.g., `v1.2.3`) will also be picked up.
Optional `?init` specifies where to start the search (default: 1).

# Examples

```fennel
(parse \" v1.0.0 1.0.0-alpha 1.0.1\") ;=> \"1.0.0\"
(parse \"1.0.0 2.0.0\" 2) ;=> \"2.0.0\"
```"
  (when (not= :string (type text))
    (error "expected text string, got " (view text)))
  (var found nil)
  (let [text (if (= nil ?init)
                 text
                 (= :number (type ?init))
                 (text:sub ?init)
                 (error "expected number, got " (view ?init)))]
    (each [word (text:gmatch "[%w%-%+%.]+") &until found]
      (case word
        (where vtag (vtag:match "^v%d"))
        (let [v (vtag:match "^v(.*)")]
          (when (version? v)
            (set found v)))
        v (when (version? v)
            (set found v)))))
  found)

(fn gparse [text]
  "Return an iterator that returns version strings in the `text` one by one.

# Example

```fennel
(let [text \"4.5.6.7 1.2.3+m 4.3.2a v1.2.3 1.2.3-dev+a2\"]
  (doto (icollect [v (gparse text)] v)
    table.sort))
;=> [\"1.2.3\" \"1.2.3+m\" \"1.2.3-dev+a2\"]
```"
  (when (not= :string (type text))
    (error "expected text string, got " (view text)))
  (let [fetch (text:gmatch "[%w%-%+%.]+")]
    (fn loop []
      (case (fetch)
        (where vtag (vtag:match "^v%d"))
        (let [v (vtag:match "^v(.*)")]
          (if (version? v) v (loop)))
        v (if (version? v) v (loop))
        _ nil))
    loop))

{: decompose
 : compose
 : version?
 : release?
 : prerelease?
 : version=
 : version<>
 : version<
 : version<=
 : version>
 : version>=
 : bump/major
 : bump/minor
 : bump/patch
 : bump/release
 : bump/prerelease
 : parse
 : gparse
 : version}

;; vim: spell
