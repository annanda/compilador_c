%{
#include <string>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <map>
#include <vector>

using namespace std;
#define MAX_DIM 2

int yylex();
void yyerror( const char* st );

struct Tipo {
  string tipo_base;
  int ndim;
  int tam[MAX_DIM];

  Tipo(){}

  Tipo (string tipo){ //cria uma var que nao e array
    tipo_base = tipo;
    ndim = 0;
  }

  Tipo (string tipo, int i){
    tipo_base = tipo;
    ndim = 1;
    this->tam[0] = i;
  }

  Tipo (string tipo, int i, int j){
    tipo_base = tipo;
    ndim = 2;
    this->tam[0] = i;
    this->tam[1] = j;
  }
}

struct Atributos {
  string valor, codigo;
  Tipo tipo;
  vector<string> lista;

  Atributos(){}

  Atributos( string v ){
    this->valor = v;
  }

  Atributos( string v, Tipo t ){
    this->valor = v;
    this->tipo = t;
  }
};

string includes =
    "#include <iostream>\n"
    "#include <stdio.h>\n"
    "#include <stdlib.h>\n"
    "#include <string.h>\n"
    "\n"
    "using namespace std;\n";

#define YYSTYPE Atributos

%}

%token TK_BEGIN TK_END TK_ID TK_CINT TK_CDOUBLE TK_RETURN TK_ATRIB
%token TK_WRITE TK_READ
%token TK_G TK_L TK_GE TK_LE TK_DIFF TK_IF TK_E TK_AND TK_OR
%token TK_FOR TK_WHILE TK_DO

%left TK_AND TK_OR
%nonassoc TK_G TK_L TK_GE TK_LE TK_ATRIB TK_DIFF TK_E
%left '+' '-'
%left '*' '/'

%%

S : DECLS MAIN
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

IDS : TK_ID ',' IDS
    | TK_ID
    ;

MAIN : BLOCO '.'
     ;

BLOCO : TK_BEGIN CMDS TK_END
      ;

CMDS : CMD CMDS
     |
     ;

CMD : WRITELN
    | ATRIB
    ;

WRITELN : TK_WRITELN '(' E ')' ';'
        ;

ATRIB : TK_ID TK_ATRIB E ';'
      ;

E : E '+' E
  | E '-' E
  | E '*' E
  | E '/' E
  | E TK_G E
  | E TK_L E
  | E TK_LE E
  | E TK_GE E
  | E TK_ATRIB E
  | E TK_E E
  | E TK_DIFF E
  | E TK_AND E
  | E TK_OR E
  | '(' E ')'
  | TK_NOT E
  | F
  ;

F : TK_ID
  | TK_CINT
  | TK_CDOUBLE
  | TK_CSTRING
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

int main( int argc, char* argv[] )
{
  yyparse();
}
