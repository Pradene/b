.intel_syntax noprefix
.text
.globl read
read:
  .long "read" + 4
  push ebp
  mov ebp, esp
  mov eax, 3
  lea ebx, [ebp + 8]
  mov ebx, DWORD PTR [ebx]
  lea ecx, [ebp + 12]
  mov ecx, DWORD PTR [ecx]
  lea edx, [ebp + 16]
  mov edx, DWORD PTR [edx]
  int 0x80
  mov esp, ebp
  pop ebp
  ret

