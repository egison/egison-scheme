(load "./egison.scm")

(define fact
  (lambda [n r]
    (if (eq? n 0)
        r
        (fact (- n 1) (+ n r)))))

(define fact2
  (lambda [n]
    (if (eq? n 0)
        1
        (+ n (fact2 (- n 1))))))

(define fact3
  (lambda [n r]
    (match-first n Integer
        [,0 1]
        [_ (fact (- n 1) (+ n r))])))

;(print (fact  100000000 1)) ; 2.57s
;(print (fact2 100000000)) ; 17.85s
;(print (fact3 100000000 1)) ; 2.56s
