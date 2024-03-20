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

;;;; ## Description
;;;;
;;;; This is a [Fennel] script to bump version string in command line.
;;;; You can use it in command line as shown in [Synopsis](#synopsis).
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

(local version :0.1.0)

(fn decompose [version]
  "Decompose `version` string to a table containing its components.

See `compose' for components' detail.

# Example

```fennel
(let [decomposed (decompose \"0.1.0-dev\")]
  (assert (= 0 decomposed.major))
  (assert (= 1 decomposed.minor))
  (assert (= 0 decomposed.patch))
  (assert (= :dev decomposed.label)))
```"
  (if (= :string (type version))
      (let [version* {:major (tonumber (version:match "^%d+"))
                      :minor (tonumber (version:match "^%d+%.(%d+)"))
                      :patch (tonumber (version:match "^%d+%.%d+%.(%d+)"))
                      :label (version:match "^%d+%.%d+%.%d+%-(.+)")}]
        (if (and version*.major version*.minor version*.patch)
            version*
            (error (.. "version missing some component(s): " version))))
      (let [{: view} (require :fennel)]
        (error (.. "version string expected, got " (view version))))))

(fn compose [{: major : minor : patch : label}]
  "Compose version string from a table that contains:

- `major`: major version,
- `minor`: minor version,
- `patch`: patch version, and
- `label`: suffix label that implies pre-release version (optional).

# Example

```fennel
(assert (= \"0.1.0-dev\"
           (compose {:major 0 :minor 1 :patch 0 :label :dev})))
```"
  (let [major (tonumber major)
        minor (tonumber minor)
        patch (tonumber patch)
        label* (when label (tostring label))]
    (if (and major minor patch
             (or (= nil label) (= :string (type label*))))
        (if label
            (.. major "." minor "." patch "-" label*)
            (.. major "." minor "." patch))
        (let [{: view} (require :fennel)]
          (error (.. "invalid version component(s): "
                     (view major) ", " (view minor) ", " (view patch) ", "
                     (view label)))))))

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
  "Strip pre-release label from the `version` string.

# Example

```fennel
(assert (= \"1.2.1\" (bump/release \"1.2.1-dev\")))
```"
  (let [version (decompose version)]
    (compose (doto version
               (tset :label nil)))))

(fn help []
  (io.stderr:write "USAGE: " (. arg 0) " --bump"
                   " [--major|-M]"
                   " [--minor|-m]"
                   " [--patch|-p]"
                   " VERSION" "\n"))

(fn main [args]
  (when (= nil (. args 1))
    (help)
    (os.exit -1))
  (let [{: bump : version}
        (accumulate [state {:bump bump/release} _ arg (ipairs args)]
          (case arg
            :--major (doto state (tset :bump bump/major))
            :-M (doto state (tset :bump bump/major))
            :--minor (doto state (tset :bump bump/minor))
            :-m (doto state (tset :bump bump/minor))
            :--patch (doto state (tset :bump bump/patch))
            :-p (doto state (tset :bump bump/patch))
            version (doto state (tset :version version))))]
    (io.stdout:write (bump version) "\n")
    (os.exit 0)))

(when (= :--bump ...)
  (main (doto [...] (table.remove 1))))

{: decompose
 : compose
 : bump/major
 : bump/minor
 : bump/patch
 : bump/release
 : version}

;; vim: tw=80 spell
