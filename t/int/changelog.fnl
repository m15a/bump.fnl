(import-macros {: testing : test} :t)
(local {: bump/major
        : bump/minor
        : bump/patch
        : bump/release
        : bump/prerelease}
       (require :bump))
(local {: parse-date
        : parse-heading
        : url/pattern
        : parse-url
        : analyze
        : validate
        : update
        : changelog?}
       (require :bump.changelog))
(local t (require :faith))

(fn contents [path]
  (with-open [in (io.open path)]
    (in:read :*a)))

(testing
  (test :parse-date []
    (t.error "string expected, got nil"
             #(parse-date nil))
    (let [fmt #(. (parse-date $) :format)]
      (t.= "%Y-%m-%d %z"
           (fmt "## 1.1.0 (2024-12-24  +0900)"))
      (t.= "%Y-%m-%d %Z"
           (fmt "## 1.1.0 - 2024-12-24 JST"))
      (t.= "%Y-%m-%d"
           (fmt "## 1.1.0 / 2024-12-24"))))
  (test :parse-heading []
    (t.error "string expected, got 1"
             #(parse-heading 1 2))
    (t.error "version string expected, got 2"
             #(parse-heading "" 2))
    (t.error "string expected, got %[1%]"
             #(parse-heading "" :1.1.0 [1]))
    (let [fmt (fn [...] (. (parse-heading ...) :format))]
      (t.= "## {{VERSION}}"
           (fmt "## Unreleased" "Unreleased"))
      (t.= "## v{{VERSION}}"
           (fmt "## v1.1.0" "1.1.0"))
      (t.= "## {{VERSION}} / {{DATE}}"
           (fmt "## 1.1.0 / 2024-01-01" "1.1.0" "%d%d%d%d%-%d%d%-%d%d"))))
  (test :url/pattern []
    (t.error "version string expected"
             #(url/pattern nil))
    (t.= {:pattern "^%s*%[v?1%.0%.0%]:%s+<?http"}
         (url/pattern "1.0.0"))
    (t.= {:pattern "^%s*%[v?unreleased%]:%s+<?http"}
         (url/pattern "unreleased")))
  (test :parse-url []
    (t.error "string expected, got 10"
             #(parse-url 10))
    (t.error "version string expected, got \"1.1.1.1\""
             #(parse-url "" "1.1.1.1"))
    (t.= {:format "[{{VERSION}}]: https://..."}
         (parse-url "[1.1.0-dev]: https://..." :1.1.0-dev))
    (t.= {:format "[{{VERSION}}]: https://.../v{{VERSION}}"}
         (parse-url "[1.1.0]: https://.../v1.1.0" :1.1.0)))
  (test :analyze/unreleased []
    (t.= [{:ln 5
           :unreleased? true
           :url {:ln 19}}
          {:ln 11
           :version "1.0.0"
           :date {:format "%Y-%m-%d"}
           :format "## [{{VERSION}}] - {{DATE}}"
           :url {:ln 20
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/v{{VERSION}}"}}]
         (analyze "t/f/c/unreleased/base/old.md"))
    (t.= [{:ln 5
           :unreleased? true
           :url {:ln 19}}
          {:ln 11
           :version "1.0.0"
           :format "## [{{VERSION}}]"
           :url {:ln 20
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/v{{VERSION}}"}}]
         (analyze "t/f/c/unreleased/nodate/old.md"))
    (t.= [{:ln 5
           :unreleased? true}
          {:ln 11
           :version "1.0.0"
           :date {:format "%Y-%m-%d"}
           :format "## {{VERSION}} ({{DATE}})"}]
         (analyze "t/f/c/unreleased/nourl/old.md")))
  (test :analyze/prerelease []
    (t.= [{:ln 5
           :version "1.1.0-dev"
           :format "## [{{VERSION}}]"
           :url {:ln 19
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/main"}}
          {:ln 11
           :version "1.0.0"
           :date {:format "%Y-%m-%d"}
           :format "## [{{VERSION}}] - {{DATE}}"
           :url {:ln 20
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/v{{VERSION}}"}}]
         (analyze "t/f/c/prerelease/base/old.md"))
    (t.= [{:ln 5
           :version "1.1.0-dev"
           :format "## [{{VERSION}}]"
           :url {:ln 19
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/main"}}
          {:ln 11
           :version "1.0.0"
           :format "## [{{VERSION}}]"
           :url {:ln 20
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/v{{VERSION}}"}}]
         (analyze "t/f/c/prerelease/nodate/old.md"))
    (t.= [{:ln 5
           :version "1.1.0-dev"
           :format "## {{VERSION}} (???)"}
          {:ln 11
           :version "1.0.0"
           :date {:format "%Y-%m-%d"}
           :format "## {{VERSION}} ({{DATE}})"}]
         (analyze "t/f/c/prerelease/nourl/old.md")))
  (test :analyze/release []
    (t.= [{:ln 5
           :version "1.1.0"
           :date {:format "%Y-%m-%d"}
           :format "## [{{VERSION}}] - {{DATE}}"
           :url {:ln 11
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/v{{VERSION}}"}}
          {}]
         (analyze "t/f/c/release/base/old.md"))
    (t.= [{:ln 5
           :version "1.1.0"
           :format "## [{{VERSION}}]"
           :url {:ln 11
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/v{{VERSION}}"}}
          {}]
         (analyze "t/f/c/release/nodate/old.md"))
    (t.= [{:ln 5
           :version "1.1.0"
           :date {:format "%Y-%m-%d"}
           :format "## {{VERSION}} / {{DATE}}"}
          {}]
         (analyze "t/f/c/release/nourl/old.md")))
  (test :validate []
    (t.error "invalid changelog: 2nd heading has pre%-release version"
             #(validate [{} {:unreleased? true}]))
    (t.error "invalid changelog: 2nd heading has pre%-release version"
             #(validate [{} {:version "0.1.1-dev"}]))
    (t.error "changelog lacks sufficient version information"
             #(validate [{} {}])))
  (test :update/unreleased []
    (let [update* #(update $1 (analyze $1) $2)]
      (t.= (contents "t/f/c/unreleased/nodate/new_1.md")
           (update* "t/f/c/unreleased/nodate/old.md" bump/major))
      (t.= (contents "t/f/c/unreleased/nodate/new_2.md")
           (update* "t/f/c/unreleased/nodate/old.md" bump/minor))
      (t.= (contents "t/f/c/unreleased/nodate/new_v.md")
           (update* "t/f/c/unreleased/nodate/old_v.md" bump/minor))
      (t.error "invalid version bumping: 1%.0%.0 %-> 1%.0%.0"
               #(update* "t/f/c/unreleased/nodate/old.md" bump/release))
      (t.error "invalid version bumping: 1%.0%.0 %-> 1%.0%.1%-dev"
               #(update* "t/f/c/unreleased/nodate/old.md" bump/prerelease))))
  (test :update/prerelease []
    (let [update* #(update $1 (analyze $1) $2)]
      (t.= (contents "t/f/c/prerelease/nodate/new_1.md")
           (update* "t/f/c/prerelease/nodate/old.md" bump/release))
      (t.= (contents "t/f/c/prerelease/nodate/new_2.md")
           (update* "t/f/c/prerelease/nodate/old.md" bump/patch))
      (t.error "invalid version bumping: 1%.1%.0%-dev %-> 1%.1%.0%-dev"
               #(update* "t/f/c/prerelease/nodate/old.md" #$))))
  (test :update/release []
    (let [update* #(update $1 (analyze $1) $2)]
      (t.= (contents "t/f/c/release/nodate/new_1.md")
           (update* "t/f/c/release/nodate/old.md" bump/major))
      (t.= (contents "t/f/c/release/nodate/new_2.md")
           (update* "t/f/c/release/nodate/old.md" bump/prerelease))
      (t.= (contents "t/f/c/release/nodate/new_3.md")
           (update* "t/f/c/release/nodate/old_2.md" bump/prerelease))
      (t.error "invalid version bumping: 1%.1%.0 %-> 1%.1%.0"
               #(update* "t/f/c/release/nodate/old.md" bump/release))))
  (test :changelog? []
    (t.= true (changelog? "CHANGELOG.md"))
    (t.= true (changelog? "CHANGELOG.markdown"))
    ;; FIXME: recognize non-markdown changelog.
    ; (t.= false (changelog? "CHANGELOG.adoc"))
    (t.= true (changelog? "path/to/changelog.md"))))

;; vim: set lw+=testing,test:
