(local {: bump/major
        : bump/minor
        : bump/patch
        : bump/prerelease
        : bump/release}
       (require :bump))
(local {: update! : <<?} (require :bump.utils))
(local generic (require :bump.generic))
(local changelog (require :bump.changelog))

(macro print/exit [msg stdout?]
  (if _G._BUMPFNL_DEBUG
      `(error ,msg)
      `(let [out# (if ,stdout? io.stdout io.stderr)]
         (out#:write ,msg "\n")
         (os.exit (if ,stdout? 0 1)))))

(fn show-help [stdout?]
  (let [msg (.. "USAGE: " (. arg 0)
                " [--help|-h]"
                " [--version|-v]"
                " [--major|-M]"
                " [--minor|-m]"
                " [--patch|-p]"
                " [--dev|--alpha|--any-string]"
                " VERSION|FILE")]
    (print/exit msg stdout?)))

(fn show-version []
  (let [{: version} (require :bump)]
    (io.stdout:write version "\n"))
  (os.exit))

(fn parse-args [args]
  (-> (accumulate [config {} _ arg (ipairs args)]
        (case arg
          :--help    (show-help :stdout)
          :-h        (show-help :stdout)
          :--version (show-version)
          :-v        (show-version)
          :--major (update! config :bump #(<<? bump/major $))
          :-M      (update! config :bump #(<<? bump/major $))
          :--minor (update! config :bump #(<<? bump/minor $))
          :-m      (update! config :bump #(<<? bump/minor $))
          :--patch (update! config :bump #(<<? bump/patch $))
          :-p      (update! config :bump #(<<? bump/patch $))
          (where flag (flag:match "^%-%-[^%-]+.*"))
          (let [label (flag:match "^%-%-([^%-]+.*)")]
            (update! config :bump #(<<? #(bump/prerelease $ label) $)))
          any (update! config :version|file #(if $ (show-help) any))))
      (#(if (. $ :version|file) $ (show-help)))
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

{: show-help
 : show-version
 : parse-args
 : bump/version
 : bump/file}
