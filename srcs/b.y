%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol.h"
#include "y.tab.h"

int yylex(void);
void yyerror(const char *s);
void yylex_destroy(void);

extern int yylineno;
extern int yycolumn;
extern char *yytext;

static size_t label_fn = 0;
static size_t label_if = 0;
static size_t label_while = 0;
static size_t label_switch = 0;
static size_t label_tern = 0;
static size_t label_const = 0;
static int    pointer = 0;

static size_t else_label_stack[100];
static size_t end_label_stack[100];
static int label_stack_top = -1;

/* Function to handle escape sequences like C */
int handle_escape_char(char c) {
  switch(c) {
    case '0':  return 0;   /* null character */
    case 'a':  return 7;   /* alert (bell) */
    case 'b':  return 8;   /* backspace */
    case 't':  return 9;   /* horizontal tab */
    case 'n':  return 10;  /* newline */
    case 'v':  return 11;  /* vertical tab */
    case 'f':  return 12;  /* form feed */
    case 'r':  return 13;  /* carriage return */
    case 'e':  return 27;  /* escape (non-standard but kept for compatibility) */
    case '"':  return 34;  /* double quote */
    case '\'': return 39;  /* single quote */
    case '(':  return 40;  /* left parenthesis (non-standard but kept) */
    case ')':  return 41;  /* right parenthesis (non-standard but kept) */
    case '*':  return 42;  /* asterisk (non-standard but kept) */
    case '?':  return 63;  /* question mark */
    case '\\': return 92;  /* backslash */
    default:   return c;   /* return the character as-is for unknown escapes */
  }
}
%}

%glr-parser
%expect-rr 54

%union {
  char *string;
  int   number;
}

%type <string> constant opt_constant
%type <string> array opt_array
%type <number> arguments opt_arguments
%type <string> ival

%token <string> ID
%token <string> NUMBER
%token <string> STRING
%token <string> CHAR
%token AUTO
%token EXTRN
%token RETURN
%token SWITCH
%token CASE
%token IF
%token ELSE
%token WHILE
%token GOTO
%token ASSIGN
      ASSIGN_OR 
      ASSIGN_AND 
      ASSIGN_EQ 
      ASSIGN_NE 
      ASSIGN_LT 
      ASSIGN_LTE
      ASSIGN_GT
      ASSIGN_GTE
      ASSIGN_LSHIFT
      ASSIGN_RSHIFT
      ASSIGN_PLUS
      ASSIGN_MINUS
      ASSIGN_MOD
      ASSIGN_MUL
      ASSIGN_DIV
%token GTE
%token GT
%token LTE
%token LT
%token EQ
%token NE
%token RSHIFT LSHIFT
%token INCREMENT DECREMENT

/* Ordered from LOWEST to HIGHEST precedence */
%nonassoc EMPTY
%nonassoc ELSE
%right    ASSIGN
          ASSIGN_OR
          ASSIGN_AND
          ASSIGN_EQ
          ASSIGN_NE
          ASSIGN_LT
          ASSIGN_LTE
          ASSIGN_GT
          ASSIGN_GTE
          ASSIGN_LSHIFT
          ASSIGN_RSHIFT
          ASSIGN_PLUS
          ASSIGN_MINUS
          ASSIGN_MOD
          ASSIGN_MUL
          ASSIGN_DIV                              /* Assignment operators */
%right    '?' ':'                                 /* Ternary expression */
%left     '|'                                     /* Logical OR */
%left     '&'                                     /* Logical AND */
%left     EQ NE                                   /* Equality operators */
%left     LT LTE GT GTE                           /* Relational operators */
%left     LSHIFT RSHIFT                           /* Bitwise shifts */
%left     '+' '-'                                 /* Additive operators */
%left     '*' '/' '%'                             /* Multiplicative operators */
%right    MINUS NOT DEREF REF INCREMENT DECREMENT /* Unary operators */
%nonassoc '[' ']'                                 /* Array subscript */
%nonassoc '(' ')'                                 /* Function call */
%nonassoc '{' '}'                                 /* Scope */

