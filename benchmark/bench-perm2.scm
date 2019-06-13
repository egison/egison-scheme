(load "./egison.scm")

(print (match-all (iota 500 1) (List Something) ((join _ (cons x (join _ (cons y _)))) `(,x ,y))))
