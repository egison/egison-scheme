(define-syntax egi0
  (lambda (p)
    (syntax-case p ()
      [(_ q)  #'(let ((q 10)) q)])))

(define-syntax egi1
  (lambda (p)
    (syntax-case p ()
      [(_ q)  (syntax (let ((q 10)) q))])))

(define-syntax egi2
  (lambda (p)
    (syntax-case p ()
      [(_ q) (let ((v (car (syntax->datum (syntax q)))))
               #'(let ((v 10)) v))])))

(define-syntax egi3
  (lambda (x)
    (syntax-case x ()
      [(_ . ()) #''()]
      [(_ p . q) (let ((v (car (syntax->datum (syntax p)))))
                    #'(let ((v 10)) '()))])))

(display (egi0 x))
(display (egi1 x))
(display (egi2 (y)))
(display (egi3))
(display (egi3 (x)))

(define odd
  (lambda [n]
    (if (eq? n 0)
        #f
        (even (- n 1)))))

(define even
  (lambda [n]
    (if (eq? n 0)
        #t
        (odd (- n 1)))))

(display (odd 3))



