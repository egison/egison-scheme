(use math.prime)
(use util.stream)

(load "./stream-egison.scm")

(define stream-primes (stream-filter bpsw-prime? (stream-iota -1)))

(stream->list
 (stream-take
  (match-all stream-primes (List Integer)
             [`(join _ (cons p (cons ,(+ p 2) _)))
              `(,p ,(+ p 2))])
  10))
; ((3 5) (5 7) (11 13) (17 19) (29 31) (41 43) (59 61) (71 73) (101 103) (107 109))
