(import-macros {: testing : test} :t)
(local {: changelog} (require :t.bump))
(local {: parse-date
        : parse-heading}
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
           (fmt "## 1.1.0 / 2024-01-01" "1.1.0" "%d%d%d%d%-%d%d%-%d%d")))))

;; vim: set lw+=testing,test:
