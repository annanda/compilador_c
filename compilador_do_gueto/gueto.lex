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

%{
#include <stdio.h>

void count(int c);
%}


{LINHA}    { nlinha++; count(0); }
{DELIM}    { count(1);           }
{COMMENT}  {}

{T}        { count(1); return TK_TRUE;   }
{F}        { count(1); return TK_FALSE;  }

"xar"      { count(1); return TK_CHAR;   }
"intero"   { count(1); return TK_INT;    }
"daboul"   { count(1); return TK_DOUBLE; }
"cadea"    { count(1); return TK_STRING; }
"bul"      { count(1); return TK_BOOL;   }
"nada"     { count(1); return TK_VOID;   }

"{"        { count(1); yylval = Atributos(yytext); return TK_BEGIN;  }
"}"        { count(1); yylval = Atributos(yytext); return TK_END;    }
"mano"     { count(1); yylval = Atributos(yytext); return TK_MAIN;   }
"flwvlw"   { count(1); yylval = Atributos(yytext); return TK_RETURN; }
"revela"   { count(1); yylval = Atributos(yytext); return TK_WRITE;  }
"descobre" { count(1); yylval = Atributos(yytext); return TK_READ;   }
"se"       { count(1); yylval = Atributos(yytext); return TK_IF;     }
"senao"    { count(1); yylval = Atributos(yytext); return TK_ELSE;   }
"pra"      { count(1); yylval = Atributos(yytext); return TK_FOR;    }
"enquanto" { count(1); yylval = Atributos(yytext); return TK_WHILE;  }
"fassa"    { count(1); yylval = Atributos(yytext); return TK_DO;     }
"qqtuqr"   { count(1); yylval = Atributos(yytext); return TK_SWITCH; }
"cabou"    { count(1); yylval = Atributos(yytext); return TK_BREAK;  }
"essi"     { count(1); yylval = Atributos(yytext); return TK_CASE;   }
"padraum"  { count(1); yylval = Atributos(yytext); return TK_DEFAULT;}
"em"       { count(1); yylval = Atributos(yytext); return TK_IN;     }

"&"       { count(1); yylval = Atributos(yytext); return TK_REF; }
"="       { count(1); yylval = Atributos(yytext); return TK_ATRIB; }
"<="      { count(1); yylval = Atributos(yytext); return TK_LE;    }
">="      { count(1); yylval = Atributos(yytext); return TK_GE;    }
"<>"      { count(1); yylval = Atributos(yytext); return TK_DIFF;  }
"=="      { count(1); yylval = Atributos(yytext); return TK_E;     }
"<"       { count(1); yylval = Atributos(yytext); return TK_L;     }
">"       { count(1); yylval = Atributos(yytext); return TK_G;     }
"e"       { count(1); yylval = Atributos(yytext); return TK_AND;   }
"ou"      { count(1); yylval = Atributos(yytext); return TK_OR;    }
"naum"    { count(1); yylval = Atributos(yytext); return TK_NOT;   }
"modis"   { count(1); yylval = Atributos(yytext); return TK_MOD;   }

{CSTRING}  { count(1); yylval = Atributos(yytext, Tipo("string")); return TK_CSTRING; }
{CCHAR}    { count(1); yylval = Atributos(yytext, Tipo("char"));   return TK_CCHAR;   }

{ID}       { count(1); yylval = Atributos(renomeia_variavel_usuario(yytext));
              return TK_ID;                                                 }
{INT}      { count(1); yylval = Atributos(yytext, Tipo("int")); return TK_CINT;       }
{DOUBLE}   { count(1); yylval = Atributos(yytext, Tipo("double")); return TK_CDOUBLE; }
.          { count(1); yylval = Atributos(yytext); return *yytext;                    }

%%

void count(int c){
    nColuna = (nColuna + yyleng) * c;
}
