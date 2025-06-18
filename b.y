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

size_t stack_offset = 0;
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
    printf(".text\n");
    printf(".globl %s\n", $1);
    printf("%s:\n", $1);
    printf("  .long %s + 4\n", $1);
    printf("  push ebp\n");
    printf("  mov ebp, esp\n");
    stack_offset = 0;
    free($1);
  } statement {
    printf("  mov esp, ebp\n");
    printf("  pop ebp\n");
    printf("  ret\n");
  }
;

parameters:
  /* Empty */
| ID                  { free($1); }
| parameters COMMA ID { free($3); }
;

constant:
  NUMBER { $$ = $1; }
| CHAR   { $$ = $1; }
| STRING { $$ = $1; }
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
| IF LPAREN rvalue RPAREN statement else
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
| SWITCH rvalue statement
| GOTO rvalue SEMICOLON
| RETURN opt_rvalue SEMICOLON
| opt_rvalue SEMICOLON
;

statements:
  /* Empty */
| statements statement
;

auto_identifiers:
  ID {
    stack_offset += 4;
    printf("  sub esp, 4\n");
    printf("  mov WORD PTR [ebp - %zu], 0\n", stack_offset);
    symbol_add($1, stack_offset, yylineno, yycolumn);
    free($1);
  }
| auto_identifiers COMMA ID {
    stack_offset += 4;
    printf("  sub esp, 4\n");
    printf("  mov WORD PTR [ebp - %zu], 0\n", stack_offset);
    free($3);
  }
| ID COLON statement {
    free($1);
  }
| CASE constant COLON statement {
    free($2);
  }
;

extrn_identifiers:
  ID                         { free($1); }
| extrn_identifiers COMMA ID { free($3); }
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
    printf("  lea eax, [ebp - 4]\n");
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
| lvalue
| constant             { printf("  mov eax, %s\n", $1); free($1); }
| lvalue ASSIGN {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  mov [ecx], eax\n");
  }
| inc_dec lvalue       { printf("\n"); free($1); }
| lvalue inc_dec       { printf("  %s eax, 1\n", $2); free($2); }
| unary rvalue         {  }
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
| rvalue LPAREN opt_rvalue RPAREN {
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

opt_rvalue:
  /* Empty */
| rvalue
;

%%

void yyerror(const char *s) {
  fprintf(stderr, "Error: %d:%d: %s\n", yylineno, yycolumn, s);
}

int main(void) {
  int result = yyparse();
  yylex_destroy();
  return result;
}
