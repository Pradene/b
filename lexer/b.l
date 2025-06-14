NUMBER      [0-9]+(\.[0-9]+)?
NAME        [a-zA-Z][a-zA-Z0-9]*

%option noyywrap

%%

extrn       { printf("EXTRN\n"); }
auto        { printf("AUTO\n"); }
return      { printf("RETURN\n"); }
if          { printf("IF\n"); }
else        { printf("ELSE\n"); }
goto        { printf("GOTO\n"); }
while       { printf("WHILE\n"); }
break       { printf("BREAK\n"); }

";"         { printf(";\n"); }
"("         { printf("(\n"); }
")"         { printf(")\n"); }
"["         { printf("[\n"); }
"]"         { printf("]\n"); }
"{"         { printf("{\n"); }
"}"         { printf("}\n"); }
","         { printf(",\n"); }
"!"         { printf("!\n"); }
"?"         { printf("?\n"); }
":"         { printf(":\n"); }

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

{NUMBER}    { printf("NUMBER: %s\n", yytext); }
{NAME}      { printf("NAME: %s\n", yytext); }
'[^']*'     { printf("CHAR: %s\n", yytext); }
\"[^\"]*\"  { printf("STRING: %s\n", yytext); }

[ \t\n]+    { /* ignore whitespace */ }
.           { printf("UNKNOWN: %c\n", *yytext); }
