default Order dec
$include <prelude.sail>

type regidx  = bits(5)

scattered union ast

val encdec : ast <-> bits(32)

union clause ast = RISCV_JAL : (bits(21), regidx)

$include "jal.sail"
