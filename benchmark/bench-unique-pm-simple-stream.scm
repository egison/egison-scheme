(load "./stream-egison.scm")

(define pm-unique-simple
  (lambda (xs)
    (stream->list
     (match-all (list->stream xs) (List Eq)
                ((join _ (cons x (not (join _ (cons ,x _))))) x)))))

(print (pm-unique-simple (iota 200 1)))
