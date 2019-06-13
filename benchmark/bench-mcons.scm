(load "./egison.scm")

(print (match-all (iota 1000 1) (Multiset Integer) ((cons ,3 _) "OK")))