%start program

%locations

%%

program:
  {
    scope_create();
    printf(".intel_syntax noprefix\n");
    printf(".text\n");
  } definitions {
    scope_destroy();
  }
;

definitions:
  /* Empty */ %prec EMPTY
| definitions definition
;

definition:
  ID opt_array {
    symbol_add($1, $2 != NULL ? POINTER : VARIABLE, EXTERNAL);
    printf(".data\n");
    printf(".globl %s\n", $1);
    printf("%s:\n", $1);
    free($1);
  } opt_ivals ';' {}
| ID '(' {
    symbol_add($1, POINTER, EXTERNAL);
    scope_create();
    printf(".text\n");
    printf(".globl %s\n", $1);
    printf("%s:\n", $1);
    printf("  .long \"%s\" + 4\n", $1);
    printf("  push ebp\n");
    printf("  mov ebp, esp\n");
    free($1);
  } opt_parameters ')' statement {
    printf(".LF%zu:\n", label_fn++);
    printf("  mov esp, ebp\n");
    printf("  pop ebp\n");
    printf("  ret\n");
    scope_destroy();
  }
;

array:
  '[' opt_constant ']' { $$ = $2; }
;

opt_array:
  /* Empty */ %prec EMPTY { $$ = NULL; }
| array                   { $$ = $1; }
;

ival:
  constant  { $$ = $1; }
| ID        { $$ = $1; }
;

ivals:
  ival {
    printf("  .long %s\n", $1);
    free($1);
  }
| ivals ',' ival {
    printf("  .long %s\n", $3);
    free($3);
  }
;

opt_ivals:
  /* Empty */ %prec EMPTY { printf("  .long 0\n"); }
| ivals
;

parameters:
  ID {
    symbol_add($1, VARIABLE, INTERNAL);
    free($1);
  }
| parameters ',' ID {
    symbol_add($3, VARIABLE, INTERNAL);
    free($3);
  }
;

opt_parameters:
  /* Empty */ %prec EMPTY
| parameters
;

constant:
  NUMBER { $$ = $1; }
| CHAR {
    char *buf = (char *)malloc(32);
    if (buf == NULL) exit(1);
    char *s = $1;
    int c = (s[1] == '\\') ? handle_escape_char(s[2]) : (int)s[1];
    sprintf(buf, "%d", c);
    $$ = buf;
    free($1);
  }
| STRING {
    char* buf = (char *)malloc(32);
    if (buf == NULL) exit(1);
    printf(".section .rodata\n");
    printf(".LC%zu:\n", label_const);
    printf("  .long .LC%zu + 4\n", label_const);
    printf("  .string %s\n", $1);
    printf(".text\n");
    sprintf(buf, ".LC%zu", label_const++);
    $$ = buf;
    free($1);
  }
;

opt_constant:
  /* Empty */ %prec EMPTY { $$ = NULL; }
| constant                { $$ = $1; }
;

statement:
  AUTO auto ';' statement
| EXTRN extrn ';' statement
| '{' {
    scope_create();
  } statements '}' {
    scope_destroy();
  }
| IF '(' rvalue {
    label_stack_top++;
    else_label_stack[label_stack_top] = label_if++;
    end_label_stack[label_stack_top] = label_if++;
    printf("  test eax, eax\n");
    printf("  jz .LIE%zu\n", else_label_stack[label_stack_top]);
  } ')' statement {
    printf("  jmp .LIE%zu\n", end_label_stack[label_stack_top]);
    printf(".LIE%zu:\n", else_label_stack[label_stack_top]);
  } else {
    printf(".LIE%zu:\n", end_label_stack[label_stack_top]);
    label_stack_top--;
  }
| WHILE {
    printf(".LW%zu:\n", ++label_while);
  } '(' rvalue ')' {
    printf("  test eax, eax\n");
    printf("  jz .LW%zu\n", ++label_while);
  } statement {
    printf("  jmp .LW%zu\n", --label_while);
    printf(".LW%zu:\n", ++label_while);
  }
