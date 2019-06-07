(load "./egison.scm")

(print (match-all (iota 2000 1) (List Something) ((join _ (cons x (join _ (cons y _)))) `(,x ,y))))
