%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

extern int yylineno;
extern int yycolumn;
extern char *yytext;

int stack_offset = 0;

%}

%union {
  char *string;
  int   number;
}

%token <string> ID
%token <number> NUMBER
%token <string> STRING CHAR
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

%%

program:
  /* Empty */ {
    printf(".intel_syntax noprefix\n");
    printf(".text\n");
  }
| program definition
;

definition:
  ID LBRACKET constant_optional RBRACKET value_list_optional SEMICOLON
| ID LPAREN parameters RPAREN {
    printf(".text\n");
    printf("global %s\n", $1);
    printf("%s:\n", $1);
    printf("push rbp\n");
    printf("mov rbp, rsp\n");
    stack_offset = 0;
    free($1);
  } LBRACE statement RBRACE {
    printf("mov rsp, rbp\n");
    printf("pop rbp\n");
    printf("ret\n");
  }
;

parameters:
  /* Empty */ { $$ = 0; }
| ID { $$ = 1; free($1); }
| parameters COMMA ID { $$ = $1 + 1; free($3); }
;

statement:
  /* Empty */
| AUTO auto_identifiers SEMICOLON statement
| EXTRN extrn_identifiers SEMICOLON statement
;

auto_identifiers:
  ID {
    stack_offset += 8;
    printf("sub rsp, 8\n");
    printf("mov qword ptr [rbp-%d], 0\n", stack_offset);
    free($1); 
  }
| auto_identifiers COMMA ID {
    stack_offset += 8;
    printf("sub rsp, 8\n");
    printf("mov qword ptr [rbp-%d], 0\n", stack_offset);
    free($3);
  }
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

constant_optional:
  /* Empty */
| constant
;

value:
  constant
| ID
;

value_list:
  value
| value_list COMMA value
;

value_list_optional:
  /* Empty */
| value_list
;

lvalue:
  ID
| ASTERISK rvalue
| rvalue LBRACKET rvalue RBRACKET
;

rvalue:
  LPAREN rvalue RPAREN
| lvalue
| constant
| ASTERISK lvalue
;

%%

void yyerror(const char *s) {
  fprintf(stderr, "Error: %d:%d: %s (token: %s)\n", yylineno, yycolumn, s, yytext);
}

int main(void) {
  return yyparse();
}