| SWITCH '(' rvalue ')' {
    printf("  mov ebx, eax\n");
  } statement
| CASE constant {
    printf("  mov eax, %s\n", $2);
  } ':' {
    printf("  cmp ebx, eax\n");
    printf("  jnz .LS%zu\n", label_switch);
    free($2);
  } statement {
    printf(".LS%zu:\n", label_switch++);
  }
| ID ':' {
    symbol_add($1, POINTER, LABEL);
    printf(".%s:\n", $1);
    printf("  .long .%s + 4\n", $1);
    free($1);
  } statement
| GOTO rvalue ';' {
    printf("  jmp [eax]\n");
  }
| RETURN return ';' {
    printf("  jmp .LF%zu\n", label_fn);
  }
| opt_rvalue ';'
;

opt_rvalue:
  /* Empty */
| rvalue
;

return:
  /* Empty */ %prec EMPTY
| '(' rvalue ')'
;

statements:
  /* Empty */ %prec EMPTY
| statements statement
;

auto:
  auto_def
| auto ',' auto_def
;

auto_def:
  ID {
    symbol_add($1, VARIABLE, AUTOMATIC);
    printf("  sub esp, 4\n");
    printf("  mov DWORD PTR [ebp - %zu], 0\n", current_scope->local_offset);
  } opt_constant {
    if ($3 != NULL) {
      printf("  mov DWORD PTR [ebp - %zu], %s\n", current_scope->local_offset, $3);
      free($3);
    }
  }
;

extrn:
  ID {
    symbol_add($1, POINTER, EXTERNAL);
    printf(".extern %s\n", $1);
    free($1);
  }
| extrn ',' ID {
    symbol_add($3, POINTER, EXTERNAL);
    printf(".extern %s\n", $3);
    free($3);
  }
;

else:
  /* Empty */ %prec EMPTY
| ELSE statement
;

rvalue:
  '(' rvalue ')'
| lvalue %prec EMPTY {
    if (pointer == VARIABLE) {
      printf("  mov eax, DWORD PTR [eax]\n");
    }
    pointer = NONE;
  }
| constant {
    printf("  mov eax, %s\n", $1);
    free($1);
  }
| lvalue ASSIGN {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_OR {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  or [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN_AND {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  and [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN_EQ {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  sete al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_NE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setne al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_LT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setl al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_LTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setle al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_GT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setg al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_GTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setge al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_LSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  mov cl, dl\n");
    printf("  shl eax, cl\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_RSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  mov cl, dl\n");
    printf("  shr eax, cl\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_PLUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  add [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN_MINUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  sub [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN_MOD {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  cdq\n");
    printf("  idiv edx\n");
    printf("  mov eax, edx\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_MUL {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  imul eax, edx\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_DIV {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  cdq\n");
    printf("  idiv edx\n");
    printf("  mov [ecx], eax\n");
  }
| INCREMENT lvalue {
    printf("  add DWORD PTR [eax], 1\n");
    printf("  mov eax, DWORD PTR [eax]\n");
  }
| DECREMENT lvalue {
    printf("  sub DWORD PTR [eax], 1\n");
    printf("  mov eax, DWORD PTR [eax]\n");
  }
| lvalue INCREMENT {
    printf("  mov ecx, DWORD PTR [eax]\n");
    printf("  add DWORD PTR [eax], 1\n");
    printf("  mov eax, ecx\n");
  }
| lvalue DECREMENT {
    printf("  mov ecx, DWORD PTR [eax]\n");
    printf("  sub DWORD PTR [eax], 1\n");
    printf("  mov eax, ecx\n");
  }
| rvalue EQ {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  sete al\n");
    printf("  movzx eax, al\n");
  }
| rvalue NE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setne al\n");
    printf("  movzx eax, al\n");
  }
| rvalue LT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setl al\n");
    printf("  movzx eax, al\n");
  }
| rvalue LTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setle al\n");
    printf("  movzx eax, al\n");
  }
| rvalue GT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setg al\n");
    printf("  movzx eax, al\n");
  }
| rvalue GTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setge al\n");
    printf("  movzx eax, al\n");
  }
