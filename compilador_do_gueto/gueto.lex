DELIM   [\t ]
LINHA   [\n]
NUMERO  [0-9]
LETRA   [a-zA-Z_]
INT     {NUMERO}+
DOUBLE  {NUMERO}+("."{NUMERO}+)?
ID      {LETRA}({LETRA}|{NUMERO})*
CSTRING \"(\\.|[^\\"])*\"
COMMENT "/*"([^*]|\*+[^*/])*\*+"/"

%%

{LINHA}    { nlinha++; }
{DELIM}    {}
{COMMENT}  {}

"xar"      { return TK_CHAR;   }
"intero"   { return TK_INT;    }
"daboul"   { return TK_DOUBLE; }
"cadea"    { return TK_STRING; }
"bul"      { return TK_BOOL;   }
"nada"     { return TK_VOID;   }

"{"        { return TK_BEGIN;  }
"}"        { return TK_END;    }
"main"     { return TK_MAIN;   }
"flwvlw"   { return TK_RETURN; }
"revela"   { return TK_WRITE;  }
"descobre" { return TK_READ;   }
"se"       { return TK_IF;     }
"senao"    { return TK_ELSE;   }
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
{ID}       { yylval = Atributos(yytext); return TK_ID; }
{INT}      { return TK_CINT; }
{DOUBLE}   { return TK_CDOUBLE; }
.          { return *yytext; }

%%
