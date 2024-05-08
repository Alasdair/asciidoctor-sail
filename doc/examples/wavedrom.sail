default Order dec
$include <prelude.sail>

scattered union Instr

val encdec : Instr <-> bits(32)

union clause Instr = Add : (bits(5), bits(5), bits(5))

$[wavedrom "REG3 dest ADD input input"]
mapping clause encdec =
    Add(rd, rx, ry) <-> 0xFFFF @ rd : bits(5) @ 0b1 @ rx : bits(5) @ ry : bits(5)

union clause Instr = Sub : (bits(5), bits(5), bits(5))

$[wavedrom "REG3 _ SUB _ _"]
mapping clause encdec =
    Sub(rd, rx, ry) <-> 0xFFFF @ rd : bits(5) @ 0b1 @ rx : bits(5) @ ry : bits(5)

union clause Instr = Xor : (bits(5), bits(5), bits(5))

mapping clause encdec =
    Xor(rd, rx, ry) <-> 0xFFFE @ 0b1 @ rd : bits(5) @ rx : bits(5) @ ry : bits(5)
