(
  (tag 0 eq) $is-nil  (tag 1 eq) $is-atom (tag 3 eq) $is-pair (tag 4 eq) $is-clos

  ($n ^n ^n)                     $dup
  ('t cswap)                     $swap
  ($a $b ^b ^a ^b)               $over
  ($a $b $c ^c ^b ^a ^c)         $over2
  ($a $b $c ^b ^a ^c)            $rot
  ($x x)                         $force
  (force cswap $_ force)         $if
  ($f $t $c $fn ^f ^t ^c fn)     $endif
  ($a $b '() ('() 't b if) a if) $and
  ($a $b ('() 't b if) 't a if)  $or


  ; rec: Recursion via Y-Combinator
  ($f ($x (^x x) f) dup force) $Y ($g (^g Y)) $rec

  ; env-find
  ($self $key $env
    ^if (^env is-nil) ('NOT_FOUND_IN_ENV ^key cons print FAIL) (
      ^env car $kv
      ^if (^kv car ^key eq) (^kv cdr)
        (^env cdr ^key self) endif
    ) endif
  ) rec $env-find


  ; stack operations
  (cons)                                      $stack-push
  ($b stack-push ^b stack-push)               $stack-push2
  (dup cdr swap car)                          $stack-pop
  (stack-pop $b stack-pop ^b)                 $stack-pop2
  (stack-pop $c stack-pop $b stack-pop ^b ^c) $stack-pop3

  ($expr $env '() ^env cons ^expr cons '#closure cons)  $make-closure
  ($expr (^expr car '#closure eq) (^expr is-pair) and)  $is-closure

  ; compute
  ($self $eval $stack $comp $env (^eval self) $self ; curry eval into self
    ^if (^comp is-nil) ^stack (
      ^comp stack-pop $cmd $comp
      ^if (^cmd 'quote eq) (
        ^comp stack-pop $literal $comp
        ^stack ^literal stack-push $stack
        ^env ^comp ^stack self
      ) (
        ^env ^cmd ^stack eval $stack $env
        ^env ^comp ^stack self
      ) endif) endif
  ) rec $compute

  ; eval: $eval $stack $expr $env -> $stack $env
  ($eval $stack $expr $env (^eval compute) $compute ; curry eval into compute
    ^if (^expr is-atom) (
      ^env ^expr env-find $callable
      ^if (^callable is-closure) (^env ^callable cdr dup cdr car swap car ^stack compute)
      (^if (^callable is-clos)   (^env ^stack callable)
                                 (^env ^stack ^callable stack-push) endif) endif)
    (^if ((^expr is-nil) (^expr is-pair) or)
      (^env ^stack ^env ^expr make-closure stack-push)
      (^env ^stack ^expr stack-push) endif) endif
  ) rec $eval

 ; init-env
 '()

 (stack-pop over2 swap env-find stack-push)  'push   cons cons
 (stack-pop2 cons rot swap cons swap)        'pop    cons cons
 (stack-pop car stack-push)                  'car    cons cons
 (stack-pop cdr stack-push)                  'cdr    cons cons
 (dup cons)                                  'stack  cons cons
 (stack-pop print)                           'print  cons cons
 (stack-pop2 eq stack-push)                  'eq     cons cons
 (stack-pop3 cswap stack-push2)              'cswap  cons cons
 (stack-pop2 - stack-push)                   '-      cons cons
 (stack-pop2 * stack-push)                   '*      cons cons

 read '() ^eval compute
)

(
 45
 '(a b c) cdr car pop
 ^b print
)

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
    ^if [ ^n 0 eq ] 1
      ([ ^n 1 - ] self ^n *)
    endif
  ) rec $factorial

  5 factorial print
)
