DELIM   [\t ]
LINHA   [\n]
NUMERO  [0-9]
LETRA   [A-Za-z_]
INT     {NUMERO}+
DOUBLE  {NUMERO}+("."{NUMERO}+)?
ID      {LETRA}({LETRA}|{NUMERO})*

%%

{LINHA}    { nlinha++; }
{DELIM}    {}
"x"        { yylval.e = "x"; yylval.d = "1"; return X; }
{ID}       { yylval.e = yytext; yylval.d = "0";  return TK_ID; }
{INT}      { yylval.e = yytext; yylval.d = "0"; return TK_CINT; }
{DOUBLE}   { yylval.e = yytext; yylval.d = "0"; return TK_CDOUBLE; }
.          { return *yytext; }

%%

 


