%{
#include <stdio.h>
#include <stdlib.h>
#include "grammar.tab.h"
%}
%option noyywrap
%option yylineno
INTEGER             \-?[0-9]+
STRING              \"(\\.|[^"\\])*\"
IDENTIFIER          [_a-zA-Z][_a-zA-Z0-9]*
%%
main                        { return MAIN; }
end                         { return END; }
int                         { return INT; }
let                         { return LET; }
if                          { return IF; }
else                        { return ELSE; }
while                       { return WHILE; }
or                          { return OR; }
and                         { return AND; }
"=="                        { return EQ; }
"!="                        { return NEQ; }
">="                        { return SUPEQ; }
"<="                        { return INFEQ; }
not                         { return NOT; }
[{}()\.,;+\-*/&\|<>=~]      { return yytext[0]; }
{INTEGER}                   { yylval.num = atoi(yytext); return INTEGERCONSTANT; }
{IDENTIFIER}                { yylval.str = strdup(yytext); return IDENTIFIER; }
[ \t\n]                     { ; }
%%