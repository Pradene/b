.intel_syntax noprefix
.text
.globl fork
fork:
  .long "fork" + 4
  push ebp
  mov ebp, esp
  mov eax, 2
  int 0x80
  mov esp, ebp
  pop ebp
  ret

