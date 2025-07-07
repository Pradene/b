.intel_syntax noprefix
.text
.globl wait
wait:
  .long "wait" + 4
  push ebp
  mov ebp, esp
  mov eax, 7
  mov ebx, -1
  mov ecx, 0
  mov edx, 0
  int 0x80
  mov esp, ebp
  pop ebp
  ret

