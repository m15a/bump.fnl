#!/usr/bin/env fennel

;;;; bump.fnl - a tiny helper for version bumping.
;;;;
;;;; <https://sr.ht/~m15a/bump.fnl>

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

;;;; ## Description
;;;;
;;;; This is a [Fennel] script to bump version string in command line.
;;;; You can use it in command line as shown in [Synopsis](#synopsis).
;;;; See an example usage [`./bump.bash`](./bump.bash).
;;;; It also can be used as a library to compose, decompose, or bump version
;;;; string. See [API documentation](#api-documentation) for more
;;;; details.
;;;;
;;;; [Fennel]: https://fennel-lang.org/

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

(local version :0.3.0-dev)

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
```"
  (if (= :string (type version))
      (let [v {:major (tonumber (version:match "^%d+"))
               :minor (tonumber (version:match "^%d+%.(%d+)"))
               :patch (tonumber (version:match "^%d+%.%d+%.(%d+)"))
               :prerelease (version:match "^%d+%.%d+%.%d+%-([%w][%-%.%w]*)")
               :build
               (or
                 (version:match "^%d+%.%d+%.%d+%-[%w][%-%.%w]*%+([%w][%-%+%.%w]*)")
                 (version:match "^%d+%.%d+%.%d+%+([%w][%-%+%.%w]*)"))}]
        (if (and v.build (string.match v.build "%+"))
            (error (.. "expected one build tag, found many: " version))
            (and v.major v.minor v.patch)
            v
            (error (.. "version missing some component(s): " version))))
      (let [{: view} (require :fennel)]
        (error (.. "version string expected, got " (view version))))))

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
  (let [major (tonumber major)
        minor (tonumber minor)
        patch (tonumber patch)
        prerelease* (when prerelease (tostring prerelease))
        build* (when build (tostring build))]
    (if (and major minor patch
             (or (= nil prerelease) (= :string (type prerelease*)))
             (or (= nil build) (= :string (type build*))))
        (if (and prerelease build)
            (.. major "." minor "." patch "-" prerelease* "+" build*)
            (and prerelease (not build))
            (.. major "." minor "." patch "-" prerelease*)
            (and (not prerelease) build)
            (.. major "." minor "." patch "+" build*)
            (.. major  "." minor "." patch))
        (let [{: view} (require :fennel)]
          (error (.. "invalid version component(s): "
                     (view {: major : minor : patch : prerelease : build})))))))

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
  (let [version (decompose version)]
    (compose (doto version
               (tset :prerelease nil)
               (tset :build nil)))))

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
        prerelease
        (if ?prerelease
            (let [{: view} (require :fennel)]
              (assert (and (= :string (type ?prerelease))
                           (< 0 (length ?prerelease)))
                      (.. "invalid pre-release label: " (view ?prerelease)))
              ?prerelease)
            :dev)]
    (compose (doto version
               (tset :patch (+ version.patch 1))
               (tset :prerelease prerelease)))))

(fn help []
  (io.stderr:write "USAGE: " (. arg 0) " --bump"
                   " [--major|-M]"
                   " [--minor|-m]"
                   " [--patch|-p]"
                   " [--dev|--alpha|--any-string]"
                   " VERSION" "\n"))

(fn <<? [f ?g]
  (if ?g #(f (?g $)) f))

(fn main [args]
  (when (= nil (. args 1))
    (help)
    (os.exit -1))
  (var bump nil)
  (var version nil)
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
      version* (set version version*)))
  (when (= nil version)
    (help)
    (os.exit -1))
  (set bump (or bump bump/release))
  (io.stdout:write (bump version) "\n")
  (os.exit 0))

(when (= :--bump ...)
  (main (doto [...] (table.remove 1))))

{: decompose
 : compose
 : bump/major
 : bump/minor
 : bump/patch
 : bump/release
 : bump/prerelease
 : version}

;; vim: tw=80 spell
