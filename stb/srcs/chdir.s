.intel_syntax noprefix
.text
.globl chdir
chdir:
  .long "chdir" + 4
  push ebp
  mov ebp, esp
  mov eax, 12
  lea ebx, [ebp + 8]
  mov ebx, DWORD PTR [ebx]
  int 0x80
  mov esp, ebp
  pop ebp
  ret

