DELIM   [\t ]
LINHA   [\n]
NUMERO  [0-9]
LETRA   [A-Za-z_]
INT     {NUMERO}+
DOUBLE  {NUMERO}+("."{NUMERO}+)?
ID      {LETRA}({LETRA}|{NUMERO})*
CSTRING "'"([^\n']|"''")*"'"
COMMENT "/*"([^*]|\*+[^*/])*\*+"/"

%%

{LINHA}    { nlinha++; }
{DELIM}    {}
{COMMENT}  {}


"{"        { return TK_BEGIN;  }
"}"        { return TK_END;    }
"main"     { return TK_MAIN;   }
"flwvlw"   { return TK_RETURN; }
"revela"   { return TK_WRITE;  }
"descobre" { return TK_READ;   }
"se"       { return TK_IF;     }
"pra"      { return TK_FOR;    }
"enquanto" { return TK_WHILE;  }
"fassa"    { return TK_DO;     }

"="       { return TK_ATRIB; }
"<="      { return TK_LE;    }
">="      { return TK_GE;    }
"<>"      { return TK_DIFF;  }
"=="      { return TK_E;     }
"<"       { return TK_L;     }
">"       { return TK_G;     }
"e"       { return TK_AND;   }
"ou"      { return TK_OR;    }
"naum"    { return TK_NOT;   }

{CSTRING}  { return TK_CSTRING; }
{ID}       { return TK_ID; }
{INT}      { return TK_CINT; }
{DOUBLE}   { return TK_CDOUBLE; }
.          { return *yytext; }

%%
