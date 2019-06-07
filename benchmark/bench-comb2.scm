(load "./egison.scm")

(print (match-all (iota 200 1) (Multiset Something) ((cons x (cons y _)) `(,x ,y))))
