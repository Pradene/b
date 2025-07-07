.intel_syntax noprefix
.text
.globl ctime
ctime:
  .long "ctime" + 4
  push ebp
  mov ebp, esp
  mov esp, ebp
  pop ebp
  ret

