(
 ($x x)                          $force
 ($a $b ^a ^b force)             $force2
 ($a $b $c ^a ^b ^c force)       $force3
 ($a $b $c $d ^a ^b ^c ^d force) $force4

 ($x ^x ^x)                $dup
 ($x)                      $drop
 ($x $y ^x ^y)             $swap
 (0 swap - -)              $+
 (force cswap drop force)  $if
 (force4)                  $endif
 ($cond 't '() ^cond if)   $not
 ($fn $arg (^arg fn))      $partial


 ;; Y-Combinator
 ($f
   ($x (^x x) f)
   ($x (^x x) f)
   force
 ) $Y

 ; Recusive function builder
 (^Y partial) $rec

 ; Sum 1 -> n (recursively defined)
 ($self $n
   ^if (0 ^n eq)
     (^n 1 - self ^n +)
   endif
 ) rec $sum

 ; Map fn() over list
 ($self $fn $list
    ^if ('() ^list eq) '()
      (^list cdr ^fn self ^list car fn cons)
    endif
 ) rec $map

 ; Range
 ($self $start $end
   ^if (^start ^end eq) '()
     (^end ^start 1 + self ^start cons)
   endif
 ) rec $range

;; Show off some things

 5 0 range
 'range print dup print

 (10 *) map
 'map print dup print

 cdr
 'cdr print dup print

 'foo 'bar swap cons print

 'a 'a eq

 123 print

 12 34 eq print
 34 35 1 - eq print

 ; For loop
 ($self $iter $body
   ^if ('() ^iter eq) '()
     (^iter car body
      ^body ^iter cdr self)
   endif
 ) rec $for
 (force3) $endfor

 ^for ^range 0 10 force3 (print) endfor
 ^for ^range 0 10 force3 ($n ^n 10 * print) endfor

 ; length
 ($self $list
   ^if (^list '() eq) 0
     (^list cdr self 1 +)
   endif
 ) rec $length

 ; depth
 (stack length) $depth

 'length print
 '(1 2 3 4) length print

 ; dropall
 ($self ^if depth 1 eq () ($_ self) endif)
 rec $dropall

 dropall
 'depth2 print
 3 4 depth print
 dropall
 'depth0 print
 depth print

 ; reverse
 ($self $list $new
   ^if ('() ^list eq) ^new
     (^new ^list car cons ^list cdr self)
   endif
 ) rec
 ($helper ($list '() ^list helper)) force
 $reverse

 ; explode
 ($self $list
   ^if ('() ^list eq) ()
     (^list cdr self ^list car)
   endif
 ) rec $explode

 ; implode
 ($self $n
   ^if (0 ^n eq) '()
     ($tmp ^n 1 - self ^tmp cons)
   endif
 ) rec $implode


 'reverse print
 '(1 2 3) reverse print

 depth print
 '(1 2 3) dup explode
 depth print
 3 implode print

 10 0 range explode 10 + 10 implode print

 ; factorial
 ($self $n
   ^if (^n 0 eq) 1
     (^n 1 - self ^n *)
   endif
 ) rec $factorial

 5 factorial print

 ; stack-set
 ($self $list
   ^if ('() ^list eq) ()
     (^list cdr self ^list car)
   endif
 ) rec
 ($helper ($list dropall ^list helper)) force $stack-set

 dropall
 5 4
 stack print
 (8 9) force stack stack-set + print

)
