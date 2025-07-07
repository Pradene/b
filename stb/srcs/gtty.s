.intel_syntax noprefix
.text
.globl gtty
gtty:
  .long "gtty" + 4
  push ebp
  mov ebp, esp
  mov esp, ebp
  pop ebp
  ret

