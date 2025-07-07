.intel_syntax noprefix
.text
.globl getuid
getuid:
  .long "getuid" + 4
  push ebp
  mov ebp, esp
  mov eax, 20
  int 0x80
  mov esp, ebp
  pop ebp
  ret

