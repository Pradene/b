.intel_syntax noprefix
.text
.globl time
time:
  .long "time" + 4
  push ebp
  mov ebp, esp
  mov esp, ebp
  pop ebp
  ret



