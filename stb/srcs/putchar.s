.intel_syntax noprefix
.text
.globl putchar
putchar:
  .long "putchar" + 4
  push ebp
  mov ebp, esp
  sub esp, 4
  mov DWORD PTR [ebp - 4], 0
  lea eax, [ebp - 4]
  lea ebx, [ebp + 8]
  mov ebx, DWORD PTR [ebx]
  mov [eax], ebx
  mov eax, 4
  mov ebx, 1
  lea ecx, [ebp - 4]
  mov edx, 1
  int 0x80
  mov esp, ebp
  pop ebp
  ret
