(use util.match)
(use srfi-1)

(load "./egison.scm")

(define neg (lambda (x) (* -1 x)))

(define delete-literal
  (lambda [l cnf]
    (map (lambda [c] (match-all c (Multiset Integer)
                        [(cons (and (not ,l) m) _) m]))
         cnf)))

(define delete-clauses-with
  (lambda [l cnf]
    (match-all cnf (Multiset (Multiset Integer))
      [(cons (and (not (cons ,l _)) c) _) c])))

(define assign-true
  (lambda [l cnf]
    (delete-literal (neg l) (delete-clauses-with l cnf))))

(define tautology?
  (lambda [c]
    (match-first c (Multiset Integer)
      [(cons l (cons ,(neg l) _)) #t]
      [_ #f])))

(define resolve-on
  (lambda [v cnf]
    (filter (lambda [c] (not (tautology? c)))
            (match-all cnf (Multiset (Multiset Integer))
              [(cons (cons ,v xs)
                (cons (cons ,(neg v) ys)
                  _))
               (delete-duplicates (append xs ys))]))))

(define dp
  (lambda [vars cnf]
    (match-first `[,vars ,cnf] `[,(Multiset Integer) ,(Multiset (Multiset Integer))]
                 ['[_ ()] #t]
                 ['[_ (cons () _)] #f]
                 ['[_ (cons (cons l ()) _)]
                  (dp (delete (abs l) vars) (assign-true l cnf))]
                 ['[(cons v vs) (not (cons (cons ,(neg v) _) _))]
                  (dp vs (assign-true v cnf))]
                 ['[(cons v vs) (not (cons (cons ,v _) _))]
                  (dp vs (assign-true (neg v) cnf))]
                 ['[(cons v vs) _]
                  (dp vs (append (resolve-on v cnf)
                                 (delete-clauses-with v (delete-clauses-with (neg v) cnf))))])))

(dp '{} '{}) ; #t
(dp '{} '{{}}) ; #f
(dp '{1} '{{1}}) ; #t
(dp '{1} '{{1} {-1}}) ; #f
(dp '{1 3} '{{-1 3} {1 -3}}) ; #t
(dp '{1 2 3} '{{1 2} {-1 3} {1 -3}}) ; #t
(dp '{1 2} '{{1 2} {-1 -2} {1 -2}}) ; #t
(dp '{1 2} '{{1 2} {-1 -2} {1 -2} {-1 2}}) ; #f
(dp '{1 2 3 4 5} '{{-1 -2 3} {-1 -2 -3} {1 2 3 4} {-4 -2 3} {5 1 2 -3} {-3 1 -5} {1 -2 3 4} {1 -2 -3 5}}) ; #t
(dp '{1 2} '{{-1 -2} {1}}) ; #t
