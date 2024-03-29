(import-macros {: testing : test} :t)
(local t (require :faith))
(local {: bump/minor} (require :bump))

(fn copy [src dst]
  (with-open [in (io.open src)
              out (io.open dst :w)]
    (out:write (in:read :*a))))

(fn slurp [path]
  (with-open [in (io.open path)]
    (in:read :*a)))

(testing
  (local {: require-version
          : read-version
          : edit}
         (require :bump.generic))
  (test :require-version []
    (t.= "1.0.0" (require-version "t/f/version-exposed.fnl")) 
    (t.error "invalid version "
             #(require-version "t/f/version-invalid.fnl")) 
    (t.error "version not exported "
             #(require-version "t/f/version-not-found.fnl")) 
    (t.error "failed to require "
             #(require-version "t/f/invalid-code.fnl"))) 
  (test :read-version []
    (t.= "1.0.0" (read-version "t/f/version-exposed.fnl")) 
    (t.= "1.1.0" (read-version "t/f/twin-versions.fnl")) 
    (t.error "multiple version strings found"
             #(read-version "t/f/many-versions.fnl")) 
    (t.error "no version string found"
             #(read-version "t/f/no-version.fnl"))) 
  (test :edit []
    (let [origin "t/f/origin-1.fnl"
          clone "t/p/clone-1.fnl"]
      (copy origin clone)
      (t.= true (pcall edit clone bump/minor))
      (t.= "{:version :1.3.0}\n" (slurp clone)))))

;; vim: set lw+=testing,test:
