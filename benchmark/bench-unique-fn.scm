(define fn-unique
  (lambda (xs)
    (if (null? xs)
        '()
        (cons (car xs) (fn-unique (delete-all (car xs) (cdr xs)))))))

(define delete-all
  (lambda (x xs)
    (if (null? xs)
        '()
        (if (eq? x (car xs))
            (delete-all x (cdr xs))
            (cons (car xs) (delete-all x (cdr xs)))))))

(print (fn-unique (iota 1200 1)))
