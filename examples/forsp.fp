(
  ; core utility functions
  ($n ^n ^n)                     $dup
  ('t cswap)                     $swap
  ($a $b $c ^c ^b ^a ^c)         $over2
  ($a $b $c ^b ^a ^c)            $rot
  ($x x)                         $force
  ($c $t $f c ^f ^t rot cswap $_ force) $if
  ($f $t $c $fn ^f ^t ^c fn)     $endif

  ; object type predicate functions
  (tag 0 eq) $is-nil  (tag 1 eq) $is-atom (tag 3 eq) $is-pair (tag 4 eq) $is-clos
  ($x ('() 't (^x is-pair) if) 't (^x is-nil) if) $is-list

  ; recursion via y-combinator
  ($f ($x (^x x) f) dup force) $Y ($g (^g Y)) $rec

  ; env-find
  ($self $key $env
    ^if (^env is-nil) ('NOT_FOUND_IN_ENV ^key cons print FAIL) (
      ^if (^env car car ^key eq) (^env car cdr) (^env cdr ^key self) endif
    ) endif
  ) rec $env-find

  ; stack operations
  (cons)                                      $stack-push
  ($b stack-push ^b stack-push)               $stack-push2
  (dup cdr swap car)                          $stack-pop
  (stack-pop $b stack-pop ^b)                 $stack-pop2
  (stack-pop $c stack-pop $b stack-pop ^b ^c) $stack-pop3

  ; closure operations
  ($expr $env '() ^env cons ^expr cons '#closure cons)        $make-closure
  ($x '() ('() 't (^x car '#closure eq) if) (^x is-pair) if)  $is-closure
  (dup cdr car swap car)                                      $unpack-closure

  ; compute [$comp $stack $env -> $stack]
  ($compute $eval
    ^if (dup is-nil) (rot $_ $_) ( ; false case: return $stack
      stack-pop
      ^if (dup 'quote eq)
        ($_ stack-pop rot swap stack-push swap ^eval compute)
        (swap $comp eval ^comp ^eval compute) endif
    ) endif
  ) rec $compute

  ; eval: [$expr $stack $env -> $stack $env]
  ($eval
    ^if (dup is-atom) (
      over2 swap env-find dup $callable
      ^if (dup is-closure) (swap $stack cdr unpack-closure ^stack swap ^eval compute)
      (^if (dup is-clos)   (force)
                           (stack-push)  endif) endif)
    (^if (dup is-list)
      (over2 swap make-closure stack-push)
      (stack-push) endif) endif
  ) rec $eval

 ; tag function
 ($x ((^x tag) 4 ^x is-closure if) 5 (^x is-clos) if) $new-tag

 ; init-env
 '()
 (stack-pop over2 swap env-find stack-push)  'push   cons cons
 (stack-pop2 cons rot swap cons swap)        'pop    cons cons
 (stack-pop2 cons stack-push)                'cons   cons cons
 (stack-pop car stack-push)                  'car    cons cons
 (stack-pop cdr stack-push)                  'cdr    cons cons
 (stack-pop2 eq stack-push)                  'eq     cons cons
 (stack-pop3 cswap stack-push2)              'cswap  cons cons
 (stack-pop new-tag stack-push)              'tag    cons cons
 (read stack-push)                           'read   cons cons
 (stack-pop print)                           'print  cons cons
 (dup cons)                                  'stack  cons cons
 (stack-pop2 - stack-push)                   '-      cons cons
 (stack-pop2 * stack-push)                   '*      cons cons

 '() read ^eval compute
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Input: factorial
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
