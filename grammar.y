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
%token INT MAIN LET IF ELSE WHILE END
%token <num> INTEGERCONSTANT
%token <str> IDENTIFIER

%type <str> expression varName varDecl varDecls whileStatement letStatement statement statements main
%type <str> ifThenElseStmt ifThenStatement condition
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

program         : varDecls main funtions END            { printf("start\n%s%sstop\n", $1,$2); print_table(symbolTable); }
                ;

varDecls        :                                       { asprintf(&$$, "%s", "");}
                | varDecls varDecl                      { asprintf(&$$, "%s%s", $1, $2); }
                ;

varDecl         : INT IDENTIFIER ';' {
                        asprintf(&$$, "pushi 0\npushi 0\nstoreg %d\n", globalCount);
                        if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                        ht_insert(symbolTable, $2, globalCount, "int");
                        globalCount++;
                    }
                | INT IDENTIFIER '=' constant ';' {
                        asprintf(&$$, "pushi 0\npushi %d\nstoreg %d\n", $4, globalCount);
                        if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                        ht_insert(symbolTable, $2, globalCount, "int");
                        globalCount++;
                        
                    }
                | INT IDENTIFIER '=' expression ';' {
                        if (hasDuplicates(symbolTable, $2)) return fprintf(stderr, "%d: error: redeclaration of ‘%s’\n", yylineno, $2);
                        asprintf(&$$, "pushi 0\n%sstoreg %d\n", $4, globalCount);
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
                    };

statements      :                                       { asprintf(&$$, "%s", ""); }
                | statements statement                  { asprintf(&$$, "%s%s", $1, $2); }
                ;

statement       : ifThenElseStmt                        { asprintf(&$$, "%s", $1); }
                | ifThenStatement                       { asprintf(&$$, "%s", $1); }
                | whileStatement                        { asprintf(&$$, "%s", $1); }
                | letStatement                          { asprintf(&$$, "%s", $1); }
                | varDecl                               { return fprintf(stderr, "%d: error: variables must be declared before any function\n", yylineno); }
                ;

ifThenElseStmt  : IF '(' condition ')' '{' statements '}' ELSE '{' statements '}' { 
                        asprintf(&$$, "%sjz ELSE%d\n%sjump ENDIF%d\nELSE%d:\n%sENDIF%d:\n", $3, labelCount, $6, labelCount, labelCount, $10, labelCount); 
                        labelCount++; 
                    };

ifThenStatement : IF '(' condition ')' '{' statements '}' { 
                        asprintf(&$$, "%sjz L%d\n%sL%d:\n", $3, labelCount, $6, labelCount); 
                        labelCount++; 
                    };

whileStatement  : WHILE '(' condition ')' '{' statements '}' { 
                        asprintf(&$$, "WHILE%d:\n%sjz ENDWHILE%d\n%sjump WHILE%d\nENDWHILE%d:\n", labelCount, $3, labelCount, $6, labelCount, labelCount); 
                        labelCount++; 
                    };

letStatement    : LET varName '=' expression ';'    { 
                        asprintf(&$$, "%sstoreg %d\n", $4, ((ht_search(symbolTable, $2))->varPos));
                    }

expression      : constant                              { asprintf(&$$, "pushi %d\n", $1); }
                | IDENTIFIER {
                        if (hasDuplicates(symbolTable, $1) == 0) return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this function)\n", yylineno, $1);
                        asprintf(&$$, "pushg %d\n", ((ht_search(symbolTable, $1))->varPos));
                    }
                | '(' expression ')'                    { asprintf(&$$, "%s", $2); }
                | expression '+' expression             { asprintf(&$$, "%s%sadd\n", $1, $3); }
                | expression '-' expression             { asprintf(&$$, "%s%ssub\n", $1, $3); }
                | expression '*' expression             { asprintf(&$$, "%s%smul\n", $1, $3); }
                | expression '/' expression             { asprintf(&$$, "%s%sdiv\n", $1, $3); }
                ;

condition       : constant                              { asprintf(&$$, "pushi %d\n", $1); }
                | IDENTIFIER {
                        if (hasDuplicates(symbolTable, $1) == 0) return fprintf(stderr, "%d: error: ‘%s’ undeclared (first use in this function)\n", yylineno, $1);
                        asprintf(&$$, "pushg %d\n", ((ht_search(symbolTable, $1))->varPos));
                    }
                | '(' condition ')'                     { asprintf(&$$, "%s", $2); }
                | condition '>' condition               { asprintf(&$$, "%s%ssup\n", $1, $3); }
                | condition '<' condition               { asprintf(&$$, "%s%sinf\n", $1, $3); }
                | condition SUPEQ condition             { asprintf(&$$, "%s%ssupeq\n", $1, $3); }
                | condition INFEQ condition             { asprintf(&$$, "%s%sinfeq\n", $1, $3); }
                | condition EQ condition                { asprintf(&$$, "%s%sequal\n", $1, $3); }
                | condition NEQ condition               { asprintf(&$$, "%s%sequal\npushi 1\nadd\npushi 2\nmod\n", $1, $3); }
                | NOT condition                         { asprintf(&$$, "%spushi 1\nadd\npushi 2\nmod\n", $2); }
                | condition AND condition               { asprintf(&$$, "%s%smul\n", $1, $3); }
                | condition OR condition                { asprintf(&$$, "%s%sadd\npushi 2\nmod\n%s%smul\nadd\n", $1, $3, $1, $3); }
                ;

varName         : IDENTIFIER                            { asprintf(&$$, "%s", $1); }
                ;

constant        : INTEGERCONSTANT                       { $$ = $1; }
                ;
%%

#include "lex.yy.c"

int yyerror(const char *s) { fprintf(stderr, "%d: error: %s \n", yylineno, s); return 0; }

int main() { symbolTable = create_table(CAPACITY); yyparse(); return(0); }