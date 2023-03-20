default Order dec
$include <prelude.sail>

scattered union Instr

val encdec : Instr <-> bits(32)

union clause Instr = Add : (bits(5), bits(5), bits(5))

mapping clause encdec =
    Add(rd, rx, ry) <-> 0xFFFF @ rd : bits(5) @ 0b1 @ rx : bits(5) @ ry : bits(5)
