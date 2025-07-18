%{
#include "y.tab.h"

int yycolumn = 0;

#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno; \
                       yylloc.first_column = yycolumn; \
                       yylloc.last_column = yycolumn + yyleng - 1; \
                       yycolumn += yyleng;
%}

DECIMAL     0|[1-9][0-9]*
OCTAL       0[0-7]+
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
goto        { return GOTO; }
";"         { return ';'; }
"("         { return '('; }
")"         { return ')'; }
"["         { return '['; }
"]"         { return ']'; }
"{"         { return '{'; }
"}"         { return '}'; }
","         { return ','; }
"!"         { return '!'; }
"?"         { return '?'; }
":"         { return ':'; }

"&"         { return '&'; }
"*"         { return '*'; }
"/"         { return '/'; }
"+"         { return '+'; }
"-"         { return '-'; }
"%"         { return '%'; }
"|"         { return '|'; }
">>"        { return RSHIFT; }
"<<"        { return LSHIFT; }
"++"        { return INCREMENT; }
"--"        { return DECREMENT; }

">="        { return GTE; }
">"         { return GT; }
"<="        { return LTE; }
"<"         { return LT; }
"=="        { return EQ; }
"!="        { return NE; }

"="         { return ASSIGN; }
"=|"        { return ASSIGN_OR; }
"=&"        { return ASSIGN_AND; }
"=+"        { return ASSIGN_PLUS; }
"=-"        { return ASSIGN_MINUS; }
"=*"        { return ASSIGN_MUL; }
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

[-+]?{DECIMAL}   {
  yylval.string = strdup(yytext);
  return NUMBER;
}

{OCTAL}     {
  yylval.string = strdup(yytext);
  return NUMBER;
}

{ID}        { 
  yylval.string = strdup(yytext);
  return ID;
}

"/*"        { BEGIN(COMMENT); }
<COMMENT>{
  "*/"      { BEGIN(INITIAL); }
  .|\n      {}
  <<EOF>>   { fprintf(stderr, "Unterminated comment\n"); exit(1); }
}

'[^'\\]'    {
  yylval.string = strdup(yytext);
  return CHAR;
}

'\\[0abtnvfre\'\"\\?]' {
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
