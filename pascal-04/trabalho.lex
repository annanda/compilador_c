DELIM   [\t ]
LINHA   [\n]
NUMERO  [0-9]
LETRA   [A-Za-z_]
INT     {NUMERO}+
DOUBLE  {NUMERO}+("."{NUMERO}+)?
ID      {LETRA}({LETRA}|{NUMERO})*
CSTRING "'"([^\n']|"''")*"'"

%%

{LINHA}    { nlinha++; }
{DELIM}    {}

"Var"      { yylval = Atributos( yytext ); return TK_VAR; }
"Program"  { yylval = Atributos( yytext ); return TK_PROGRAM; }
"Begin"    { yylval = Atributos( yytext ); return TK_BEGIN; }
"End"      { yylval = Atributos( yytext ); return TK_END; }
"WriteLn"  { yylval = Atributos( yytext ); return TK_WRITELN; }

":="       { yylval = Atributos( yytext ); return TK_ATRIB; }

{CSTRING}  { yylval = Atributos( yytext, "string" ); return TK_CSTRING; }
{ID}       { yylval = Atributos( yytext ); return TK_ID; }
{INT}      { yylval = Atributos( yytext, "int" ); return TK_CINT; }
{DOUBLE}   { yylval = Atributos( yytext, "double" ); return TK_CDOUBLE; }

.          { yylval = Atributos( yytext ); return *yytext; }

%%

 


