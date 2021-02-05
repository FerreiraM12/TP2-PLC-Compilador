%{
#include <stdio.h>
#include <stdlib.h>
#include "grammar.tab.h"
%}
%option noyywrap
%option yylineno
INTEGER             \-?[0-9]+
IDENTIFIER          [_a-zA-Z][_a-zA-Z0-9]*
STRING              \"(\\.|[^"\\])*\"
%%
"main"                      { return MAIN; }
"return"                    { return RETURN; }
"read()"                    { return READ; }
"print"                     { return PRINT; }
"printStr"                  { return PRINTSTR; }
"int"                       { return INT; }
"if"                        { return IF; }
"else"                      { return ELSE; }
"while"                     { return WHILE; }
"for"                       { return FOR; }
"until"                     { return UNTIL; }
"or"                        { return OR; }
"and"                       { return AND; }
"=="                        { return EQ; }
"!="                        { return NEQ; }
">="                        { return SUPEQ; }
"<="                        { return INFEQ; }
"not"                       { return NOT; }
[\[\]{}();+\-*/<>=%]        { return yytext[0]; }
{INTEGER}                   { yylval.num = atoi(yytext); return INTEGER; }
{IDENTIFIER}                { yylval.str = strdup(yytext); return IDENTIFIER; }
{STRING}                    { yylval.str = strdup(yytext); return STRING;}
"//".*                      { ; }
"/*"([^*]|\*+[^*/])*\*+"/"  { ; }
[ \t\n]                     { ; }
.                           { return yytext[0]; }
%%