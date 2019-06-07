(load "./egison.scm")

(define pm-comb2
  (lambda (xs)
    (match-all xs (List Something)
               ((join _ (cons x (join _ (cons y _)))) `(,x ,y)))))

(print (length (pm-comb2 (iota 800 1))))

; 100: 0.181
; 200: 0.829
; 400: 5.897
; 800: 55.188
