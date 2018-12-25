(use util.match)
(use srfi-1)

(define-macro (match-all t M . clauses)
  (if (eq? clauses '())
      '()
      (let* {[clause (car clauses)]
             [p (car clause)]
             [e (cadr clause)]}
        `(append (map (lambda (ret) (apply (lambda ,(extract-pattern-variables p) ,e) ret)) (gen-match-results ,p ,M ,t))
                 (match-all ,t ,M . ,(cdr clauses))))))

(define-macro (match-first t M . clauses)
  (if (eq? clauses '())
      'not-matched
      (let* {[clause (car clauses)]
             [p (car clause)]
             [e (cadr clause)]}
        `(let {[rets (map (lambda (ret) (apply (lambda ,(extract-pattern-variables p) ,e) ret)) (gen-match-results ,p ,M ,t))]}
           (if (eq? rets  '())
               (match-first ,t ,M . ,(cdr clauses))
               (car rets))))))


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
           (('MState {[('val f) M t] . mStack} ret)
            (let {[next-matomss (M `(val ,(apply f ret)) t)]}
              (map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss)))
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
             (('cons px py)
              (map (lambda (xy) `((,px ,M ,(car xy)) (,py ,(Multiset M) ,(cadr xy))))
                   (match-all t (List M)
                              ['(join hs (cons x ts)) `(,x ,(append hs ts))])))
             (pvar
              `(((,pvar Something ,t))))
             ))))
