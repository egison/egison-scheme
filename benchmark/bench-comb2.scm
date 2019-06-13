(load "./egison.scm")

(print (match-all (iota 1600 1) (Multiset Something) ((cons x (cons y _)) `(,x ,y))))
