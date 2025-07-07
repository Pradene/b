.intel_syntax noprefix
.text
.globl exit
exit:
  .long "exit" + 4
  push ebp
  mov ebp, esp
  mov eax, 1
  mov ebx, 0
  int 0x80
  mov esp, ebp
  pop ebp
  ret

