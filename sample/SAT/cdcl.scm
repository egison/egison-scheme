(use util.match)
(use srfi-1)

(load "./egison.scm")

(define TaggedLiteral `[,Integer ,Integer])

(define Assignment
  (lambda (p t)
    (match p
      [('deduced pi pls)
       (match t
         [('Deduced i ls) `{{[,pi ,TaggedLiteral ,i] [,pls ,(Multiset TaggedLiteral) ,ls]}}]
         [_ `{}])]
      [('guessed pi)
       (match t
         [('Guessed i) `{{[,pi ,TaggedLiteral ,i]}}]
         [_ `{}])]
      [('Fixed pi)
       (match t
         [('Fixed i) `{{[,pi ,TaggedLiteral ,i]}}]
         [_ `{}])]
      [('whichever pi)
       (match t
         [('Deduced i _) `{{[,pi ,TaggedLiteral ,i]}}]
         [('Guessed i) `{{[,pi ,TaggedLiteral ,i]}}]
         [('Fixed i) `{{[,pi ,TaggedLiteral ,i]}}]
         [_ `{}])]
      [('either pi)
       (match t
         [('Guessed i) `{{[,pi ,TaggedLiteral ,i]}}]
         [('Fixed i) `{{[,pi ,TaggedLiteral ,i]}}]
         [_ `{}])]
      [_ 'error-not-defined-in-Assignment])))

(define neg (lambda (x) (* -1 x)))

(define to-cnf
  (lambda [cs]
    (map (lambda [c] `(,c ,c)) cs)))

(define from-cnf
  (lambda [cnf]
    (map (lambda [c] (car c)) cnf)))

(define init-vars
  (lambda [vs]
    (append
     (map (lambda [v] `(,(neg v) ,0)) vs)
     (map (lambda [v] `(,v ,0)) vs))))

(define add-vars
  (lambda [vs vars]
    (match-first `[,vs ,vars] `[,(List Integer) ,(List `[,Integer ,Integer])]
                 ['[(nil) _]
                  (sort vars > cadr)]
                 ['[(cons v vs2) (join hs (cons '[,v c] ts))]
                  (add-vars vs2 (append hs (cons `[,v ,(+ c 1)] ts)))])))

(define delete-var
  (lambda [v vars]
    (match-first vars (Multiset `[,Integer ,Integer])
                 [(cons '[,v _] (cons '[,(neg v) _] vars2)) vars2]
                 [_ 'error-in-delete-var])))

(define get-stage
  (lambda [l trail]
    (match-first trail (List Assignment)
                 [(join _ (cons (whichever '[,(neg l) s]) _)) s]
                 [_ 'error-no-stage])))

(define delete-literal
  (lambda [l cnf]
    (map (lambda [c] (cons (match-all (car c) (Multiset Integer)
                                      [(cons (and (not ,l) m) _) m])
                           (cdr c)))
         cnf)))

(define delete-clauses-with
  (lambda [l cnf]
    (match-all cnf (Multiset `[,(Multiset Integer) ,Something])
      [(cons '[(and (not (cons ,l _)) c1) c2] _) `(,c1 ,c2)])))

(define assign-true
  (lambda [l cnf]
    (delete-literal (neg l) (delete-clauses-with l cnf))))

(define unit-propagate3
  (lambda [stage cnf trail]
    (match-first cnf (Multiset `[,(Multiset Integer) ,(Multiset Integer)])
                 ; empty clause
                 [(cons '[(nil) _] _) `(,cnf ,trail)]
                 ; 1-literal rule
                 [(cons '[(cons l (nil)) (cons ,l rs)] _)
                  (unit-propagate3 stage (assign-true l cnf) (cons `(Deduced [,l ,stage] ,(map (lambda [r] `[,r ,(get-stage r trail)]) rs)) trail))]
                 ; otherwise
                 [_ `(,cnf ,trail)])))

(define unit-propagate2
  (lambda [stage cnf trail otrail]
    (match-first trail (List Assignment)
                 [(cons (whichever '[l _]) trail2) (unit-propagate2 stage (assign-true l cnf) trail2 otrail)]
                 [_ (unit-propagate3 stage cnf otrail)])))

(define unit-propagate
  (lambda [stage cnf trail]
    (unit-propagate2 stage cnf trail trail)))

(define learn3
  (lambda [stage cp trail]
    (match-first `[,trail ,cp] `[,(List Assignment) ,(Multiset TaggedLiteral)]
                 ['[(cons (deduced '[l ,stage] ds) trail2)
                    (cons '[,(neg l) ,stage] rp)]
                  (learn2 stage (lset-union equal? rp ds) trail2)]
                 ['[(cons (deduced '[_ _] _) trail2) _]
                  (learn3 stage cp trail2)]
                 ['[_ _] 'error-learn3])))

(define learn2
  (lambda [stage cp trail]
    (match-first cp (List TaggedLiteral)
                 [(not (join _ (cons '[_ ,stage] (join _ (cons '[_ ,stage] _)))))
                  `(,(apply min (map cadr cp)) ,(map car cp))]
                 [_ (learn3 stage cp trail)])))

(define learn
  (lambda [stage cl trail]
    (learn2 stage (map (lambda [l] `[,l ,(get-stage l trail)]) cl) trail)))

(define backjump
  (lambda [s trail]
    (match-first trail (List Assignment)
                 [(join _ (and (cons (either '[_ ,s]) _) trail2))
                  trail2]
                 [_ trail])))

(define choose
  (lambda [vars trail]
    (match-first `[,vars ,trail] `[,(List `[,Integer ,Integer]) ,(List Assignment)]
                 ['[(cons '[v _] vars2) (join _ (cons (whichever '[(or ,v ,(neg v)) _]) _))]
                  (choose vars2 trail)]
                 ['[(cons '[v _] _) _]
                  (neg v)])))

(define cdcl2
  (lambda [count stage vars cnf trail]
    (print count)
    (print trail)
    (let-values {[(cnf2 trail2) (apply values (unit-propagate stage cnf trail))]}
      (match-first cnf2 (Multiset `[,(Multiset Integer) ,Something])
                   [(nil) #t]
                   [(cons '[(nil) cl] _)
                    (match-first trail2 (List Assignment)
                                 [(join _ (cons (either '[l ,stage]) trail3))
                                  (let-values {[(s lc) (apply values (learn stage cl trail2))]}
                                    (let {[trail4 (backjump s trail3)]}
                                      (print "learning result:")
                                      (print `(,s ,cl ,lc))
                                      (cdcl2 (+ count 1) s (add-vars lc vars) (cons `(,lc ,lc) cnf) trail4)))
                                  ]
                                 [_ #f])]
                   [_
                    (let {[gl (choose vars trail2)]}
                      (cdcl2 (+ count 1) (+ stage 1) vars cnf (cons `(Guessed [,gl ,(+ stage 1)]) trail2)))]))))

(define cdcl
  (lambda [vars cnf]
    (cdcl2 0 0 (init-vars vars) (to-cnf cnf) '{})))

;(print (cdcl '{} '{})) ; #t
;(print (cdcl '{} '{{}})) ; #f
;(print (cdcl '{1} '{{1}})) ; #t
;(print (cdcl '{1} '{{1} {-1}})) ; #f
;(print (cdcl '{1 3} '{{-1 3} {1 -3}})) ; #t
;(print (cdcl '{1 2 3} '{{1 2} {-1 3} {1 -3}})) ; #t
;(print (cdcl '{1 2} '{{1 2} {-1 -2} {1 -2}})) ; #t
;(print (cdcl '{1 2} '{{1 2} {-1 -2} {1 -2} {-1 2}})) ; #f
;(print (cdcl '{1 2 3 4 5} '{{-1 -2 3} {-1 -2 -3} {1 2 3 4} {-4 -2 3} {5 1 2 -3} {-3 1 -5} {1 -2 3 4} {1 -2 -3 5}})) ; #t
;(print (cdcl '{1 2} '{{-1 -2} {1}})) ; #t

(define problem20
 '{{ 4 -18 19}
   {3 18 -5}
   {-5 -8 -15}
   {-20 7 -16}
   {10 -13 -7}
   {-12 -9 17}
   {17 19 5}
   {-16 9 15}
   {11 -5 -14}
   {18 -10 13}
   {-3 11 12}
   {-6 -17 -8}
   {-18 14 1}
   {-19 -15 10}
   {12 18 -19}
   {-8 4 7}
   {-8 -9 4}
   {7 17 -15}
   {12 -7 -14}
   {-10 -11 8}
   {2 -15 -11}
   {9 6 1}
   {-11 20 -17}
   {9 -15 13}
   {12 -7 -17}
   {-18 -2 20}
   {20 12 4}
   {19 11 14}
   {-16 18 -4}
   {-1 -17 -19}
   {-13 15 10}
   {-12 -14 -13}
   {12 -14 -7}
   {-7 16 10}
   {6 10 7}
   {20 14 -16}
   {-19 17 11}
   {-7 1 -20}
   {-5 12 15}
   {-4 -9 -13}
   {12 -11 -7}
   {-5 19 -8}
   {1 16 17}
   {20 -14 -15}
   {13 -4 10}
   {14 7 10}
   {-5 9 20}
   {10 1 -19}
   {-16 -15 -1}
   {16 3 -11}
   {-15 -10 4}
   {4 -15 -3}
   {-10 -16 11}
   {-8 12 -5}
   {14 -6 12}
   {1 6 11}
   {-13 -5 -1}
   {-7 -2 12}
   {1 -20 19}
   {-2 -13 -8}
   {15 18 4}
   {-11 14 9}
   {-6 -15 -2}
   {5 -12 -15}
   {-6 17 5}
   {-13 5 -19}
   {20 -1 14}
   {9 -17 15}
   {-5 19 -18}
   {-12 8 -10}
   {-18 14 -4}
   {15 -9 13}
   {9 -5 -1}
   {10 -19 -14}
   {20 9 4}
   {-9 -2 19}
   {-5 13 -17}
   {2 -10 -18}
   {-18 3 11}
   {7 -9 17}
   {-15 -6 -3}
   {-2 3 -13}
   {12 3 -2}
   {-2 -3 17}
   {20 -15 -16}
   {-5 -17 -19}
   {-20 -18 11}
   {-9 1 -5}
   {-19 9 17}
   {12 -2 17}
   {4 -16 -5}})

(define problem50
 '{{ 18 -8 29}
   {-16 3 18}
   {-36 -11 -30}
   {-50 20 32}
   {-6 9 35}
   {42 -38 29}
   {43 -15 10}
   {-48 -47 1}
   {-45 -16 33}
   {38 42 22}
   {-49 41 -34}
   {12 17 35}
   {22 -49 7}
   {-10 -11 -39}
   {-28 -36 -37}
   {-13 -46 -41}
   {21 -4 9}
   {12 48 10}
   {24 23 15}
   {-8 -41 -43}
   {-44 -2 -35}
   {-27 18 31}
   {47 35 6}
   {-11 -27 41}
   {-33 -47 -45}
   {-16 36 -37}
   {27 -46 2}
   {15 -28 10}
   {-38 46 -39}
   {-33 -4 24}
   {-12 -45 50}
   {-32 -21 -15}
   {8 42 24}
   {30 -49 4}
   {45 -9 28}
   {-33 -47 -1}
   {1 27 -16}
   {-11 -17 -35}
   {-42 -15 45}
   {-19 -27 30}
   {3 28 12}
   {48 -11 -33}
   {-6 37 -9}
   {-37 13 -7}
   {-2 26 16}
   {46 -24 -38}
   {-13 -24 -8}
   {-36 -42 -21}
   {-37 -19 3}
   {-31 -50 35}
   {-7 -26 29}
   {-42 -45 29}
   {33 25 -6}
   {-45 -5 7}
   {-7 28 -6}
   {-48 31 -11}
   {32 16 -37}
   {-24 48 1}
   {18 -46 23}
   {-30 -50 48}
   {-21 39 -2}
   {24 47 42}
   {-36 30 4}
   {-5 28 -1}
   {-47 32 -42}
   {16 37 -22}
   {-43 42 -34}
   {-40 39 -20}
   {-49 29 6}
   {-41 -3 39}
   {-16 -12 43}
   {24 22 3}
   {47 -45 43}
   {45 -37 46}
   {-9 26 5}
   {-3 23 -13}
   {5 -34 13}
   {12 39 13}
   {22 50 37}
   {19 9 46}
   {-24 8 -27}
   {-28 7 21}
   {8 -25 50}
   {20 50 4}
   {27 36 13}
   {26 31 -25}
   {39 -44 -32}
   {-20 41 -10}
   {49 -28 35}
   {1 44 34}
   {39 35 -11}
   {-50 -42 -7}
   {-24 7 47}
   {-13 5 -48}
   {-9 -20 -23}
   {2 17 -19}
   {11 23 21}
   {-45 30 15}
   {11 26 -24}
   {38 33 -13}
   {44 -27 -7}
   {41 49 2}
   {-18 12 -37}
   {-2 12 -26}
   {-19 7 32}
   {-22 11 33}
   {8 12 -20}
   {16 40 -48}
   {-2 -24 -11}
   {26 -17 37}
   {-14 -19 46}
   {5 47 36}
   {-29 -9 19}
   {32 4 28}
   {-34 20 -46}
   {-4 -36 -13}
   {-15 -37 45}
   {-21 29 23}
   {-6 -40 7}
   {-42 31 -29}
   {-36 24 31}
   {-45 -37 -1}
   {3 -6 -29}
   {-28 -50 27}
   {44 26 5}
   {-17 -48 49}
   {12 -40 -7}
   {-12 31 -48}
   {27 32 -42}
   {-27 -10 1}
   {6 -49 10}
   {-24 8 43}
   {23 31 1}
   {11 -47 38}
   {-28 26 -13}
   {-40 12 -42}
   {-3 39 46}
   {17 41 46}
   {23 21 13}
   {-14 -1 -38}
   {20 18 6}
   {-50 20 -9}
   {10 -32 -18}
   {-21 49 -34}
   {44 23 -35}
   {40 -19 34}
   {-1 6 -12}
   {6 -2 -7}
   {32 -20 34}
   {-12 43 -29}
   {24 2 -49}
   {10 -4 40}
   {11 5 12}
   {-3 47 -31}
   {43 -23 21}
   {-41 -36 -50}
   {-8 -42 -24}
   {39 45 7}
   {7 37 -45}
   {41 40 8}
   {-50 -10 -8}
   {-5 -39 -14}
   {-22 -24 -43}
   {-36 40 35}
   {17 49 41}
   {-32 7 24}
   {-30 -8 -9}
   {-41 -13 -10}
   {31 26 -33}
   {17 -22 -39}
   {-21 28 3}
   {-14 46 23}
   {29 16 19}
   {42 -32 -44}
   {-24 10 23}
   {-1 -32 -21}
   {-8 -44 -39}
   {39 11 9}
   {19 14 -46}
   {46 44 -42}
   {37 23 -29}
   {32 25 20}
   {14 -43 -12}
   {-36 -18 46}
   {14 -26 -10}
   {-2 -30 5}
   {6 -18 46}
   {-26 2 -44}
   {20 -8 -11}
   {-31 3 16}
   {-22 -9 39}
   {-49 44 -42}
   {-45 -44 31}
   {-31 50 -11}
   {-32 -46 2}
   {-6 -7 17}
   {19 -32 48}
   {39 20 -10}
   {-22 -37 38}
   {-31 9 -48}
   {40 12 7}
   {-24 -4 9}
   {-22 49 33}
   {-12 43 10}
   {25 -30 -10}
   {46 47 31}
   {13 27 -7}
   {-45 32 -35}
   {-50 34 9}
   {2 34 30}
   {3 16 2}
   {-18 45 -12}
   {33 37 10}
   {43 7 -18}
   {-22 44 -19}
   {-31 -27 -42}
   {-3 -40 8}
   {-23 -31 38}})

(print (cdcl (iota 20 1) problem20)) ; #t ; 0.538 (after implementing VSIDS 2019/06/27 17:30)
;(print (cdcl (iota 50 1) problem50)) ; #f ; 14.106 (after implementing VSIDS 2019/06/27 17:30)
