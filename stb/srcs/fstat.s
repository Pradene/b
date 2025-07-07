.intel_syntax noprefix
.text
.globl fstat
fstat:
  .long "fstat" + 4
  push ebp
  mov ebp, esp
  mov eax, 108
  lea ebx, [ebp + 8]
  mov ebx, DWORD PTR [ebx]
  lea ecx, [ebp + 12]
  mov ecx, DWORD PTR [ecx]
  int 0x80
  mov esp, ebp
  pop ebp
  ret

