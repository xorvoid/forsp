(
  ; Welcome to Forsp: A Forth+Lisp Hybrid Lambda Calculus Language
  ;
  ; As you can see, comment lines always start with the ';' semicolon character.
  ; Also, all code is inside () braces. Actually, all code is an S-Expression, but
  ; if you don't understand what that means, it's okay.
  ;
  ; In Forsp, we have a value stack. We can print it out as follows:

  stack print  ; ()

  ; This should print a pair of parenthesis which means that the stack is empty.
  ; Let's put something on the stack

  5

  ; And now let's print the stack again

  stack print ; (5)

  ; Now we have something! Let's put on a few more numbers

  4 3

  ; Now we have something! Let's put on a few more numbers

  stack print ; (3 4 5)

  ; A stack is LIFO order, or Last-In-First-Off. This means that the next value to be
  ; removed from the stack will be 3. Let's "print" and find out.

  print        ; 3
  stack print  ; (4 5)

  ; Checks out!
  ; Let's try arithmetic!

  * print     ; 20
  stack print ; ()

  ; The * operation multiplies the top-two values on the stack and then pushes it back to stack.
  ; Then "print" prints the value, leaving the stack empty.

  ; Sometimes working only with stack values is challenging. Luckily Forsp has variables as well.
  ; We can pop the stack and store to a variable as follows:

  5 $my-variable
  stack print ; ()

  ; Now "my-variable" is bound to 5. To push a value onto the stack from a variable we can do the following:

  ^my-variable
  stack print ; (5)
  $_

  ; Coolio. Notice that we bound the variable "_" to remove the value from the stack.
  ; Now, say we wanted to square "my-variable". we could to the following:

  ^my-variable ^my-variable * print ; 25

  ; Forsp also has function abstraction. They are simply () parenthesis grouping.

  ($x ^x ^x *)
  stack print  ; (CLOSURE<(quote x pop quote x push quote x push *), 0x600001c26d60>)

  ; What's this scary value on the stack now? When we build a function with (), it forms a lexical
  ; closure around the current environment. If you prefer, you can just think of "CLOSURE"
  ; as a "callable function value".

  ; Fair enough, but how do we call it? As it turns out "print" and "stack" are both functions.
  ; To call a function in Forsp, you simply write the function's name. But, our function has no
  ; name yet. So, let's give it one by popping it and binding to a variable name!

  $square

  ; And lets call it on an argument:

  6 square
  stack print ; 36

  ; How cool! It should be easy enough to understand the function definition: ($x ^x ^x *). Pop and bind "x".
  ; Push "x". Push "x" again. Call the "*" function.

  ; Sometimes you need to refer to some data that you don't want evaluated.
  ; For this, you can simply quote the value:

  'something
  '(1 2 3)
  '(abc (1 foo) ())
  stack print  ; ((abc (1 foo) ()) (1 2 3) something 36)

  ; You can also write "quote" verbosely:

  quote other
  stack print  ; (other (abc (1 foo) ()) (1 2 3) something 36)

  ; Let's define another function to remove values for the stack, and use it
  ; to cleanup the stack

  ($_) $drop
  drop drop drop drop drop
  
  ; Believe it or now, this is ALL of Forsp's syntax and semantics!

  ; Forsp has only a small number of built-in function primitives:
  ; ---------------------------------------------------------------
  ;
  ;   CORE: Primitives needed to self-implement
  ;
  ;     primitive [args]          |  description                                      | example usage
  ;     --------------------------|---------------------------------------------------|--------------
  ;     push  [$name]             |  resolve "name" in environment and push           | 'foo push
  ;     pop   [$name $val]        |  bind "val" to "name" in environment              | 'foo pop
  ;     eq    [$a $b]             |  if "a" and "b" are equal, then "t", else "()"    | 'a 'b eq
  ;     cons  [$fst $snd]         |  construct a pair from "fst" and "snd"            | '(2 3) 1 cons
  ;     car   [$pair]             |  extract the first element of a pair              | '(1 2 3) car
  ;     cdr   [$pair]             |  extract the second element of a pair             | '(1 2 3) cdr
  ;     cswap [$cond $a $b]       |  if cond is "t" then perform a swap               | 1 2 't cswap
  ;     tag   [$obj]              |  query the type-tag of any object                 | ^tag tag
  ;     read  []                  |  read an s-expression from input data             | read
  ;     print [$obj]              |  print an object as an s-expression               | '(foo bar) print
  ;
  ;   EXTRA: Additional primitives that are not strictly needed by useful to have
  ;
  ;     primitive [args]          |  description                                      | example usage
  ;     --------------------------|---------------------------------------------------|--------------
  ;     stack                     |  push the "stack" onto the stack: cons'ing self   | stack
  ;     env                       |  push the "env" onto the stack                    | env
  ;     -    [$b $a]              |  push the result of "a-b" (subtraction)           | 3 2 -
  ;     *    [$b $a]              |  push the result of "a*b" (multiply)              | 3 2 *
  ;     nand [$b $a]              |  push the result of "~(a&b)" (bitwise nand)       | 3 2 nand
  ;     <<   [$b $a]              |  push the result of "a<<b" (signed left-shift)    | 3 2 <<
  ;     >>   [$b $a]              |  push the result of "a>>b" (signed right-shift)   | 3 2 >>
  ;
  ;  LOWLEVEL: Dangerous low-level memory unsafe operations
  ;
  ;     primitive [args]          |  description                                      | example usage
  ;     --------------------------|---------------------------------------------------|--------------
  ;     ptr-state!                | push a pointer to interpreter state memory        | ptr-state!
  ;     ptr-read!     [$ptr]      | read from "ptr" and push result                   | 1234 ptr-read!
  ;     ptr-write!    [$val $ptr] | write "val" to "ptr"                              | 1234 42 ptr-write!
  ;     ptr-to-obj!   [$ptr]      | convert a pointer (number) into an object         | 1234 ptr-to-obj!
  ;     ptr-from-obj! [$ptr]      | convert an object into a pointer                  | 1234 ptr-from-obj!

  ; And that's all the primitives!
  ; From just this, we can implement effectively anything, and we more ease than you'd guess.

  ; Let's implement some common functions:

  ($x ^x ^x) $dup

  ; This function duplicates the top-of the stack. We can now square numbers as follows:

  7 dup * print ; 49

  ; Here are a handful of stack manipulation functions:

  ($x $y ^x ^y)       $swap
  ($x $y ^y ^x ^y)    $over
  ($x $y $z ^y ^x ^z) $rot

  ; Let's demonstrate them by example:

  9 8 7 stack print  ; (7 8 9)
  swap stack print   ; (8 7 9)
  over stack print   ; (7 8 7 9)
  drop stack print   ; (8 7 9)
  rot stack print    ; (9 8 7)
  drop drop drop

  ; You may have noticed that we don't have any way to do addition. We'll it's easy to define:

  (0 swap - -) $+
  4 5 + print ; 9

  ; Another useful function is "force". We can use this function to force computation of a function on the stack:

  ($x x) $force

  ; And here's an example of usage, forcing a function without naming it:
  
  (dup *) 8 swap force print ; 64

  ; We can also define control structures such as if-statements

  ($cond $true $false cond ^false ^true rot cswap drop force) $if

  ; Some examples

  (5) (4) 't  if print  ; 4
  (5) (4) '() if print  ; 5

  ; Writing if-statements backwards is tricky, so we can fix it by defining "endif" which will flip the arguments:

  ($false $true $cond $if ^false ^true ^cond if) $endif

  ; Now we can write:

  ^if (1 2 eq)
    ('true print)
    ('false print)  ; false
  endif

  ^if (1 1 eq)
    ('true print)   ; true
    ('false print)
  endif

  ; Finally, we'll finish with recursion. Forsp uses the Y-Combinator for recursion

  ($f ($x (^x x) f) dup force) $Y

  ; We'll also implement a wrapper called "rec" that performs the application Y

  ($g (^g Y)) $rec

  ; Now we can implement recursive functions:

  ($self $list
    ^if (^list '() eq) 0 (
      ^list cdr self 1 +
    ) endif
  ) rec $length

  '()      length print ; 0
  '(5)     length print ; 1
  '(8 9)   length print ; 2
  '(1 2 3) length print ; 3

  ; This concludes the tutorial. You're encouraged to explore the examples to learn more!
)
