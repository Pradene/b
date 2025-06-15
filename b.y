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
  ID LPAREN parameters RPAREN {
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
| statement AUTO auto_identifiers SEMICOLON
| statement EXTRN extrn_identifiers SEMICOLON
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

%%

void yyerror(const char *s) {
  fprintf(stderr, "Error: %d:%d: %s (token: %s)\n", yylineno, yycolumn, s, yytext);
}

int main(void) {
  return yyparse();
}