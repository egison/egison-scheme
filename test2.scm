(load "./egison.scm")

(print (match-all `(1 1 2) (List Integer) [(cons x (cons (not ,x) _)) x])) ; ()
(print (match-all `(1 1 2) (List Integer) [(cons x (cons (not `x) _)) x])) ; ()
(print `,(match-all `(1 1 2) (List Integer) [(cons x (cons (not ,x) _)) x])) ; ()
(print `,(match-all `(1 1 2) (List Integer) [(cons x (cons (not `x) _)) x])) ; ()

(define-macro (match-two-identical-head-elements t e)
  `(match-all ,t (List Integer) [(cons x (cons `x _)) x]))

(print (match-two-identical-head-elements '(1 1 2) x))
