%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol.h"
#include "y.tab.h"

int yylex(void);
void yyerror(const char *s);
void yylex_destroy(void);

extern int yylineno;
extern int yycolumn;
extern char *yytext;

static size_t label_fn = 0;
static size_t label_if = 0;
static size_t label_while = 0;
static size_t label_switch = 0;
static size_t label_tern = 0;
static size_t label_const = 0;
static int    pointer = 0;

/* Function to handle escape sequences like C */
int handle_escape_char(char c) {
  switch(c) {
    case '0':  return 0;   /* null character */
    case 'a':  return 7;   /* alert (bell) */
    case 'b':  return 8;   /* backspace */
    case 't':  return 9;   /* horizontal tab */
    case 'n':  return 10;  /* newline */
    case 'v':  return 11;  /* vertical tab */
    case 'f':  return 12;  /* form feed */
    case 'r':  return 13;  /* carriage return */
    case 'e':  return 27;  /* escape (non-standard but kept for compatibility) */
    case '"':  return 34;  /* double quote */
    case '\'': return 39;  /* single quote */
    case '(':  return 40;  /* left parenthesis (non-standard but kept) */
    case ')':  return 41;  /* right parenthesis (non-standard but kept) */
    case '*':  return 42;  /* asterisk (non-standard but kept) */
    case '?':  return 63;  /* question mark */
    case '\\': return 92;  /* backslash */
    default:   return c;   /* return the character as-is for unknown escapes */
  }
}
%}

%union {
  char *string;
  int   number;
}

%type <string> constant opt_constant
%type <string> array opt_array
%type <number> arguments opt_arguments
%type <string> value

%token <string> ID
%token <string> NUMBER
%token <string> STRING
%token <string> CHAR
%token AUTO
%token EXTRN
%token RETURN
%token SWITCH
%token CASE
%token IF
%token ELSE
%token WHILE
%token GOTO
%token SEMICOLON
%token LPAREN RPAREN
%token LBRACKET RBRACKET
%token LBRACE RBRACE
%token COMMA
%token BANG
%token QUESTION
%token COLON
%token ASSIGN ASSIGN_OR ASSIGN_AND ASSIGN_EQ ASSIGN_NE ASSIGN_LT ASSIGN_LTE ASSIGN_GT ASSIGN_GTE ASSIGN_LSHIFT ASSIGN_RSHIFT ASSIGN_PLUS ASSIGN_MINUS ASSIGN_MOD ASSIGN_MUL ASSIGN_DIV
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
%token OR
%token RSHIFT LSHIFT
%token INCREMENT DECREMENT

/* Ordered from LOWEST to HIGHEST precedence */
%nonassoc EMPTY
%nonassoc ID
%nonassoc ELSE
%nonassoc LVALUE
%right    ASSIGN
          ASSIGN_OR
          ASSIGN_AND
          ASSIGN_EQ
          ASSIGN_NE
          ASSIGN_LT
          ASSIGN_LTE
          ASSIGN_GT
          ASSIGN_GTE
          ASSIGN_LSHIFT
          ASSIGN_RSHIFT
          ASSIGN_PLUS
          ASSIGN_MINUS
          ASSIGN_MOD
          ASSIGN_MUL
          ASSIGN_DIV                                            /* Assignment operators */
%right    QUESTION COLON                                        /* Conditional expression */
%left     OR                                                    /* Logical OR */
%left     AMPERSAND                                             /* Logical OR */
%left     EQ NE                                                 /* Equality operators */
%left     LT LTE GT GTE                                         /* Relational operators */
%left     LSHIFT RSHIFT                                         /* Bitwise shifts */
%left     PLUS MINUS                                            /* Additive operators */
%left     ASTERISK DIV MOD                                      /* Multiplicative operators */
%right    UMINUS UBANG UASTERISK UAMPERSAND INCREMENT DECREMENT /* Unary operators */
%nonassoc LBRACKET RBRACKET                                     /* Array subscript */
%nonassoc LPAREN RPAREN                                         /* Function call */
%nonassoc LBRACE RBRACE

%start program

%locations

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
  /* Empty */ %prec EMPTY
| definitions definition
;

