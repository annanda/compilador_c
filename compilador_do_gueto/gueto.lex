DELIM   [\t ]
LINHA   [\n]
NUMERO  [0-9]
LETRA   [a-zA-Z_]
INT     {NUMERO}+
DOUBLE  {NUMERO}+("."{NUMERO}+)?
ID      {LETRA}({LETRA}|{NUMERO})*
CSTRING \"(\\.|[^\\"])*\"
CCHAR   ['][^\n'][']
COMMENT "/*"([^*]|\*+[^*/])*\*+"/"
F       "FALSIANE"|"falsiane"|"Falsiane"
T       "verdadeiriane"|"VERDADEIRIANE"|"Verdadeiriane"

%%

{LINHA}    { nlinha++; }
{DELIM}    {}
{COMMENT}  {}

{T}        { return TK_TRUE;   }
{F}        { return TK_FALSE;  }

"xar"      { return TK_CHAR;   }
"intero"   { return TK_INT;    }
"daboul"   { return TK_DOUBLE; }
"cadea"    { return TK_STRING; }
"bul"      { return TK_BOOL;   }
"nada"     { return TK_VOID;   }

"{"        { yylval = Atributos(yytext); return TK_BEGIN;  }
"}"        { yylval = Atributos(yytext); return TK_END;    }
"mano"     { yylval = Atributos(yytext); return TK_MAIN;   }
"flwvlw"   { yylval = Atributos(yytext); return TK_RETURN; }
"revela"   { yylval = Atributos(yytext); return TK_WRITE;  }
"descobre" { yylval = Atributos(yytext); return TK_READ;   }
"se"       { yylval = Atributos(yytext); return TK_IF;     }
"senao"    { yylval = Atributos(yytext); return TK_ELSE;   }
"pra"      { yylval = Atributos(yytext); return TK_FOR;    }
"enquanto" { yylval = Atributos(yytext); return TK_WHILE;  }
"fassa"    { yylval = Atributos(yytext); return TK_DO;     }
"qqtuqr"   { yylval = Atributos(yytext); return TK_SWITCH; }
"cabou"    { yylval = Atributos(yytext); return TK_BREAK;  }
"essi"     { yylval = Atributos(yytext); return TK_CASE;   }
"padraum"  { yylval = Atributos(yytext); return TK_DEFAULT;}

"="       { yylval = Atributos(yytext); return TK_ATRIB; }
"<="      { yylval = Atributos(yytext); return TK_LE;    }
">="      { yylval = Atributos(yytext); return TK_GE;    }
"<>"      { yylval = Atributos(yytext); return TK_DIFF;  }
"=="      { yylval = Atributos(yytext); return TK_E;     }
"<"       { yylval = Atributos(yytext); return TK_L;     }
">"       { yylval = Atributos(yytext); return TK_G;     }
"e"       { yylval = Atributos(yytext); return TK_AND;   }
"ou"      { yylval = Atributos(yytext); return TK_OR;    }
"naum"    { yylval = Atributos(yytext); return TK_NOT;   }
"modis"   { yylval = Atributos(yytext); return TK_MOD;   }

{CSTRING}  { yylval = Atributos(yytext, Tipo("string")); return TK_CSTRING; }
{CCHAR}    { yylval = Atributos(yytext, Tipo("char"));   return TK_CCHAR;   }

{ID}       { yylval = Atributos(renomeia_variavel_usuario(yytext));
              return TK_ID;                                                 }
{INT}      { yylval = Atributos(yytext, Tipo("int")); return TK_CINT;       }
{DOUBLE}   { yylval = Atributos(yytext, Tipo("double")); return TK_CDOUBLE; }
.          { yylval = Atributos(yytext); return *yytext;                    }

%%
