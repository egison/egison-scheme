;(define-module egison
;  (export match-all
;          match-first
;          Something
;          Eq
;          Integer
;          List
;          Multiset
;          ))
;(select-module egison)

(use util.match)
(use srfi-1)

(define-macro (match-all t M . clauses)
  (if (eq? clauses '())
      '()
      (let* {[clause (car clauses)]
             [p (rewrite-pattern (list 'quasiquote (car clause)))]
             [e (cadr clause)]}
        `(append (map (lambda (ret) (apply (lambda ,(extract-pattern-variables p) ,e) ret)) (gen-match-results ,p ,M ,t))
                 (match-all ,t ,M . ,(cdr clauses))))))

(define-macro (match-first t M . clauses)
  (if (eq? clauses '())
      'not-matched
      (let* {[clause (car clauses)]
             [p (rewrite-pattern (list 'quasiquote (car clause)))]
             [e (cadr clause)]}
        `(let {[rets (map (lambda (ret) (apply (lambda ,(extract-pattern-variables p) ,e) ret)) (gen-match-results ,p ,M ,t))]}
           (if (eq? rets  '())
               (match-first ,t ,M . ,(cdr clauses))
               (car rets))))))

(define rewrite-pattern
  (lambda (p)
    (let {[ret (rewrite-pattern-helper p '())]}
      (car (rewrite-later-pattern-helper (car ret) (cdr ret))))))

(define rewrite-pattern-helper
  (lambda (p xs)
        (match p
               (('unquote q) (cons (list 'val (list 'unquote `(lambda ,xs ,q))) xs))
               (('quote (? list? ps))
                (let {[ret (rewrite-patterns-helper ps xs)]}
                  (cons `(quote ,(car ret)) (cdr ret))))
               (('later p) (cons `(later ,p) xs))
               ((c . args)
                (let {[ret (rewrite-patterns-helper args xs)]}
                  (cons `(,c . ,(car ret)) (cdr ret))))
               ('_ (cons '_ xs))
               (pvar (cons pvar (append xs `(,pvar)))))))

(define rewrite-patterns-helper
  (lambda (ps xs)
    (match ps
           (() (cons '() xs))
           ((p . qs)
            (let* {[ret (rewrite-pattern-helper p xs)]
                   [p2 (car ret)]
                   [xs2 (cdr ret)]
                   [ret2 (rewrite-patterns-helper qs xs2)]
                   [qs2 (car ret2)]
                   [ys (cdr ret2)]}
              (cons (cons p2 qs2)  ys))))))

(define rewrite-later-pattern-helper
  (lambda (p xs)
    (match p
           (('later p)
            (let {[ret (rewrite-pattern-helper p xs)]}
              (cons `(later ,(car ret)) (cdr ret))))
           ((c . args)
            (let {[ret (rewrite-later-patterns-helper args xs)]}
              (cons `(,c . ,(car ret)) (cdr ret))))
           (_ (cons p xs)))))

(define rewrite-later-patterns-helper
  (lambda (ps xs)
    (match ps
           (() (cons '() xs))
           ((p . qs)
            (let* {[ret (rewrite-later-pattern-helper p xs)]
                   [p2 (car ret)]
                   [xs2 (cdr ret)]
                   [ret2 (rewrite-later-patterns-helper qs xs2)]
                   [qs2 (car ret2)]
                   [ys (cdr ret2)]}
              (cons (cons p2 qs2)  ys))))))

(define extract-pattern-variables
  (lambda (p)
    (match p
           (('val _) '())
           (('quote args)
            (concatenate (map extract-pattern-variables args)))
           ((c . args)
            (concatenate (map extract-pattern-variables args)))
           (() '())
           ('_ '())
           (pvar `(,pvar))
           )))

(define-macro (gen-match-results p M t)
  `(processMStates (list (list 'MState (list (list ,p ,M ,t) ) {}))))

(define processMStates
  (lambda (mStates)
    (match mStates
           (() '())
           ((('MState '{} ret) . rs)
            (cons ret (processMStates rs)))
           ((mState . rs)
            (processMStates (append (processMState mState) rs)))
           )))

(define processMState
  (lambda (mState)
    (match mState
           (('MState {[('quote (? list? ps)) (? list? Ms) ts] . mStack} ret)
            (list `(MState ,(append (zip3 ps Ms ts) mStack) ,ret)))
           (('MState {[('val f) M t] . mStack} ret)
            (let {[next-matomss (M `(val ,(apply f ret)) t)]}
              (map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss)))
           (('MState {[('and . ps) M t] . mStack} ret)
            (let {[next-matoms (map (lambda (p) `[,p ,M ,t]) ps)]}
              (list `(MState ,(append next-matoms mStack) ,ret))))
           (('MState {[('or . ps) M t] . mStack} ret)
            (let {[next-matomss (map (lambda (p) `{[,p ,M ,t]}) ps)]}
              (map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss)))
           (('MState {[('not p) M t] . mStack} ret)
            (if (null? (processMStates (list `(MState {[,p ,M ,t]} ,ret))))
                (list `(MState ,mStack ,ret))
                '()))
           (('MState {[('later p) M t] . mStack} ret)
            (list `(MState ,(append mStack `{[,p ,M ,t]}) ,ret)))
           (('MState {['_ 'Something t] . mStack} ret)
            `((MState ,mStack ,ret)))
           (('MState {[pvar 'Something t] . mStack} ret)
            `((MState ,mStack ,(append ret `(,t)))))
           (('MState {[p M t] . mStack} ret)
            (let {[next-matomss (M p t)]}
              (map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss)))
           )))

(define Something 'Something)

(define Eq
  (lambda (p t)
    (match p
           (('val x)
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
             (('cons px py)
              (match t
                     (() '())
                     ((x . xs)
                      `(((,px ,M ,x) (,py ,(List M) ,xs)))
                      )))
             (('join px py)
              (map (lambda (xy) `((,px ,(List M) ,(car xy)) (,py ,(List M) ,(cadr xy))))
                    (unjoin t)))
             (('val x)
              (if (eq? x t)
                  '(())
                  '()))
             (pvar
              `(((,pvar Something ,t))))
             ))))

(define unjoin
  (lambda (xs)
    (unjoin-helper '() xs)))

(define unjoin-helper
  (lambda (ret xs)
    (match xs
           (() ret)
           ((y . ys)
            (cons `(() ,xs) (map (lambda (p) `(,(cons y (car p)) ,(cadr p))) (unjoin ys))))
           )))

(define Multiset
  (lambda (M)
    (lambda (p t)
      (match p
             (() (if (eq? t '()) '{[]} '{}))
             (('cons px py)
              (map (lambda (xy) `((,px ,M ,(car xy)) (,py ,(Multiset M) ,(cadr xy))))
                   (match-all t (List M)
                              [(join hs (cons x ts)) `(,x ,(append hs ts))])))
             (pvar
              `(((,pvar Something ,t))))
             ))))

;;
;; Utility functions
;;

(define zip3
  (lambda [xs ys zs]
    (match `(,xs ,ys ,zs)
           ((() _ _) '())
           ((_ () _) '())
           ((_ _ ()) '())
           (((x . xs) (y . ys) (z . zs)) (cons `(,x ,y ,z) (zip3 xs ys zs))))))
