(import-macros {: testing : test} :t)
(local {: changelog} (require :t.bump))
(local {: parse-date
        : parse-heading
        : url/pattern
        : parse-url
        : analyze
        : validate
        : changelog?}
       changelog)
(local t (require :faith))

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
    (t.= {:pattern "^%s*%[1%.0%.0%]:%s+<?http"}
         (url/pattern "1.0.0"))
    (t.= {:pattern "^%s*%[unreleased%]:%s+<?http"}
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
         (analyze "t/f/c/unreleased/base.md"))
    (t.= [{:ln 5
           :unreleased? true
           :url {:ln 19}}
          {:ln 11
           :version "1.0.0"
           :format "## [{{VERSION}}]"
           :url {:ln 20
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/v{{VERSION}}"}}]
         (analyze "t/f/c/unreleased/nodate.md"))
    (t.= [{:ln 5
           :unreleased? true}
          {:ln 11
           :version "1.0.0"
           :date {:format "%Y-%m-%d"}
           :format "## {{VERSION}} ({{DATE}})"}]
         (analyze "t/f/c/unreleased/nourl.md")))
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
         (analyze "t/f/c/prerelease/base.md"))
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
         (analyze "t/f/c/prerelease/nodate.md"))
    (t.= [{:ln 5
           :version "1.1.0-dev"
           :format "## {{VERSION}} (???)"}
          {:ln 11
           :version "1.0.0"
           :date {:format "%Y-%m-%d"}
           :format "## {{VERSION}} ({{DATE}})"}]
         (analyze "t/f/c/prerelease/nourl.md")))
  (test :analyze/release []
    (t.= [{:ln 5
           :version "1.1.0"
           :date {:format "%Y-%m-%d"}
           :format "## [{{VERSION}}] - {{DATE}}"
           :url {:ln 11
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/v{{VERSION}}"}}
          {}]
         (analyze "t/f/c/release/base.md"))
    (t.= [{:ln 5
           :version "1.1.0"
           :format "## [{{VERSION}}]"
           :url {:ln 11
                 :format "[{{VERSION}}]: https://a.com/b/c/refs/v{{VERSION}}"}}
          {}]
         (analyze "t/f/c/release/nodate.md"))
    (t.= [{:ln 5
           :version "1.1.0"
           :date {:format "%Y-%m-%d"}
           :format "## {{VERSION}} / {{DATE}}"}
          {}]
         (analyze "t/f/c/release/nourl.md")))
  (test :validate []
    (t.error "invalid changelog: 2nd heading has pre%-release version"
             #(validate [{} {:unreleased? true}]))
    (t.error "invalid changelog: 2nd heading has pre%-release version"
             #(validate [{} {:version "0.1.1-dev"}]))
    (t.error "changelog lacks sufficient version information"
             #(validate [{} {}])))
  (test :changelog? []
    (t.= true (changelog? "CHANGELOG.md"))
    (t.= true (changelog? "CHANGELOG.markdown"))
    ;; FIXME: recognize non-markdown changelog.
    ; (t.= false (changelog? "CHANGELOG.adoc"))
    (t.= true (changelog? "path/to/changelog.md"))))

;; vim: set lw+=testing,test:
