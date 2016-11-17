%{
#include <string>
#include <iostream>
#include <vector>
#include <stdio.h>
#include <stdlib.h>
#include <map>

using namespace std;

int yylex();
void yyerror( const char* st );

map< string, string > tipo_opr;

struct Atributos {
  string v, t, c; // Valor, tipo e código gerado.
  vector<string> lista; // Uma lista auxiliar.
  
  Atributos() {} // Constutor vazio
  Atributos( string valor ) {
    v = valor;
  }

  Atributos( string valor, string tipo ) {
    v = valor;
    t = tipo;
  }
};

// Declarar todas as funções que serão usadas.
string consulta_ts( string nome_var );
string gera_nome_var_temp( string tipo );

string includes = 
"#include <iostream>\n"
"#include <stdio.h>\n"
"#include <stdlib.h>\n";
//"\n"
//"using namespace std;\n";


#define YYSTYPE Atributos

%}

%token TK_ID TK_CINT TK_CDOUBLE TK_VAR TK_PROGRAM TK_BEGIN TK_END TK_ATRIB
%token TK_WRITELN TK_CSTRING

%left '+' '-'
%left '*' '/'

%%

S : PROGRAM DECLS MAIN 
    {
      cout << includes << endl;
      cout << $2.c << endl;
      cout << $3.c << endl;
    }
  ;
  
PROGRAM : TK_PROGRAM TK_ID ';' 
        ; 
  
DECLS : DECL DECLS
      | 
      ;  

DECL : TK_VAR VARS
     ;
     
VARS : VAR ';' VARS
     | 
     ;     
     
VAR : IDS ':' TK_ID
    ;
    
IDS : IDS ',' TK_ID 
      { $$  = $1;
        $$.lista.push_back( $3.v ); }
    | TK_ID 
      { $$ = Atributos();
        $$.lista.push_back( $1.v ); }
    ;          

MAIN : BLOCO '.'
       { $$.c = "int main()\n" + $1.c; } 
     ;
     
BLOCO : TK_BEGIN CMDS TK_END
        { $$.c = "{\n" + $2.c + "}\n"; }
      ;  
      
CMDS : CMD CMDS
       { $$.c = $1.c + $2.c; }
     |
     ;  
     
CMD : WRITELN
    | ATRIB 
    ;     

WRITELN : TK_WRITELN '(' E ')' ';'
        ;
  
ATRIB : TK_ID TK_ATRIB E ';'
        { $$.c = "  " + $1.v + " = " + $3.v + ";\n"; } 
      ;   

E : E '+' E
  | E '-' E
  | E '*' E
    { $$.t = tipo_opr[ $1.t + "*" + $3.t ]; 
      $$.v = gera_nome_var_temp( $$.t );
      $$.c = "  " + $$.v + " = " + $1.v + "*" + $3.v + ";\n"; 
      cerr << "Debug: " << $$.t << endl;
      cerr << "Debug: " << $$.v << endl;
      cerr << "Debug: " << $$.c << endl;
    }
  | E '/' E
  | '(' E ')'
  | F
  ;
  
F : TK_ID 
    { $$.v = $1.v; $$.t = consulta_ts( $1.v ); $$.c = $1.c; };
  | TK_CINT 
    { $$.v = $1.v; $$.t = "i"; $$.c = $1.c; };
  | TK_CDOUBLE
    { $$.v = $1.v; $$.t = "d"; $$.c = $1.c; };
  | TK_CSTRING
    { $$.v = $1.v; $$.t = "s"; $$.c = $1.c; };
  ;
  
%%
int nlinha = 1;

#include "lex.yy.c"

int yyparse();

void yyerror( const char* st )
{
  puts( st );
  printf( "Linha: %d, [%s]\n", nlinha, yytext );
}

void inicializa_operadores() {
  // Resultados para o operador "+"
  tipo_opr["i+i"] = "i";
  tipo_opr["i+d"] = "d";
  tipo_opr["d+i"] = "d";
  tipo_opr["d+d"] = "d";
  tipo_opr["s+s"] = "s";
  tipo_opr["c+s"] = "s";
  tipo_opr["s+c"] = "s";
  tipo_opr["c+c"] = "s";
 
  // Resultados para o operador "*"
  tipo_opr["i*i"] = "i";
  tipo_opr["i*d"] = "d";
  tipo_opr["d*i"] = "d";
  tipo_opr["d*d"] = "d";
}

string consulta_ts( string nome_var ) {
  // fake. Deveria ser ts[nome_var], onde ts é um map.
  // Antes de retornar, tem que verificar se a variável existe.
  return "i";
}

string gera_nome_var_temp( string tipo ) {
  // fake. Tem que incrementar um contador.
  return "ti_1";
}

int main( int argc, char* argv[] )
{
  inicializa_operadores();
  yyparse();
}
