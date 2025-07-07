.intel_syntax noprefix
.text
.globl lchar
lchar:
  .long "lchar" + 4
  push ebp
  mov ebp, esp
  lea eax, [ebp + 8]
  mov eax, DWORD PTR [eax]
  lea ecx, [ebp + 12]
  mov ecx, DWORD PTR [ecx]
  add eax, ecx
  lea ebx, [ebp + 16]
  mov ebx, DWORD PTR [ebx]
  mov [eax], ebx
  mov esp, ebp
  pop ebp
  ret

