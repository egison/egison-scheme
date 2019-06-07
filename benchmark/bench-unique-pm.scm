(load "./egison.scm")

(define pm-unique
  (lambda (xs)
    (match-all xs (List Eq)
               ((join (later (not (join _ (cons ,x _)))) (cons x _)) x))))

(print (pm-unique (iota 600 1)))
