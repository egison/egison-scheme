(load "./egison.scm")

;(print (match-all (iota 800 1) (Multiset Something) ((cons x (cons y _)) `(,x ,y))))

(print (match-all (iota 800 1) (Multiset Integer) ((cons x (cons ,x _)) x)))