definition:
  ID opt_array {
    printf(".data\n");
    if ($2 != NULL) {
      symbol_add($1, POINTER, EXTERNAL);
      int size = atoi($2);
      if (size <= 0) size = 1;
      printf(".globl %s\n", $1);
      printf("%s:\n", $1);
      printf("  .long \"%s\" + 4\n", $1);
      printf("  .space %d\n", size * 4);
    } else {
      symbol_add($1, VARIABLE, EXTERNAL);
      printf(".globl %s\n", $1);
      printf("%s:\n", $1);
      printf("  .long \"%s\" + 4\n", $1);
      printf("  .long 0\n");
    }
    if ($2 != NULL) free($2);
    free($1);
  } opt_values SEMICOLON {}
| ID LPAREN {
    symbol_add($1, POINTER, EXTERNAL);
    scope_create();
    printf(".text\n");
    printf(".globl %s\n", $1);
    printf("%s:\n", $1);
    printf("  .long \"%s\" + 4\n", $1);
    printf("  push ebp\n");
    printf("  mov ebp, esp\n");
    free($1);
  } opt_parameters RPAREN statement {
    printf(".LF%zu:\n", label_fn++);
    printf("  mov esp, ebp\n");
    printf("  pop ebp\n");
    printf("  ret\n");
    scope_destroy();
  }
;

array:
  LBRACKET opt_constant RBRACKET { $$ = $2; }
;

opt_array:
  /* Empty */ %prec EMPTY { $$ = NULL; }
| array                   { $$ = $1; }
;

parameters:
  ID {
    symbol_add($1, VARIABLE, INTERNAL);
    free($1);
  }
| parameters COMMA ID {
    symbol_add($3, VARIABLE, INTERNAL);
    free($3);
  }
;

opt_parameters:
  /* Empty */ %prec EMPTY
| parameters
;

constant:
  NUMBER { $$ = $1; }
| CHAR {
    char *s = $1;

    int c;
    if (s[1] == '\\') {
      c = handle_escape_char(s[2]);
    } else {
      c = (int)s[1];
    }

    char *buf = (char *)malloc(32);
    if (buf == NULL) {
      exit(1);
    }

    sprintf(buf, "%d", c);
    $$ = buf;
    free($1);
  }
| STRING {
    printf(".section .rodata\n");
    printf(".LC%zu:\n", label_const);

    printf("  .long .LC%zu + 4\n", label_const);
    printf("  .string %s\n", $1);
    printf(".text\n");

    char* buf = (char *)malloc(32);
    if (buf == NULL) {
      exit(1);
    }

    sprintf(buf, ".LC%zu", label_const++);
    $$ = buf;
    free($1);
  }
;

opt_constant:
  /* Empty */ %prec EMPTY { $$ = NULL; }
| constant                { $$ = $1; }
;

value:
  constant  { $$ = $1; }
| ID        { $$ = $1; }
;

values:
  value {
    printf("  .long %s\n", $1);
    free($1);
  }
| values COMMA value {
    printf("  .long %s\n", $3);
    free($3);
  }
;

opt_values:
  /* Empty */ %prec EMPTY
| values
;

statement:
  AUTO auto SEMICOLON statement
| EXTRN extrn SEMICOLON statement
| LBRACE {
    scope_create();
  } statements RBRACE {
    scope_destroy();
  }
| IF LPAREN rvalue {
    printf("  test eax, eax\n");
    printf("  jz .LIE%zu\n", ++label_if);
  } RPAREN statement {
    printf("  jmp .LIE%zu\n", ++label_if);
    printf(".LIE%zu:\n", --label_if);
  } else {
    printf(".LIE%zu:\n", ++label_if);
  }
| WHILE {
    printf(".LW%zu:\n", ++label_while);
  } LPAREN rvalue RPAREN {
    printf("  test eax, eax\n");
    printf("  jz .LW%zu\n", ++label_while);
  } statement {
    printf("  jmp .LW%zu\n", --label_while);
    printf(".LW%zu:\n", ++label_while);
  }
| SWITCH rvalue {
    printf("  mov ebx, eax\n");
  } statement
| CASE constant {
    printf("  mov eax, %s\n", $2);
  } COLON {
    printf("  cmp ebx, eax\n");
    printf("  jnz .LS%zu\n", label_switch);
    free($2);
  } statement {
    printf(".LS%zu:\n", label_switch++);
  }
