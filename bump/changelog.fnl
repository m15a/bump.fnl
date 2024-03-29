(local {: view} (require :fennel))
(local {: version?
        : release?
        : prerelease?
        : parse}
       (require :bump))
(local {: escape-regex
        : merge!
        : read-lines
        : lines->text
        : write-contents
        : warn
        : warn/nil}
       (require :bump.utils))
(import-macros {: each/index} :bump.utils)

(fn unreleased? [x]
  (if (and (= :string (type x))
           (x:match "^[Uu]nreleased$"))
      true
      false))

(fn parse-date [line]
  (when (not= :string (type line))
    (error (.. "string expected, got " (view line))))
  (let [Y-m-d-z {:pattern "%d%d%d%d%-%d%d%-%d%d%s+[%-%+]%d%d%d%d"
                 :format "%Y-%m-%d %z"}
        Y-m-d-Z {:pattern "%d%d%d%d%-%d%d%-%d%d%s+%u%u%u"
                 :format "%Y-%m-%d %Z"}
        Y-m-d {:pattern "%d%d%d%d%-%d%d%-%d%d"
               :format "%Y-%m-%d"}]
    (if (line:match Y-m-d-z.pattern) Y-m-d-z
        (line:match Y-m-d-Z.pattern) Y-m-d-Z
        (line:match Y-m-d.pattern) Y-m-d
        (values nil "no date pattern found"))))

(fn parse-heading [line version ?date-pattern]
  (when (not= :string (type line))
    (error (.. "string expected, got " (view line))))
  (when (not (or (version? version)
                 (unreleased? version)))
    (error (.. "version string expected, got " (view version))))
  (when (and (not= nil ?date-pattern)
             (not= :string (type ?date-pattern)))
    (error (.. "string expected, got " (view ?date-pattern))))
  (let [fmt (line:gsub (escape-regex version) "{{VERSION}}")]
    {:format (if ?date-pattern
                 (fmt:gsub ?date-pattern "{{DATE}}")
                 fmt)}))

(fn url/pattern [version]
  (when (not (or (version? version)
                 (unreleased? version)))
    (error (.. "version string expected, got " (view version))))
  {:pattern (.. "^%s*%[v?" (escape-regex version) "%]:%s+<?http")})

(fn parse-url [line version]
  (when (not= :string (type line))
    (error (.. "string expected, got " (view line))))
  (when (not (or (version? version)
                 (unreleased? version)))
    (error (.. "version string expected, got " (view version))))
  {:format (line:gsub (escape-regex version) "{{VERSION}}")})

(fn %analyze/heading! [info ln id line]
  (doto (. info id)
    (merge! {: ln :date (parse-date line)}))
  (case (or (line:match "[Uu]nreleased")
            (parse line))
    v (doto (. info id)
        (merge! (if (version? v)
                    {:version v}
                    {:unreleased? true})
                (if (version? v)
                    (parse-heading line v (case (?. info id :date)
                                            d d.pattern))
                    {})
                {:url (url/pattern v)}))))

(fn %analyze/url! [info ln id line]
  (doto (. info id :url)
    (merge! {: ln}
            (case (?. info id :version)
              v (parse-url line v)))))

(fn %analyze/cleanup! [info]
  (for [i 1 2]
    (when (?. info i :date :pattern)
      (tset info i :date :pattern nil))
    (when (?. info i :url :pattern)
      (tset info i :url :pattern nil))
    (when (not (next (?. info i :url)))
      (tset info i :url nil)))
  info)

(fn analyze [path]
  "Analyze changelog at the `path` and return the analysed information.

The result is a sequential table of length 2, each contains information about
the first and second level-2 headings, respectively:

- `ln`: line number of the heading;
- `unreleased?`: whether the heading is `Unreleased` or not;
- `version`: contained version string if any;
- `format`: Format of the heading, e.g., `## [{{VERSION}}] - {{DATE}}`;
- `date` - date information:
  - `format`: `os.date` format;
- `url` - information about the URL line corresponding to the heading:
  - `ln`: line number; and
  - `format`: URL line format, e.g., `[{{VERSION}}]: https://.../v{{VERSION}}`.

Return the result information in case of success; otherwise return `nil`."
  (case (io.open path)
    in (with-open [in in]
         (let [info [{:url {}} {:url {}}]]
           (var heading-id 1)
           (var url-id 1)
           (each/index [ln line (in:lines) &until (< 2 url-id)]
             (when (and (<= heading-id 2)
                        (line:match "^%s*## "))
               (%analyze/heading! info ln heading-id line)
               (set heading-id (+ heading-id 1)))
             (when (and (<= url-id 2)
                        (case (?. info url-id :url :pattern)
                          pat (line:match pat)))
               (%analyze/url! info ln url-id line)
               (set url-id (+ url-id 1))))
           (%analyze/cleanup! info)))
    (_ msg) (warn/nil msg)))

(fn validate [info]
  (if (or (?. info 2 :unreleased?)
          (prerelease? (?. info 2 :version)))
      (warn/nil "invalid changelog: 2nd heading has pre-release version")
      (and (not (?. info 1 :version))
           (not (?. info 2 :version)))
      (warn/nil "changelog lacks sufficient version information")
      info))

