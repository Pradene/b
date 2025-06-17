%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol.h"
#include "y.tab.h"

int yylex(void);
void yyerror(const char *s);

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
%token AUTO
%token EXTRN
%token RETURN
%token SEMICOLON
%token LPAREN RPAREN
%token LBRACKET RBRACKET
%token LBRACE RBRACE
%token COMMA
%token BANG
%token QUESTION
%token COLON
%token ASSIGN
%token OPERATOR
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
%token SWITCH
%token CASE
%token IF
%token ELSE
%token WHILE
%token BREAK
%token GOTO

%type <number> parameters 
%type <string> constant

%type <string> lvalue rvalue
%type <string> inc_dec

%start program

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
  ID opt_array opt_value_list SEMICOLON
| ID LPAREN parameters RPAREN {
    printf(".text\n");
    printf(".globl %s\n", $1);
    printf("%s:\n", $1);
    printf("  .long %s + 4\n", $1);
    printf("  push ebp\n");
    printf("  mov ebp, esp\n");
    stack_offset = 0;
    free($1);
    scope_create();
  } statement {
    printf("  mov esp, ebp\n");
    printf("  pop ebp\n");
    printf("  ret\n");
    scope_destroy();
  }
;

parameters:
  /* Empty */         { $$ = 0; }
| ID                  { $$ = 1; free($1); }
| parameters COMMA ID { $$ = $1 + 1; free($3); }
;

constant:
  NUMBER
| CHAR
| STRING
;


value:
  constant
| ID
;

statement:
  /* Empty */
| AUTO auto_identifiers SEMICOLON statement {
    
  }
| EXTRN extrn_identifiers SEMICOLON statement
| ID COLON statement
| CASE constant COLON statement
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
| ID COLON statement
| CASE constant COLON statement
| LBRACKET  RBRACKET
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
    Symbol *symbol = symbol_find($1);
    if (symbol == NULL) {
      yyerror("Undefined variable");
      YYERROR;
    }
    printf("  lea eax, [ebp - 4]\n");
  }
| ASTERISK rvalue
| rvalue LBRACKET rvalue RBRACKET {
    printf("  push eax\n");      // Save base address
    printf("  imul eax, 4\n");   // Multiply by element size (4 bytes for int)
    printf("  pop ecx\n");       // Retrieve base address
    printf("  add eax, ecx\n");  // eax = base + index*4
  }
;

rvalue:
  LPAREN rvalue RPAREN
| lvalue
| constant             { printf("  mov eax, %s\n", $1); }
| lvalue ASSIGN {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  mov [ecx], eax\n");
  }
| inc_dec lvalue       { printf("\n"); }
| lvalue inc_dec       { printf("  %s eax, 1\n", $2); free($2); }
| unary rvalue
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
| rvalue LPAREN opt_rvalue RPAREN
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
| constant
;

opt_binary:
  /* Empty */
| binary
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
  return yyparse();
}
