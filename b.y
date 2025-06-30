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

size_t label = 0;
size_t label_fn = 0;
size_t label_if = 0;
size_t label_while = 0;
size_t label_switch = 0;
size_t label_tern = 0;
size_t label_const = 0;
int    pointer = 0;
%}

%union {
  char *string;
  int   number;
}

%token <string> ID NUMBER STRING CHAR
%token AUTO EXTRN RETURN SWITCH CASE IF ELSE WHILE BREAK GOTO
%token SEMICOLON
%token LPAREN RPAREN
%token LBRACKET RBRACKET
%token LBRACE RBRACE
%token COMMA
%token BANG
%token QUESTION
%token COLON
%token ASSIGN
%token AMPERSAND
%token ASTERISK
%token GTE
%token GT
%token LTE
%token LT
%token EQ
%token NE
%token DIV
%token PLUS
%token MINUS
%token MOD
%token PIPE
%token RSHIFT LSHIFT
%token INCREMENT DECREMENT

%type <string> constant opt_constant
%type <string> array opt_array
%type <number> arguments opt_arguments

/* Precedence and associativity - lowest to highest precedence */
%right ASSIGN                            /* Assignment operators (right associative) */
%right QUESTION COLON                    /* Conditional expression (right associative) */
%left  PIPE                              /* OR operator */
%left  AMPERSAND                         /* AND operator */
%left  EQ NE                             /* Equality operators */
%left  LT LTE GT GTE                     /* Relational operators */
%left  LSHIFT RSHIFT                     /* Shift operators */
%left  PLUS MINUS                        /* Additive operators */
%left  ASTERISK DIV MOD                  /* Multiplicative operators */
%right UMINUS UBANG UASTERISK UAMPERSAND /* Unary operators (right associative) */
%right INCREMENT DECREMENT               /* Increment/decrement operators */
%left  LBRACKET RBRACKET LPAREN RPAREN   /* Array subscript and function call */

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
  /* Empty */
| definitions definition
;

definition:
  ID opt_array opt_values SEMICOLON {
    free($1);
  }
| ID LPAREN {
    symbol_add($1, EXTERNAL);
    scope_create();
    printf(".text\n");
    printf(".globl %s\n", $1);
    printf("%s:\n", $1);
    printf("  .long \"%s\" + 4\n", $1);
    printf("  push ebp\n");
    printf("  mov ebp, esp\n");
    free($1);
  } opt_parameters RPAREN statement {
    printf(".LF%zu:\n", label_fn++);
    printf("  mov esp, ebp\n");
    printf("  pop ebp\n");
    printf("  ret\n");
    scope_destroy();
  }
;

array:
  LBRACKET opt_constant RBRACKET { $$ = $2; }
;

opt_array:
  /* Empty */ { $$ = NULL; }
| array       { $$ = $1; }
;

parameters:
  ID {
    symbol_add($1, INTERNAL);
    free($1);
  }
| ID COMMA parameters {
    symbol_add($1, INTERNAL);
    free($1);
  }
;

opt_parameters:
  /* Empty */
| parameters
;

constant:
  NUMBER { $$ = $1; }
| CHAR   {
    char *s = $1;
    int c;
    if (s[1] == '\\') {
        switch(s[2]) {
            case '0':  c = 0; break;
            case 't':  c = 9; break;
            case 'n':  c = 10; break;
            case 'e':  c = 27; break;
            case '"':  c = 34; break;
            case '\'': c = 39; break;
            case '(':  c = 40; break;
            case ')':  c = 41; break;
            case '*':  c = 42; break;
            default:   c = s[2]; break;
        }
    } else {
        c = s[1];
    }
    char *buf = malloc(32);
    if (buf == NULL) {
      exit(1);
    }

    sprintf(buf, "%d", c);
    free($1);
    $$ = buf;
  }
| STRING {
    char *s = $1;

    printf(".section .rodata\n");
    printf(".LC%zu:\n", label_const);

    int c;
    for (int i = 1; i < (int)strlen(s) - 1; i++) {
      c = (int)s[i];
      if (c == '\\') {
        c = (int)s[++i];
        switch(c) {
          case '0':  c = 0; break;
          case 't':  c = 9; break;
          case 'n':  c = 10; break;
          case 'e':  c = 27; break;
          case '"':  c = 34; break;
          case '\'': c = 39; break;
          case '(':  c = 40; break;
          case ')':  c = 41; break;
          case '*':  c = 42; break;
          default:   break;
        }
      }
      printf("  .long %d\n", c);
    }
    printf("  .long 0\n");
    printf(".text\n");

    char* buf = (char *)malloc(32);
    if (buf == NULL) {
      exit(1);
    }

    sprintf(buf, "OFFSET .LC%zu", label_const++);
    $$ = buf;
    free($1);
  }
;

opt_constant:
  /* Empty */ { $$ = NULL; }
| constant    { $$ = $1; }
;

value:
  constant  { free($1); }
| ID        { free($1); }
;

values:
  value
| values COMMA value
;

opt_values:
  /* Empty */
| values
;

statement:
  /* Empty */
| AUTO auto SEMICOLON statement
| EXTRN extrn SEMICOLON statement
| LBRACE {
    scope_create();
  } statements RBRACE {
    scope_destroy();
  }
| IF LPAREN rvalue {
    printf("  test eax, eax\n");
    printf("  jz .LIE%zu\n", ++label_if);
  } RPAREN statement {
    printf("  jmp .LIE%zu\n", ++label_if);
    printf(".LIE%zu:\n", --label_if);
  } else {
    printf(".LIE%zu:\n", ++label_if);
  }