| rvalue '|' {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  or eax, ecx\n");
  }
| rvalue '&' {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  and eax, ecx\n");
  }
| rvalue '+' {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  add eax, ecx\n");
  }
| rvalue '-' {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  sub ecx, eax\n");
    printf("  mov eax, ecx\n");
  }
| rvalue '*' {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  imul eax, ecx\n");
  }
| rvalue '/' {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  cdq\n");
    printf("  idiv ecx\n");
  }
| rvalue '%' {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  cdq\n");
    printf("  idiv ecx\n");
    printf("  mov eax, edx\n");
  }
| rvalue LSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  shl eax, cl\n");
  }
| rvalue RSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  shr eax, cl\n");
  }
| rvalue '?' {
    printf("  test eax, eax\n");
    printf("  jz .LT%zu\n", ++label_tern);
  } rvalue {
    printf("  jmp .LT%zu\n", ++label_tern);
    printf(".LT%zu:\n", --label_tern);
  } ':' rvalue {
    printf(".LT%zu:\n", ++label_tern);
  }
| '-' rvalue %prec MINUS {
    printf("  neg eax\n");
  }
| '!' rvalue %prec NOT {
    printf("  test eax, eax\n");
    printf("  setz al\n");
    printf("  movzx eax, al\n");
  }
| '&' lvalue %prec REF
| rvalue '(' {
    printf("  push eax\n");
  } opt_arguments ')' {
    for (int i = 0; i < ($4 + 1) / 2; ++i) {
      printf("  mov ebx, [esp + %d]\n", i * 4);
      printf("  mov ecx, [esp + %d]\n", ($4 - i) * 4);
      printf("  mov [esp + %d], ebx\n", ($4 - i) * 4);
      printf("  mov [esp + %d], ecx\n", i * 4);
    }
    printf("  pop eax\n");
    printf("  call [eax]\n");
    if ($4 > 0) {
      printf("  add esp, %d\n", $4 * 4);
    }
  }
;

arguments:
  rvalue {
    printf("  push eax\n");
    $$ = 1;
  }
| arguments ',' rvalue {
    printf("  push eax\n");
    $$ = $1 + 1;
  }
;

opt_arguments:
  /* Empty */ %prec EMPTY { $$ = 0; }
| arguments               { $$ = $1; }
;

lvalue:
  ID {
    Symbol *symbol = symbol_find_global($1);
    if (symbol == NULL) {
      free($1);
      yyerror("Undefined variable");
      break ;
    }
    switch (symbol->storage) {
      case AUTOMATIC:
        printf("  lea eax, [ebp - %zu]\n", symbol->offset);
        break ;
      case INTERNAL:
        printf("  lea eax, [ebp + %zu]\n", symbol->offset);
        break ;
      case EXTERNAL:
        printf("  lea eax, [%s]\n", symbol->name);
        break ;
      case LABEL:
        printf("  lea eax, [.%s]\n", symbol->name);
        break ;
      default:
        break ;
    }
    pointer = symbol->type;
    free($1);
  } %dprec 1
| '*' rvalue %prec DEREF {
    pointer = VARIABLE;
  }
| rvalue '[' {
    printf("  push eax\n");
  } rvalue ']' {
    printf("  mov ecx, eax\n");
    printf("  shl ecx, 2\n");
    printf("  pop eax\n");
    printf("  add eax, ecx\n");
    pointer = VARIABLE;
  } %dprec 2
;


%%

void yyerror(const char *s) {
  fprintf(stderr, "Error: %d:%d: %s '%s'\n", yylineno, yycolumn, s, yytext);
}

int main(void) {
  int result = yyparse();
  yylex_destroy();
  return result;
}
