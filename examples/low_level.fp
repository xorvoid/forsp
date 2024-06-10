(
  ;; This example is all about low-level ptr operations
  ;; Assumption: implementation is running on a 64-bit machine and thus all words are 64-bits

  ; core utilities
  ($x $y ^x ^y) $swap
  (0 swap - -)  $+
  ($x ^x ^x)    $dup

  ; array access
  ; (8 * + ptr-read! dup print)        $array-read!
  ; ($v 8 * + dup print ^v ptr-write!) $array-write!

  ; functions to manipulate interpretor's "atom_true"
  (ptr-state! 6 8 * +)                       $ptr-true!
  (ptr-true! ptr-read! ptr-to-obj!)          $load-true!
  ($v ptr-true! ^v ptr-from-obj! ptr-write!) $set-true!

   'true set-true!
   5 5 eq print

  't set-true!
   5 5 eq print
)