(define fn-perm2
  (lambda (xs)
    (fn-perm2-helper xs '())))

(define fn-perm2-helper
  (lambda (xs hs)
    (if (eq? xs '())
        '()
        (append (append (map (lambda (y) `(,(car xs) ,y)) hs)
                        (map (lambda (y) `(,(car xs) ,y)) (cdr xs)))
                (fn-perm2-helper (cdr xs) (cons (car xs) hs))))))

(print (fn-perm2 (iota 1600 1)))
