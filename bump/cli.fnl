(local {: bump/major
        : bump/minor
        : bump/patch
        : bump/prerelease
        : bump/release}
       (require :bump))
(local {: update! : <<?} (require :bump.utils))
(local generic (require :bump.generic))
(local changelog (require :bump.changelog))

(fn help []
  (let [msg (.. "USAGE: " (. arg 0)
                " [--major|-M]"
                " [--minor|-m]"
                " [--patch|-p]"
                " [--dev|--alpha|--any-string]"
                " VERSION|FILE" "\n")]
    (if _G._BUMPFNL_DEBUG
        (error msg)
        (do
          (io.stderr:write msg)
          (os.exit 1)))))

(fn parse-args [args]
  (-> (accumulate [config {} _ arg (ipairs args)]
        (case arg
          :--major (update! config :bump #(<<? bump/major $))
          :-M      (update! config :bump #(<<? bump/major $))
          :--minor (update! config :bump #(<<? bump/minor $))
          :-m      (update! config :bump #(<<? bump/minor $))
          :--patch (update! config :bump #(<<? bump/patch $))
          :-p      (update! config :bump #(<<? bump/patch $))
          (where flag (flag:match "^%-%-[^%-]+.*"))
          (let [label (flag:match "^%-%-([^%-]+.*)")]
            (update! config :bump #(<<? #(bump/prerelease $ label) $)))
          any (update! config :version|file #(if $ (help) any))))
      (#(if (. $ :version|file) $ (help)))
      (update! :bump #(or $ bump/release))))

(fn bump/version [bump version]
  (io.stdout:write (bump version) "\n")
  (os.exit))

(fn bump/file [bump path]
  (case (if (changelog.changelog? path)
            (changelog.edit path bump)
            (generic.edit path bump))
    true (os.exit)
    _ (os.exit 1)))

{: help
 : parse-args
 : bump/version
 : bump/file}
