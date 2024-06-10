(
  ; this version builds up to an imperative/mutating language for implementation
  ; depends on low-level to implement set!

  ; core utilities
  ($x ^x ^x)          $dup
  ($x $y ^x ^y)       $swap
  ($a $b $c ^b ^a ^c) $rot
  (0 swap - -)        $+
  ('() eq)            $null?
  ($x x)              $force

  ; recursion via y-combinator
  ($f ($x (^x x) f) dup force) $Y ($g (^g Y)) $rec

  ; if-stmt
  ($c $t $f c ^f ^t rot cswap $_ force) $if
  ($f $t $c $fn ^f ^t ^c fn)     $endif

  ; for-loop
  ($self $start $end $body
    ^if (^start ^end eq) () (^start body ^body ^end ^start 1 + self) endif
  ) rec $for
  ($b $e $s $f ^b ^e ^s f) $endfor

  ; errors
  ($msg ^msg 'FAILURE cons print FAIL) $fail

  ; env-findpair
  ($self $key $env
    ^if ^env null? ('(: could not find in env) ^key cons fail) (
     ^if (^env car car ^key eq) (^env car) (^env cdr ^key self) endif
    ) endif
  ) rec $env-findpair

  ; set-car! [$val $pair]
  ($val ptr-from-obj! 8 + ^val ptr-from-obj! ptr-write!) $set-car!

  ; set-cdr! [$val $pair]
  ($val ptr-from-obj! 16 + ^val ptr-from-obj! ptr-write!) $set-cdr!

  ; set! [$value $name $env]
  ($value env-findpair ^value set-cdr!) $set!

  ; var [$val -> $get $set]
  ($val
    ($new-val env 'val ^new-val set!)  ; set function
    (^val )                            ; get function
  ) $var

  ; implementation
  1 var $a $set-a
  0 var $b $set-b
  ^for 1 10 ($_
    b $tmp
    a b + set-b
    ^tmp set-a
    b print
  ) endfor
)