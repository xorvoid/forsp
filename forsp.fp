(
  (tag 0 eq) $is-nil
  (tag 1 eq) $is-atom
  (tag 2 eq) $is-num
  (tag 3 eq) $is-pair
  (tag 4 eq) $is-clos
  (tag 5 eq) $is-prim

  ($n ^n ^n)                     $dup
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

  ; stack operations
  (cons)                    $push
  ($b push ^b push)         $push2
  (dup cdr swap car)        $pop
  (pop $b pop ^b)           $pop2
  (pop $c pop $b pop ^b ^c) $pop3

  ; make-closure
  ($expr $env
    '() ^env cons ^expr cons '#closure cons)
  $make-closure

  ; is-closure
  ($expr (^expr car '#closure eq) (^expr is-pair) and)
  $is-closure

  ; compute
  ($self $eval $stack $comp $env (^eval self) $self ; curry eval into self
    ^if (^comp is-nil) ^stack (
      ^comp pop $cmd $comp
      ^if (^cmd '' eq) (
        ^comp pop $literal $comp
        ^stack ^literal push $stack
        ^env ^comp ^stack self
      ) (^if  (^cmd '^ eq) (
        ^comp pop $name $comp
        ^env ^name env-find $value
        ^stack ^value push $stack
        ^env ^comp ^stack self
      ) (^if  (^cmd '$ eq) (
        ^comp pop $name $comp
        ^stack pop $val $stack
        ^env ^val ^name env-define $env
        ^env ^comp ^stack self
      ) (
        ^env ^cmd ^stack eval $stack
        ^env ^comp ^stack self
      ) endif) endif) endif) endif
  ) rec $compute

  ; apply: $eval $stack $expr
  ($eval $stack $expr (^eval compute) $compute ; curry eval into compute
    ^if (^expr is-closure) (
      ^expr explode $_ ^stack compute
    ) (^if (^expr is-clos) (
      ^stack expr
    ) (
      ^stack ^expr push
    ) endif) endif
  ) $apply

  ; eval: $eval $stack $expr $env
  ($eval $stack $expr $env (^eval apply) $apply ; curry eval into apply
    ^if (^expr is-atom) (
      ^env ^expr env-find ^stack apply
    ) (^if ((^expr is-nil) (^expr is-pair) or) (
      ^stack ^env ^expr make-closure push
    ) (
      ^stack ^expr push
    ) endif) endif
  ) rec $eval

 ; init-env
 '()
 (pop print)        'print  cons cons
 (dup push)         'stack  cons cons
 (pop2 eq push)     'eq     cons cons
 (pop3 cswap push2) 'cswap  cons cons
 (pop2 - push)      '-      cons cons
 (pop2 * push)      '*      cons cons
 $env

 read $expr
 ^env ^expr '()
 eval pop swap ^eval apply
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
