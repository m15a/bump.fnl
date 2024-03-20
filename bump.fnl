#!/usr/bin/env fennel

;;;; bump.fnl - a tiny helper for version bumping.
;;;;
;;;; * URL: https://git.sr.ht/~m15a/bump.fnl
;;;; * License: BSD 3-clause

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

;;; BSD 3-Clause License
;;; 
;;; Copyright (c) 2024, NACAMURA Mitsuhiro
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

(local version :0.1.0-dev)

(fn decompose [version]
  "Decompose `version` string to a table containing its components."
  (if (= :string (type version))
      (let [version* {:major (version:match "^%d+")
                      :minor (version:match "^%d+%.(%d+)")
                      :patch (version:match "^%d+%.%d+%.(%d+)")
                      :label (version:match "^%d+%.%d+%.%d+%-(.+)")}]
        (if (and version*.major version*.minor version*.patch)
            version*
            (error (.. "version missing some component(s): " version))))
      (let [{: view} (require :fennel)]
        (error (.. "version string expected, got " (view version))))))

(fn compose [{: major : minor : patch : label}]
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
  (let [version (decompose version)]
    (compose (doto version
               (tset :major (+ version.major 1))))))

(fn bump/minor [version]
  (let [version (decompose version)]
    (compose (doto version
               (tset :minor (+ version.minor 1))))))

(fn bump/patch [version]
  (let [version (decompose version)]
    (compose (doto version
               (tset :patch (+ version.patch 1))))))

(fn bump/release [version]
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
        (accumulate [state {:bump bump/release} _ arg (ipairs arg)]
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
