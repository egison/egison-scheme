(load "./egison.scm")

(define fn-comb2
  (lambda (xs)
    (if (null? xs)
        '()
        (append (map (lambda (y) `(,(car xs) ,y)) (cdr xs))
                (fn-comb2 (cdr xs))))))

(print (length (fn-comb2 (iota 500 1))))
