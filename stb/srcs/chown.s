.intel_syntax noprefix
.text
.globl chwon
chwon:
  .long "chwon" + 4
  push ebp
  mov ebp, esp
  mov eax, 182
  lea ebx, [ebp + 8]
  mov ebx, DWORD PTR [ebx]
  lea ecx, [ebp + 12]
  mov ecx, DWORD PTR [ecx]
  mov edx, 0
  int 0x80
  mov esp, ebp
  pop ebp
  ret

