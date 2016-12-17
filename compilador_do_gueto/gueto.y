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
string leitura_padrao(Atributos s3);
string gera_label(string tipo);
string desbloquifica(string lexema);

int is_atribuivel(Atributos s1, Atributos s3);
int toInt(string valor);

Atributos gera_codigo_operador(Atributos s1, string opr, Atributos s3);
Atributos gera_codigo_if(Atributos expr,
                         Atributos bloco_if,
                         Atributos bloco_else);
Atributos gera_codigo_while(Atributos expr, Atributos bloco);

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

%token TK_INT TK_CHAR TK_DOUBLE TK_STRING TK_BOOL TK_VOID TK_TRUE TK_FALSE
%token TK_MAIN TK_BEGIN TK_END TK_ID TK_CINT TK_CDOUBLE
%token TK_CSTRING TK_RETURN TK_ATRIB TK_CCHAR
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

SUB_BLOCO : TK_BEGIN CMDS TK_END
            {
              $$.codigo = "{\n";
              $$.codigo += $2.codigo + "}\n";
            }
          ;

CMDS  : CMD CMDS
        {
          $$.codigo = $1.codigo + $2.codigo;
        }
      | { $$ = Atributos(); }
      ;

CMD : CMD_REVELA ';'
    | CMD_DESCOBRE ';'
    | CMD_RETURN ';'
    | CMD_CALL ';'
    | CMD_IF       // nao tem ponto e virgula
    | CMD_FOR
    | CMD_WHILE
    | ATRIB ';'   // Atribuicoes locais
    | VAR ';'  { $$ = $1; }    // Variaveis locais
    ;

// Precisa adicionar IF, WHILE, DO, FOR aqui
// Porem nao pode ser CMD pq nao tem ;

CMD_REVELA : TK_WRITE '(' E ')'
             {
               $$.codigo = $3.codigo +
                     "  cout << " + $3.valor + ";\n"
                     "  cout << endl;\n";
             }
           ;

CMD_DESCOBRE : TK_READ '(' TK_ID ')'
               {
                 $3.tipo = consulta_ts($3.valor);
                 $$.codigo = leitura_padrao($3);
               }
             ;

// tipo da pra dar flwvlw em qualquer parte do codigo
// porem o gabarito do zimbrao aceita return em qualquer parte do codigo
CMD_RETURN : TK_RETURN
             {
               $$.codigo = $1.codigo + "  return 0;\n";
             }
           | TK_RETURN E
             {
               $$.codigo = $1.codigo + $2.codigo + "  return "+ $2.valor +";\n";
             }
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

CMD_IF : TK_IF '(' E ')' SUB_BLOCO
         {
           $$ = gera_codigo_if($3, $5, Atributos());
         }
       | TK_IF '(' E ')' SUB_BLOCO TK_ELSE SUB_BLOCO
         {
           $$ = gera_codigo_if($3, $5, $7);
         }
       ;

CMD_FOR : TK_FOR '(' TK_INT TK_ID TK_ATRIB E ';' E ';' TK_ID TK_ATRIB E ')' SUB_BLOCO
        ;

CMD_WHILE : TK_WHILE '(' E ')' SUB_BLOCO
            {
              $$ = gera_codigo_while($3, $5);
            }
          ;

E : E '+' E
    {
      $$ = gera_codigo_operador($1, "+", $3);
    }
  | E '-' E
    {
      $$ = gera_codigo_operador($1, "-", $3);
    }
  | E '*' E
    {
      $$ = gera_codigo_operador($1, "*", $3);
    }
  | E '/' E
    {
      $$ = gera_codigo_operador($1, "/", $3);
    }
  | E TK_G E
    {
      $$ = gera_codigo_operador($1, ">", $3);
    }
  | E TK_L E
    {
      $$ = gera_codigo_operador($1, "<", $3);
    }
  | E TK_GE E
    {
      $$ = gera_codigo_operador($1, ">=", $3);
    }
  | E TK_LE E
    {
      $$ = gera_codigo_operador($1, "<=", $3);
    }
  | E TK_DIFF E
    {
      $$ = gera_codigo_operador($1, "!=", $3);
    }
  | E TK_E E
    {
      $$ = gera_codigo_operador($1, "==", $3);
    }
  | '(' E ')'
    {
      $$ = $2;
    }
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
  | TK_CCHAR
    {
      $$.valor = $1.valor;
      $$.tipo = Tipo("c");
      $$.codigo = $1.codigo;
    }
  | TK_CSTRING
    {
      $$.valor = $1.valor;
      $$.tipo = Tipo("s");
      $$.codigo = $1.codigo;
    }
  | BOOL
  ;

