# Scheme Macros for Egison Pattern Matching

This Scheme library provides the users with macros for pattern matching against non-free data types.
This pattern-matching facility is originally proposed in [this paper](https://arxiv.org/abs/1808.10603) and implemented in [the Egison programming language](http://github.com/egison/egison/).

We have tested this library on [Gauche](http://practical-scheme.net/gauche/) 0.9.6.

Draft paper for this Scheme library (presented at Scheme Workshop 2019): [github.com/egisatoshi/macro-paper](https://github.com/egisatoshi/macro-paper/blob/master/main.pdf)

## Usage

Non-free data types are data types whose data have no standard forms.
For example, multisets are non-free data types because the multiset {a,b,b} has two other equivalent but literally different forms {b,a,b} and {b,b,a}.
This library provides the users with a pattern-matching facility for these non-free data types.

For example, the following program pattern-matches a list `(1 2 5 9 4)` as a multiset.
This pattern matches if the target collection contains pairs of elements in sequence.
A non-linear pattern is effectively used for expressing the pattern.

```
(load "./egison.scm")

(match-all '(1 2 5 9 4) (Multiset Integer) [(cons x (cons `(+ x 1) _)) x])
; (1 4)
```

`match-all` returns a list of all the results.
We provide two types of `match-all` that return a list and a stream, respectively.
`egison.scm` provides the list version.
`stream-egison.scm` provides the stream version.
`match-all` of `stream-egison.scm` supports pattern matching with infinitely many results.

```
(use math.prime)
(use util.stream)

(load "./stream-egison.scm")

(define stream-primes (stream-filter bpsw-prime? (stream-iota -1)))

