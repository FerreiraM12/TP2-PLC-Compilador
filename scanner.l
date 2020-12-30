%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
%}
%option noyywrap
%option yylineno
INTEGER             \-?[0-9]+
STRING              \"(\\.|[^"\\])*\"
IDENTIFIER          [_a-zA-Z][_a-zA-Z0-9]*
%%
main                        { return MAIN; }
end                         { return END; }
function                    { return FUNCTION; }
var                         { return VAR; }
int                         { return INT; }
char                        { return CHAR; }
boolean                     { return BOOLEAN; }
void                        { return VOID; }
true                        { return TTRUE; }
false                       { return TFALSE; }
null                        { return TNULL; }
this                        { return THIS; }
let                         { return LET; }
do                          { return DO; }
if                          { return IF; }
else                        { return ELSE; }
while                       { return WHILE; }
return                      { return RETURN; }
[{}()\.,;+\-*/&\|<>=~]      { return yytext[0]; }
{INTEGER}                   { yylval.num = atoi(yytext); return INTEGERCONSTANT; }
{STRING}                    { yylval.str = strdup(yytext); return STRINGCONSTANT; }
{IDENTIFIER}                { yylval.str = strdup(yytext); return IDENTIFIER; }
[ \t\n]                     { ; }
%%