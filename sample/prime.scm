(use math.prime)
(use util.stream)

(load "./stream-egison.scm")

(define stream-primes (stream-filter bpsw-prime? (stream-iota -1)))

(stream->list
 (stream-take
  (match-all stream-primes (List Integer)
             [(join _ (cons p (cons ,(+ p 2) _)))
              `(,p ,(+ p 2))])
  10))
; ((3 5) (5 7) (11 13) (17 19) (29 31) (41 43) (59 61) (71 73) (101 103) (107 109))

(stream->list
 (stream-take
  (match-all stream-primes (List Integer)
             [(join _ (cons p (cons (and (or ,(+ p 2) ,(+ p 4)) m) (cons ,(+ p 6) _))))
              `(,p ,m ,(+ p 6))])
  10))
; ((5 7 11) (7 11 13) (11 13 17) (13 17 19) (17 19 23) (37 41 43) (41 43 47) (67 71 73) (97 101 103) (101 103 107))

(stream->list
 (stream-take
  (match-all stream-primes (List Integer)
             [(join _ (cons p (cons (not ,(+ p 2)) _)))
              `(,p ,(+ p 2))])
  10))
; ((2 4) (7 9) (13 15) (19 21) (23 25) (31 33) (37 39) (43 45) (47 49) (53 55))
