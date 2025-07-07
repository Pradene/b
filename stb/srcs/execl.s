.intel_syntax noprefix
.text
.globl execl
execl:
  .long "execl" + 4
  push ebp
  mov ebp, esp
  mov esp, ebp
  pop ebp
  ret

