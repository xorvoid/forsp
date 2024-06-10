(
  ; core utilities
  ($x ^x ^x)          $dup
  ($x $y ^x ^y)       $swap
  ($a $b $c ^b ^a ^c) $rot
  (0 swap - -)        $+
  ('())               $nil
  (nil eq)            $null?
  ($x x)              $force

  ; bit operations
  (dup nand)      $~
  (nand ~)        $&
  (~ swap ~ nand) $|

  ; if-stmt
  ($c $t $f c ^f ^t rot cswap $_ force) $if
  ($f $t $c $fn ^f ^t ^c fn)     $endif

  ; logical operations
  ($c 't '() ^c if) $!
  (! !)             $!!
  ($a $b a $a '() (b $b '() 't b if) a if) $and
  ($a $b a $a (b $b '() 't b if) 't a if) $or

  ; comparisons
  (1 63 << dup rot & eq) $is-neg
  (- is-neg) $<
  (< !)      $>=
  (swap <)   $>
  (swap >=)  $<=

  ; recursion via y-combinator
  ($f ($x (^x x) f) dup force) $Y ($g (^g Y)) $rec

  ; range
  ($self $start $end
    ^if (^start ^end eq) nil
      (^end ^start 1 + self ^start cons)
    endif
  ) rec $range

  ; map [$fn $list -> $out-list]
  ($self $fn $list
    ^if (^list null?) nil
      ( ^list car fn ^list cdr ^fn self swap cons)
    endif
  ) rec $map

  ; filter [$pred $list -> $out-list]
  ($self $pred $list
    ^if (^list null?) nil (
      ^list cdr ^pred self
      ^if (^list car pred) (^list car cons) () endif
    ) endif
  ) rec $filter

  ; reduce [$fn $init $list -> $out]
  ($self $fn $init $list
    ^if (^list null?) ^init (
      ^list cdr ^list car ^init fn ^fn self
    ) endif
  ) rec $reduce

  ; is-even
  (1 & 0 eq) $even?

  10 0 range
  (3 *) map
  ($x (^x even?) (^x 10 >) and) filter
  0 ^+ reduce
  print
)