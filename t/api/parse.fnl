(import-macros {: testing : test} :t)
(local {: parse : gparse} (require :bump))
(local t (require :faith))

(testing
  (test :parse []
    (t.= "1.0.0-alpha"
         (parse " v1.0.0 1.0.0-alpha 1.0.1"))
    (t.= "2.0.0"
         (parse "1.0.0 2.0.0" 2)))
  (test :gparse []
    (let [text "4.5.6.7 1.2.3+m 4.3.2a 1.2.3 1.2.3-dev+a2 v0.1.0"]
      (t.= [:1.2.3 :1.2.3+m :1.2.3-dev+a2]
           (doto (icollect [v (gparse text)] v)
             table.sort)))))

;; vim: set lw+=testing,test:
