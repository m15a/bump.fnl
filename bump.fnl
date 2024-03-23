#!/usr/bin/env fennel

;;;; bump.fnl - a tiny helper for version bumping.
;;;;
;;;; <https://sr.ht/~m15a/bump.fnl>
;;;;
;;;; [![ci]][status]
;;;;
;;;; [ci]: https://builds.sr.ht/~m15a/bump.fnl/commits/main/ci.yml.svg
;;;; [status]: https://builds.sr.ht/~m15a/bump.fnl/commits/main/ci.yml

;;;; ## Synopsis
;;;;
;;;;     $ ./bump.fnl --bump 1.2.3-dev # Drop pre-release label by default.
;;;;     1.2.3
;;;;
;;;;     $ ./bump.fnl --bump 1.2.3-dev --major # or -M
;;;;     2.0.0-dev
;;;;
;;;;     $ ./bump.fnl --bump 1.2.3-dev --minor # or -m
;;;;     1.3.0-dev
;;;;
;;;;     $ ./bump.fnl --bump 1.2.3-dev --patch # or -p
;;;;     1.2.4-dev
;;;;
;;;;     $ ./bump.fnl --bump 1.2.3 --dev
;;;;     1.2.4-dev
;;;;
;;;;     $ ./bump.fnl --bump 1.2.3 --any-string
;;;;     1.2.4-any-string
;;;;
;;;;     $ ./bump.fnl --bump 1.2.3 --chain --minor --minor
;;;;     1.4.0-chain
;;;;
;;;;     $ ./bump.fnl --bump bump.fnl --major
;;;;     $ grep 'local version' bump.fnl
;;;;     (local version :2.0.0-dev)

;;;; ## Description
;;;;
;;;; This is a [Fennel] script to bump version string. You can use it in
;;;; command line as shown in [Synopsis](#synopsis): it can bump command line
;;;; argument version string, or version string contained in a file.
;;;; See an example usage [`./bump.bash`](./bump.bash).
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
;;;; [Fennel]: https://fennel-lang.org/
;;;; [SemVer]: https://semver.org/

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

(local version :0.4.0-dev)

(local {: view : dofile} (require :fennel))

(fn decompose [version]
  "Decompose `version` string to a table containing its components.

See `compose' for components' detail.

# Examples

```fennel
(let [decomposed (decompose \"0.1.0-dev\")]
  (assert (= 0 decomposed.major))
  (assert (= 1 decomposed.minor))
  (assert (= 0 decomposed.patch))
  (assert (= :dev decomposed.prerelease)))

(let [decomposed (decompose \"0.1.0-dev-1+0.0.1\")]
  (assert (= 0 decomposed.major))
  (assert (= 1 decomposed.minor))
  (assert (= 0 decomposed.patch))
  (assert (= :dev-1 decomposed.prerelease))
  (assert (= :0.0.1 decomposed.build)))

(let [(ok? msg) (pcall decompose \"0.0.1+a+b\")]
  (assert (and (= false ok?)
               (= \"expected one build tag, found many: 0.0.1+a+b\" msg))))

(let [(ok? msg) (pcall decompose \"0.0.1=dev\")]
  (assert (and (= false ok?)
               (= \"invalid pre-release label and/or build tag: 0.0.1=dev\" msg))))
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

# Examples

```fennel
(assert (= \"0.1.0-dev\"
           (compose {:major 0 :minor 1 :patch 0
                     :prerelease :dev})))
(assert (= \"0.1.0+rc1\"
           (compose {:major 0 :minor 1 :patch 0
                     :build :rc1})))
(assert (= \"0.1.0-test-case+exp.1\"
           (compose {:major 0 :minor 1 :patch 0
                     :prerelease :test-case :build :exp.1})))
```"
  (let [major* (tonumber major)
        minor* (tonumber minor)
        patch* (tonumber patch)
        prerelease* (when (not= nil prerelease) (tostring prerelease))
        build* (when (not= nil build) (tostring build))]
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
(assert (= true (version? \"1.2.3-dev+111\")))
(assert (= false (version? \"pineapple\")))
(assert (= false (version? {:major 1 :minor 2 :patch 3})))
```"
  (case (type x)
    :string (pick-values 1 (pcall decompose x))
    _ false))

(fn release? [x]
  "If `x` is a release version string, return `true`; otherwise `false`.

# Examples

```fennel
(assert (= false (release? :1.0.0+a+b)))
(assert (= false (release? \"1.0.0-alpha\")))
(assert (= true (release? \"1.0.0+sha.a1bf00a\")))
```"
  (case-try (type x)
    :string (pcall decompose x)
    (true v) (if v.prerelease false true)
    (catch _ false)))

(fn prerelease? [x]
  "If `x` is a prerelease version string, return `true`; otherwise `false`.

# Examples

```fennel
(assert (= false (prerelease? :1.0.0.0)))
(assert (= true (prerelease? \"1.0.0-alpha\")))
(assert (= false (prerelease? \"1.0.0+sha.a1bf00a\")))
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
(assert (= true (version< :1.0.0-alpha :1.0.0-alpha.1)))
(assert (= true (version< :1.0.0-alpha.1 :1.0.0-alpha.beta)))
(assert (= true (version< :1.0.0-alpha.beta :1.0.0-beta)))
(assert (= true (version< :1.0.0-beta.2 :1.0.0-beta.11)))
(assert (= true (version< :1.0.0-beta.11 :1.0.0-rc.1)))
(assert (= true (version< :1.0.0-rc.1 :1.0.0)))
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
(assert (= false (version<> :1.0.0-alpha+001 :1.0.0-alpha+100)))
```"
  (or (version< left right) (version< right left)))

(fn version= [left right]
  "Return `true` if `left` and `right` versions have the same precedence.

Otherwise `false`. Note that build tags are ignored for version comparison.

# Example

```fennel
(assert (= true (version= :1.0.0-alpha+001 :1.0.0-alpha+010)))
```"
  (not (or (version< left right) (version< right left))))

(fn bump/major [version]
  "Bump major version number in the `version` string.

# Example

```fennel
(assert (= \"1.0.0\" (bump/major \"0.9.28\")))
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
(assert (= \"0.3.0-dev\" (bump/minor \"0.2.3-dev\")))
```"
  (let [version (decompose version)]
    (compose (doto version
               (tset :minor (+ version.minor 1))
               (tset :patch 0)))))

(fn bump/patch [version]
  "Bump patch version number in the `version` string.

# Example

```fennel
(assert (= \"0.6.1-alpha\" (bump/patch \"0.6.0-alpha\")))
```"
  (let [version (decompose version)]
    (compose (doto version
               (tset :patch (+ version.patch 1))))))

(fn bump/release [version]
  "Strip pre-release and/or build label(s) from the `version` string.

# Example

```fennel
(assert (= \"1.2.1\" (bump/release \"1.2.1-dev+001\")))
```"
  (compose (doto (decompose version)
             (tset :prerelease nil)
             (tset :build nil))))

(fn bump/prerelease [version ?prerelease]
  "Append `?prerelease` label (default: `dev`) to the `version` string.

Besides, it increments patch version number. If you like to increment
other than patch number, compose it with any other `bump/*` function.

# Example

```fennel
(assert (= \"1.2.1-dev\" (bump/prerelease \"1.2.0\")))
(assert (= \"1.2.1-alpha\" (bump/prerelease \"1.2.0\" :alpha)))

(assert (= \"1.2.0-dev\" (-> \"1.1.4\"
                           bump/prerelease
                           bump/minor)))
```"
  (let [version (decompose version)
        prerelease (if (= nil ?prerelease)
                       :dev
                       (tostring ?prerelease))]
    (when (not (and prerelease (< 0 (length prerelease))))
      (error (.. "invalid pre-release label: " (view ?prerelease))))
    (compose (doto version
               (tset :patch (+ version.patch 1))
               (tset :prerelease prerelease)))))

(fn parse [text ?init]
  "Return the first version string found in the `text`.

Optional `?init` specifies where to start the search (default: 1).

# Example

```fennel
(assert (= \"1.0.0-alpha\" (parse \" v1.0.0 1.0.0-alpha 1.0.1\")))
(assert (= \"2.0.0\" (parse \"1.0.0 2.0.0\" 2)))
```"
  (when (not= :string (type text))
    (error "expected text string, got " (view text)))
  (var found nil)
  (let [text (if (= nil ?init)
                 text
                 (= :number (type ?init))
                 (text:sub ?init)
                 (error "expected number, got " (view ?init)))]
    (each [v (text:gmatch "[%w%-%+%.]+") &until found]
      (when (version? v)
        (set found v))))
  found)

(fn gparse [text]
  "Return an iterator that returns version strings in the `text` one by one.

# Example

```fennel
(let [found (collect [v (gparse \"4.5.6.7 1.2.3+m 4.3.2a 1.2.3 1.2.3-dev+a2\")]
              (values v true))]
  (assert (= 3 (length (icollect [v _ (pairs found)] v))))
  (assert (. found \"1.2.3\"))
  (assert (. found \"1.2.3+m\"))
  (assert (. found \"1.2.3-dev+a2\")))
```"
  (when (not= :string (type text))
    (error "expected text string, got " (view text)))
  (let [fetch (text:gmatch "[%w%-%+%.]+")]
    (fn loop []
      (case (fetch)
        v (if (version? v) v (loop))
        _ nil))
    loop))

(fn parse/one [text]
  "Find the one true version in the `text`.

If not found or multiple versions found, it raises error."
  (let [versions (collect [v (gparse text)] v true)]
    (case (next versions)
      v (case (next versions v)
          u (error (.. "multiple version strings found: at least " v " and " u))
          _ v)
      _ (error "no version string found"))))

(fn warn [...]
  (io.stderr:write "bump.fnl: " ...)
  (io.stderr:write "\n"))

(fn warn/nil [...]
  (warn ...)
  nil)

(fn require-version [path]
  "Try `dofile` the `path` and search for exposed version."
  (case (pcall dofile path)
    (where (true x) (= :table (type x)))
    (case (. x :version)
      v (if (version? v) v
            (warn/nil "invalid version " (view v) " in '" path "'"))
      _ (warn/nil "version not exported in '" path "'"))
    _ (warn/nil "failed to require version from '" path "'")))

(fn read-version [path]
  "Read the `path` and search for exactly one version string."
  (warn "attempt to read version from '" path "' as text file")
  (case (io.open path)
    in (with-open [in in]
         (case (pcall parse/one (in:read :*a))
           (true v) v
           (_ msg) (warn/nil msg)))
    (_ msg) (warn/nil msg)))

(fn read-contents [path]
  (case (io.open path)
    in (with-open [in in] (in:read :*a))
    (_ msg) (warn/nil msg)))

(fn write-contents [text path]
  (case (io.open path :w)
    out (with-open [out out] (out:write text))
    (_ msg) (warn/nil msg)))

(fn %escape [s]
  (s:gsub "([%^%$%(%)%%%.%[%]%*%+%-%?])" "%%%1"))

(fn %replace [old new text]
  (string.gsub text (%escape old) new))

(fn edit [path bump]
  "Bump version in a file at the `path` by using `bump` function.

First of all, it tries to detect the version declared in the file with
the following heuristics one by one:

1. Require the file with `dofile` and see if it has `:version` entry.
2. Read the file as text and search for one unique version string.

After that, if any unique version is found, it bumps the version and
replace the old version string with the new version in the file.

It returns `true` in case of success and `nil` in failure."
  (case-try (or (require-version path)
                (read-version path))
    version (read-contents path)
    text (let [edited (%replace version (bump version) text)]
           (and (write-contents edited path) true))
    (catch
      _ (warn/nil "failed to edit '" path "'"))))

(fn help []
  (io.stderr:write "USAGE: " (. arg 0) " --bump"
                   " [--major|-M]"
                   " [--minor|-m]"
                   " [--patch|-p]"
                   " [--dev|--alpha|--any-string]"
                   " VERSION|FILE" "\n")
  (os.exit false))

(fn <<? [f ?g]
  (if ?g #(f (?g $)) f))

(fn main [args]
  (var bump nil)
  (var version|file nil)
  (each [_ arg (ipairs args)]
    (case arg
      :--major (set bump (<<? bump/major bump))
      :-M      (set bump (<<? bump/major bump))
      :--minor (set bump (<<? bump/minor bump))
      :-m      (set bump (<<? bump/minor bump))
      :--patch (set bump (<<? bump/patch bump))
      :-p      (set bump (<<? bump/patch bump))
      (where flag (flag:match "^%-%-[^%-]+.*"))
      (let [label (flag:match "^%-%-([^%-]+.*)")]
        (set bump (<<? #(bump/prerelease $ label) bump)))
      any (set version|file any)))
  (when (not version|file)
    (help))
  (set bump (or bump bump/release))
  (if (version? version|file)
      (let [version version|file]
        (io.stdout:write (bump version) "\n")
        (os.exit))
      (let [file version|file
            ok? (or (edit file bump) false)]
        (os.exit ok?))))

(when (= :--bump ...)
  (main (doto [...] (table.remove 1))))

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

;; vim: tw=80 spell
