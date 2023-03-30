$[wavedrom _ offset[20..1] _ _ dest JAL]
mapping clause encdec =
    RISCV_JAL(imm : bits(20) @ 0b0, rd)
    <->
    imm[20] @ imm[10..1] @ imm[11] @ imm[19..12] @ rd @ 0b1101111
