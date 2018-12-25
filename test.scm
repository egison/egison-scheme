(use math.prime)

;;
;; Debug
;;

(extract-pattern-variables '(join _ (cons x (join _ (cons (val ,(lambda (x) x)) _)))))
(extract-pattern-variables '(join _ (cons x (join _ (cons y _)))))
(extract-pattern-variables `(cons x y))
(extract-pattern-variables `(join _ (cons p (cons (val ,(lambda (p) (+ p 2))) _))))

(gen-match-results 'x 'Something 10)

(macroexpand '(match-all 10 Something [x x]))
(macroexpand '(gen-match-results x Something 10))

;;
;; Test
;;

(match-all 10 Something ['x x])
(match-all 10 Eq [`(val ,(lambda () 10)) "OK"])
(match-all 10 Integer [`(val ,(lambda () 10)) "OK"])
(match-all 10 Integer [`x x])
(match-all '(1 2 3) (List Integer) [`(cons x y) `(,x ,y)])
(match-all '(1 2 3) (List Integer) [`(join x y) `(,x ,y)])
(match-all '(1 2 3) (List Integer) [`(join _ (cons x _)) x])
(match-all '(1 2 3) (List Integer) [`(join _ (cons x (join _ (cons y _)))) `(,x ,y)])
(match-all '(1 2 3) (Multiset Integer) [`(cons x (cons y _)) `(,x ,y)])
(match-all '(1 2 3 2 1) (List Integer) [`(join _ (cons x (join _ (cons (val ,(lambda (x) x)) _)))) x])
(match-all '(1 2 3 2 1) (Multiset Integer) [`(cons x (cons (val ,(lambda (x) x)) _)) x])
(take (match-all (take *primes* 300) (List Integer) [`(join _ (cons p (cons (val ,(lambda (p) (+ p 2))) _))) `(,p ,(+ p 2))]) 10)

(match-first '(1 2 3 2 1) (List Integer) [`(join _ (cons x (join _ (cons (val ,(lambda (x) x)) _)))) x])
