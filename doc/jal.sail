$[wavedrom _ dest JAL]
mapping clause encdec = RISCV_JAL(offset @ 0b0, rd)
  <-> offset : bits(20) @ rd @ 0b1101111