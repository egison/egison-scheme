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

(macroexpand '(match-all '(1 2 3 2 1) (List Integer)
                         [`(join _ (cons x (join _ (cons (val ,(lambda (x) x)) _))))
                          x]))

;;
;; Test
;;

(match-all 10 Something ['x x]) ; ("OK")
(match-all 10 Eq [`,10 "OK"]) ; ("OK")
(match-all 10 Integer [`x x]) ; (10)
(match-all '(1 2 3) (List Integer) [`(cons x y) `(,x ,y)]) ; ((1 (2 3)))
(match-all '(1 2 3) (List Integer) [`(join x y) `(,x ,y)]) ; ((() (1 2 3)) ((1) (2 3)) ((1 2) (3)))
(match-all '(1 2 3) (List Integer) [`(join _ (cons x _)) x]) ; (1 2 3)
(match-all '(1 2 3) (List Integer) [`(join _ (cons x (join _ (cons y _)))) `(,x ,y)]) ; ((1 2) (1 3) (2 3))
(match-all '(1 2 3) (Multiset Integer) [`(cons x (cons y _)) `(,x ,y)]) ; ((1 2) (1 3) (2 1) (2 3) (3 1) (3 2))
(match-all '(1 2 3 2 1) (List Integer) [`(join _ (cons x (join _ (cons ,x _)))) x]) ; (1 2)
(match-all '(1 2 5 7 4) (Multiset Integer) [`(cons x (cons ,(+ x 1) _)) x]) ; (1 4)
(take (match-all (take *primes* 300) (List Integer) [`(join _ (cons p (cons ,(+ p 2) _))) `(,p ,(+ p 2))]) 10) ; ((3 5) (5 7) (11 13) (17 19) (29 31) (41 43) (59 61) (71 73) (101 103) (107 109))

(match-first '(1 2 5 7 4) (Multiset Integer) [`(cons x (cons ,(+ x 1) _)) x]) ; 1

(stream->list (lazy-match-all 10 Something ['x x])) ; (10)
(stream->list (lazy-match-all 10 Integer ['x x])) ; (10)
(stream->list (lazy-match-all 10 Integer [`,10 "OK"])) ; ("OK")
(stream->list (lazy-match-all (list->stream '(1 2 3)) (List Integer) [`(cons x y) `(,x ,(stream->list y))])) ; ((1 (2 3)))
(stream->list (lazy-match-all (list->stream '(1 2 3)) (List Integer) [`(join x y) `(,(stream->list x) ,(stream->list y))])) ; ((() (1 2 3)) ((1) (2 3)) ((1 2) (3)))

(stream->list (stream-take (lazy-match-all (stream-iota -1) (List Integer) [`(join x y) `(,(stream->list x) ,y)]) 10))
; ((() (1 2 3)) ((1) (2 3)) ((1 2) (3)))

(stream->list (stream-take (lazy-match-all (stream-iota 3) (Multiset Integer) [`(cons x (cons y _)) `(,x ,y)]) 6)) ; ((0 1) (0 2) (1 0) (1 2) (2 0) (2 1))

(define stream-primes (stream-filter bpsw-prime? (stream-iota -1)))

(stream->list
 (stream-take
  (lazy-match-all stream-primes (List Integer)
                  [`(join _ (cons p (cons ,(+ p 2) _)))
                   `(,p ,(+ p 2))])
  10))
; ((3 5) (5 7) (11 13) (17 19) (29 31) (41 43) (59 61) (71 73) (101 103) (107 109))
