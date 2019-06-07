(load "./egison.scm")

(define pm-map
  (lambda (f xs)
    (match-all xs (List Something)
               ((join _ (cons x _)) (f x)))))

(print (pm-map (lambda (x) (+ x 10)) (iota 1000 1)))
; (11 12 13 14)
