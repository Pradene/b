.intel_syntax noprefix
.text
.globl getchar
getchar:
  .long "getchar" + 4
  push ebp
  mov ebp, esp
  sub esp, 4
  mov DWORD PTR [ebp - 4], 0
  mov eax, 3
  mov ebx, 1
  lea ecx, [ebp - 4]
  mov edx, 1
  int 0x80
  mov esp, ebp
  pop ebp
  ret

