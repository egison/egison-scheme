(define fn-map
  (lambda (f xs)
    (if (null? xs)
        '()
        (cons (f (car xs)) (fn-map f (cdr xs))))))

(print (fn-map (lambda (x) (+ x 10)) (iota 1000 1)))
; (11 12 13 14)
