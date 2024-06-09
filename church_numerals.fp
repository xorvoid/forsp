(
  ; utilities
  ($x x)                   $force
  ($fn ($x ($y ^y ^x fn))) $curry2

  ; church numerals: core
  (($f))                            $zero
  ($n ($f ^f n f))                  $succ
  ($m $n ($f ^f n ^f m))            $add
  ($m $n ($f (^f n) m))             $mult
  ($m $n ($f ^f ^m curry2 n force)) $exp

  ; church pred function: standard
  ($n ($f $x ($u ^x) ($g ($h ^f g h)) n $k ($x ^x) k)) $pred

  ; church pred function: alternative
  ($x $y ($f ^y ^x f))                     $pair
  ($x $y ^x)                               $first
  ($x $y ^y)                               $second
  zero zero pair                           $pred-init
  ($p ^second p succ ^second p pair)       $pred-inc
  ($n ^pred-init ^pred-inc n $p ^first p)  $pred-alt

  ; church numerals: constants
  (zero  succ) $one
  (one   succ) $two
  (two   succ) $three
  (three succ) $four
  (four  succ) $five
  (five  succ) $six
  (six   succ) $seven
  (seven succ) $eight
  (eight succ) $nine

  ; show: helper to print out as conventional number
  ($n 0 (0 1 - -) n print) $show

  ; demo
  zero show
  eight show
  eight nine add show
  seven succ nine add succ show
  seven eight mult show
  zero pred show
  one pred show
  nine pred show
  zero pred-alt show
  one pred-alt show
  nine pred-alt show
  nine nine mult pred show
  nine nine mult pred-alt show
  one one exp show
  four three exp show
  three four exp show
)


