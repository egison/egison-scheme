;;
;; Stream Egison Test
;;

(load "./stream-egison.scm")

(stream->list (match-all 10 Something [x x])) ; (10)
(stream->list (match-all 10 Integer [x x])) ; (10)
(stream->list (match-all 10 Integer [,10 "OK"])) ; ("OK")
(stream->list (match-all (list->stream '(1 2 3)) (List Integer) [(cons x y) `(,x ,(stream->list y))])) ; ((1 (2 3)))
(stream->list (match-all (list->stream '(1 2 3)) (List Integer) [(join x y) `(,(stream->list x) ,(stream->list y))])) ; ((() (1 2 3)) ((1) (2 3)) ((1 2) (3)))

(stream->list (stream-take (match-all (stream-iota -1) (List Integer) [(join x y) `(,(stream->list x) ,y)]) 10))
; ((() (1 2 3)) ((1) (2 3)) ((1 2) (3)))

(stream->list (stream-take (match-all (stream-iota 3) (Multiset Integer) [(cons x (cons y _)) `(,x ,y)]) 6)) ; ((0 1) (0 2) (1 0) (1 2) (2 0) (2 1))
