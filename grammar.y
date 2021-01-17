%{
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include "hashTable.h"
#define CAPACITY 50000
int yydebug=1;
int yylex();
int yyerror();
extern int yylineno;
int globalCount = 0;
int localCount = 0;
int functionCount = 0;
int labelCount;
HashTable *symbolTable;

typedef struct {
    char *str;
    int num;
    char *funcs;
} info;

%}
%define parse.error verbose

%union { char* str; int num; info info; }
%token INT MAIN IF ELSE WHILE DO UNTIL FOR READ PRINT RETURN
%token <num> INTEGER
%token <str> IDENTIFIER

%type <str> expression varDecl whileStatement doUntil forStatement letStatement statement statements main
%type <str> ifThenElseStmt ifThenStatement condition print funcao functionCall
%type <info> decls

%right  '='                 
%left   OR                  
%left   AND                 
%left   EQ NEQ              
%left   '>' '<' SUPEQ INFEQ 
%left   '+' '-'             
%left   '*' '/'             
%left   NOT                 

%%

program         : decls main                            { printf("// Declarations\n"
                                                                 "%s\n"
                                                                 "// Program\n"
                                                                 "start\n"
                                                                 "%s"
                                                                 "stop\n\n", $1.str,$2);
                                                                 if (strcmp($1.funcs, "") != 0) printf("// Functions\n%s", $1.funcs);
                                                                 print_table(symbolTable); }

decls           :                                       { asprintf(&$$.str, "%s", ""); asprintf(&$$.funcs, "%s", "");}

                | decls varDecl                         { asprintf(&$$.str, "%s"
                                                                            "%s", $1.str, $2); }

                | decls funcao                          { asprintf(&$$.str, "%s\n", $1.str); asprintf(&$$.funcs, "%s\n", $2); }

varDecl         : INT IDENTIFIER ';'                    { if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                                                          asprintf(&$$, "pushi 0\n");
                                                          ht_insert(symbolTable, $2, globalCount++, "int"); }

                | INT IDENTIFIER '=' expression ';'     { if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                                                          asprintf(&$$, "pushi 0\n"
                                                                        "%s"
                                                                        "storeg %d\n", $4, globalCount);
                                                          ht_insert(symbolTable, $2, globalCount++, "int"); }

                | INT IDENTIFIER '[' INTEGER ']' ';'    { if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                                                          asprintf(&$$, "pushn %d\n", $4);
                                                          ht_insert(symbolTable, $2, globalCount, "intArray");
                                                          globalCount += $4; }

funcao          : INT IDENTIFIER '(' ')' '{' 
                  statements 
                  RETURN expression ';' '}'             { if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                                                          ht_insert(symbolTable, $2, -1, "function");
                                                          asprintf(&$$, "%s:\n"
                                                                        "%s"
                                                                        "%s"
                                                                        "storel -1\n"
                                                                        "return\n", $2, $6, $8); }
                                                      
main            : INT MAIN '(' ')' '{' statements '}'   { asprintf(&$$, "%s", $6); }

statements      :                                       { asprintf(&$$, "%s", ""); }

                | statements statement                  { asprintf(&$$, "%s"
                                                                        "%s", $1, $2); }

statement       : ifThenElseStmt                        { asprintf(&$$, "%s", $1); }
                | ifThenStatement                       { asprintf(&$$, "%s", $1); }
                | whileStatement                        { asprintf(&$$, "%s", $1); }
                | forStatement                          { asprintf(&$$, "%s", $1); }
                | letStatement                          { asprintf(&$$, "%s", $1); }
                | varDecl                               { return fprintf(stderr, "%d: error: variables must be declared before any function\n", yylineno); }
                | print                                 { asprintf(&$$, "%s", $1); }
                | functionCall                          { asprintf(&$$, "%s", $1); }

ifThenElseStmt  : IF '(' condition ')' 
                  '{' statements '}' 
                  ELSE '{' statements '}'               { asprintf(&$$, "%s"
                                                                        "jz ELSE%d\n"
                                                                        "%s"
                                                                        "jump ENDIF%d\n"
                                                                        "ELSE%d:\n"
                                                                        "%s"
                                                                        "ENDIF%d:\n", $3, labelCount, $6, labelCount, labelCount, $10, labelCount); labelCount++}

ifThenStatement : IF '(' condition ')' 
                  '{' statements '}'                    { asprintf(&$$, "%s"
                                                                        "jz L%d\n"
                                                                        "%s"
                                                                        "L%d:\n", $3, labelCount, $6, labelCount); labelCount++}

whileStatement  : WHILE '(' condition ')' 
                  '{' statements '}'                    { asprintf(&$$, "WHILE%d:\n"
                                                                        "%s"
                                                                        "jz ENDWHILE%d\n"
                                                                        "%s"
                                                                        "jump WHILE%d\n"
                                                                        "ENDWHILE%d:\n", labelCount, $3, labelCount, $6, labelCount, labelCount); labelCount++}

