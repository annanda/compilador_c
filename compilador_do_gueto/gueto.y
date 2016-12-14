%{
#include <string>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <map>
#include <vector>

using namespace std;

#define MAX_DIM 2

struct Tipo;

int yylex();

void yyerror(const char* st);
void erro(string msg);
void insere_ts(string nome, Tipo tipo);

string declara_variavel(string nome, Tipo tipo);
string traduz_interno_para_C(string interno);
string traduz_gueto_para_interno(string gueto);

map<string, Tipo> ts;

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
  vector<string> lista_str;

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
        $$.codigo = "";
        // Aqui precisamos iterar sobre a lista_str de $2,
        // declarar cada variável e inseri-las na tabela
        // de simbolos.
        // Idealmente nao declarariamos as variaveis direto, mas
        // sim colocariamos elas numa lista para serem declaradas
        // no inicio do bloco.
        for(vector<string>::iterator it = $2.lista_str.begin();
                                     it != $2.lista_str.end();
                                     it++){
          $$.codigo += "  " + declara_variavel(*it, $1.tipo) + ";\n";
          insere_ts(*it, $1.tipo);
        }
      }
    | TIPO ATRIB
      {
        // Aqui podemos fazer apenas a atribuicao, uma vez que
        // as variaveis sejam adequadamente declaradas no inicio
        // do bloco.
      }
    ;

// Permite declaracoes como tipo a, b, c, d;
VAR_DEFS  : VAR_DEF ',' VAR_DEFS
            {
              $$.lista_str.push_back($1.valor);
              $$.lista_str.insert($$.lista_str.end(),
                                  $3.lista_str.begin(),
                                  $3.lista_str.end());
            }
          | VAR_DEF
            {
              $$.lista_str.push_back($1.valor);
            }
          ;

VAR_DEF   : TK_ID
            {
              $$.valor = $1.valor;
            }
          | TK_ID '[' E ']'
          ;

ATRIB : VAR_DEF TK_ATRIB E
       |
       ;

TIPO  : TK_INT
        {
          Tipo t("i");
          $$ = Atributos("int", t);
        }
      | TK_CHAR
        {
          Tipo t("c");
          $$ = Atributos("char", t);
        }
      | TK_DOUBLE
        {
          Tipo t("d");
          $$ = Atributos("double", t);
        }
      | TK_STRING
        {
          // TODO(jullytta): lidar com strings
        }
      | TK_BOOL
        {
          Tipo t("b");
          $$ = Atributos("int", t);
        }
      | TK_VOID
        {
          Tipo t("v");
          $$ = Atributos("void", t);
        }
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
          $$.codigo = $1.codigo + $3.codigo;
        }
      | { $$ = Atributos(); }
      ;

CMD : CMD_REVELA
    | CMD_DESCOBRE
    | CMD_RETURN
    | CMD_CALL
    | ATRIB   // Atribuicoes locais
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

void yyerror(const char* st){
  puts( st );
  printf( "Linha: %d, [%s]\n", nlinha, yytext );
}

void erro(string msg){
  cerr << "Erro: " << msg << endl;
  fprintf(stderr, "Linha: %d, [%s]\n", nlinha, yytext );
  exit(1);
}

void insere_ts(string nome, Tipo tipo){
  if(ts.find(nome) != ts.end()){
    erro("Variavel ja declarada: " + nome);
  }
  ts[nome] = tipo;
}

string declara_variavel(string nome, Tipo tipo){
  return traduz_interno_para_C(tipo.tipo_base) + " " + nome;
}

string traduz_interno_para_C(string interno){
  // TODO(jullytta): lidar com strings
  if(interno == "i")
    return "int";
  if(interno == "c")
    return "char";
  if(interno == "b")
    return "int";
  if(interno == "d")
    return "double";
  if(interno == "v")
    return "void";
  erro("Bug no compilador. Tipo interno inexistente.");
  return "";
}

string traduz_gueto_para_interno(string gueto){
  if(gueto == "intero")
    return "i";
}

int main(int argc, char* argv[]){
  yyparse();
}
