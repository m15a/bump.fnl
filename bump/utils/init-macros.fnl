;; fennel-ls: macro-file

(local unpack (or table.unpack _G.unpack))

(fn each/index [bindings & body]
  (let [index (table.remove bindings 1)
        each-form `(each ,bindings ,(unpack body))]
    (table.insert each-form `(set ,index (+ ,index 1)))
    `(do
       (var ,index 1)
       ,each-form)))

(fn warn [& msgs]
  (when (not _G._BUMPFNL_DEBUG)
    (let [warn `(io.stderr:write "bump.fnl: " ,(unpack msgs))]
      (table.insert warn "\n")
      warn)))

(fn warn/nil [& msgs]
  (if _G._BUMPFNL_DEBUG
      `(error (table.concat ,msgs ""))
      `(do
         (warn ,(unpack msgs))
         nil)))

{: each/index
 : warn
 : warn/nil}