| ID COLON {
    symbol_add($1, POINTER, LABEL);
    printf(".%s:\n", $1);
    printf("  .long .%s + 4\n", $1);
    free($1);
  } statement
| GOTO rvalue SEMICOLON {
    printf("  jmp [eax]\n");
  }
| RETURN return SEMICOLON {
    printf("  jmp .LF%zu\n", label_fn);
  }
| rvalue SEMICOLON
| SEMICOLON
;

return:
  /* Empty */ %prec EMPTY
| LPAREN rvalue RPAREN
;

statements:
  /* Empty */ %prec EMPTY
| statements statement
;

auto:
  auto_def
| auto COMMA auto_def
;

auto_def:
  ID {
    symbol_add($1, VARIABLE, AUTOMATIC);
    printf("  sub esp, 4\n");
    printf("  mov DWORD PTR [ebp - %zu], 0\n", current_scope->local_offset);
  } opt_constant {
    if ($3 != NULL) {
      printf("  mov DWORD PTR [ebp - %zu], %s\n", current_scope->local_offset, $3);
      free($3);
    }
  }
;

extrn:
  ID {
    symbol_add($1, POINTER, EXTERNAL);
    printf(".extern %s\n", $1);
    free($1);
  }
| extrn COMMA ID {
    symbol_add($3, POINTER, EXTERNAL);
    printf(".extern %s\n", $3);
    free($3);
  }
;

else:
  /* Empty */ %prec EMPTY
| ELSE statement
;

lvalue:
  ID {
    Symbol *symbol = symbol_find_global($1);
    if (symbol == NULL) {
      fprintf(stderr, "Error: %d:%d: Undefined variable %s\n", @1.first_line, @1.first_column, $1);
      free($1);
      YYERROR;
    }

    switch (symbol->storage) {
      case AUTOMATIC:
        printf("  lea eax, [ebp - %zu]\n", symbol->offset);
        break ;
      case INTERNAL:
        printf("  lea eax, [ebp + %zu]\n", symbol->offset);
        break ;
      case EXTERNAL:
        printf("  lea eax, [%s]\n", symbol->name);
        break ;
      case LABEL:
        printf("  lea eax, [.%s]\n", symbol->name);
        break ;
      default:
        break ;
    }

    pointer = symbol->type;
    free($1);
  }
| ASTERISK rvalue %prec UASTERISK
| rvalue LBRACKET {
    printf("  push eax\n");
  } rvalue RBRACKET {
    printf("  mov ecx, eax\n");
    printf("  shl ecx, 2\n");
    printf("  pop eax\n");
    printf("  add eax, ecx\n");
  }
;

rvalue:
  LPAREN rvalue RPAREN
| lvalue %prec LVALUE {
    if (pointer == VARIABLE) {
      printf("  mov eax, DWORD PTR [eax]\n");
    }

    pointer = 0;
  }
| constant {
    printf("  mov eax, %s\n", $1);
    free($1);
  }
