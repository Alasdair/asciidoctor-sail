default Order dec
$include <prelude.sail>

/* Pretend we have accessors for reading and writing registers */
val rX : bits(5) -> bits(32)

val wX : (bits(5), bits(32)) -> unit

overload X = {rX, wX}

scattered union Instr

val execute : Instr -> unit

union clause Instr = Add : (bits(5), bits(5), bits(5))

function clause execute Add(rd, rx, ry) = {
    X(rd) = add_bits(X(rx), X(ry))
}

union clause Instr = Sub : (bits(5), bits(5), bits(5))

function clause execute Sub(0b00000, rx, ry) = {
    ()
}

function clause execute Sub(rd, rx, ry) = {
    X(rd) = sub_bits(X(rx), X(ry))
}
