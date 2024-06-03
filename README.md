# FORSP: A Forth+Lisp Hybrid Lambda Calculus Language

FORSP is a hybrid lanaguage combining FORTH and LISP.

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
  - Only 3 special forms and a few primitives

## Discussion

See blog post for details: [FORSP: A Forth+Lisp Hybrid Lambda Calculus Language](https://xorvoid.com/forsp.html)

## Recursive Factorial Example

```
(
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

  ; rec syntax sugar for Y-Combinator
  ($g (^g Y)) $rec

  ; factorial
  ($self $n
    ^if [ ^n 0 eq ] 1
      ([ ^n 1 - ] self ^n *)
    endif
  ) rec $factorial

  5 factorial print
)
```

## Building and Demo

Building:

```
./build.sh
```

NOTE: Only tested on Mac M1

Demo:

```
./forsp demo.fp
```
