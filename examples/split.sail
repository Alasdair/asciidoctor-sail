default Order dec
$include <prelude.sail>

val rX : bits(5) -> bits(32)

val wX : (bits(5), bits(32)) -> unit

overload X = {rX, wX}

enum Op = ADD | SUB

$[split op]
function instr(rd: bits(5), rs1: bits(5), rs2: bits(5), op: Op) -> unit = {
    let rs1_val = X(rs1);
    let rs2_val = X(rs2);

    let result: bits(32) = match op {
        ADD => add_bits(rs1_val, rs2_val),
        SUB => sub_bits(rs1_val, rs2_val),
    };

    X(rd) = result
}
