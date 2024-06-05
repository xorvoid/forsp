(
  (tag 0 eq) $is-nil
  (tag 1 eq) $is-atom
  (tag 2 eq) $is-num
  (tag 3 eq) $is-pair
  (tag 4 eq) $is-clos
  (tag 5 eq) $is-prim

  ($n ^n ^n)                     $dup
  ($_)                           $drop
  ('t cswap)                     $swap
  (force cswap $_ force)         $if
  ($f $t $c $fn ^f ^t ^c fn)     $endif
  ($a $b '() ('() 't b if) a if) $and
  ($a $b ('() 't b if) 't a if)  $or

  ; debug
  ('debug print stack print) $debug

  ; fail
  (FAIL) $fail

  ; Y-Combinator
  ($f
    ($x (^x x) f)
    ($x (^x x) f)
    force
  ) $Y

  ; rec: syntax sugar for applying the Y-Combinator
  ($g (^g Y)) $rec

  ; explode
  ($self $list
    ^if ('() ^list eq) ()
      (^list cdr self ^list car)
    endif
  ) rec $explode

  ; env-find
  ($self $key $env
    ^if (^env is-nil) ('NOT_FOUND_IN_ENV ^key cons print FAIL) (
      ^env car $kv
      ^if (^kv car ^key eq) (^kv cdr)
        (^env cdr ^key self) endif
    ) endif
  ) rec $env-find

  ; env-define: $key $val $env
  (cons cons) $env-define

  ; push: $stack $value -> $stack
  (swap cons) $push

  ; pop: $stack -> $stack $value
  (dup car swap cdr) $pop

  ; make-closure
  ($expr $env
    '() ^env cons ^expr cons '#closure cons)
  $make-closure

  ; is-closure
  ($expr (^expr car '#closure eq) (^expr is-pair) and)
  $is-closure

  ; compute
  ($self $eval $stack $comp $env
    (^eval self) $self ; curry eval into self
    ^if (^comp is-nil) ^stack (
      ^comp pop $comp $cmd
      ^if (^cmd '' eq) (
        ^comp pop $comp ^stack push $stack
        ^env ^comp ^stack self
      ) (^if  (^cmd '^ eq) (
        ^comp pop $comp $name
        ^env ^name env-find ^stack push $stack
        ^env ^comp ^stack self
      ) (^if  (^cmd '$ eq) (
        ^comp pop $comp $name
        ^stack pop $stack $val
        ^env ^val ^name env-define $env
        ^env ^comp ^stack self
      ) (
        ^env ^cmd ^stack eval $stack
        ^env ^comp ^stack self
      ) endif) endif) endif) endif
  ) rec $compute

  ; apply: $eval $stack $expr
  ($eval $stack $expr
    (^eval compute) $compute ; curry eval into compute
    ^if (^expr is-closure) (
      ^expr explode drop ^stack compute
    ) (^if (^expr is-clos) (
      ^stack expr
    ) (
      ^expr ^stack push
    ) endif) endif
  ) $apply

  ; eval: $eval $stack $expr $env
  ($eval $stack $expr $env
    (^eval apply) $apply ; curry eval into apply
    ^if (^expr is-atom) (
      ^env ^expr env-find     ^stack apply
    ) (^if ((^expr is-nil) (^expr is-pair) or) (
      ^env ^expr make-closure ^stack push
    ) (
      ^expr ^stack push
    ) endif) endif
  ) rec $eval
  (^eval apply) $apply ; curry eval into apply

 ; init-env
 (
   '()

   (pop swap print)
   'print cons cons

   (dup push)
   'stack cons cons

   (pop pop $stack eq ^stack push)
   'eq cons cons

   (pop swap $cond
    pop swap $a
    pop swap $b
    $st
    ^b ^a ^cond
    cswap swap
    ^st push push
   ) 'cswap cons cons

   (pop swap $b
    pop swap $a
    ^a ^b - swap push
   ) '- cons cons

   (pop swap $b
    pop swap $a
    ^a ^b * swap push
   ) '* cons cons
 ) force $env

 read $expr
 ^env ^expr '()
 eval pop apply
)

(
  ($fn fn)                     $force
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
