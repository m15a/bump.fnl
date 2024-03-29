(local {: view} (require :fennel))

(fn <<? [f ?g]
  (if ?g #(f (?g $)) f))

(fn merge! [tbl ...]
  (each [_ tbl* (ipairs [...])]
    (each [k v (pairs tbl*)]
      (tset tbl k v)))
  tbl)

(fn update! [tbl key fun ?init]
  (doto tbl
    (tset key (fun (or (. tbl key) ?init)))))

(fn escape-regex [s]
  (case (type s)
    :string (pick-values 1 (s:gsub "([%^%$%(%)%%%.%[%]%*%+%-%?])" "%%%1"))
    _ (error "string expected, got " (view s))))

(fn read-contents [path]
  (case (io.open path)
    in (with-open [in in] (in:read :*a))
    (_ msg) (values nil msg)))

(fn read-lines [path]
  (case (io.open path)
    in (with-open [in in]
         (icollect [line (in:lines)] line))
    (_ msg) (values nil msg)))

(fn lines->text [lines]
  (.. (table.concat lines "\n") "\n"))

(fn write-contents [text path]
  (case (io.open path :w)
    out (with-open [out out] (out:write text))
    (_ msg) (values nil msg)))

(fn replace [old new text]
  (case (type text)
    :string (pick-values 1 (text:gsub (escape-regex old) new))
    _ (error "string expected, got " (view text))))

(fn warn [...]
  (when (not _G._BUMPFNL_DEBUG)
    (io.stderr:write "bump.fnl: " ...)
    (io.stderr:write "\n")))

(fn warn/nil [...]
  (if _G._BUMPFNL_DEBUG
      (error (table.concat [...] ""))
      (do
        (warn ...)
        nil)))

{: <<?
 : merge!
 : update!
 : escape-regex
 : read-contents
 : read-lines
 : lines->text
 : write-contents
 : replace
 : warn
 : warn/nil}
