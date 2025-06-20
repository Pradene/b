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
%type <string> inc_dec
%type <number> opt_lst_rvalue
%type <number> lst_rvalue

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
| ID LPAREN parameters RPAREN {
    symbol_add($1, EXTERNAL);
    printf(".text\n");
    printf(".globl %s\n", $1);
    printf("%s:\n", $1);
    printf("  .long \"%s\" + 4\n", $1);
    printf("  push ebp\n");
    printf("  mov ebp, esp\n");
    free($1);
  } statement {
    printf("  mov esp, ebp\n");
    printf("  pop ebp\n");
    printf("  ret\n");
  }
;

parameters:
  /* Empty */
| ID                  {
    symbol_add($1, INTERNAL);
    free($1);
  }
| parameters COMMA ID {
    symbol_add($3, INTERNAL);
    free($3);
  }
;

constant:
  NUMBER { $$ = $1; }
| CHAR   { $$ = $1; }
| STRING {
  printf(".section .rodata\n");
  printf(".L%zu:\n", label_id);
  printf("  .long .L%zu + 4\n", label_id);
  printf("  .string %s\n", $1);
  printf(".text\n");

  char* label = malloc(16);
  sprintf(label, ".L%zu", label_id++);
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
| LBRACE {
    scope_create();
  } statements RBRACE {
    scope_destroy();
  }
| IF LPAREN rvalue {
    printf("  test eax, eax\n");
    printf("  jz .L%zu\n", label_id);
  } RPAREN statement {
    printf("  jmp .L%zu\n", ++label_id);
    printf(".L%zu:\n", label_id - 1);
  } else {
    printf(".L%zu:\n", label_id++);
  }
| WHILE {
    printf(".L%zu:\n", label_id);
    printf("  .long .L%zu + 4\n", label_id++);
  } LPAREN rvalue RPAREN {
    printf("  test eax, eax\n");
    printf("  jz .L%zu\n", label_id);
  } statement {
    printf("  jmp .L%zu\n", label_id - 1);
    printf(".L%zu:\n", label_id++);
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
    printf("  mov WORD PTR [ebp - %zu], 0\n", current_scope->local_offset);
    free($1);
  }
| auto_identifiers COMMA ID {
    symbol_add($3, AUTOMATIC);
    printf("  sub esp, 4\n");
    printf("  mov WORD PTR [ebp - %zu], 0\n", current_scope->local_offset);
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


inc_dec:
  INCREMENT { $$ = strdup("add"); }
| DECREMENT { $$ = strdup("sub"); }
;

unary:
  MINUS
| BANG
;

binary:
  PIPE
| AMPERSAND
| EQ
| NE
| LT
| LTE
| GT
| GTE
| LSHIFT
| RSHIFT
| MINUS
| PLUS
| MOD
| ASTERISK
| DIV
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
      printf("  lea eax, \"%s\"\n", symbol->name);
    }
    free($1);
  }
| ASTERISK rvalue
| rvalue {
    printf("  push eax\n");      // Save base address
  } LBRACKET rvalue RBRACKET {
    printf("  imul eax, 4\n");   // Multiply by element size (4 bytes for int)
    printf("  pop ecx\n");       // Retrieve base address
    printf("  add eax, ecx\n");  // eax = base + index*4
  }
;

rvalue:
  LPAREN rvalue RPAREN
| lvalue { printf("  mov eax, [eax]\n"); }
| constant             { printf("  mov eax, %s\n", $1); free($1); }
| lvalue ASSIGN {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  mov [ecx], eax\n");
  }
| unary rvalue         {}
| inc_dec lvalue {
    printf("  %s DWORD PTR [eax], 1\n", $1);
    printf("  mov eax, DWORD PTR [eax]\n");
    free($1);
  }
| lvalue inc_dec {
    printf("  mov ecx, DWORD PTR [eax]\n");
    printf("  %s DWORD PTR [eax], 1\n", $2);
    printf("  mov eax, ecx\n");
    free($2);
  }
| AMPERSAND lvalue     { printf("  lea eax, []\n"); }
| rvalue {
    printf("  push eax\n");
  } binary rvalue {
    printf("  pop ecx\n");
  }
| rvalue QUESTION {
    printf("  test eax, eax\n");
    printf("  jz .L%zu\n", label_id);
  } rvalue {
    printf("  jmp .L%zu\n", label_id + 1);
  } COLON {
    printf(".L%zu\n", label_id++);
  } rvalue {
    printf(".L%zu\n", label_id++);
  }
| rvalue LPAREN opt_lst_rvalue RPAREN {
    printf("  pop eax\n");
    printf("  call eax\n");
    if ($3 > 0) {
      printf("  add esp, %d\n", $3 * 4);
    }
  }
;

/* Optional */

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
