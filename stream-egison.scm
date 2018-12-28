;(define-module stream-egison
;  (export match-all
;          Something
;          Eq
;          Integer
;          List
;          Multiset
;          ))
;(select-module stream-egison)

(use util.match)
(use srfi-1)
(use util.stream)

(define-macro (match-all t M . clauses)
  (if (eq? clauses '())
      '()
      (let* {[clause (car clauses)]
             [p (rewrite-pattern (car clause))]
             [e (cadr clause)]}
        `(stream-append (stream-map (lambda (ret) (apply (lambda ,(extract-pattern-variables p) ,e) ret))
                                    (gen-match-results ,p ,M ,t))
                        (match-all ,t ,M . ,(cdr clauses))))))

(define rewrite-pattern
  (lambda (p)
    (car (rewrite-pattern-helper p '()))))

(define rewrite-pattern-helper
  (lambda (p xs)
        (match p
               (('unquote q) (cons (list 'val (list 'unquote `(lambda ,xs ,q))) xs))
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

(define extract-pattern-variables
  (lambda (p)
    (match p
           (('val _) '())
           ((c . args)
            (concatenate (map extract-pattern-variables args)))
           ('_ '())
           (pvar `(,pvar))
           )))

(define-macro (gen-match-results p M t)
  `(processMStatesAll (list (stream (list 'MState (list (list ,p ,M ,t) ) {})))))

(define processMStatesAll
  (lambda (mStatess)
    (if (eq? mStatess '())
        stream-null
        (let* {
               [newMStatess (filter (lambda (s) (not (stream-null? s))) (concatenate (map processMStates mStatess)))]
               [ret (extractBindings newMStatess)]
               [bindings (car ret)]
               [nextMStatess (cdr ret)]
               }
          (stream-append (list->stream bindings) (lazy (processMStatesAll nextMStatess)))))))

(define extractBindings
  (lambda (mStatess)
    (cons (map (lambda (mStates) (extractBinding (stream-car mStates)))
               (filter (lambda (mStates) (matchingResult? (stream-car mStates)))
                       mStatess))
          (filter (lambda (mStates)
                    (not (matchingResult? (stream-car mStates))))
                  mStatess))))

(define matchingResult?
  (lambda (mState)
    (match mState
           (('MState '{} ret) #t)
           (_ #f))))

(define extractBinding
  (lambda (mState)
    (match mState
           (('MState '{} ret) ret))))

(define processMStates
  (lambda (mStates)
    (if (stream-null? mStates)
        '()
        (let {[mState (stream-car mStates)]}
          `(,(processMState mState) ,(stream-cdr mStates))))))

(define processMStatesOld
  (lambda (mStates)
    (if (stream-null? mStates)
        '()
        (let {[mState (stream-car mStates)]}
          (match mState
                 (('MState '{} ret)
                  (stream-cons ret (processMStates (stream-cdr mStates))))
                 (_
                  (processMStates (stream-append (processMState mState) (stream-cdr mStates))))
                 )))))

(define processMState
  (lambda (mState)
    (match mState
           (('MState {[('val f) M t] . mStack} ret)
            (let {[next-matomss (M `(val ,(apply f ret)) t)]}
              (stream-map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss)))
           (('MState {['_ 'Something t] . mStack} ret)
            (stream `(MState ,mStack ,ret)))
           (('MState {[pvar 'Something t] . mStack} ret)
            (stream `(MState ,mStack ,(append ret `(,t)))))
           (('MState {[p M t] . mStack} ret)
            (let {[next-matomss (M p t)]}
              (stream-map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss)))
           )))

(define Something 'Something)

(define Eq
  (lambda (p t)
    (match p
           (('val x)
            (if (eq? x t)
                (stream '())
                stream-null))
           (pvar
            (stream `((,pvar Something ,t))))
           )))

(define Integer Eq)

(define List
  (lambda (M)
    (lambda (p t)
      (match p
             (('cons px py)
              (stream-map (lambda (xy) `((,px ,M ,(car xy)) (,py ,(List M) ,(cadr xy))))
                          (uncons t)))
             (('join px py)
              (stream-map (lambda (xy) `((,px ,(List M) ,(car xy)) (,py ,(List M) ,(cadr xy))))
                          (unjoin t)))
             (('val x)
              (if (eq? x t)
                  (stream '())
                  stream-null))
             (pvar
              (stream `((,pvar Something ,t))))
             ))))

(define uncons
  (lambda (xs)
    (if (stream-null? xs)
        stream-null
        (stream `(,(stream-car xs) ,(stream-cdr xs))))))

(define unjoin
  (lambda (xs)
    (if (stream-null? xs)
        stream-null
        (stream-cons `(,stream-null ,xs)
                     (stream-map (lambda (p) `(,(stream-cons (stream-car xs) (car p)) ,(cadr p)))
                                 (unjoin (stream-cdr xs)))))))

(define Multiset
  (lambda (M)
    (lambda (p t)
      (match p
             (('cons px py)
              (stream-map (lambda (xy) `((,px ,M ,(car xy)) (,py ,(Multiset M) ,(cadr xy))))
                          (match-all t (List M)
                                     ['(join hs (cons x ts)) `(,x ,(stream-append hs ts))])))
             (pvar
              (stream `((,pvar Something ,t))))
             ))))