(stream->list
 (stream-take
  (match-all stream-primes (List Integer)
             [(join _ (cons p (cons `(+ p 2) _)))
              `(,p ,(+ p 2))])
  10))
; ((3 5) (5 7) (11 13) (17 19) (29 31) (41 43) (59 61) (71 73) (101 103) (107 109))
```

For more examples, please see the following samples.

## Samples

### Strict pattern matching

- [The basic list processing functions defined in pattern-matching-oriented programming style](https://github.com/egison/egison-scheme/blob/master/sample/pattern-matching-oriented-programming-style.scm)
- [Poker hands](https://github.com/egison/egison-scheme/blob/master/sample/poker.scm)
- [SAT solver (Davis-Putnam Algorithm)](https://github.com/egison/egison-scheme/blob/master/sample/SAT/dp.scm)
- [SAT solver (CDCL)](https://github.com/egison/egison-scheme/blob/master/sample/SAT/cdcl.scm)

### Lazy pattern matching

- [Twin primes](https://github.com/egison/egison-scheme/blob/master/sample/primes.scm)

## Syntax

Here is the formal syntax of `match-all`, `match-first`, and the patterns.
`e`, `M`, `p`, and `x` are a metavariable that denotes an expression, matcher, pattern, and symbol, respectively.

```
(match-all e M [p e*]*)
(match-first e M [p e*]*)

p = x        (pattern variable)
 | `e        (value pattern)
 | '(p*)     (tuple pattern)
 | (c p*)    (inductive pattern)
 | (and p*)  (and-pattern)
 | (or p*)   (or-pattern)
 | (not p)   (not-pattern)
 | (later p) (later pattern)
```

### Match-all

`match-all` is a syntax construct for pattern matching provided by our library.
`match-all` takes a target and match-clauses as the match expressions of the other functional programming languages.
However, `match-all` has two characteristic parts: (i) its name is match-"all", and (ii) it takes an additional argument a <i>matcher</i> as its second argument.

First, `match-all` evaluates the body for <b>all</b> the pattern-matching results and returns a list of the evaluation results.
This is the reason of the name "match-all".
The following sample returns a list that contains one result `(1 (2 3))`.
The reason is because `cons` for the list has only one decomposition.

```
(match-all '(1 2 3) (List Integer) [(cons x xs) `(,x ,xs)])
; ((1 (2 3)))
```

Second, a matcher is a special object in our pattern-matching system to specify the method for interpreting patterns.
If we change the matcher, the pattern-matching result also changes.
In the following sample, we changed the matcher from `(List Integer)` to `(Multiset Integer)`.
As the result, the pattern-matching results changes from `((1 (2 3)))` to `((1 (2 3)) (2 (1 3)) (3 (1 2)))`.
The reason is because `cons` for the multiset has multiple decompositions since the multiset ignores the order of the elements in a collection.

```
(match-all '(1 2 3) (Multiset Integer) [(cons x xs) `(,x ,xs)])
; ((1 (2 3)) (2 (1 3)) (3 (1 2)))
```

A matcher is defined in Scheme in our library.
Users can define their own matchers in Scheme.

### Match-first

The `match-first` is similar to the traditional `match` expression; it evaluates the body of the first match clause whose pattern matches with the target.

```
(match-first '(1 2 3) (Multiset Integer) [(cons x xs) `(,x ,xs)])
; (1 (2 3))
```

We do not use the name `match` to avoid the name conflict with Wright's `match`because Wright's `match` plays fundamental role for defining a user-defined matcher.
The only difference between `match-first` and the traditional `match` expression is `match-first` takes a matcher.

### Value patterns

Our pattern-matching system supports <i>non-linear patterns</i>.
A non-linear pattern is a pattern that allows multiple occurrences of identical pattern variables in a pattern.
Non-linear pattern is especially useful for pattern matching against non-free data types.
For example, we can write a pattern that matches if the target collection contains a pair of identical elements.

A pattern that is prepend with <code>\`</code> is called a <i>value-pattern</i>.
Value patterns match the target if the target is equal to the content of the value pattern.
The expression after <code>\`</code> is evaluated referring to the value bound to the pattern variables that appear left-side of the patterns.

```
(match-all '(1 2 5 9 4) (Multiset Integer) [(cons x (cons `(+ x 1) _)) x])
; (1 4)
```

### Tuple patterns

Tuple patterns are represented by prepending `'` to a list of patterns.
Each element of a tuple pattern is pattern-matched with the corresponding element of a target list using the corresponding element of a matcher list as a matcher.

```
(match-all '[1 2] `[,Integer ,Integer] ['[x y] `(,x ,y)]) ; ((1 2))
(match-all '[1 2 3] `[,Integer ,Integer ,Integer] ['[x y z] `(,x ,y ,z)]) ; ((1 2 3))
```

Preppending `'` is important to distinguish a tuple pattern from a inductive pattern.
For example, `'[x y]` cannot be distinguished from an constructor pattern whose constructor is `x` if `'` is not prepended.

### Or-patterns, and-patterns, and not-patterns

An or-pattern matches if one of the argument patterns matches the target.

```
(match-all '(1 2 3) (List Integer) [(cons (or `1 `10) _) "OK"])
; ("OK")
```

An and-pattern matches if all the argument patterns match the target.

```
(match-all '(1 2 3) (List Integer) [(cons (and `1 x) _) x])
; (1)
```

A not-pattern matches if the argument pattern does not match the target.

```
(match-all '(1 2 3) (List Integer) [(cons x (not (cons `x _))) x])
; (1)
```

### Later patterns

A later pattern is used to change the order of the pattern-matching process.
Basically, our pattern-matching system processes patterns from left to right in order.
However, we sometimes want this order, for example, to refer to the value bound to the right side of pattern variables.
A later pattern can be used for such purpose.

```
(match-all '(1 1 2 3) (List Integer) [(cons (later `x) (cons x _)) x])
; (1)
```

## Implemented method

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
                [(join hs (cons x ts)) `(,x ,(append hs ts))])))
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
(match-all t M [p e])
```
->
```
`(map (lambda ,(extract-pattern-variables p) ,e) ,(pattern-match p M t))
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

### Implementation of loop patterns

We can implement [loop patterns](https://arxiv.org/abs/1809.03252) using the same method in the Egison interpreter.
It will extend the expressiveness of patterns very much.

### Implementation of Haskell and OCaml extensions

We can apply the method for implementing this macro for the other languages.
We have avoided to use the `eval` function in this implementation for that purpose.
Currently, we are working to implement a Haskell extension for this pattern-matching facility.

## References

* Satoshi Egi, Yuichi Nishiwaki: [Non-linear Pattern Matching with Backtracking for Non-free Data Types](https://arxiv.org/abs/1808.10603) ([APLAS 2018](http://aplas2018.org/))
* Satoshi Egi: [Loop Patterns: Extension of Kleene Star Operator for More Expressive Pattern Matching against Arbitrary Data Structures](https://arxiv.org/abs/1809.03252) ([Scheme Workshop 2018](https://www.brinckerhoff.org/scheme2018/))
