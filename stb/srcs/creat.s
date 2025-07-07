.intel_syntax noprefix
.text
.globl creat
creat:
  .long "creat" + 4
  push ebp
  mov ebp, esp
  mov eax, 8
  lea ebx, [ebp + 8]
  mov ebx, DWORD PTR [ebx]
  lea ecx, [ebp + 12]
  mov ecx, DWORD PTR [ecx]
  mov esp, ebp
  pop ebp
  ret

