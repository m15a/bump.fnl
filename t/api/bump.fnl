(import-macros {: testing : test} :t)
(local t (require :faith))
(local {: bump/major
        : bump/minor
        : bump/patch
        : bump/release
        : bump/prerelease}
       (require :bump))

(testing
  (test :bump/major []
    (t.= "1.0.0"
         (bump/major "0.9.28"))
    (t.= "1.0.0-dev+001"
         (bump/major "0.1.0-dev+001")))
  (test :bump/minor []
    (t.= "0.10.0"
         (bump/minor "0.9.28")))
  (test :bump/patch []
    (t.= "0.9.29"
         (bump/patch "0.9.28")))
  (test :bump/release []
    (t.= "1.1.0"
         (bump/release "1.1.0-dev"))
    (t.= "1.1.0"
         (bump/release "1.1.0-dev+abc")))
  (test :bump/prerelease []
    (t.= "1.1.1-dev"
         (bump/prerelease "1.1.0"))
    (t.= "1.1.1-alpha"
         (bump/prerelease "1.1.0" :alpha))
    (t.= "1.1.1-dev"
         (bump/prerelease "1.1.0+001"))
    (t.error "invalid pre%-release label:"
             #(bump/prerelease "1.1.0" {}))
    (t.error "invalid pre%-release label:"
             #(bump/prerelease "1.1.0" false))
    (t.= "1.2.0-dev" (-> "1.1.1" bump/prerelease bump/minor))))

;; vim: set lw+=testing,test:
