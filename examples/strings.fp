(
  0 make-string print

  2 make-string $str
  str 0 72 string-poke
  str 1 105 string-poke
  str print

  "Hello world!" print
  "Hello\nworld!" print

  "\x3a\x29" print
)
