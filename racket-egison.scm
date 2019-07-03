(module match-all racket
        (provide match-all Something List Multiset Eq Integer)

(require racket/match)
(require srfi/1)
(require racket/utils)

(define-syntax gen-match-results
  (lambda (x)
          (syntax-case x ()
            [(_ p M t)
             #'(processMStates (list (list MState ((p M t)) '())))])))

(define-syntax match-all
  (lambda (x)
    (syntax-case x ()
      [(t M . ()) #'()]
      [(t M clause . rcs)
       (let* ([clause-datum (syntax->datum (syntax clause))]
              [p (rewrite-pattern (list 'quasiquote (car clause-datum)))]
              [vs (extract-pattern-variables p)]
              [es (cdr clause-datum)])
         #'(append (map (lambda (ret) (apply (lambda vs (begin . es)) ret)) (gen-match-results p M t))
                   (match-all t M . rcs)))])))

;(define-macro (gen-first-match-result p M t)
;  `(processMStates1 (list (list 'MState (list (list ,p ,M ,t) ) {}))))

(define Something 'Something)

(define Eq
  (lambda (p t)
    (match p
           ((list `val x)
            (if (eq? x t)
                '(())
                '()))
           (pvar
            `(((,pvar Something ,t))))
           )))

(define Integer Eq)

(define List
  (lambda (M)
    (lambda (p t)
      (match p
        ((list `nil) (if (eq? t '()) '{{}} '{}))
        ((list `cons px py)
         (match t
                ((list) '{})
                ((list x xs ...)
                 `{{[,px ,M ,x] [,py ,(List M) ,xs]}})))
        ((list `join `_ py)
         (map (lambda (y) `{[,py ,(List M) ,y]})
               (tails t)))
        ((list `join px py)
         (map (lambda (xy) `{[,px ,(List M) ,(car xy)] [,py ,(List M) ,(cadr xy)]})
              (unjoin t)))
        ((list `val x) (if (eq? x t) '{{}} '{}))
        (pvar `{{[,pvar Something ,t]}})))))

(define tails
  (lambda (xs)
    (if (eq? xs '())
        '(())
        (cons xs (tails (cdr xs))))))

(define unjoin
  (lambda (xs)
    (unjoin-helper '((() ())) xs)))

(define unjoin-helper
  (lambda (ret xs)
    (match xs
           ((list) ret)
           ((list y ys ...)
            (cons `(() ,xs) (map (lambda (p) `(,(cons y (car p)) ,(cadr p))) (unjoin ys))))
           )))

(define Multiset
  (lambda (M)
    (lambda (p t)
      (match p
        ((list `nil) (if (eq? t '()) '{{}} '{}))
        ((list `cons px `_) (map (lambda (x) `{[,px ,M ,x]}) t))
        ((list `cons px py)
         (map (lambda (xy) `{[,px ,M ,(car xy)] [,py ,(Multiset M) ,(cadr xy)]})
              (match-all t (List M)
                [(join hs (cons x ts)) `(,x ,(append hs ts))])))
        ((list `val v)
         (match-first `(,v ,t) `(,(List M) ,(Multiset M))
           ('((nil) (nil)) '{{}})
           ('((cons x xs) (cons ,x ,xs)) '{{}})
           ('(_ _) '{})))
        (pvar `{{[,pvar Something ,t]}})))))

)
