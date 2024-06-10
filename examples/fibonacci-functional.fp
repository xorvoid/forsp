(
  ; this version implements with recursion and higher-order functions

  ; core utilities
  ($x ^x ^x)          $dup
  ($_)                $drop
  ($x $y ^x ^y)       $swap
  ($a $b $c ^b ^a ^c) $rot
  (0 swap - -)        $+
  ('())               $nil
  ('() eq)            $null?
  ($x x)              $force

  ; recursion via y-combinator
  ($f ($x (^x x) f) dup force) $Y ($g (^g Y)) $rec

  ; if-stmt
  ($c $t $f c ^f ^t rot cswap $_ force) $if
  ($f $t $c $fn ^f ^t ^c fn)     $endif

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

  ; each [$fn $list]
  ($fn (fn '()) map drop) $each
  
  ; implementation
  (0 1 ($self $a $b $n
    ^if (^n 0 eq) ^b (
      ^n 1 - ^a ^b + ^b self
    ) endif
  ) rec force) $fibonacci

  10 1 range
  ^fibonacci map
  ^print each


)