| WHILE {
    printf(".LW%zu:\n", ++label_while);
  } LPAREN rvalue RPAREN {
    printf("  test eax, eax\n");
    printf("  jz .LW%zu\n", ++label_while);
  } statement {
    printf("  jmp .LW%zu\n", --label_while);
    printf(".LW%zu:\n", ++label_while);
  }
| SWITCH rvalue {
    printf("  push ebx\n");
    printf("  mov ebx, eax\n");
  } statement {
    printf("  pop ebx\n");
  }
| CASE constant COLON {
    printf("  cmp ebx, eax\n");
    printf("  jnz .LS%zu\n", label_switch);
    free($2);
  } statement {
    printf(".LS%zu:\n", label_switch++);
  }
| ID COLON {
    symbol_add($1, LABEL);
    printf(".%s:\n", $1);
    printf("  .long .L%s + 4\n", $1);
    free($1);
  } statement
| GOTO rvalue SEMICOLON {
    printf("  jmp [eax]\n");
  }
| RETURN return SEMICOLON {
    printf("  jmp .LF%zu\n", label_fn);
  }
| opt_rvalue SEMICOLON
;

return:
  /* Empty */
| LPAREN rvalue RPAREN
;

statements:
  /* Empty */
| statements statement
;

auto:
  auto_def
| auto COMMA auto_def
;

auto_def:
  ID {
    symbol_add($1, AUTOMATIC);
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
  ID                         {
    symbol_add($1, EXTERNAL);
    printf(".extern %s\n", $1);
    free($1);
  }
| extrn COMMA ID {
    symbol_add($3, EXTERNAL);
    printf(".extern %s\n", $3);
    free($3);
  }
;

else:
  /* Empty */
| ELSE statement
;

lvalue:
  ID {
    Symbol *symbol = symbol_find_global($1);
    if (symbol == NULL) {
      fprintf(stderr, "Error: %d:%d: Undefined variable %s\n", @1.first_line, @1.first_column, $1);
      free($1);
      YYERROR;
    }

    switch (symbol->storage) {
      case AUTOMATIC:
        printf("  lea eax, [ebp - %zu]\n", symbol->offset);
        break ;
      case INTERNAL:
        printf("  lea eax, [ebp + %zu]\n", symbol->offset);
        break ;
      case EXTERNAL:
        printf("  lea eax, %s\n", symbol->name);
        pointer = 1;
        break ;
      case LABEL:
        printf("  lea eax, [.L%s]\n", symbol->name);
        pointer = 1;
        break ;
      default:
        break;
    }
    free($1);
  }
| ASTERISK rvalue %prec UASTERISK
| rvalue LBRACKET {
    printf("  push eax\n");
  } rvalue RBRACKET {
    printf("  mov ecx, eax\n");
    printf("  shl ecx, 2\n");
    printf("  pop eax\n");
    printf("  add eax, ecx\n");
  }
;

rvalue:
  LPAREN rvalue RPAREN
| lvalue {
    if (pointer == 0) {
      printf("  mov eax, DWORD PTR [eax]\n");
    }

    pointer = 0;
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
| lvalue ASSIGN PIPE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  or [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN AMPERSAND {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  and [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue EQ ASSIGN {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  sete al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN NE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setne al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN LT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setl al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN LTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setle al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN GT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setg al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN GTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setge al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN LSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  mov cl, dl\n");
    printf("  shl eax, cl\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN RSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  mov cl, dl\n");
    printf("  shr eax, cl\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN PLUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  add [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN MINUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  sub [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN MOD {
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
| lvalue ASSIGN ASTERISK {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  imul eax, edx\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN DIV {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  cdq\n");
    printf("  idiv edx\n");
    printf("  mov [ecx], eax\n");
  }
| MINUS rvalue %prec UMINUS {
    printf("  neg eax\n");
  }
| BANG rvalue %prec UBANG {
    printf("  test eax, eax\n");
    printf("  setz al\n");
    printf("  movzx eax, al\n");
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
| AMPERSAND lvalue %prec UAMPERSAND
| rvalue PIPE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  or eax, ecx\n");
  }
| rvalue AMPERSAND {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  and eax, ecx\n");
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
| rvalue PLUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  add eax, ecx\n");
  }
| rvalue MINUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  sub ecx, eax\n");
    printf("  mov eax, ecx\n");
  }
| rvalue ASTERISK {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  imul eax, ecx\n");
  }
| rvalue DIV {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  cdq\n");
    printf("  idiv ecx\n");
  }
| rvalue MOD {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  cdq\n");
    printf("  idiv ecx\n");
    printf("  mov eax, edx\n");
  }
| rvalue QUESTION {
    printf("  test eax, eax\n");
    printf("  jz .LT%zu\n", ++label_tern);
  } rvalue {
    printf("  jmp .LT%zu\n", ++label_tern);
    printf(".LT%zu:\n", --label_tern);
  } COLON rvalue {
    printf(".LT%zu:\n", ++label_tern);
  }
| rvalue LPAREN {
    printf("  mov ebx, eax\n");
  } opt_arguments RPAREN {
    printf("  mov eax, ebx\n");
    printf("  call eax\n");
    if ($4 > 0) {
      printf("  add esp, %d\n", $4 * 4);
    }
  }
;

opt_rvalue:
  /* Empty */
| rvalue
;

arguments:
  rvalue      {
    printf("  push eax\n");
    $$ = 1;
  }
| arguments COMMA rvalue {
    printf("  push eax\n");
    $$ = $1 + 1;
  }
;

opt_arguments:
  /* Empty */ { $$ = 0; }
| arguments   { $$ = $1; }
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
