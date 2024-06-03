# FORSP: A Forth+Lisp Hybrid Lambda Calculus Language

FORSP is a hybrid lanaguage combining FORTH and LISP.

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
