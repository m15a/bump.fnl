;; fennel-ls: macro-file

(local unpack (or table.unpack _G.unpack))

(fn each/index [bindings & body]
  (let [index (table.remove bindings 1)
        each-form `(each ,bindings ,(unpack body))]
    (table.insert each-form `(set ,index (+ ,index 1)))
    `(do
       (var ,index 1)
       ,each-form)))

{: each/index}
