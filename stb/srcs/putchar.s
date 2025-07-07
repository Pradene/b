.intel_syntax noprefix
.text
.globl putchar
putchar:
  .long "putchar" + 4
  push ebp
  mov ebp, esp
  mov eax, 4
  mov ebx, 1
  lea ecx, [ebp + 8]
  mov ecx, DWORD PTR [ecx]
  mov edx, 1
  int 0x80
  mov esp, ebp
  pop ebp
  ret

