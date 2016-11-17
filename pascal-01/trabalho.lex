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

"Var"      { return TK_VAR; }
"Program"  { return TK_PROGRAM; }
"Begin"    { return TK_BEGIN; }
"End"      { return TK_END; }
"WriteLn"  { return TK_WRITELN; }

":="       { return TK_ATRIB; }

{CSTRING}  { return TK_CSTRING; }
{ID}       { return TK_ID; }
{INT}      { return TK_CINT; }
{DOUBLE}   { return TK_CDOUBLE; }
.          { return *yytext; }

%%

 


