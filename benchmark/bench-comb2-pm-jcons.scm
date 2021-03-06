(load "./egison.scm")

(define pm-comb2
  (lambda (xs)
    (match-all xs (List Something)
               ((jcons x (jcons y _)) `(,x ,y)))))

(print (length (pm-comb2 (iota 400 1))))

; 100: 0.181 ->
; 200: 0.829 ->
; 400: 5.897 -> 0.668
; 800: 55.188 -> 2.520
