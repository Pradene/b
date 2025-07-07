.intel_syntax noprefix
.text
.globl open
open:
  .long "open" + 4
  push ebp
  mov ebp, esp
  mov eax, 5
  lea ebx, [ebp + 8]
  mov ebx, DWORD PTR [ebx]
  mov ecx, 0
  lea edx, [ebp + 12]
  mov edx, DWORD PTR [edx]
  int 0x80
  mov esp, ebp
  pop ebp
  ret