doUntil         : DO '{' statements '}' 
                  UNTIL '(' condition ')'               { ; } 

forStatement    : FOR '('                               { ; }

letStatement    : IDENTIFIER '=' expression ';'         { if (hasDuplicates(symbolTable, $1) == 0) 
                                                          return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this program)\n", yylineno, $1);
                                                          asprintf(&$$, "%s"
                                                                        "storeg %d\n", $3, ((ht_search(symbolTable, $1))->varPos)); }

                | IDENTIFIER '[' expression ']' '=' expression ';' {
                                                          if (hasDuplicates(symbolTable, $1) == 0) 
                                                          return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this program)\n", yylineno, $1);
                                                          asprintf(&$$, "pushgp\n"
                                                                        "pushi %d\n"
                                                                        "padd\n"
                                                                        "%s"
                                                                        "%s"
                                                                        "storen\n", (ht_search(symbolTable, $1)->varPos), $3, $6); }

                | IDENTIFIER '=' functionCall           { if (hasDuplicates(symbolTable, $1) == 0) 
                                                          return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this program)\n", yylineno, $1);
                                                          asprintf(&$$, "pushi 0\n"
                                                                        "%s"
                                                                        "storeg %d\n", $3, (ht_search(symbolTable, $1)->varPos)); }
                                                                        
print           : PRINT '(' expression ')' ';'          { asprintf(&$$, "%s"
                                                                        "writei\n", $3); }

functionCall    : IDENTIFIER '(' ')' ';'                { if (hasDuplicates(symbolTable, $1) == 0) 
                                                          return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this program)\n", yylineno, $1);
                                                          asprintf(&$$, "pusha %s\n"
                                                                        "call\n", $1); }

expression      : INTEGER                               { asprintf(&$$, "pushi %d\n", $1); }

                | IDENTIFIER                            { if (hasDuplicates(symbolTable, $1) == 0) 
                                                          return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this program)\n", yylineno, $1);
                                                          asprintf(&$$, "pushg %d\n", ((ht_search(symbolTable, $1))->varPos)); }
                
                | IDENTIFIER '[' expression ']'         { if (hasDuplicates(symbolTable, $1) == 0)
                                                          return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this program)\n", yylineno, $1);
                                                          asprintf(&$$, "pushgp\n"
                                                                        "pushi %d\n"
                                                                        "padd\n"
                                                                        "%s"
                                                                        "loadn\n", ((ht_search(symbolTable, $1))->varPos), $3); }

                | READ                                  { asprintf(&$$, "read\n"
                                                                        "atoi\n"); }
                
                | '(' expression ')'                    { asprintf(&$$, "%s", $2); }

                | expression '+' expression             { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "add\n", $1, $3); }

                | expression '-' expression             { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "sub\n", $1, $3); }

                | expression '*' expression             { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "mul\n", $1, $3); }

                | expression '/' expression             { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "div\n", $1, $3); }

                | expression '%' expression             { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "MOD\n", $1, $3); }

condition       : INTEGER                               { asprintf(&$$, "pushi %d\n", $1); }

                | IDENTIFIER                            { if (hasDuplicates(symbolTable, $1) == 0) 
                                                          return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this function)\n", yylineno, $1);
                                                          asprintf(&$$, "pushg %d\n", ((ht_search(symbolTable, $1))->varPos)); }

                | '(' condition ')'                     { asprintf(&$$, "%s", $2); }

                | condition '>' condition               { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "sup\n", $1, $3); }

                | condition '<' condition               { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "inf\n", $1, $3); }

                | condition SUPEQ condition             { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "supeq\n", $1, $3); }

                | condition INFEQ condition             { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "infeq\n", $1, $3); }

                | condition EQ condition                { asprintf(&$$, "%s%s"
                                                                        "equal\n", $1, $3); }

                | condition NEQ condition               { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "equal\n"
                                                                        "pushi 1\n"
                                                                        "add\n"
                                                                        "pushi 2\n"
                                                                        "mod\n", $1, $3); }

                | NOT condition                         { asprintf(&$$, "%s"
                                                                        "pushi 1\n"
                                                                        "add\n"
                                                                        "pushi 2\n"
                                                                        "mod\n", $2); }

                | condition AND condition               { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "mul\n", $1, $3); }

                | condition OR condition                { asprintf(&$$, "%s"
                                                                        "%s"
                                                                        "add\n"
                                                                        "pushi 2\n"
                                                                        "mod\n"
                                                                        "%s%s"
                                                                        "mul\n"
                                                                        "add\n", $1, $3, $1, $3); }

%%

#include "lex.yy.c"

int yyerror(const char *s) { fprintf(stderr, "%d: error: %s \n", yylineno, s); return 0; }

int main() { symbolTable = create_table(CAPACITY); yyparse(); return(0); }