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
"="         { return ASSIGN; }

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
"|"         { return PIPE; }
">>"        { return RSHIFT; }
"<<"        { return LSHIFT; }
"++"        { return INCREMENT; }
"--"        { return DECREMENT; }

{NUMBER}    {
    yylval.string = strdup(yytext);
    return NUMBER;
}
{ID}        { 
    yylval.string = strdup(yytext);
    return ID;
}

'[^'\\]'        {
    char *result = malloc(16);
    sprintf(result, "%d", (int)yytext[1]);
    yylval.string = result;
    return CHAR;
}

'\\[0ent()'"*]' {
    char *result = malloc(16);
    int char_val;
    switch(yytext[2]) {
        case '0': char_val = 0; break;
        case 'e': char_val = 27; break;
        case 'n': char_val = 10; break;
        case 't': char_val = 9; break;
        case '(': char_val = 40; break;
        case ')': char_val = 41; break;
        case '\'': char_val = 39; break;
        case '"': char_val = 34; break;
        case '*': char_val = 42; break;
        default: char_val = yytext[2]; break;
    }
    sprintf(result, "%d", char_val);
    yylval.string = result;
    return CHAR;
}

\"[^\"]*\"  {
    yylval.string = strdup(yytext);
    return STRING;
}

[ \t]+      { /* ignore whitespace */ }
\n          { yycolumn = 0; }
.           { return *yytext; }
