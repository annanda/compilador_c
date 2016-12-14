%{
#include <string>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <map>
#include <vector>

using namespace std;

#define MAX_DIM 2
#define MAX_STRING_SIZE 256

struct Tipo;
struct Atributos;

int yylex();

void yyerror(const char* st);
void erro(string msg);
void inicializa_operadores();
void insere_ts(string nome, Tipo tipo);

Tipo consulta_ts(string nome);

string toString(int n);
string declara_variavel(string nome, Tipo tipo);
string traduz_interno_para_C(string interno);
string traduz_gueto_para_interno(string gueto);
string traduz_interno_para_gueto(string interno);
string renomeia_variavel_usuario(string nome);
string gera_nome_var_temp(string tipo_interno);
string atribuicao_var(Atributos s1, Atributos s3);

int is_atribuivel(Atributos s1, Atributos s3);

Atributos gera_codigo_operador(Atributos s1, string opr, Atributos s3);

map<string, Tipo> ts;
// Pilha de variaveis (temporarias ou definidas pelo usuario)
// que vao ser declaradas no inicio de cada bloco.
vector<string> vars_bloco;
// Faz o mapeamento dos tipos dos operadores
map<string, string> tipo_opr;


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
        // Os nomes das variaveis estao na lista_str de $2.
        // Cada variavel e' inserida na tabela de simbolos e
        // sua declaracao e' adicionada a lista de declaracao
        // do bloco atual, que so sera impressa no inicio do bloco.
        for(vector<string>::iterator it = $2.lista_str.begin();
                                     it != $2.lista_str.end();
                                     it++){
          vars_bloco[vars_bloco.size()-1] += "  "
                                          + (declara_variavel(*it, $1.tipo))
                                          + ";\n";
          insere_ts(*it, $1.tipo);
        }
      }
    | TIPO ATRIB
      {
        // Aqui podemos fazer apenas a atribuicao, uma vez que
        // as variaveis sejam adequadamente declaradas no inicio
        // do bloco.
        // Problema encontrado: nao temos como saber dentro da producao
        // de ATRIB se a variavel ja era para ter sido declarada.
        // Provavelmente nao poderemos usar ATRIB aqui.
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

ATRIB : TK_ID TK_ATRIB E
        {
          $1.tipo = consulta_ts($1.valor);
          $$.codigo = atribuicao_var($1, $3);
        }
      | TK_ID '[' E ']' TK_ATRIB E
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
          Tipo t("s", MAX_STRING_SIZE);
          $$ = Atributos("char[]", t);
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

BLOCO : TK_BEGIN { vars_bloco.push_back(""); } CMDS TK_END
        {
          $$.codigo = "{\n";
          // Adiciona as variaveis desse bloco ao inicio do mesmo e
          // desempilha a lista de variaveis desse bloco.
          $$.codigo += vars_bloco[vars_bloco.size()-1];
          vars_bloco.pop_back();
          $$.codigo += $3.codigo + "}\n";
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
    {
      $$ = gera_codigo_operador($1, "+", $3);
    }
  | E '-' E
  | E '*' E
  | E '/' E
  | '(' E ')'
  | F
  ;

F : TK_ID
    {
      $$.valor = $1.valor;
      $$.tipo = consulta_ts($1.valor);
      $$.codigo = $1.codigo;
    }
  | TK_CINT
    {
      $$.valor = $1.valor;
      $$.tipo = Tipo("i");
      $$.codigo = $1.codigo;
    }
  | TK_CDOUBLE
    {
      $$.valor = $1.valor;
      $$.tipo = Tipo("d");
      $$.codigo = $1.codigo;
    }
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

void inicializa_operadores() {
  // Operador +
  // TODO(jullytta): operacoes com char,
  // concatenar int/double/char com string
  tipo_opr["i+i"] = "i";
  tipo_opr["i+d"] = "d";

  tipo_opr["d+i"] = "d";
  tipo_opr["d+d"] = "d";

  tipo_opr["s+s"] = "s";

}

void insere_ts(string nome, Tipo tipo){
  if(ts.find(nome) != ts.end()){
    erro("Variavel ja declarada: " + nome);
  }
  ts[nome] = tipo;
}

Tipo consulta_ts(string nome) {
  if(ts.find(nome) == ts.end()){
    erro("Variavel nao declarada: " + nome);
  }
  return ts[nome];
}

string toString(int n){
  char buff[100];

  sprintf(buff, "%d", n);

  return buff;
}

string declara_variavel(string nome, Tipo tipo){
  if(tipo.tipo_base == "s")
    return "char " + nome + "[" + toString(MAX_STRING_SIZE) + "]";
  return traduz_interno_para_C(tipo.tipo_base) + " " + nome;
}

string traduz_interno_para_C(string interno){
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
  erro("Bug no compilador! Tipo interno inexistente: " + interno);
  return "";
}

string traduz_gueto_para_interno(string gueto){
  if(gueto == "xar")
    return "c";
  if(gueto == "intero")
    return "i";
  if(gueto == "daboul")
    return "d";
  if(gueto == "cadea")
    return "s";
  if(gueto == "bul")
    return "b";
  if(gueto == "nada")
    return "v";
  erro("Bug no compilador! Tipo em gueto inexistente: " + gueto);
  return "";
}

string traduz_interno_para_gueto(string interno){
  if(interno == "i")
    return "intero";
  if(interno == "c")
    return "xar";
  if(interno == "b")
    return "bul";
  if(interno == "d")
    return "daboul";
  if(interno == "v")
    return "nada";
  if(interno == "s")
    return "cadea";
  erro("Bug no compilador! Tipo interno inexistente: " + interno);
  return "";
}

string renomeia_variavel_usuario(string nome){
  return "_" + nome;
}

string gera_nome_var_temp(string tipo_interno){
  static int n = 1;
  string nome = "t" + tipo_interno + "_" + toString(n++);

  vars_bloco[vars_bloco.size()-1] += "  "
                                  + declara_variavel(nome, Tipo(tipo_interno))
                                  + ";\n";

  return nome;
}

string atribuicao_var(Atributos s1, Atributos s3){
  if (is_atribuivel(s1, s3) == 1){
    if (s1.tipo.tipo_base == "s"){
       //lidarei com strings depois
    }else{
      return s3.codigo + "  " + s1.valor + " = " + s3.valor + ";\n";
    }
  }else{
    // melhorar esse erro
    erro("Atribuicao nao permitida!");
  }
}

int is_atribuivel(Atributos s1, Atributos s3){
  // dummy code enquanto essa funcao nao esta pronta
  return 1;

  // precisa gerar o codigo das expressoes para isso funcionar
  // essa nao pode ser a unica condicao
  if (s1.tipo.tipo_base == s3.tipo.tipo_base){
    return 1;
  }
  return 0;
}

Atributos gera_codigo_operador(Atributos s1, string opr, Atributos s3){
  Atributos ss;

  string tipo1 = s1.tipo.tipo_base;
  string tipo3 = s3.tipo.tipo_base;
  string tipo_resultado = tipo_opr[tipo1 + opr + tipo3];

  // TODO(jullytta): conferir se tratamos de vetores aqui,
  // ou de strings.
  if(tipo_resultado == "")
    erro("Operacao nao permitida. "
       + traduz_interno_para_gueto(tipo1)
       + " " + opr + " "
       + traduz_interno_para_gueto(tipo3));

  ss.valor = gera_nome_var_temp(tipo_resultado);
  ss.tipo = Tipo(tipo_resultado);

  ss.codigo = s1.codigo + s3.codigo
            + "  " + ss.valor + " = "
            + s1.valor + " " + opr + " " + s3.valor
            + ";\n";

  return ss;
}


int main(int argc, char* argv[]){
  inicializa_operadores();
  yyparse();
}
