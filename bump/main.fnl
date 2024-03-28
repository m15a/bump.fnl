(local {: version?} (require :bump))
(local {: parse-args
        : bump/version
        : bump/file}
       (require :bump.cli))

(let [{: bump : version|file} (parse-args [...])]
  (if (version? version|file)
      (bump/version bump version|file)
      (bump/file bump version|file)))