BOOL : TK_TRUE
      {
        $$.valor = "1";
        $$.tipo = Tipo("b");
        $$.codigo = $1.codigo;
      }
     | TK_FALSE
      {
        $$.valor = "0";
        $$.tipo = Tipo("b");
        $$.codigo = $1.codigo;
      }
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
  // TODO(jullytta): operacoes com char,
  // concatenar int/double/char com string

  // Operador +
  tipo_opr["i+i"] = "i";
  tipo_opr["i+d"] = "d";
  tipo_opr["d+i"] = "d";
  tipo_opr["d+d"] = "d";
  tipo_opr["s+s"] = "s";

  // Operador -
  tipo_opr["i-i"] = "i";
  tipo_opr["i-d"] = "d";
  tipo_opr["d-i"] = "d";
  tipo_opr["d-d"] = "d";

  // Operador *
  tipo_opr["i*i"] = "i";
  tipo_opr["i*d"] = "d";
  tipo_opr["d*i"] = "d";
  tipo_opr["d*d"] = "d";

  // Operador /
  // TODO(jullytta): lidar com a polemica desse operador
  tipo_opr["i/d"] = "d";
  tipo_opr["i/i"] = "i";
  tipo_opr["d/i"] = "d";
  tipo_opr["d/d"] = "d";

  // TODO(jullytta): comparacao de strings
  // Operadores: <>, ==, >, <, <=, >=
  // Operador >
  tipo_opr["i>i"] = "b";
  tipo_opr["i>d"] = "b";
  tipo_opr["d>i"] = "b";
  tipo_opr["d>d"] = "b";
  tipo_opr["c>c"] = "b";
  tipo_opr["i>c"] = "b";
  tipo_opr["c>i"] = "b";

  // Operador <
  tipo_opr["i<i"] = "b";
  tipo_opr["i<d"] = "b";
  tipo_opr["d<i"] = "b";
  tipo_opr["d<d"] = "b";
  tipo_opr["c<c"] = "b";
  tipo_opr["i<c"] = "b";
  tipo_opr["c<i"] = "b";

  // Operador >=
  tipo_opr["i>=i"] = "b";
  tipo_opr["i>=d"] = "b";
  tipo_opr["d>=i"] = "b";
  tipo_opr["d>=d"] = "b";
  tipo_opr["c>=c"] = "b";
  tipo_opr["i>=c"] = "b";
  tipo_opr["c>=i"] = "b";

  // Operador <=
  tipo_opr["i<=i"] = "b";
  tipo_opr["i<=d"] = "b";
  tipo_opr["d<=i"] = "b";
  tipo_opr["d<=d"] = "b";
  tipo_opr["c<=c"] = "b";
  tipo_opr["i<=c"] = "b";
  tipo_opr["c<=i"] = "b";

  // Operador ==
  tipo_opr["i==i"] = "b";
  tipo_opr["i==d"] = "b";
  tipo_opr["d==i"] = "b";
  tipo_opr["d==d"] = "b";
  tipo_opr["c==c"] = "b";
  tipo_opr["i==c"] = "b";
  tipo_opr["c==i"] = "b";

  // Operador <>
  tipo_opr["i!=i"] = "b";
  tipo_opr["i!=d"] = "b";
  tipo_opr["d!=i"] = "b";
  tipo_opr["d!=d"] = "b";
  tipo_opr["c!=c"] = "b";
  tipo_opr["i!=c"] = "b";
  tipo_opr["c!=i"] = "b";

  // Operador =
  tipo_opr["i=i"] = "i";
  tipo_opr["b=b"] = "b";
  tipo_opr["b=i"] = "b";
  tipo_opr["d=d"] = "d";
  tipo_opr["d=i"] = "d";
  tipo_opr["c=c"] = "c";
  tipo_opr["s=s"] = "s";
  tipo_opr["s=c"] = "s";

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
       return s3.codigo + "  strncpy("+ s1.valor + ", " + s3.valor +", "
                        + toString(MAX_STRING_SIZE) + ");\n";
    } else if (s1.tipo.tipo_base == "b" && s3.tipo.tipo_base == "i") {
      string val = (s3.valor == "0" ? "0" : "1"); //lida com b=i
      return s3.codigo + "  " + s1.valor + " = " + val + ";\n";
    } else {
      return s3.codigo + "  " + s1.valor + " = " + s3.valor + ";\n";
    }
  } else{
    erro("Atribuicao nao permitida! "
          + traduz_interno_para_gueto(s1.tipo.tipo_base) + " = "
          + traduz_interno_para_gueto(s3.tipo.tipo_base));
  }
}

