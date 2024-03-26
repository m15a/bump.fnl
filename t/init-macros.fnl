;; fennel-ls: macro-file

(local unpack (or table.unpack _G.unpack))

(fn testing/setup [setups & tests]
  `(let [out# (collect [k# v# (pairs ,setups)] k# v#)]
     (each [_# test# (ipairs ,tests)]
       (each [tname# tfn# (pairs test#)]
         (tset out# tname# tfn#)))
     out#))

(fn testing [& tests]
  (testing/setup {} (unpack tests)))

(fn test [name arglist & body]
  (let [tname (.. :test- name)]
    `{,tname (fn ,arglist ,(unpack body))}))

{: testing : testing/setup : test}
