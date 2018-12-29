# Scheme Macros for Egison Pattern Matching

This Scheme library provides users with macros for pattern matching against non-free data types.
This pattern-matching facility is originally proposed in [this paper](https://arxiv.org/abs/1808.10603) and implemented in [the Egison programming language](http://github.com/egison/egison/).

We have tested this library on [Gauche](http://practical-scheme.net/gauche/) 0.9.6.

## Usage

Non-free data types are data types whose data have no standard forms.
For example, multisets are non-free data types because the multiset {a,b,b} has two other equivalent but literally different forms {b,a,b} and {b,b,a}.
This library provides users with a pattern-matching facility for these non-free data types.

For example, the following program pattern-matches a list `(1 2 3 2 1)` as a multiset.
This pattern matches if the target collection contains pairs of elements in sequence.
A non-linear pattern is effectively used for expressing the pattern.

```
(load "./egison.scm")

(match-all '(1 2 5 9 4) (Multiset Integer) [`(cons x (cons ,(+ x 1) _)) x])
; (1 4)
```

`match-all` returns a list of all the results.
We provides two types of `match-all` that returns a list and stream.
`egison.scm` provides the list version.
`stream-egison.scm` provides the stream version.
`match-all` of `stream-egison.scm` supports pattern matching with infinitely many results as follows.

```
(use math.prime)
(use util.stream)

(load "./stream-egison.scm")

(define stream-primes (stream-filter bpsw-prime? (stream-iota -1)))

(stream->list
 (stream-take
  (match-all stream-primes (List Integer)
             [`(join _ (cons p (cons ,(+ p 2) _)))
              `(,p ,(+ p 2))])
  10))
; ((3 5) (5 7) (11 13) (17 19) (29 31) (41 43) (59 61) (71 73) (101 103) (107 109))
```

For more examples, please see [test.scm](https://github.com/egison/egison-scheme/blob/master/test.scm) and the following samples for now.

## Samples

### Strict pattern matching

- [The basic list functions defined in pattern-matching-oriented programming style](https://github.com/egison/egison-scheme/blob/master/pattern-matching-oriented-programming-style.scm)
- [Poker hands](https://github.com/egison/egison-scheme/blob/master/poker.scm)

### Lazy pattern matching

- [Twin primes](https://github.com/egison/egison-scheme/blob/master/primes.scm)

## Features of this implementation

We do not use the `eval` function in this implementation.
It enables us to apply the method developed in this implementation to implementation of Haskell and OCaml extensions.

## Method for implementation

### Matchers are defined as a function that takes a pattern and target, and returns next matching atoms.

For example, `Multiset` is defined as follows.
(`Multiset` is a function that takes and returns a matcher.)

```
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
```

`Something` is the only built-in matcher.
`processMState` has a branch for `Something`.

```
(define Something 'Something)
```

### Match-all is transformed into an application of map.

Match-all is transformed into an application of map whose arguments uses `extract-pattern-variables` and `pattern-match` as follows.
It allows us to implement `match-all` without using `eval`.

```
(match-all t m [p e])
```
->
```
`(map (lambda ,(extract-pattern-variables p) ,e) ,(pattern-match p m t))
```

`extract-pattern-variables` takes a pattern and returns a list of pattern variables that appear in the pattern.
The order of the pattern variables corresponds with the order they appeared in the pattern.

`pattern-match` returns a list of pattern-matching results.
The pattern-matching results consist of values that are going to bound to the pattern variables returned by `extract-pattern-variables`.
The order of the values in the pattern-matching results must correspond with the order of pattern variables returned by `extract-pattern-variables`.

### Value patterns are transformed into lambda

Value patterns are transformed into lambda expressions using `rewrite-pattern` inside the macro.
For example, `(join _ (cons x (join _ (cons ,x _))))` is transformed into `(join _ (cons x (join _ (cons (val ,(lambda (x) x)) _))))`.

## Future work

### Pattern matching with infinitely many results

If we implement the lazy match-all, we can support pattern matching with infinitely many results.

```
(take (match-all primes (List Integer)
        [`(join _ (cons x (join _ (cons (val ,(lambda (p) (+ p 2))) _))))
         `(,p ,(+ p 2))])
      5)
; ((3 5) (5 7) (11 13) (17 19) (29 31))
```

### And-patterns, or-patterns, not-patterns, loop-patterns, ...

We can implement these patterns using the same method in the Egison interpreter.

### Implementation of Haskell and OCaml extensions

We can apply the method for implementing this macro for the other languages.
However, additional work is required for implementing this pattern-matching facility for languages with a static type system such as Haskell and OCaml.
For these languages, the translated programs need to have types.
The most difficult part for making being typed is a stack of matching atoms.
This is because the target type of each matching atom is different, therefore we cannot type a stack of matching atoms as a list of matching atoms simply.

## References

* Satoshi Egi, Yuichi Nishiwaki: [Non-linear Pattern Matching with Backtracking for Non-free Data Types](https://arxiv.org/abs/1808.10603) (APLAS 2018)
* Satoshi Egi: [Loop Patterns: Extension of Kleene Star Operator for More Expressive Pattern Matching against Arbitrary Data Structures](https://arxiv.org/abs/1809.03252) (Scheme Workshop 2018)
