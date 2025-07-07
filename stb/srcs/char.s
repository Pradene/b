.intel_syntax noprefix
.text
.globl char
char:
  .long "char" + 4
  push ebp
  mov ebp, esp
  lea eax, [ebp + 8]
  mov eax, DWORD PTR [eax]
  lea ecx, [ebp + 12]
  mov ecx, DWORD PTR [ecx]
  add eax, ecx
  movzx eax, BYTE PTR [eax]
  mov esp, ebp
  pop ebp
  ret

