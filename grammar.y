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

%}
%define parse.error verbose

%union { char* str; int num; }
%token INT MAIN IF ELSE WHILE READ PRINT
%token <num> INTEGERCONSTANT
%token <str> IDENTIFIER

%type <str> expression varName varDecl varDecls whileStatement letStatement statement statements main
%type <str> ifThenElseStmt ifThenStatement condition print
%type <num> constant
%right  '='                 
%left   OR                  
%left   AND                 
%left   EQ NEQ              
%left   '>' '<' SUPEQ INFEQ 
%left   '+' '-'             
%left   '*' '/'             
%left   NOT                 

%%

program         : varDecls main                         { printf("%s"
                                                                 "start\n"
                                                                 "%s"
                                                                 "stop\n", $1,$2);
                                                                 /*print_table(symbolTable);*/ }

varDecls        :                                       { asprintf(&$$, "%s", ""); }

                | varDecls varDecl                      { asprintf(&$$, "%s"
                                                                        "%s", $1, $2); }

varDecl         : INT IDENTIFIER ';'                    { asprintf(&$$, "pushi 0\n");
                                                          if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                                                          ht_insert(symbolTable, $2, globalCount, "int");
                                                          globalCount++; }

                | INT IDENTIFIER '=' constant ';'       { asprintf(&$$, "pushi 0\n"
                                                                        "pushi %d\n"
                                                                        "storeg %d\n", $4, globalCount);
                                                          if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                                                          ht_insert(symbolTable, $2, globalCount, "int");
                                                          globalCount++; }

                | INT IDENTIFIER '=' expression ';'     { if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                                                          asprintf(&$$, "pushi 0\n"
                                                                        "%s"
                                                                        "storeg %d\n", $4, globalCount);
                                                          ht_insert(symbolTable, $2, globalCount, "int");
                                                          globalCount++; }

                | INT IDENTIFIER '[' constant ']' ';'   { asprintf(&$$, "pushn %d\n", $4);
                                                          ht_insert(symbolTable, $2, globalCount, "intArray");
                                                          globalCount += $4; }
                                                          
main            : INT MAIN '(' ')' '{' statements '}'   { asprintf(&$$, "%s", $6); }

statements      :                                       { asprintf(&$$, "%s", ""); }

                | statements statement                  { asprintf(&$$, "%s"
                                                                        "%s", $1, $2); }

statement       : ifThenElseStmt                        { asprintf(&$$, "%s", $1); }
                | ifThenStatement                       { asprintf(&$$, "%s", $1); }
                | whileStatement                        { asprintf(&$$, "%s", $1); }
                | letStatement                          { asprintf(&$$, "%s", $1); }
                | varDecl                               { return fprintf(stderr, "%d: error: variables must be declared before any function\n", yylineno); }
                | print                                 { asprintf(&$$, "%s", $1); }

ifThenElseStmt  : IF '(' condition ')' '{' statements '}' ELSE '{' statements '}' { 
                                                          asprintf(&$$, "%s"
                                                                        "jz ELSE%d\n"
                                                                        "%s"
                                                                        "jump ENDIF%d\n"
                                                                        "ELSE%d:\n"
                                                                        "%s"
                                                                        "ENDIF%d:\n", $3, labelCount, $6, labelCount, labelCount, $10, labelCount); 
                                                          labelCount++; }

ifThenStatement : IF '(' condition ')' '{' statements '}' { 
                                                          asprintf(&$$, "%s"
                                                                        "jz L%d\n"
                                                                        "%s"
                                                                        "L%d:\n", $3, labelCount, $6, labelCount); 
                                                          labelCount++; }

whileStatement  : WHILE '(' condition ')' '{' statements '}' { 
                                                          asprintf(&$$, "WHILE%d:\n"
                                                                        "%s"
                                                                        "jz ENDWHILE%d\n"
                                                                        "%s"
                                                                        "jump WHILE%d\n"
                                                                        "ENDWHILE%d:\n", labelCount, $3, labelCount, $6, labelCount, labelCount); 
                                                          labelCount++; }

letStatement    : varName '=' expression ';'            { asprintf(&$$, "%s"
                                                                        "storeg %d\n", $3, ((ht_search(symbolTable, $1))->varPos)); }

                | varName '[' expression ']' '=' expression ';' {
                                                          asprintf(&$$, "pushgp\n"
                                                                        "pushi %d\n"
                                                                        "padd\n"
                                                                        "%s"
                                                                        "%s"
                                                                        "storen\n", (ht_search(symbolTable, $1)->varPos), $3, $6); }
                                                                        
print           : PRINT '(' expression ')' ';'          { asprintf(&$$, "%s"
                                                                        "writei\n", $3); }

expression      : constant                              { asprintf(&$$, "pushi %d\n", $1); }

                | IDENTIFIER                            { if (hasDuplicates(symbolTable, $1) == 0) 
                                                          return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this program)\n", yylineno, $1);
                                                          asprintf(&$$, "pushg %d\n", ((ht_search(symbolTable, $1))->varPos)); }
                
                | IDENTIFIER '[' expression ']'         { asprintf(&$$, "pushgp\n"
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

condition       : constant                              { asprintf(&$$, "pushi %d\n", $1); }

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

varName         : IDENTIFIER                            { asprintf(&$$, "%s", $1); }

constant        : INTEGERCONSTANT                       { $$ = $1; }


%%

#include "lex.yy.c"

int yyerror(const char *s) { fprintf(stderr, "%d: error: %s \n", yylineno, s); return 0; }

int main() { symbolTable = create_table(CAPACITY); yyparse(); return(0); }