| lvalue ASSIGN {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_OR {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  or [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN_AND {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  and [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN_EQ {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  sete al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_NE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setne al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_LT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setl al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_LTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setle al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_GT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setg al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_GTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp [ecx], eax\n");
    printf("  setge al\n");
    printf("  movzx eax, al\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_LSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  mov cl, dl\n");
    printf("  shl eax, cl\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_RSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  mov cl, dl\n");
    printf("  shr eax, cl\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_PLUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  add [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN_MINUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  sub [ecx], eax\n");
    printf("  mov eax, [ecx]\n");
  }
| lvalue ASSIGN_MOD {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  cdq\n");
    printf("  idiv edx\n");
    printf("  mov eax, edx\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_MUL {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  imul eax, edx\n");
    printf("  mov [ecx], eax\n");
  }
| lvalue ASSIGN_DIV {
    printf("  push eax\n");
  } rvalue {
    printf("  mov edx, eax\n");
    printf("  pop ecx\n");
    printf("  mov eax, [ecx]\n");
    printf("  cdq\n");
    printf("  idiv edx\n");
    printf("  mov [ecx], eax\n");
  }
| INCREMENT lvalue {
    printf("  add DWORD PTR [eax], 1\n");
    printf("  mov eax, DWORD PTR [eax]\n");
  }
| DECREMENT lvalue {
    printf("  sub DWORD PTR [eax], 1\n");
    printf("  mov eax, DWORD PTR [eax]\n");
  }
| lvalue INCREMENT {
    printf("  mov ecx, DWORD PTR [eax]\n");
    printf("  add DWORD PTR [eax], 1\n");
    printf("  mov eax, ecx\n");
  }
| lvalue DECREMENT {
    printf("  mov ecx, DWORD PTR [eax]\n");
    printf("  sub DWORD PTR [eax], 1\n");
    printf("  mov eax, ecx\n");
  }
| rvalue OR {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  or eax, ecx\n");
  }
| rvalue AMPERSAND {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  and eax, ecx\n");
  }
| rvalue EQ {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  sete al\n");
    printf("  movzx eax, al\n");
  }
| rvalue NE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setne al\n");
    printf("  movzx eax, al\n");
  }
| rvalue LT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setl al\n");
    printf("  movzx eax, al\n");
  }
| rvalue LTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setle al\n");
    printf("  movzx eax, al\n");
  }
| rvalue GT {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setg al\n");
    printf("  movzx eax, al\n");
  }
| rvalue GTE {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  cmp ecx, eax\n");
    printf("  setge al\n");
    printf("  movzx eax, al\n");
  }
| rvalue LSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  shl eax, cl\n");
  }
| rvalue RSHIFT {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  shr eax, cl\n");
  }
| rvalue PLUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  add eax, ecx\n");
  }
| rvalue MINUS {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  sub ecx, eax\n");
    printf("  mov eax, ecx\n");
  }
| rvalue ASTERISK {
    printf("  push eax\n");
  } rvalue {
    printf("  pop ecx\n");
    printf("  imul eax, ecx\n");
  }
| rvalue DIV {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  cdq\n");
    printf("  idiv ecx\n");
  }
| rvalue MOD {
    printf("  push eax\n");
  } rvalue {
    printf("  mov ecx, eax\n");
    printf("  pop eax\n");
    printf("  cdq\n");
    printf("  idiv ecx\n");
    printf("  mov eax, edx\n");
  }
| rvalue QUESTION {
    printf("  test eax, eax\n");
    printf("  jz .LT%zu\n", ++label_tern);
  } rvalue {
    printf("  jmp .LT%zu\n", ++label_tern);
    printf(".LT%zu:\n", --label_tern);
  } COLON rvalue {
    printf(".LT%zu:\n", ++label_tern);
  }
| MINUS rvalue %prec UMINUS {
    printf("  neg eax\n");
  }
| BANG rvalue %prec UBANG {
    printf("  test eax, eax\n");
    printf("  setz al\n");
    printf("  movzx eax, al\n");
  }
| AMPERSAND lvalue %prec UAMPERSAND
| rvalue LPAREN {
    printf("  push eax\n");
  } opt_arguments RPAREN {
    for (int i = 0; i < ($4 + 1) / 2; ++i) {
      printf("  mov ebx, [esp + %d]\n", i * 4);
      printf("  mov ecx, [esp + %d]\n", ($4 - i) * 4);
      printf("  mov [esp + %d], ebx\n", ($4 - i) * 4);
      printf("  mov [esp + %d], ecx\n", i * 4);
    }

    printf("  pop eax\n");
    printf("  call [eax]\n");
    if ($4 > 0) {
      printf("  add esp, %d\n", $4 * 4);
    }
  }
;

arguments:
  rvalue {
    printf("  push eax\n");
    $$ = 1;
  }
| arguments COMMA rvalue {
    printf("  push eax\n");
    $$ = $1 + 1;
  }
;

opt_arguments:
  /* Empty */ %prec EMPTY { $$ = 0; }
| arguments               { $$ = $1; }
;

%%

void yyerror(const char *s) {
  fprintf(stderr, "Error: %s %d:%d: %s '%s'\n", __FILE__, yylineno, yycolumn, s, yytext);
}

int main(void) {
  int result = yyparse();
  yylex_destroy();
  return result;
}
