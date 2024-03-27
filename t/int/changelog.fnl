(import-macros {: testing : test} :t)
(local {: changelog} (require :t.bump))
(local {: parse-date
        : parse-heading
        : url/pattern
        : parse-url}
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
         (parse-url "[1.1.0]: https://.../v1.1.0" :1.1.0))))

;; vim: set lw+=testing,test:
