(import-macros {: testing : test} :t)
(local t (require :faith))
(local {: compose : decompose} (require :bump))

(testing
  (test :decompose []
    (t.= {:major 0 :minor 1 :patch 0 :prerelease :dev :build :001}
         (decompose "0.1.0-dev+001"))
    (t.error "expected one build tag,"
             #(decompose "0.0.1+a+b"))
    (t.error "invalid pre%-release label and/or build tag:"
             #(decompose "0.0.1=dev")))
  (test :compose []
    (t.= "0.1.0-dev"
         (compose {:major 0 :minor 1 :patch 0 :prerelease :dev}))
    (t.= "0.1.0-dev"
         (compose {:major :0 :minor :1 :patch :0 :prerelease :dev}))
    (t.= "0.1.0+0.15"
         (compose {:major 0 :minor 1 :patch 0 :build 0.15}))
    (t.= "0.1.0-test-case+exp.1"
         (compose {:major 0 :minor 1 :patch 0 :prerelease :test-case
                   :build :exp.1}))
    (let [msg "invalid version component%(s%)"]
      (t.error msg #(compose {:minor 1 :patch 0}))
      (t.error msg #(compose {:major 1 :minor 1 :patch 0 :prerelease false}))
      (t.error msg #(compose {:major 1 :minor 1 :patch 0 :prerelease [1]}))
      (t.error msg #(compose {:major 1 :minor 1 :patch 0 :build #$})))))

;; vim: set lw+=testing,test:
