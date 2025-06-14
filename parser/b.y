%token AUTO EXTRN RETURN IDENTIFIER

%%

statement:
  AUTO identifier_list ';'
  EXTRN identifier_list ';'
;

identifier_list:
  IDENTIFIER
| identifier_list ',' IDENTIFIER
;