string leitura_padrao(Atributos s3){
  string codigo;
  // Usado para encontrar o pula linha que vem com fgets
  // e devidamente se livrar do mesmo.
  string indice_pula_linha = gera_nome_var_temp("i");
  if (s3.tipo.tipo_base == "s"){
    codigo = s3.codigo + "  fgets(" + s3.valor
                       + ", " + toString(MAX_STRING_SIZE) + ", stdin);\n"
                       + "  " + indice_pula_linha + " = strcspn(" + s3.valor
                       + ", \"\\n\");\n"
                       + "  " + s3.valor + "[" + indice_pula_linha
                       + "] = 0;\n";
  } else{
    codigo = s3.codigo + "  cin >> " + s3.valor +  ";\n";
  }
  return codigo;
}

string gera_label(string tipo){
  static int n = 0;
  string nome = "l_" + tipo + "_" + toString(++n);
  return nome;
}

string desbloquifica(string lexema){
  lexema[0] = ' '; //remove {
  lexema[lexema.size()-2] = ' '; // remove }
  return lexema;
}

int is_atribuivel(Atributos s1, Atributos s3){
  string key = s1.tipo.tipo_base + "=" + s3.tipo.tipo_base;
  if (tipo_opr.find(key) != tipo_opr.end()){
    return 1;
  }
  return 0;
}

int toInt(string valor) {
  int aux = -1;
  if( sscanf( valor.c_str(), "%d", &aux ) != 1 )
    erro( "Numero invalido: " + valor );
  return aux;
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

Atributos gera_codigo_if(Atributos expr,
                         Atributos bloco_if,
                        Atributos bloco_else){
  Atributos ss;
  string label_else = gera_label( "else" );
  string label_end = gera_label( "end" );
  string condicao_var = gera_nome_var_temp(expr.tipo.tipo_base);
  ss.codigo = expr.codigo + "  " + condicao_var
            + " = !" + expr.valor + ";\n\n"
            + "  if( " + condicao_var + " ) goto "
            + label_else + ";\n"
            + desbloquifica(bloco_if.codigo)
            + "  goto " + label_end + ";\n"
            + label_else + ":;\n"
            + desbloquifica(bloco_else.codigo)
            + label_end + ":;\n";
  return ss;
}

Atributos gera_codigo_while(Atributos expr, Atributos bloco){
  Atributos ss;
  string label_teste = gera_label( "teste_while" );
  string label_end = gera_label( "fim_while" );
  // o zizi coloca "b" ao inves de tipo_base, mas acho tipo_base melhor pra verificar erros
  string condicao_var = gera_nome_var_temp(expr.tipo.tipo_base);

  ss.codigo = label_teste + ":;\n"
            + expr.codigo + "  "
            + condicao_var + " = !" + expr.valor + ";\n\n"
            + "if ("+ condicao_var +") goto " + label_end
            + ";\n" + desbloquifica(bloco.codigo)
            + "goto " + label_teste + ";\n"
            + label_end + ":;\n"
            ;
  return ss;
}

int main(int argc, char* argv[]){
  inicializa_operadores();
  yyparse();
}
