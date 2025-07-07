.intel_syntax noprefix
.text
.globl execv
execv:
  .long "execv" + 4
  push ebp
  mov ebp, esp
  mov esp, ebp
  pop ebp
  ret
