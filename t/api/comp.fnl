(import-macros {: testing : test} :t)
(local {: version=
        : version<>
        : version<
        : version<=
        : version>
        : version>=}
       (require :bump))
(local t (require :faith))

(testing
  (test :version< []
    (t.= false (version< :1.1.0 :1.1.0))
    (t.= false (version< :1.1.0+001 :1.1.0+002))
    (t.= true (version< :1.0.0-alpha :1.0.0-alpha.1))
    (t.= true (version< :1.0.0-alpha.1 :1.0.0-alpha.beta))
    (t.= true (version< :1.0.0-alpha.beta :1.0.0-beta))
    (t.= true (version< :1.0.0-beta.2 :1.0.0-beta.11))
    (t.= true (version< :1.0.0-beta.11 :1.0.0-rc.1))
    (t.= true (version< :1.0.0-rc.1 :1.0.0))
    (t.= false (version<  :1.0.0-alpha.1 :1.0.0-alpha))
    (t.= false (version<  :1.0.0-alpha.beta :1.0.0-alpha.1))
    (t.= false (version<  :1.0.0-beta :1.0.0-alpha.beta))
    (t.= false (version<  :1.0.0-beta.11 :1.0.0-beta.2))
    (t.= false (version<  :1.0.0-rc.1 :1.0.0-beta.11))
    (t.= false (version<  :1.0.0 :1.0.0-rc.1)))
  (test :version<= []
    (t.= true (version<= :1.1.0 :1.1.0))
    (t.= true (version<= :1.1.0+001 :1.1.0+002)))
  (test :version> []
    (t.= false (version> :1.1.0 :1.1.0))
    (t.= false (version> :1.1.0+001 :1.1.0+002))
    (t.= false (version> :1.0.0-alpha :1.0.0-alpha.1))
    (t.= false (version> :1.0.0-alpha.1 :1.0.0-alpha.beta))
    (t.= false (version> :1.0.0-alpha.beta :1.0.0-beta))
    (t.= false (version> :1.0.0-beta.2 :1.0.0-beta.11))
    (t.= false (version> :1.0.0-beta.11 :1.0.0-rc.1))
    (t.= false (version> :1.0.0-rc.1 :1.0.0))
    (t.= true (version>  :1.0.0-alpha.1 :1.0.0-alpha))
    (t.= true (version>  :1.0.0-alpha.beta :1.0.0-alpha.1))
    (t.= true (version>  :1.0.0-beta :1.0.0-alpha.beta))
    (t.= true (version>  :1.0.0-beta.11 :1.0.0-beta.2))
    (t.= true (version>  :1.0.0-rc.1 :1.0.0-beta.11))
    (t.= true (version>  :1.0.0 :1.0.0-rc.1)))
  (test :version>= []
    (t.= true (version>= :1.1.0 :1.1.0))
    (t.= true (version>= :1.1.0+001 :1.1.0+002)))
  (test :version= []
    (t.= true (version= :1.1.0 :1.1.0))
    (t.= true (version= :1.1.0+001 :1.1.0+002))
    (t.= true (version= :1.1.0+001 :1.1.0))
    (t.= false (version= :1.1.0 :1.1.1))
    (t.= false (version= :1.1.0+001 :1.1.0-dev)))
  (test :version<> []
    (t.= false (version<> :1.1.0 :1.1.0))
    (t.= false (version<> :1.1.0+001 :1.1.0+002))
    (t.= false (version<> :1.1.0+001 :1.1.0))
    (t.= true (version<> :1.1.0 :1.1.1))
    (t.= true (version<> :1.1.0+001 :1.1.0-dev))))

;; vim: set lw+=testing,test:
