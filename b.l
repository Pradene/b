%{
#include "y.tab.h"

int yycolumn = 0;

#define YY_USER_ACTION yycolumn += yyleng;
%}

NUMBER      [0-9]+(\.[0-9]+)?
ID          [a-zA-Z][a-zA-Z0-9]*

%option noyywrap
%option yylineno

%%
extrn       { return EXTRN; }
auto        { return AUTO; }
return      { return RETURN; }
switch      { return SWITCH; }
case        { return CASE; }
if          { return IF; }
else        { return ELSE; }
while       { return WHILE; }
break       { return BREAK; }
goto        { return GOTO; }
";"         { return SEMICOLON; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"["         { return LBRACKET; }
"]"         { return RBRACKET; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
","         { return COMMA; }
"!"         { return BANG; }
"?"         { return QUESTION; }
":"         { return COLON; }
"="         { return ASSIGNMENT; }

">="        |
">"         |
"<="        |
"<"         |
"=="        |
"!="        |
"*"         |
"/"         |
"+"         |
"-"         |
"%"         |
"&"         |
"|"         |
">>"        |
"<<"        |
"++"        |
"--"        { return OPERATOR; }

{NUMBER}    { return NUMBER; }
{ID}        { return ID; }

'[^']*'     { return CHAR; }
\"[^\"]*\"  { return STRING; }

[ \t]+      { /* ignore whitespace */ }
\n          { yycolumn = 0; }
.           { return *yytext; }
