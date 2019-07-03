(module utils racket
        (extract-pattern-variables processMStates processMStates1 zip3 rewrite-pattern)

(require racket/match)
(require srfi/1)

(define rewrite-pattern
  (lambda (p)
    (let {[ret (rewrite-pattern-helper p '())]}
      (car (rewrite-later-pattern-helper (car ret) (cdr ret))))))

(define rewrite-pattern-helper
  (lambda (p xs)
        (match p
               [(list `unquote q) (cons (list 'val (list 'unquote `(lambda ,xs ,q))) xs)]
               ((list `pred q) (cons (list 'pred (list 'unquote `(lambda ,xs ,q))) xs))
               ((list `quote (? list? ps))
                (let {[ret (rewrite-patterns-helper ps xs)]}
                  (cons `(quote ,(car ret)) (cdr ret))))
               ((list `later p) (cons `(later ,p) xs))
               ((list c args ...)
                (let {[ret (rewrite-patterns-helper args xs)]}
                  (cons `(,c . ,(car ret)) (cdr ret))))
               (`_ (cons '_ xs))
               (pvar (cons pvar (append xs `(,pvar)))))))

(define rewrite-patterns-helper
  (lambda (ps xs)
    (match ps
           ((list) (cons '() xs))
           ((list p qs ...)
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
           ((list `later p)
            (let {[ret (rewrite-pattern-helper p xs)]}
              (cons `(later ,(car ret)) (cdr ret))))
           ((list c args ...)
            (let {[ret (rewrite-later-patterns-helper args xs)]}
              (cons `(,c . ,(car ret)) (cdr ret))))
           (_ (cons p xs)))))

(define rewrite-later-patterns-helper
  (lambda (ps xs)
    (match ps
           ((list) (cons '() xs))
           ((list p qs ...)
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
           ((list `val _) '())
           ((list `pred _) '())
           ((list `or pat _ ...) (extract-pattern-variables pat))
           ((list `quote args)
            (concatenate (map extract-pattern-variables args)))
           ((list c args ...)
            (concatenate (map extract-pattern-variables args)))
           ((list) '())
           (`_ '())
           (pvar `(,pvar))
           )))

(define processMStates
  (lambda (mStates)
    (match mStates
           [(list) '()]
           [(list (list `MState (list) ret) rs ...)
            (cons ret (processMStates rs))]
           [(list mState rs ...)
            (processMStates (append (processMState mState) rs))]
           )))

(define processMStates1
  (lambda (mStates)
    (match mStates
           ((list) '())
           ((list (list `MState (list) ret) rs ...)
            `(,ret))
           ((list mState rs ...)
            (processMStates1 (append (processMState mState) rs)))
           )))

(define processMState
  (lambda (mState)
    (match mState
           ((list `MState (list (list (list `quote (? list? ps)) (? list? Ms) ts) mStack ...) ret)
            (list `(MState ,(append (zip3 ps Ms ts) mStack) ,ret)))
           ((list `MState (list (list p (? list? Ms) t) mStack ...) ret)
            (list `(MState ,(cons `(,p Something ,t) mStack) ,ret)))
           ((list `MState (list (list (list `val f) M t) mStack ...) ret)
            (let {[next-matomss (M `(val ,(apply f ret)) t)]}
              (map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss)))
           ((list `MState (list (list (list `pred f) _ t) mStack ...) ret)
            (if ((apply f ret) t)
                (list `(MState ,mStack ,ret))
                '()))
           ((list `MState (list (list (list `and ps ...) M t) mStack ...) ret)
            (let {[next-matoms (map (lambda (p) `[,p ,M ,t]) ps)]}
              (list `(MState ,(append next-matoms mStack) ,ret))))
           ((list `MState (list (list (list `or ps ...) M t) mStack ...) ret)
            (let {[next-matomss (map (lambda (p) `{[,p ,M ,t]}) ps)]}
              (map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss)))
           ((list `MState (list (list (list `not p) M t) mStack ...) ret)
            (if (null? (processMStates (list `(MState {[,p ,M ,t]} ,ret))))
                (list `(MState ,mStack ,ret))
                '()))
           ((list `MState (list (list (list `later p) M t) mStack ...) ret)
            (list `(MState ,(append mStack `{[,p ,M ,t]}) ,ret)))
           ((list `MState (list (list `_ `Something t) mStack ...) ret)
            `((MState ,mStack ,ret)))
           ((list `MState (list (list pvar `Something t) mStack ...) ret)
            `((MState ,mStack ,(append ret `(,t)))))
           ((list `MState (list (list p M t) mStack ...) ret)
            (let {[next-matomss (M p t)]}
              (map (lambda (next-matoms) `(MState ,(append next-matoms mStack) ,ret)) next-matomss)))
           )))

(define zip3
  (lambda [xs ys zs]
    (match `(,xs ,ys ,zs)
           ((list (list) _ _) '())
           ((list _ (list) _) '())
           ((list _ _ (list)) '())
           ((list (list x xs ...) (list y ys ...) (list z zs ...)) (cons `(,x ,y ,z) (zip3 xs ys zs))))))

)
