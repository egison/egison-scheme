(define fn-comb2
  (lambda (xs)
    (fn-comb2-helper xs '())))

(define fn-comb2-helper
  (lambda (xs hs)
    (if (eq? xs '())
        '()
        (append (append (map (lambda (y) `(,(car xs) ,y)) hs)
                        (map (lambda (y) `(,(car xs) ,y)) (cdr xs)))
                (fn-comb2-helper (cdr xs) (append hs `(,(car xs))))))))

(print (fn-comb2 (iota 50 1)))