(fn %new-heading [info heading-id new-version]
  (case (?. info heading-id :format)
    fmt (fmt:gsub "{{VERSION}}" new-version)
    _ (error (.. (. ["1st" "2nd"] heading-id)
                 " level-2 heading has no format"))))

(fn %new-heading/date [info heading-id new-version]
  (let [heading (%new-heading info heading-id new-version)]
    (case (?. info heading-id :date :format)
      dfmt (heading:gsub "{{DATE}}" (os.date dfmt))
      _ heading)))

(fn %update/unreleased [lines info new]
  (let [heading (%new-heading/date info 2 new)
        unreleased (. info 1)]
    (doto lines
      (table.insert (+ unreleased.ln 1) "")
      (table.insert (+ unreleased.ln 2) heading))
    (case (?. info 2 :url)
      url (let [line (url.format:gsub "{{VERSION}}" new)]
            (doto lines
              (table.insert (+ url.ln 2) line)))
      _ lines)))

(fn %update/prerelease->prerelease [lines info new]
  (let [heading (%new-heading info 1 new)]
    (tset lines (. info 1 :ln) heading)
    (case (?. info 1 :url)
      url (let [line (url.format:gsub "{{VERSION}}" new)]
            (doto lines
              (tset url.ln line)))
      _ lines)))

(fn %update/prerelease->release [lines info new]
  (let [heading (%new-heading/date info 2 new)]
    (tset lines (. info 1 :ln) heading)
    (case-try (?. info 1 :url)
      url-1 (?. info 2 :url)
      url-2 (let [line (url-2.format:gsub "{{VERSION}}" new)]
              (doto lines
                (tset url-1.ln line)))
      (catch _ lines))))

(fn %update/release->prerelease [lines info new]
  (let [heading (-> (%new-heading info 1 new)
                    (string.gsub "{{DATE}}" "???"))
        release (. info 1)]
    (doto lines
      (table.insert release.ln heading)
      (table.insert (+ release.ln 1) ""))
    (case (?. info 1 :url)
      url (let [line (-> url.format
                         (string.gsub "{{VERSION}}" new 1)
                         (string.gsub "v?{{VERSION}}" "HEAD"))]
            (doto lines
              (table.insert (+ url.ln 2) line)))
      _ lines)))

(fn %update/release->release [lines info new]
  (let [heading (%new-heading/date info 1 new)
        release (. info 1)]
    (doto lines
      (table.insert release.ln heading)
      (table.insert (+ release.ln 1) ""))
    (case (?. info 1 :url)
      url (let [line (url.format:gsub "{{VERSION}}" new)]
            (doto lines
              (table.insert (+ url.ln 2) line)))
      _ lines)))

(fn %select-updater [info bump]
  (if (?. info 1 :unreleased?)
      (case (?. info 2 :version)
        old (let [new (bump old)]
              (if (or (= old new) (not (release? new)))
                  #(warn/nil "invalid version bumping: " old " -> " new)
                  #(%update/unreleased $1 $2 new)))
        _ (warn/nil "missing previous version string"))

      (prerelease? (?. info 1 :version))
      (let [old (. info 1 :version)
            new (bump old)]
        (if (= old new)
            #(warn/nil "invalid version bumping: " old " -> " new)
            (release? new)
            #(%update/prerelease->release $1 $2 new)
            #(%update/prerelease->prerelease $1 $2 new)))

      ;; If the first level-2 heading has release version but missing
      ;; date AND the second level-2 heading has version and date,
      ;; it may imply pre-release version.
      (and (release? (?. info 1 :version))
           (not (?. info 1 :date))
           (?. info 2 :version)
           (?. info 2 :date))
      (let [new (. info 1 :version)]
        (warn "ignore flags and just release version: " new)
        #(%update/prerelease->release $1 $2 new))

      (release? (?. info 1 :version))
      (let [old (. info 1 :version)
            new (bump old)]
        (if (= old new)
            #(warn/nil "invalid version bumping: " old " -> " new)
            (release? new)
            #(%update/release->release $1 $2 new)
            #(%update/release->prerelease $1 $2 new)))

      (error "failed to select updater")))

(fn update [path info bump]
  "Update changelog at `path` based on the analyzed `info` and `bump` function."
  (case-try (%select-updater info bump)
    update (read-lines path)
    old (update old info)
    new (lines->text new)
    (catch
      (_ ?msg) (let [msg (.. "failed to update changelog '" path "'")
                     more (if ?msg (.. ": " ?msg) "")]
                 (warn/nil msg more)))))

(fn edit [path bump]
  "Bump version in a changelog at the `path` by using `bump` function.

To update changelog, we will insert or update a level-2 heading containing
bumped version string, and insert or update a URL line (i.e., a line around
the bottom of the changelog, which looks like `[version]: https://...`)."
    (case-try (analyze path)
      info (validate info)
      info (update path info bump)
      edited (and (write-contents edited path) true)
      (catch _ (warn/nil "failed to edit changelog '" path "'"))))

(fn changelog? [path]
  (case (type path)
    :string (if (path:match "[Cc][Hh][Aa][Nn][Gg][Ee][Ll][Oo][Gg]")
                true
                false)
    _ false))

{: parse-date
 : parse-heading
 : url/pattern
 : parse-url
 : analyze
 : validate
 : update
 : edit
 : changelog?}

;; vim: lw+=each/index
