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

size_t label_id = 0;
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
%token RSHIFT
%token LSHIFT
%token INCREMENT
%token DECREMENT

%type <string> constant
%type <number> opt_lst_rvalue
%type <number> lst_rvalue

/* Precedence and associativity - lowest to highest precedence */
%right ASSIGN                          /* Assignment operators (right associative) */
%right QUESTION COLON                  /* Conditional expression (right associative) */
%left PIPE                             /* OR operator */
%left AMPERSAND                        /* AND operator */
%left EQ NE                            /* Equality operators */
%left LT LTE GT GTE                    /* Relational operators */
%left LSHIFT RSHIFT                    /* Shift operators */
%left PLUS MINUS                       /* Additive operators */
%left ASTERISK DIV MOD                 /* Multiplicative operators */
%right UMINUS UBANG UASTERISK UAMPERSAND /* Unary operators (right associative) */
%right INCREMENT DECREMENT             /* Increment/decrement operators */
%left LBRACKET RBRACKET LPAREN RPAREN  /* Array subscript and function call */

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
  ID opt_array opt_value_list SEMICOLON {
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
    printf("  mov esp, ebp\n");
    printf("  pop ebp\n");
    printf("  ret\n");
    scope_destroy();
  }
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
| CHAR   { $$ = $1; }

| STRING {
    printf(".section .rodata\n");
    printf(".L%zu:\n", ++label_id);
    char *str = $1;
    for (int i = 1; i <= (int)strlen(str) - 1; i++) {
      printf("  .long %d\n", (int)str[i]);
    }
    printf("  .long 0\n");

    printf(".text\n");
    char* label = malloc(32);
    sprintf(label, "OFFSET .L%zu", label_id);
    $$ = label;
    free($1);
  }
;

value:
  constant  { free($1); }
| ID        { free($1); }
;

statement:
  /* Empty */
| AUTO auto_identifiers SEMICOLON statement
| EXTRN extrn_identifiers SEMICOLON statement
| ID COLON statement {
    free($1);
  }
| CASE constant COLON statement {
    free($2);
  }
| LBRACE statements RBRACE
| IF LPAREN rvalue {
    printf("  test eax, eax\n");
    printf("  jz .L%zu\n", ++label_id);
  } RPAREN statement {
    printf("  jmp .L%zu\n", ++label_id);
    printf(".L%zu:\n", --label_id);
  } else {
    printf(".L%zu:\n", ++label_id);
  }
| WHILE {
    printf(".L%zu:\n", ++label_id);
  } LPAREN rvalue RPAREN {
    printf("  test eax, eax\n");
    printf("  jz .L%zu\n", ++label_id);
  } statement {
    printf("  jmp .L%zu\n", --label_id);
    printf(".L%zu:\n", ++label_id);
  }
| SWITCH rvalue statement {

  }
| GOTO rvalue SEMICOLON {

  }
| RETURN opt_paren_rvalue SEMICOLON
| opt_rvalue SEMICOLON
;

statements:
  /* Empty */
| statements statement
;

auto_identifiers:
  ID {
    symbol_add($1, AUTOMATIC);
    printf("  sub esp, 4\n");
    printf("  mov DWORD PTR [ebp - %zu], 0\n", current_scope->local_offset);
    free($1);
  }
| auto_identifiers COMMA ID {
    symbol_add($3, AUTOMATIC);
    printf("  sub esp, 4\n");
    printf("  mov DWORD PTR [ebp - %zu], 0\n", current_scope->local_offset);
    free($3);
  }
;

extrn_identifiers:
  ID                         {
    symbol_add($1, EXTERNAL);
    free($1);
  }
| extrn_identifiers COMMA ID {
    symbol_add($3, EXTERNAL);
    free($3);
  }
;

else:
  /* Empty */
| ELSE statement
;

value_list:
  value
| value_list COMMA value
;

lvalue:
  ID {
    Symbol *symbol = symbol_find_global($1);
    if (symbol == NULL) {
      fprintf(stderr, "Error: %d:%d: Undefined variable %s\n", @1.first_line, @1.first_column, $1);
      free($1);
      YYERROR;
    }

    if (symbol->storage == AUTOMATIC) {
      printf("  lea eax, [ebp - %zu]\n", symbol->offset);
    } else if (symbol->storage == INTERNAL) {
      printf("  lea eax, [ebp + %zu]\n", symbol->offset);
    } else {
      printf("  lea eax, %s\n", symbol->name);
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
  LPAREN rvalue RPAREN { }
| lvalue {
    printf("  mov eax, DWORD PTR [eax]\n");
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
    printf("  pop ecx\n");
    printf("  mov cl, al\n");
    printf("  mov eax, ecx\n");
    printf("  shl eax, cl\n");
  }
| rvalue RSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  mov cl, al\n");
    printf("  mov eax, ecx\n");
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
| rvalue QUESTION rvalue COLON rvalue {
    printf("  pop ecx\n");
    printf("  test ecx, ecx\n");
    printf("  jz .L%zu\n", ++label_id);
    printf("  pop eax\n");
    printf("  jmp .L%zu\n", ++label_id);
    printf(".L%zu:\n", --label_id);
    printf("  pop ebx\n");
    printf("  mov eax, ebx\n");
    printf(".L%zu:\n", ++label_id);
  }
| ID LPAREN opt_lst_rvalue RPAREN {
    printf("  call %s\n", $1);
    if ($3 > 0) {
      printf("  add esp, %d\n", $3 * 4);
    }
    free($1);
  }
| rvalue {
    printf("  mov ebx, eax\n");
  } LPAREN opt_lst_rvalue RPAREN {
    printf("  mov eax, ebx\n");
    printf("  call eax\n");
    if ($4 > 0) {
      printf("  add esp, %d\n", $4 * 4);
    }
  }
;

opt_array:
  /* Empty */
| LBRACKET opt_constant RBRACKET
;

opt_value_list:
  /* Empty */
| value_list
;

opt_constant:
  /* Empty */
| constant { free($1); }
;

opt_paren_rvalue:
  /* Empty */
| LPAREN rvalue RPAREN
;

opt_lst_rvalue:
  /* Empty */ { $$ = 0; }
| lst_rvalue  { $$ = $1; }
;

lst_rvalue:
  rvalue      {
    printf("  push eax\n");
    $$ = 1;
  }
| lst_rvalue COMMA rvalue {
    printf("  push eax\n");
    $$ = $1 + 1;
  }
;

opt_rvalue:
  /* Empty */
| rvalue
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
