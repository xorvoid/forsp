(
  ('t cswap)   $swap
  (0 swap - -) $+

  (+) $fn
  
  ($x x)                   $apply
  ($fn ($x ($y ^y ^x fn))) $curry2
  ($fn (^fn apply apply))  $uncurry2

  ^fn curry2 $fn-curried
  ^fn-curried uncurry2 $fn-uncurried
  
  5 4 fn print
  ^fn-curried 4 swap apply 5 swap apply print
  5 4 fn-uncurried print
)