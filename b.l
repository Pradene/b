%{
#include "y.tab.h"

int yycolumn = 0;

#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno; \
                       yylloc.first_column = yycolumn; \
                       yylloc.last_column = yycolumn + yyleng - 1; \
                       yycolumn += yyleng;
%}

NUMBER      [0-9]+(\.[0-9]+)?
ID          [a-zA-Z_][a-zA-Z0-9_]*

%option noyywrap
%option noinput
%option nounput
%option yylineno

%x COMMENT

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

"&"         { return AMPERSAND; }
"*"         { return ASTERISK; }
">="        { return GTE; }
">"         { return GT; }
"<="        { return LTE; }
"<"         { return LT; }
"=="        { return EQ; }
"!="        { return NE; }
"/"         { return DIV; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"%"         { return MOD; }
"|"         { return OR; }
">>"        { return RSHIFT; }
"<<"        { return LSHIFT; }
"++"        { return INCREMENT; }
"--"        { return DECREMENT; }

"="         { return ASSIGN; }
"=|"        { return ASSIGN_OR; }
"=&"        { return ASSIGN_AMPERSAND; }
"=+"        { return ASSIGN_PLUS; }
"=-"        { return ASSIGN_MINUS; }
"=*"        { return ASSIGN_ASTERISK; }
"=/"        { return ASSIGN_DIV; }
"=%"        { return ASSIGN_MOD; }
"==="       { return ASSIGN_EQ; }
"=!="       { return ASSIGN_NE; }
"=<"        { return ASSIGN_LT; }
"=<="       { return ASSIGN_LTE; }
"=>"        { return ASSIGN_GT; }
"=>="       { return ASSIGN_GTE; }
"=<<"       { return ASSIGN_LSHIFT; }
"=>>"       { return ASSIGN_RSHIFT; }

{NUMBER}    {
    yylval.string = strdup(yytext);
    return NUMBER;
}
{ID}        { 
    yylval.string = strdup(yytext);
    return ID;
}

"/*"               { BEGIN(COMMENT); }
<COMMENT>{
  "*/"             { BEGIN(INITIAL); }
  .|\n             {}
  <<EOF>>          { fprintf(stderr, "Unterminated comment\n"); exit(1); }
}

'[^'\\]'           {
    yylval.string = strdup(yytext);
    return CHAR;
}

'\\[0ent()\'\"*]' {
    yylval.string = strdup(yytext);
    return CHAR;
}

\"[^\"]*\"  {
    yylval.string = strdup(yytext);
    return STRING;
}

[ \t]+      { /* ignore whitespace */ }
\n          { yycolumn = 0; }
.           { return *yytext; }
