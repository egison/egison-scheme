;;
;; Debug
;;

(use math.prime)

(extract-pattern-variables '(join _ (cons x (join _ (cons (val x) _)))))
(extract-pattern-variables '(join _ (cons x (join _ (cons y _)))))
(extract-pattern-variables `(cons x y))
(extract-pattern-variables `(join _ (cons p (cons (val ,(lambda (p) (+ p 2))) _))))

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
(match-all '(1 2 3 2 1) (List Integer) [`(join _ (cons x (join _ (cons (val ,(lambda (x) x)) _)))) x])
(take (match-all (take *primes* 300) (List Integer) [`(join _ (cons p (cons (val ,(lambda (p) (+ p 2))) _))) `(,p ,(+ p 2))]) 10)
(take (lmap car (unjoin *primes*)) 10)

(map car (unjoin (take *primes* 10)))
(define pm-map
  (lambda (f xs)
    (match-all xs (List Something)
               (`(join _ (cons x _)) (f x)))))

(pm-map (lambda (x) (+ x 10)) `(1 2 3 4))

(define pm-concat
  (lambda (xss)
    (match-all xss (List (List Something))
               (`(join _ (cons (join _ (cons x _)) _)) x))))

(pm-concat `((1 2) (3) (4 5)))

(define pm-concat2
  (lambda (xss)
    (match-all xss (Multiset (Multiset Something))
               (`(cons (cons x _)) x))))

(pm-concat2 `((1 2) (3) (4 5)))
