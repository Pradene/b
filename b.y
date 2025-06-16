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
%token ASSIGNMENT
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
    printf("push ebp\n");
    printf("mov ebp, esp\n");
    stack_offset = 0;
    free($1);
  } LBRACE {
    scope_create();
  } statement RBRACE {
    printf("mov esp, ebp\n");
    printf("pop ebp\n");
    printf("ret\n");
    scope_destroy();
  }
;

parameters:
  /* Empty */ { $$ = 0; }
| ID { $$ = 1; free($1); }
| parameters COMMA ID { $$ = $1 + 1; free($3); }
;

value:
  constant
| ID
;

statement:
  /* Empty */
| AUTO auto_identifiers SEMICOLON statement
| EXTRN extrn_identifiers SEMICOLON statement
| ID COLON statement
| CASE constant COLON statement
| LBRACE {
    scope_create();
  } statement RBRACE {
    scope_destroy();
  }
| IF LPAREN rvalue RPAREN statement opt_else
| WHILE {
    printf(".L%zu:\n", label_id++);
  } LPAREN rvalue RPAREN {
    printf("test eax, eax\n");
    printf("jz .L%zu\n", label_id);
  } statement {
    printf("jmp .L%zu\n", label_id - 1);
    printf(".L%zu:\n", label_id++);
  }
| SWITCH rvalue statement
| GOTO rvalue SEMICOLON
| opt_rvalue SEMICOLON
;

auto_identifiers:
  ID {
    stack_offset += 4;
    printf("sub esp, 4\n");
    printf("mov word ptr [ebp-%zu], 0\n", stack_offset);
    free($1); 
  }
| auto_identifiers COMMA ID {
    stack_offset += 4;
    printf("sub esp, 4\n");
    printf("mov word ptr [ebp-%zu], 0\n", stack_offset);
    free($3);
  }
| ID COLON statement
| CASE constant COLON statement
| LBRACKET  RBRACKET
;

extrn_identifiers:
  ID { free($1); }
| extrn_identifiers COMMA ID { free($3); }
;

constant:
  NUMBER
| CHAR
| STRING
;

assigment:
  ASSIGNMENT opt_binary
;

inc_dec:
  INCREMENT
| DECREMENT
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
  ID { printf("mov eax, [%s]\n", $1); }
| ASTERISK rvalue { printf("mov eax, [eax]\n"); free($2); }
| rvalue LBRACKET rvalue RBRACKET
;

rvalue:
  LPAREN rvalue RPAREN { $$ = $2; }
| lvalue { $$ = $1; }
| constant { printf("mov eax, %s\n", $1); }
| AMPERSAND lvalue { printf("lea eax, []\n"); }
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

opt_else:
  /* Empty */
| ELSE statement
;

opt_rvalue:
  /* Empty */
| rvalue
;

%%

void yyerror(const char *s) {
  (void)s;
  fprintf(stderr, "Error: %d:%d: Unexpected token '%s'\n", yylineno, yycolumn, yytext);
}

int main(void) {
  return yyparse();
}
