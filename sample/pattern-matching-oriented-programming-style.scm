(load "./egison.scm")

(define pm-map
  (lambda (f xs)
    (match-all xs (List Something)
               ((join _ (cons x _)) (f x)))))

(pm-map (lambda (x) (+ x 10)) `(1 2 3 4))
; (11 12 13 14)

(define pm-concat
  (lambda (xss)
    (match-all xss (List (List Something))
               ((join _ (cons (join _ (cons x _)) _)) x))))

(pm-concat `((1 2) (3) (4 5)))
; (1 2 3 4 5)

(define pm-concat2
  (lambda (xss)
    (match-all xss (Multiset (Multiset Something))
               ((cons (cons x _) _) x))))

(pm-concat2 `((1 2) (3 4) (4 5)))
; (1 2 3 4 5)

(define pm-unique-simple
  (lambda (xs)
    (match-all xs (List Eq)
               ((join _ (cons x (not (join _ (cons ,x _))))) x))))

(pm-unique-simple `(1 2 3 2 4))
; (1 3 2 4)

(define pm-unique
  (lambda (xs)
    (match-all xs (List Eq)
               ((join (later (not (join _ (cons ,x _)))) (cons x _)) x))))

(pm-unique `(1 2 3 2 4))
; (1 2 3 4)
