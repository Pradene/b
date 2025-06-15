%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);

extern int yylineno;
extern int yycolumn;
extern char *yytext;
%}

%token AUTO EXTRN RETURN
%token ID NUMBER CHAR STRING
%token SEMICOLON LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE COMMA
%token BANG QUESTION COLON ASSIGNMENT OPERATOR
%token SWITCH CASE IF ELSE WHILE BREAK GOTO

%%

program:
  /* empty */
| program statement
;

statement:
  AUTO identifier_def SEMICOLON
| EXTRN identifier_def SEMICOLON
;

identifier_def:
  identifier
| identifier_def COMMA identifier
;

identifier:
  ID { printf("ID\n"); }
;

%%

void yyerror(const char *s) {
  fprintf(stderr, "Error: %d:%d: %s\n", yylineno, yycolumn, s);
}

int main(void) {
  return yyparse();
}