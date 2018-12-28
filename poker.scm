(use util.match)
(use srfi-1)

(load "./egison.scm")

(define Mod
  (lambda (n)
    (lambda (p t)
      (match p
             (('val x)
              (if (eq? (modulo x n) (modulo t n))
                  '(())
                  '()))
             (pvar
              `(((,pvar Something ,(modulo t n)))))
             ))))

(define Suit Eq)

(define Card
  (lambda (p t)
    (match p
           (('card ps pn)
            (match t
                   (('card s n)
                    `(((,ps ,Suit ,s) (,pn ,(Mod 13) ,n)))
                    )))
           (pvar
            `(((,pvar Something ,t)))))))


(define poker-hand
  (lambda (cs)
    (match-first cs (Multiset Card)
                 [`(cons (card s n)
                         (cons (card ,s ,(+ n 1))
                               (cons (card ,s ,(+ n 2))
                                     (cons (card ,s ,(+ n 3))
                                           (cons (card ,s ,(+ n 4))
                                                 ())))))
                  "Straight flush"]
                 [`(cons (card _ n)
                         (cons (card _ ,n)
                               (cons (card _ ,n)
                                     (cons (card _ ,n)
                                           _))))
                  "Four of kind"]
                 [`(cons (card _ m)
                         (cons (card _ ,m)
                               (cons (card _ ,m)
                                     (cons (card _ n)
                                           (cons (card _ ,n)
                                                 ())))))
                  "Full house"]
                 [`(cons (card s _)
                         (cons (card ,s _)
                               (cons (card ,s _)
                                     (cons (card ,s _)
                                           (cons (card ,s _)
                                                 ())))))
                  "Flush"]
                 [`(cons (card _ n)
                         (cons (card _ ,(+ n 1))
                               (cons (card _ ,(+ n 2))
                                     (cons (card _ ,(+ n 3))
                                           (cons (card _ ,(+ n 4))
                                                 ())))))
                  "Straight"]
                 [`(cons (card _ n)
                         (cons (card _ ,n)
                               (cons (card _ ,n)
                                     _)))
                  "Three of kind"]
                 [`(cons (card _ m)
                         (cons (card _ ,m)
                               (cons (card _ n)
                                     (cons (card _ ,n)
                                           _))))
                  "Two pair"]
                 [`(cons (card _ n)
                         (cons (card _ ,n)
                               _))
                  "One pair"]
                 [`_
                  "Nothing"]
                 )))

(poker-hand `{(card club 12)
              (card club 10)
              (card club 13)
              (card club 1)
              (card club 11)})
; "Straight flush"

(poker-hand `{(card diamond 1)
              (card club 2)
              (card club 1)
              (card heart 1)
              (card diamond 2)})
; "Full house"

(poker-hand `{(card diamond 4)
              (card club 2)
              (card club 5)
              (card heart 1)
              (card diamond 3)})
; "Straight"

(poker-hand `{(card diamond 4)
              (card club 10)
              (card club 5)
              (card heart 1)
              (card diamond 3)})
; "Nothing"
