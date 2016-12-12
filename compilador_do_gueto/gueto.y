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

  // Cria variavel basica
  Tipo (string tipo){
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
%token TK_MAIN TK_BEGIN TK_END TK_ID TK_CINT TK_CDOUBLE
%token TK_CSTRING TK_RETURN TK_ATRIB
%token TK_WRITE TK_READ
%token TK_G TK_L TK_GE TK_LE TK_DIFF TK_IF TK_ELSE
%token TK_E TK_AND TK_OR TK_NOT
%token TK_FOR TK_WHILE TK_DO

%left TK_AND TK_OR
%nonassoc TK_G TK_L TK_GE TK_LE TK_ATRIB TK_DIFF TK_E
%left '+' '-'
%left '*' '/'

%%

S : DECLS MAIN
    {
      cout << includes << endl;
      cout << $1.codigo << endl;
      cout << $2.codigo << endl;
    }
  ;

MAIN  : TK_MAIN BLOCO
        {
          $$.codigo = "int main()" + $2.codigo;
        }
      |
      ;

DECLS : DECLS DECL
      |
      ;

DECL : VAR ';' // Variaveis globais
     | FUNCAO
     ;

// Permite tipo var1, var2, var3 e tipo var1 = expr;
// mas nao tipo var1 = expr, var2;
VAR : TIPO VAR_DEFS
      {
        $$.codigo = "  " + $1.valor + " " + $2.codigo;
      }
    | TIPO ATRIBS
    ;

// Permite declaracoes como tipo a, b, c, d;
VAR_DEFS  : VAR_DEF ',' VAR_DEFS
            {
              $$.codigo = $1.codigo + ", " + $3.codigo;
            }
          | VAR_DEF
            {
              $$.codigo = $1.codigo;
            }
          ;

VAR_DEF   : TK_ID
            {
              $$.codigo = $1.valor;
            }
          | TK_ID '[' E ']'
          ;

ATRIBS : VAR_DEF TK_ATRIB E
       |
       ;

TIPO  : TK_INT
        {
          Tipo t("i");
          $$ = Atributos("int", t);
        }
      | TK_CHAR
      | TK_DOUBLE
      | TK_STRING
      | TK_BOOL
      | TK_VOID
      //| TK_ID
      // Necessario se formos implementar tipos nao basicos
      // e.g., Vector, Struct
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
      | TIPO TK_ID '[' ']'
      // Provavelmente necessario para declarar intero a[]
      ;

BLOCO : TK_BEGIN CMDS TK_END
        {
          $$.codigo = "{\n" + $2.codigo + "}\n";
        }
      ;

CMDS  : CMD ';' CMDS
        {
          $$.codigo = $1.codigo + ";\n" + $3.codigo;
        }
      | { $$ = Atributos(); }
      ;

CMD : CMD_REVELA
    | CMD_DESCOBRE
    | CMD_RETURN
    | CMD_CALL
    | ATRIBS   // Atribuicoes locais
    | VAR { $$ = $1; }    // Variaveis locais
    ;

// Precisa adicionar IF, WHILE, DO, FOR aqui
// Porem nao pode ser CMD pq nao tem ;

CMD_REVELA : TK_WRITE '(' E ')'
           ;

CMD_DESCOBRE : TK_READ '(' E ')'
             ;

CMD_RETURN : TK_RETURN
           | TK_RETURN E
           ;

// Definindo a call de uma funcao
CMD_CALL : TK_ID '(' CALL_PARAMS ')'
// Chama uma funcao, precisa verificar se foi definida!
         ;

CALL_PARAMS : C_PARAMS
            |
            ;

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