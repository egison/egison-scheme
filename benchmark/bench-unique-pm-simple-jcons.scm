(load "./egison.scm")

(define pm-unique-simple
  (lambda (xs)
    (match-all xs (List Eq)
               ((jcons x (not (jcons ,x _))) x))))

(print (pm-unique-simple (iota 400 1)))
