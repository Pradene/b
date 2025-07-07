.intel_syntax noprefix
.text
.globl stty
stty:
  .long "stty" + 4
  push ebp
  mov ebp, esp
  mov esp, ebp
  pop ebp
  ret

