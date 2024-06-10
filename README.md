# FORSP: A Forth+Lisp Hybrid Lambda Calculus Language

FORSP is a hybrid language combining FORTH and LISP.

FORSP is a minimalist language.

## Features

FORSP has:
  - An S-Expression syntax like LISP
  - Function abstraction like LISP
  - Function application like FORTH
  - An environment structure like LISP
  - Lexically-scoped closures like LISP (SCHEME)
  - Cons-cells / lists / atoms like LISP
  - A value/operand stack like FORTH
  - An ability to express the lambda calculus
  - A Call-By-Push-Value evaluation order
  - Only 3 syntax special forms: ' ^ $
  - Only 1 eval-time special form: quote
  - Only 10 primitive functions need to self-implement
  - Ability to self-implement in very little code

## Discussion

See blog post for details: [FORSP: A Forth+Lisp Hybrid Lambda Calculus Language](https://xorvoid.com/forsp.html)

## Tutorial

A "literate program" is provided for a tutorial: [here](examples/tutorial.fp)

## Recursive Factorial Example

```
(
  ($x x)                       $force
  (force cswap $_ force)       $if
  ($f $t $c $fn ^f ^t ^c fn)   $endif
  ()                           $[
  ()                           $]

  ; Y-Combinator
  ($f
    ($x (^x x) f)
    ($x (^x x) f)
    force
  ) $Y

  ; rec: syntax sugar for applying the Y-Combinator
  ($g (^g Y)) $rec

  ; factorial
  ($self $n
    ^if [ ^n 0 eq 1 ]
      ([ ^n 1 - ] self ^n *)
    endif
  ) rec $factorial

  5 factorial print
)
```

## Self-implementation (compute() and eval() core functions)

```
  ; compute [$comp $stack $env -> $stack]
  ($compute $eval (^eval compute) $compute ; curry eval into compute
    ^if (dup is-nil) (rot $_ $_) ( ; false case: return $stack
      stack-pop
      ^if (dup 'quote eq)
        ($_ stack-pop rot swap stack-push swap compute)
        (swap $comp eval ^comp compute) endif
    ) endif
  ) rec $compute

  ; eval: [$expr $stack $env -> $stack $env]
  ($eval (^eval compute) $compute ; curry eval into compute
    ^if (dup is-atom) (
      over2 swap env-find dup $callable
      ^if (dup is-closure) (swap $stack cdr unpack-closure ^stack swap compute)
      (^if (dup is-clos)   (force)
                           (stack-push)  endif) endif)
    (^if (dup is-list)
      (over2 swap make-closure stack-push)
      (stack-push) endif) endif
  ) rec $eval
```

## Building and Demo

Building:

```
./build.sh
```

NOTE: Only tested on Mac M1

Examples:

```
./forsp examples/demo.fp
./forsp examples/factorial.fp
./forsp examples/currying.fp
./forsp examples/church_numerals.fp
./forsp examples/forsp.fp
```
