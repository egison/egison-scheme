;;
;; Debug
;;

(extract-pattern-variables '(join _ (cons x (join _ (cons (val x) _)))))
(extract-pattern-variables '(join _ (cons x (join _ (cons y _)))))
(extract-pattern-variables `(cons x y))

(gen-match-results 'x 'Something 10)

(macroexpand '(match-all 10 Something [x x]))
(macroexpand '(gen-match-results x Something 10))

(match-all 10 Something ['x x])
(match-all 10 Eq ['(val 10) "OK"])
(match-all 10 Integer ['(val 10) "OK"])
(match-all 10 Integer ['x x])
(match-all '(1 2 3) (List Integer) [`(cons x y) `(,x ,y)])
(match-all '(1 2 3) (List Integer) [`(join x y) `(,x ,y)])
(match-all '(1 2 3) (List Integer) [`(join _ (cons x _)) x])
(match-all '(1 2 3) (List Integer) [`(join _ (cons x (join _ (cons y _)))) `(,x ,y)])
(match-all '(1 2 3) (Multiset Integer) [`(cons x (cons y _)) `(,x ,y)])
(match-all '(1 2 3 1) (List Integer) [`(join _ (cons x (join _ (cons (val x) _)))) `(,x ,y)])
