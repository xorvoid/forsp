(
  ; church numerals: core
  (($f))           $zero
  ($n ($f ^f n f)) $succ
  ($m $n ($f ^f n ^f m)) $add
  ($m $n ($f (^f n) m))  $mult

  ; church pred function
  ($n ($f $x ($u ^x) ($g ($h ^f g h)) n $k ($x ^x) k)) $pred

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
  nine pred show
  nine nine mult pred show
)