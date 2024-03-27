(import-macros {: testing : test} :t)
(local {: cli} (require :t.bump))
(local {: parse-args} cli)
(local t (require :faith))

(testing
  (test :parse-args []
    (t.error "USAGE: "
             #(parse-args []))
    (t.error "USAGE: "
             #(parse-args [:file-a :file-b]))
    (t.= :file-a
         (. (parse-args [:file-a]) :version|file))
    (t.= "3.0.0"
         (let [args [:--major "1.0.0" :-M]
               c (parse-args args)]
           (c.bump c.version|file)))
    (t.= "1.2.0"
         (let [args ["1.0.0" :--minor :-m]
               c (parse-args args)]
           (c.bump c.version|file)))
    (t.= "1.0.2"
         (let [args [:-p :--patch "1.0.0"]
               c (parse-args args)]
           (c.bump c.version|file)))
    (t.= "2.0.1-hello"
         (let [args ["1.0.0" :-M :--hello]
               c (parse-args args)]
           (c.bump c.version|file)))))

;; vim: set lw+=testing,test:
