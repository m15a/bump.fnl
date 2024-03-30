(import-macros {: testing : test} :t)
(local t (require :faith))
(local {: version? : release? : prerelease?} (require :bump))

(testing
  (test :version? []
    (t.= nil (let [(_ ?rest) (version? "1.0.0")] ?rest))
    (t.= nil (let [(_ ?rest) (version? "1.0.0a")] ?rest))
    (t.= true (version? "1.2.3-dev+111"))
    (t.= false (version? "pineapple"))
    (t.= false (version? {:major 1 :minor 2 :patch 3})))
  (test :release? []
    (t.= nil (let [(_ ?rest) (release? "1.0.0")] ?rest))
    (t.= nil (let [(_ ?rest) (release? "1.0.0-dev")] ?rest))
    (t.= true (release? "1.2.3+111"))
    (t.= false (release? "1.2.3-dev")))
  (test :prerelease? []
    (t.= nil (let [(_ ?rest) (prerelease? "1.0.0")] ?rest))
    (t.= nil (let [(_ ?rest) (prerelease? "1.0.0-dev")] ?rest))
    (t.= false (prerelease? "1.2.3+111"))
    (t.= true (prerelease? "1.2.3-dev+abc"))))

;; vim: set lw+=testing,test:
