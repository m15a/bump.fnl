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
;;;;     $ ./bump.fnl --bump bump.fnl && git diff
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
;;;;     $ ./bump.fnl --bump CHANGELOG.md && git diff
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
;;;; - edit Markdown changelog according to intended version bumping.
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

;;; = Utilities ========================================================

(fn <<? [f ?g]
  (if ?g #(f (?g $)) f))

(fn update! [tbl key fun ?init]
  (doto tbl
    (tset key (fun (or (. tbl key) ?init)))))

(fn read-contents [path]
  (case (io.open path)
    in (with-open [in in] (in:read :*a))
    (_ msg) (values nil msg)))

(fn read-lines [path]
  (case (io.open path)
    in (with-open [in in]
         (let [lines []]
           (each [line (in:lines)]
             (table.insert lines line))
           lines))
    (_ msg) (values nil msg)))

(fn write-contents [text path]
  (case (io.open path :w)
    out (with-open [out out] (out:write text))
    (_ msg) (values nil msg)))

(fn escape-regex [s]
  (case (type s)
    :string (pick-values 1 (s:gsub "([%^%$%(%)%%%.%[%]%*%+%-%?])" "%%%1"))
    _ (error "string expected, got " (view s))))

(fn replace [old new text]
  (case (type text)
    :string (pick-values 1 (text:gsub (escape-regex old) new))
    _ (error "string expected, got " (view text))))

(fn parse/one [text]
  "Find the one true version in the `text`; otherwise return `nil` and message."
  (let [versions (collect [v (gparse text)] v true)]
    (case (next versions)
      v (case (next versions v)
          u (values nil (.. "multiple version strings found: at least "
                            v " and " u))
          _ v)
      _ (values nil "no version string found"))))

;;; = CLI logging ======================================================

(fn warn [...]
  (io.stderr:write "bump.fnl: " ...)
  (io.stderr:write "\n"))

(fn warn/nil [...]
  (warn ...)
  nil)

;;; = Generic file editor ==============================================

(local generic {})

(fn generic.require-version [path]
  "Try `dofile` the `path` and search for exposed version."
  (case (pcall dofile path)
    (where (true x) (= :table (type x)))
    (case (. x :version)
      v (if (version? v) v
            (warn/nil "invalid version " (view v) " in '" path "'"))
      _ (warn/nil "version not exported in '" path "'"))
    _ (warn/nil "failed to require version from '" path "'")))

(fn generic.read-version [path]
  "Read the `path` and search for exactly one version string."
  (warn "attempt to find version in '" path "' as text file")
  (case (io.open path)
    in (with-open [in in]
         (case (parse/one (in:read :*a))
           v v
           (_ msg) (warn/nil msg)))
    (_ msg) (warn/nil msg)))

(fn generic.edit [path bump]
  "Bump version in the file `path` by using `bump` function.

It tries the following heuristics one by one:

1. Require the file with `dofile` and see if it has `:version` entry.
2. Read the file as text and search for one unique version string.

After that, if any unique version string is found, it bumps the version and
replace the old version string with the new one."
  (case-try (or (generic.require-version path)
                (generic.read-version path))
    version (read-contents path)
    text (let [edited (replace version (bump version) text)]
           (and (write-contents edited path) true))
    (catch _ (warn/nil "failed to edit '" path "'"))))

;;; = Changelog editor =================================================

(local changelog {})

(fn %parse-date [line]
  (let [Y-m-d-z "%d%d%d%d%-%d%d%-%d%d [%-%+]%d%d%d%d"
        Y-m-d-Z "%d%d%d%d%-%d%d%-%d%d %u%u%u"
        Y-m-d "%d%d%d%d%-%d%d%-%d%d"]
    (if (line:match Y-m-d-z)
        {:pattern Y-m-d-z :format "%Y-%m-%d %z"}
        (line:match Y-m-d-Z)
        {:pattern Y-m-d-Z :format "%Y-%m-%d %Z"}
        (line:match Y-m-d)
        {:pattern Y-m-d :format "%Y-%m-%d"}
        nil)))

(fn %heading-format [line version ?date-pattern]
  (let [fmt (line:gsub (escape-regex version) "{{VERSION}}")]
    (if ?date-pattern
        (fmt:gsub ?date-pattern "{{DATE}}")
        fmt)))

(fn %url-pattern [version]
  (.. "^%s*%[" (escape-regex version) "%]:%s+<?http"))

(fn %url-format [line version]
  (line:gsub (escape-regex version) "{{VERSION}}"))

(fn %changelog-analyze [in]
  "Ugly changelog analyzer. To be refactored."
  (let [info [{:url {}} {:url {}}]]
    (var cursor 0)
    (var heading-id 1)
    (var url-id 1)
    (each [line (in:lines) &until (< 2 url-id)]
      (set cursor (+ cursor 1))
      (when (and (<= heading-id 2)
                 (line:match "^%s*## "))
        (tset info heading-id :ln cursor)
        (case (or (line:match "[Uu]nreleased") (parse line))
          v (do
              (if (version? v)
                  (tset info heading-id :version v)
                  (tset info heading-id :unreleased? true))
              (case (%parse-date line)
                d (tset info heading-id :date d))
              (tset info heading-id :format
                    (%heading-format line v (case (?. info heading-id :date)
                                              d d.pattern)))
              (tset info heading-id :url :pattern (%url-pattern v))))
        (set heading-id (+ heading-id 1)))
      (when (and (< 2 heading-id) (<= url-id 2)
                 (?. info url-id :url :pattern)
                 (line:match (?. info url-id :url :pattern)))
        (tset info url-id :url :ln cursor)
        (case (?. info url-id :version)
          v (tset info url-id :url :format (%url-format line v)))
        (set url-id (+ url-id 1))))
    ;; Clean up
    (for [i 1 2]
      (when (?. info i :date :pattern)
        (tset info i :date :pattern nil))
      (tset info i :url :pattern nil)
      (when (not (next (?. info i :url)))
        (tset info i :url nil)))
    info))

(fn changelog.analyze [path]
  "Analyze changelog at the `path` and return the analysed information.

The result is a sequential table of length 2, each contains information about
the first and second level-2 headings, respectively:

- `ln`: line number of the heading;
- `unreleased?`: whether the heading is `Unreleased` or not;
- `version`: contained version string if any;
- `format`: Format of the heading, e.g., `## [{{VERSION}}] - {{DATE}}`;
- `date` - date information:
  - `format`: `os.date` format;
- `url` - information about the URL line corresponding to the heading:
  - `ln`: line number; and
  - `format`: URL line format, e.g., `[{{VERSION}}]: https://.../v{{VERSION}}`.

Return the result information in case of success; otherwise return `nil`."
  (case (io.open path)
    in (with-open [in in] (%changelog-analyze in))
    (_ msg) (warn/nil msg)))

(fn changelog.validate [info]
  (if (or (?. info 2 :unreleased?)
          (prerelease? (?. info 2 :version)))
      (warn/nil "invalid changelog: 2nd heading has pre-release version")
      (and (not (?. info 1 :version))
           (not (?. info 2 :version)))
      (warn/nil "changelog lacks sufficient version information")
      info))

(fn %changelog-update/unreleased [info lines new]
  (let [heading (case (?. info 2 :format)
                  fmt (fmt:gsub "{{VERSION}}" new)
                  _ (error "2nd level-2 heading has no format"))
        heading (case (?. info 2 :date :format)
                  dfmt (heading:gsub "{{DATE}}" (os.date dfmt))
                  _ heading)]
    (doto lines
      (table.insert (+ (. info 1 :ln) 1) "")
      (table.insert (+ (. info 1 :ln) 2) heading))
    (case (?. info 2 :url)
      url (let [line (url.format:gsub "{{VERSION}}" new)]
            (doto lines
             (table.insert (+ url.ln 2) line)))
      _ lines)))

(fn %changelog-update/prerelease->prerelease [info lines new]
  (let [heading (case (?. info 1 :format)
                  fmt (fmt:gsub "{{VERSION}}" new)
                  _ (error "1st level-2 heading has no format"))]
    (doto lines
      (tset (. info 1 :ln) heading))
    (case (?. info 1 :url)
      url (let [line (url.format:gsub "{{VERSION}}" new)]
            (doto lines
             (tset url.ln line)))
      _ lines)))

(fn %changelog-update/prerelease->release [info lines new]
  (let [heading (case (?. info 2 :format)
                  fmt (fmt:gsub "{{VERSION}}" new)
                  _ (error "2nd level-2 headings have no format"))
        heading (case (?. info 2 :date :format)
                  dfmt (heading:gsub "{{DATE}}" (os.date dfmt))
                  _ heading)]
    (doto lines
      (tset (. info 1 :ln) heading))
    (case-try (?. info 1 :url)
      url-1 (?. info 2 :url)
      url-2 (let [line (url-2.format:gsub "{{VERSION}}" new)]
              (doto lines
                (tset url-1.ln line)))
      (catch _ lines))))

(fn %changelog-update/release->prerelease [info lines new]
  (let [heading (case (?. info 1 :format)
                  fmt (fmt:gsub "{{VERSION}}" new)
                  _ (error "1st level-2 heading has format"))
        heading (heading:gsub "{{DATE}}" "???")]
    (doto lines
      (table.insert (. info 1 :ln) heading)
      (table.insert (+ (. info 1 :ln) 1) ""))
    (case (?. info 1 :url)
      url (let [line (-> url.format
                         (string.gsub "{{VERSION}}" new 1)
                         (string.gsub "v?{{VERSION}}" "HEAD"))]
            (doto lines
             (table.insert (+ url.ln 2) line)))
      _ lines)))

(fn %changelog-update/release->release [info lines new]
  (let [heading (case (?. info 1 :format)
                  fmt (fmt:gsub "{{VERSION}}" new)
                  _ (error "1st level-2 heading has no format"))
        heading (case (?. info 1 :date :format)
                  dfmt (heading:gsub "{{DATE}}" (os.date dfmt))
                  _ heading)]
    (doto lines
      (table.insert (. info 1 :ln) heading)
      (table.insert (+ (. info 1 :ln) 1) ""))
    (case (?. info 1 :url)
      url (let [line (url.format:gsub "{{VERSION}}" new)]
            (doto lines
             (table.insert (+ url.ln 2) line)))
      _ lines)))

(fn changelog.update [info path bump]
  "Update changelog based on the analyzed `info` and return it as text."
  (let [update
        (if (?. info 1 :unreleased?)
            (case (?. info 2 :version)
              old (let [new (bump old)]
                    (if (release? new)
                        #(%changelog-update/unreleased $1 $2 new)
                        #(warn/nil "invalid version bumping: " old " -> " new)))
              _ (warn/nil "missing previous version string"))
            (prerelease? (?. info 1 :version))
            (let [old (. info 1 :version)
                  new (bump old)]
              (if (release? new)
                  #(%changelog-update/prerelease->release $1 $2 new)
                  #(%changelog-update/prerelease->prerelease $1 $2 new)))
            ;; If the first level-2 heading has release version but missing
            ;; date, it may imply pre-release version.
            (and (release? (?. info 1 :version))
                 (not (?. info 1 :date)))
            (let [new (. info 1 :version)]
              #(%changelog-update/prerelease->release $1 $2 new))
            ;; Default case: 1st level-2 heading has previous release version
            (release? (?. info 1 :version))
            (let [old (. info 1 :version)
                  new (bump old)]
              (if (release? new)
                  #(%changelog-update/release->release $1 $2 new)
                  #(%changelog-update/release->prerelease $1 $2 new)))
            (warn/nil "something is wrong with changelog '" path "'"))]
    (case (read-lines path)
      lines (case (update info lines)
              lines (.. (table.concat lines "\n") "\n")
              _ (warn/nil "failed to update changelog '" path "'"))
      (_ msg) (warn/nil msg))))

(fn changelog.edit [path bump]
  "Bump version in a changelog at the `path` by using `bump` function.

To update changelog, we will insert or update a level-2 heading containing
bumped version string, and insert or update a URL line (i.e., a line around
the bottom of the changelog, which looks like `[version]: https://...`)."
    (case-try (changelog.analyze path)
      info (changelog.validate info)
      info (changelog.update info path bump)
      edited (and (write-contents edited path) true)
      (catch _ (warn/nil "failed to edit changelog '" path "'"))))

(fn changelog.changelog? [path]
  (case (type path)
    :string (if (path:match "[Cc][Hh][Aa][Nn][Gg][Ee][Ll][Oo][Gg]")
                true
                false)
    _ false))

;;; = CLI ==============================================================

(local cli {})

(fn cli.help []
  (io.stderr:write "USAGE: " (. arg 0) " --bump"
                   " [--major|-M]"
                   " [--minor|-m]"
                   " [--patch|-p]"
                   " [--dev|--alpha|--any-string]"
                   " VERSION|FILE" "\n")
  (os.exit 1))

(fn cli.parse-args [args]
  (-> (accumulate [config {} _ arg (ipairs args)]
        (case arg
          :--major (update! config :bump #(<<? bump/major $))
          :-M      (update! config :bump #(<<? bump/major $))
          :--minor (update! config :bump #(<<? bump/minor $))
          :-m      (update! config :bump #(<<? bump/minor $))
          :--patch (update! config :bump #(<<? bump/patch $))
          :-p      (update! config :bump #(<<? bump/patch $))
          (where flag (flag:match "^%-%-[^%-]+.*"))
          (let [label (flag:match "^%-%-([^%-]+.*)")]
            (update! config :bump #(<<? #(bump/prerelease $ label) $)))
          any (update! config :version|file #(if $ (cli.help) any))))
      (update! :bump #(or $ bump/release))))

(fn cli.bump/version [bump version]
  (io.stdout:write (bump version) "\n")
  (os.exit))

(fn cli.bump/changelog [bump path]
  (case (if (changelog.changelog? path)
            (changelog.edit path bump)
            (generic.edit path bump))
    true (os.exit)
    _ (os.exit 1)))

;;; = main =============================================================

(fn main [args]
  (let [{: bump : version|file} (cli.parse-args args)]
    (when (not version|file)
      (cli.help))
    (if (version? version|file)
        (cli.bump/version bump version|file)
        (cli.bump/changelog bump version|file))))

(when (= :--bump ...)
  (main (doto [...] (table.remove 1))))

;;; ====================================================================

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
 ;: generic
 ;: changelog
 ;: cli
 : version}

;; vim: tw=80 spell
