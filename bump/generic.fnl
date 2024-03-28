(local {: view : dofile} (require :fennel))
(local {: gparse : version?} (require :bump))
(local {: replace
        : read-contents
        : write-contents
        : warn
        : warn/nil} (require :bump.utils))

(fn parse/one [text]
  "Find the one true version in the `text`; otherwise return `nil` and message."
  (let [versions (collect [v (gparse text)] v true)]
    (case (next versions)
      v (case (next versions v)
          u (values nil (.. "multiple version strings found: at least "
                            v " and " u))
          _ v)
      _ (values nil "no version string found"))))

(fn require-version [path]
  "Try `dofile` the `path` and search for exposed version."
  (case (pcall dofile path)
    (where (true x) (= :table (type x)))
    (case (. x :version)
      v (if (version? v) v
            (warn/nil "invalid version " (view v) " in '" path "'"))
      _ (warn/nil "version not exported in '" path "'"))
    _ (warn/nil "failed to require version from '" path "'")))

(fn read-version [path]
  "Read the `path` and search for exactly one version string."
  (warn "attempt to find version in '" path "' as text file")
  (case (io.open path)
    in (with-open [in in]
         (case (parse/one (in:read :*a))
           v v
           (_ msg) (warn/nil msg)))
    (_ msg) (warn/nil msg)))

(fn edit [path bump]
  "Bump version in the file `path` by using `bump` function.

It tries the following heuristics one by one:

1. Require the file with `dofile` and see if it has `:version` entry.
2. Read the file as text and search for one unique version string.

After that, if any unique version string is found, it bumps the version and
replace the old version string with the new one."
  (case-try (or (require-version path)
                (read-version path))
    version (read-contents path)
    text (let [edited (replace version (bump version) text)]
           (and (write-contents edited path) true))
    (catch _ (warn/nil "failed to edit '" path "'"))))

{: require-version
 : read-version
 : edit}
