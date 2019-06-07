(load "./egison.scm")

(print (match-all (iota 4000 1) (List Something)
                  ((join xs ys) `(,xs ,ys))))

