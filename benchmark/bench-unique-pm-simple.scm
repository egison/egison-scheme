(load "./egison.scm")

(define pm-unique-simple
  (lambda (xs)
    (match-all xs (List Eq)
               ((join _ (cons x (not (join _ (cons ,x _))))) x))))

(print (pm-unique-simple '(1 2 3 2 3 4)))
(print (pm-unique-simple (iota 1600 1)))
