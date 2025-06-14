NUMBER      [0-9]+(\.[0-9]+)?
NAME        [a-zA-Z][a-zA-Z0-9]*
%%
extrn       { printf("EXTRN\n"); }
auto        { printf("AUTO\n"); }
return      { printf("RETURN\n"); }
if          { printf("IF\n"); }
else        { printf("ELSE\n"); }
goto        { printf("GOTO\n"); }
while       { printf("WHILE\n"); }
break       { printf("BREAK\n"); }
";"         { printf("SEMICOLON\n"); }
"("         { printf("LPAREN\n"); }
")"         { printf("RPAREN\n"); }
"["         { printf("LBRACKET\n"); }
"]"         { printf("RBRACKET\n"); }
"{"         { printf("LBRACE\n"); }
"}"         { printf("RBRACE\n"); }
","         { printf("COMMA\n"); }

"="         { printf("ASSIGNMENT\n"); }

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
"--"        { printf("OPERATOR: %s\n", yytext); }

"!"         { printf("NOT\n"); }

"?"         { printf("QUESTION\n"); }
":"         { printf("COLON\n"); }

{NUMBER}    { printf("NUMBER: %s\n", yytext); }
{NAME}      { printf("NAME: %s\n", yytext); }
'[^']*'     { printf("CHAR: %s\n", yytext); }
\"[^\"]*\"  { printf("STRING: %s\n", yytext); }

[ \t\n]+    { /* ignore whitespace */ }
.           { printf("UNKNOWN: %c\n", *yytext); }
