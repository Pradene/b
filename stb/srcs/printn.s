.intel_syntax noprefix
.text
.text
.globl printn
printn:
  .long "printn" + 4
  push ebp
  mov ebp, esp
.extern putchar
  sub esp, 4
  mov DWORD PTR [ebp - 4], 0
  lea eax, [ebp - 4]
  push eax
  lea eax, [ebp + 8]
  mov eax, DWORD PTR [eax]
  push eax
  lea eax, [ebp + 12]
  mov eax, DWORD PTR [eax]
  mov ecx, eax
  pop eax
  cdq
  idiv ecx
  pop ecx
  mov [ecx], eax
  test eax, eax
  jz .LIE1
  lea eax, [printn]
  push eax
  lea eax, [ebp - 4]
  mov eax, DWORD PTR [eax]
  push eax
  lea eax, [ebp + 12]
  mov eax, DWORD PTR [eax]
  push eax
  mov ebx, [esp + 0]
  mov ecx, [esp + 8]
  mov [esp + 8], ebx
  mov [esp + 0], ecx
  pop eax
  call [eax]
  add esp, 8
  jmp .LIE2
.LIE1:
.LIE2:
  lea eax, [putchar]
  push eax
  lea eax, [ebp + 8]
  mov eax, DWORD PTR [eax]
  push eax
  lea eax, [ebp + 12]
  mov eax, DWORD PTR [eax]
  mov ecx, eax
  pop eax
  cdq
  idiv ecx
  mov eax, edx
  push eax
  mov eax, 48
  pop ecx
  add eax, ecx
  push eax
  mov ebx, [esp + 0]
  mov ecx, [esp + 4]
  mov [esp + 4], ebx
  mov [esp + 0], ecx
  pop eax
  call [eax]
  add esp, 4
.LF0:
  mov esp, ebp
  pop ebp
  ret
