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
};
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
%token TK_INT TK_CHAR TK_DOUBLE TK_STRING TK_BOOL TK_VOID
%token TK_MAIN TK_BEGIN TK_END TK_ID TK_CINT TK_CDOUBLE TK_CSTRING TK_RETURN TK_ATRIB
%token TK_WRITE TK_READ
%token TK_G TK_L TK_GE TK_LE TK_DIFF TK_IF TK_ELSE TK_E TK_AND TK_OR TK_NOT
%token TK_FOR TK_WHILE TK_DO
%left TK_AND TK_OR
%nonassoc TK_G TK_L TK_GE TK_LE TK_ATRIB TK_DIFF TK_E
%left '+' '-'
%left '*' '/'
%%
S : DECLS MAIN
  ;
MAIN : TK_MAIN BLOCO
     |
     ;
DECLS : DECLS DECL
      |
      ;
DECL : VAR ';' // var globais
     | FUNCAO
     ;
// permite tipo var1, var2, var3 e tipo var1 = expr; mas nao tipo var1 = expr, var2;
VAR : TIPO VAR_DEFS
    | TIPO ATRIBS
    ;
// permite coisas como a, b, c, d na declaracao de uma variavel
VAR_DEFS : VAR_DEF ',' VAR_DEFS
         | VAR_DEF
         ;
VAR_DEF  : TK_ID
         | TK_ID '[' E ']'
         ;
ATRIBS : VAR_DEF TK_ATRIB E
       |
       ;
TIPO : TK_INT
     | TK_CHAR
     | TK_DOUBLE
     | TK_STRING
     | TK_BOOL
     | TK_VOID
     //| TK_ID  //necessario se formos implementar tipos nao basicos como Vector ou struct
     ;
FUNCAO : TIPO TK_ID '(' F_PARAMS ')' BLOCO
       ;
F_PARAMS : PARAMS
        |
        ;
PARAMS : PARAMS ',' PARAM
       | PARAM
       ;
PARAM : TIPO TK_ID
      | TIPO TK_ID '[' E ']'
      | TIPO TK_ID '[' ']' //provavelmente necessario para declarar intero a[]
      ;
BLOCO : TK_BEGIN CMDS TK_END
      ;
CMDS : CMD ';' CMDS
     |
     ;
CMD : CMD_REVELA
    | CMD_DESCOBRE
    | CMD_RETURN
    | CMD_CALL
    | ATRIBS   // atribuicoes locais
    | VAR     //var locais
    ;
// precisa adicionar IF, WHILE, DO, FOR aqui, porem nao pode ser CMD pq nao tem ;
CMD_REVELA : TK_WRITE '(' E ')'
           ;
CMD_DESCOBRE : TK_READ '(' E ')'
             ;
CMD_RETURN : TK_RETURN
           | TK_RETURN E
           ;
// definindo a call de uma funcao
CMD_CALL : TK_ID '(' CALL_PARAMS ')' //chama uma funcao, precisa verificar se foi definida!
         ;
CALL_PARAMS : C_PARAMS | ;
C_PARAMS : C_PARAMS ',' C_PARAM
         | C_PARAM
         ;
C_PARAM : TK_ID
        | TK_ID '[' E ']'
        ;
E : E '+' E
  | E '-' E
  | E '*' E
  | E '/' E
  | '(' E ')'
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
