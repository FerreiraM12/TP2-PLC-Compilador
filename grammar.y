%{
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include "hashTable.h"
#define CAPACITY 50000

int yylex();
int yyerror();
extern int yylineno;
int globalCount = 0;
int localCount = 0;
int functionCount = 0;
HashTable *symbolTable;
%}

%union { char* str; int num; }

%token FUNCTION VAR INT CHAR BOOLEAN TTRUE TFALSE MAIN
%token TNULL THIS LET DO IF ELSE WHILE RETURN END
%token STRINGCONSTANT
%token <num> INTEGERCONSTANT
%token <str> IDENTIFIER

%type <str> expression varName varDecl varDecls ifStatement whileStatement letStatement statement statements main
%type <num> constant
%right '='
%left  '+' '-'
%left  '*' '/'

%%

program         : varDecls main funtions END            { printf("START\n%s%sSTOP\n", $1,$2); print_table(symbolTable); }
                ;

varDecls        :                                       { asprintf(&$$, "%s", "");}
                | varDecls varDecl                      { asprintf(&$$, "%s%s", $1, $2); }
                ;

varDecl         : INT IDENTIFIER ';' {
                        asprintf(&$$, "PUSHI 0\nPUSHI 0\nSTOREG %d\n", globalCount);
                        if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                        ht_insert(symbolTable, $2, globalCount, "int");
                        globalCount++;
                    }
                | INT IDENTIFIER '=' constant ';' {
                        asprintf(&$$, "PUSHI 0\nPUSHI %d\nSTOREG %d\n", $4, globalCount);
                        if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                        ht_insert(symbolTable, $2, globalCount, "int");
                        globalCount++;
                        
                    }
                | INT IDENTIFIER '=' expression ';' {
                        if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                        asprintf(&$$, "PUSHI 0\n%sSTOREG %d\n", $4, globalCount);
                        ht_insert(symbolTable, $2, globalCount, "int");
                        globalCount++;
                    }

main            : INT MAIN '(' ')' '{' statements '}'   { asprintf(&$$, "%s", $6); }
                ;

funtions        : 
                | funtions function
                ;

function        : INT IDENTIFIER '(' ')' '{' statements '}' {
                        if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redefinition of '%s'\n", yylineno, $2);
                        ht_insert(symbolTable, $2, functionCount, "func");
                        functionCount++;
                    }
                ;

statements      :                                       { asprintf(&$$, "%s", ""); }
                | statements statement                  { asprintf(&$$, "%s%s", $1, $2); }
                ;

statement       : ifStatement                           { asprintf(&$$, "%s", $1); }
                | whileStatement                        { asprintf(&$$, "%s", $1); }
                | letStatement                          { asprintf(&$$, "%s", $1); }
                | varDecl                               { asprintf(&$$, "%s", $1); }
                ;

ifStatement     : IF '(' expression ')' '{' statements '}'
                ;

whileStatement  : WHILE '(' expression ')' '{' statements '}'
                ;

letStatement    : LET varName '=' expression ';'    { 
                        asprintf(&$$, "%sSTOREG %d\n", $4, ((ht_search(symbolTable, $2))->varPos));
                    }

expression      : constant                              { asprintf(&$$, "PUSHI %d\n", $1); }
                | IDENTIFIER {
                        if (hasDuplicates(symbolTable, $1) == 0) return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this function)\n", yylineno, $1);
                        asprintf(&$$, "PUSHG %d\n", ((ht_search(symbolTable, $1))->varPos));
                    }
                | '(' expression ')'                    { asprintf(&$$, "%s", $2); }
                | expression '+' expression             { asprintf(&$$, "%s%sADD\n", $1, $3); }
                | expression '-' expression             { asprintf(&$$, "%s%sSUB\n", $1, $3); }
                | expression '*' expression             { asprintf(&$$, "%s%sMUL\n", $1, $3); }
                | expression '/' expression             { asprintf(&$$, "%s%sDIV\n", $1, $3); }
                ;

varName         : IDENTIFIER                            { asprintf(&$$, "%s", $1); }
                ;

constant        : INTEGERCONSTANT                       { $$ = $1; }
                ;




%%

#include "lex.yy.c"

int yyerror(const char *s) { fprintf(stderr, "%d: error: %s \n", yylineno, s); return 0; }

int main() { symbolTable = create_table(CAPACITY); yyparse(); return(0); }