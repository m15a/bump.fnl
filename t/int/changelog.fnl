(import-macros {: testing : test} :t)
(local {: changelog} (require :t.bump))
(local {: parse-date} changelog)
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
           (fmt "## 1.1.0 / 2024-12-24")))))

;; vim: set lw+=testing,test:
