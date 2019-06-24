;;
;; Egison Test
;;

(load "./egison.scm")

(match-all 10 Something [x x]) ; ("OK")
(match-all 10 Eq [,10 "OK"]) ; ("OK")
(match-all 10 Integer [x x]) ; (10)
(match-all '(1 2 3) (List Integer) [(cons x y) `(,x ,y)]) ; ((1 (2 3)))
(match-all '(1 2 3) (List Integer) [(join x y) `(,x ,y)]) ; ((() (1 2 3)) ((1) (2 3)) ((1 2) (3)))
(match-all '(1 2 3) (List Integer) [(join _ (cons x _)) x]) ; (1 2 3)
(match-all '(1 2 3) (List Integer) [(join _ (cons x (join _ (cons y _)))) `(,x ,y)]) ; ((1 2) (1 3) (2 3))
(match-all '(1 2 3) (Multiset Integer) [(cons x (cons y _)) `(,x ,y)]) ; ((1 2) (1 3) (2 1) (2 3) (3 1) (3 2))
(match-all '(1 2 3 2 1) (List Integer) [(join _ (cons x (join _ (cons ,x _)))) x]) ; (1 2)
(match-all '(1 2 5 7 4) (Multiset Integer) [(cons x (cons ,(+ x 1) _)) x]) ; (1 4)

(match-first '(1 2 5 7 4) (Multiset Integer) [(cons x (cons ,(+ x 1) _)) x]) ; 1

(match-all 10 Something [(and x y) `(,x ,y)]) ; ("OK")
(match-all 10 Integer [(or ,10 ,20) "OK"]) ; ("OK")
(match-all 10 Integer [(or ,20 ,10) "OK"]) ; ("OK")
(match-all 10 Integer [(or ,20 ,30) "OK"]) ; ()
(match-all `(1 1 2) (List Integer) [(cons x (cons ,x _)) x]) ; (1)
(match-all `(1 1 2) (List Integer) [(cons (later y) (cons x _)) `(,x ,y)]) ; ()
(match-all `(1 1 2) (List Integer) [(cons (later ,x) (cons x _)) x]) ; (1)
(match-all `(1 1 2) (List Integer) [(cons x (cons (not ,x) _)) x]) ; ()

