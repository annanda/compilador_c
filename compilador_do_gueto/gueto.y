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
void empilha_ts();
void desempilha_ts();
void inicializa_operadores();
void inicializa_verificacao_tipos();
void insere_var_ts(string nome, Tipo tipo);
void insere_func_ts(string nome, Tipo tipo);

Tipo consulta_ts(string nome);

string toString(int n);
string declara_variavel(string nome, Tipo tipo);

string traduz_interno_para_C(string interno);
string traduz_gueto_para_interno(string gueto);
string traduz_interno_para_gueto(string interno);
string traduz_operador_C_para_gueto(string opr_c);

string renomeia_variavel_usuario(string nome);
string gera_nome_var_temp(string tipo_interno);
string gera_nome_var_temp_sem_declarar(string tipo_interno);
string gera_cabecalho_funcao(Tipo retorno,
                             string funcao,
                             vector<string> params,
                             vector<Tipo> tipos);
string atribuicao_var(Atributos s1, Atributos s3);
string atribuicao_array(Atributos id,
                        Atributos indice,
                        Atributos resultado);
string gera_codigo_atribuicao_string(Atributos id,
                                     Atributos indice,
                                     Atributos resultado);
string gera_codigo_acesso_string(Atributos id, Atributos indice, string nome);
string leitura_padrao(Atributos s3);
string gera_label(string tipo);
string desbloquifica(string lexema);
string testa_limites_array(Atributos id, Atributos indice);
string testa_limites_matriz(Atributos id,
                            Atributos indice1,
                            Atributos indice2);
string atributoToString(Atributos s, string buff);

int is_atribuivel(Atributos s1, Atributos s3);
int toInt(string valor);
int aceita_tipo(string opr, Atributos expr);

Atributos acessa_array(Atributos id, Atributos indice);
Atributos gera_codigo_operador(Atributos s1, string opr, Atributos s3);
Atributos gera_codigo_operador_unario(string opr, Atributos s2);
Atributos gera_codigo_if(Atributos expr,
                         Atributos bloco_if,
                         Atributos bloco_else);
Atributos gera_codigo_while(Atributos expr, Atributos bloco);
Atributos gera_codigo_do_while(Atributos bloco, Atributos expr);
Atributos gera_codigo_for(Atributos atrib,
                          Atributos condicao,
                          Atributos pulo,
                          Atributos bloco);
Atributos gera_codigo_casos(Atributos expr,
                            Atributos cmds, int tem_break);
Atributos gera_codigo_switch(Atributos cond, Atributos bloco);
Atributos atribuicao_var_global(Atributos tipo,
                                Atributos id,
                                string i,
                                string j);
Atributos gera_codigo_operador_in(Atributos var, Atributos vetor);
Atributos gera_operador_vetores(Atributos s1, string opr, Atributos s3);
Atributos gera_codigo_operador_strings(Atributos s1,
                                       string opr,
                                       Atributos s3);

// Pilha de tabelas de simbolos. Uma para cada escopo.
vector< map<string, Tipo> > ts;
// Pilha de variaveis (temporarias ou definidas pelo usuario)
// que vao ser declaradas no inicio de cada bloco.
vector<string> vars_bloco;
// Faz o mapeamento dos tipos dos operadores
map<string, string> tipo_opr;
// declara variaveis  globais
string vars_globais;
// declara as funcoes
string cabecalhos_funcao;
// faz a verificacao de tipos
map< string, vector<string> > tipo_expr;
// label de break do switch
string label_break = gera_label("break");
string label_passthrough = "";
// Compara o valor do switch com o valor do case
string compara_switch_var = "t_switch";

enum TIPO { FUNCAO = -1, BASICO = 0, VETOR = 1, MATRIZ = 2 };

struct Tipo {
  string tipo_base;
  TIPO ndim;
  int tam[MAX_DIM];
  vector<Tipo> retorno;
  vector<Tipo> params;

  Tipo(){}

  // Cria variavel basica
  Tipo (string tipo){
    tipo_base = tipo;
    ndim = BASICO;
  }

  Tipo (string tipo, int i){
    tipo_base = tipo;
    ndim = VETOR;
    this->tam[0] = i;
  }

  Tipo (string tipo, int i, int j){
    tipo_base = tipo;
    ndim = MATRIZ;
    this->tam[0] = i;
    this->tam[1] = j;
  }

  Tipo(Tipo retorno, vector<Tipo> params){
    ndim = FUNCAO;
    this->retorno.push_back(retorno);
    this->params = params;
  }
};

struct Atributos {
  string valor, codigo;
  Tipo tipo;
  vector<string> lista_str;
  vector<Tipo> lista_tipo;

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
%token TK_SWITCH TK_CASE TK_BREAK TK_DEFAULT
%token TK_IN

%left TK_OR
%left TK_AND
%nonassoc TK_G TK_L TK_GE TK_LE TK_ATRIB TK_DIFF TK_E
%left '+' '-'
%left '*' '/' TK_MOD TK_IN
%nonassoc TK_NOT

%%

S : { empilha_ts(); } DECLS MAIN
    {
      cout << includes << endl;
      cout << vars_globais << endl;
      cout << cabecalhos_funcao << endl;
      cout << $2.codigo << endl;
      cout << $3.codigo << endl;
    }
  ;

MAIN  : TK_MAIN { empilha_ts(); } BLOCO
        {
          $$.codigo += "int main()" + $3.codigo;
        }
      |
      ;

DECLS : DECLS DECL
        {
          $$ = Atributos();
          // Gambiarra para garantir que as variaveis globais
          // sejam impressas antes das funcoes.
          // TODO(jullytta): descobrir por que a linha abaixo
          // causa seg fault.
          $$.codigo = $1.codigo + "\n" + $2.codigo;
        }
      | {
          $$ = Atributos();
        }
      ;

DECL : GLOBAL_VAR ';' // Variaveis globais
     | FUNC
     ;

// nao dava para usar o VAR pq ta declarando so coisa no bloco
GLOBAL_VAR : TIPO NOME_VAR
             {
               $$ =  atribuicao_var_global($1, $2, "", "");
               $2.tipo = $1.tipo;
             }
           | TIPO NOME_VAR '[' TK_CINT ']'
             {
               $$ =  atribuicao_var_global($1, $2, $4.valor, "");
             }
           | TIPO NOME_VAR '[' TK_CINT ']' '[' TK_CINT ']'
             {
               $$ =  atribuicao_var_global($1, $2, $4.valor, $7.valor);
             }
           ;

// Permite tipo var1, var2, var3 e tipo var1 = expr;
// mas nao tipo var1 = expr, var2;
// Arrays devem ser declarados separadamente
// e.g. intero a[10]; daboul b[5][5];
VAR : TIPO VAR_DEFS
      {
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
          insere_var_ts(*it, $1.tipo);
        }
      }
    | TIPO NOME_VAR TK_ATRIB E
      {
        $$ = Atributos($2.valor, $1.tipo);
        vars_bloco[vars_bloco.size()-1] += "  "
                                        + declara_variavel($2.valor, $1.tipo)
                                        + ";\n";
        insere_var_ts($2.valor, $1.tipo);
        $2.tipo = $1.tipo;
        $$.codigo = atribuicao_var($2, $4);
      }
    | TIPO NOME_VAR '[' TK_CINT ']'
      {
        $$ = Atributos($2.valor, Tipo($1.tipo.tipo_base, toInt($4.valor)));
        vars_bloco[vars_bloco.size()-1] += "  "
                                        + declara_variavel($$.valor, $$.tipo)
                                        + ";\n";
        insere_var_ts($$.valor, $$.tipo);
      }
    | TIPO NOME_VAR '[' TK_CINT ']' '[' TK_CINT ']'
      {
        $$ = Atributos($2.valor, Tipo($1.tipo.tipo_base,
                                      toInt($4.valor),
                                      toInt($7.valor)));
        vars_bloco[vars_bloco.size()-1] += "  "
                                        + declara_variavel($$.valor, $$.tipo)
                                        + ";\n";
        insere_var_ts($$.valor, $$.tipo);
      }
    ;

// Permite declaracoes como tipo a, b, c, d;
VAR_DEFS  : NOME_VAR ',' VAR_DEFS
            {
              $$.lista_str.push_back($1.valor);
              $$.lista_str.insert($$.lista_str.end(),
                                  $3.lista_str.begin(),
                                  $3.lista_str.end());
            }
          | NOME_VAR
            {
              $$.lista_str.push_back($1.valor);
            }
          ;

NOME_VAR : TK_ID
           {
             // pro switch funcionar eu fiz isto!
             //compara_switch_var = gera_nome_var_temp("b");
             //$$.codigo = declara_variavel(compara_switch_var, Tipo("b"))
             // + ";\n";
           }
         ;

ATRIB : TK_ID TK_ATRIB E
        {
          $1.tipo = consulta_ts($1.valor);
          $$.valor = $1.valor;
          $$.codigo = atribuicao_var($1, $3);
        }
      | TK_ID '[' E ']' TK_ATRIB E
        {
          $$.codigo = $3.codigo + $6.codigo
                    + testa_limites_array($1, $3)
                    + atribuicao_array($1, $3, $6);
        }
      | TK_ID '[' E ']' '[' E ']' TK_ATRIB E
        {
          // Chama o teste de limites antes de mais nada.
          string teste_limites = testa_limites_matriz($1, $3, $6);
          string indice_temp = gera_nome_var_temp("i");

          Tipo t_matriz = consulta_ts($1.valor);
          Atributos s3(indice_temp, Tipo("i"));

          $$.codigo = $3.codigo + $6.codigo + $9.codigo
                    + "  " + indice_temp + " = " + $3.valor + "*"
                    + toString(t_matriz.tam[1]) + ";\n"
                    + "  " + indice_temp + " = "
                    + indice_temp + " + " + $6.valor + ";\n"
                    + teste_limites
                    + atribuicao_array($1, s3, $9);
        }
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
          Tipo t("s");
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

FUNC :  TIPO TK_ID { empilha_ts(); } '(' F_PARAMS ')'
        // Necessario inserir a funcao na tabela de simbolos antes
        // do bloco para que funcoes possam ser recursivas.
        { insere_func_ts($2.valor, Tipo($1.tipo, $5.lista_tipo)); } BLOCO
        {
          $$ = Atributos($2.valor, Tipo($1.tipo, $5.lista_tipo));
          string cabecalho = gera_cabecalho_funcao($1.tipo,
                                                   $2.valor,
                                                   $5.lista_str,
                                                   $5.lista_tipo);
          cabecalhos_funcao += cabecalho + ";\n";

          $$.codigo = cabecalho + $8.codigo;

          desempilha_ts();
        }
     ;

F_PARAMS :  PARAMS
            {
              $$ = $1;
              $$.codigo = "";
              // Insere parametros na tabela de simbolos da funcao
              for(int i = 0; i < $1.lista_str.size(); i++){
                $$.codigo += "  " + declara_variavel($1.lista_str[i],
                                                     $1.lista_tipo[i])
                          + ";\n";
                insere_var_ts($1.lista_str[i], $1.lista_tipo[i]);
              }
            }
         |  { $$ = Atributos(); }
         ;

PARAMS :  PARAM ',' PARAMS
          {
            $$.lista_str.push_back($1.valor);
            $$.lista_str.insert($$.lista_str.end(),
                                $3.lista_str.begin(),
                                $3.lista_str.end());
            $$.lista_tipo.push_back($1.tipo);
            $$.lista_tipo.insert($$.lista_tipo.end(),
                                $3.lista_tipo.begin(),
                                $3.lista_tipo.end());
          }
       |  PARAM
          {
            $$.lista_str.push_back($1.valor);
            $$.lista_tipo.push_back($1.tipo);
          }
       ;

PARAM : TIPO TK_ID
        {
          $$.valor = $2.valor;
          $$.tipo = $1.tipo;
        }
      | TIPO TK_ID '[' TK_CINT ']'
        {
          $$ = Atributos($2.valor,
                         Tipo($1.tipo.tipo_base, toInt($4.valor)));
        }
      | TIPO TK_ID '[' TK_CINT ']' '[' TK_CINT ']'
        {
          $$ = Atributos($2.valor,
                         Tipo($1.tipo.tipo_base,
                              toInt($4.valor),
                              toInt($7.valor)
                         )
                        );
        }
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
    | CMD_SWITCH
    | CMD_DO_WHILE ';'
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
CMD_CALL :  TK_ID '(' CALL_PARAMS ')'
            {
              // TODO(jullytta): verificar se essa sequer e' uma funcao
              // TODO(jullytta): verificar os tipos dos parametros
              Tipo t_func = consulta_ts($1.valor);
              $$ = Atributos();
              $$.codigo = $1.valor + "(" + $3.codigo + ");\n";
            }
         ;

CALL_PARAMS : C_PARAMS
              {
                $$ = $1;
                $$.codigo = "";
                for(int i = 0; i < $1.lista_str.size(); i++){
                  $$.codigo += $1.lista_str[i];
                  if(i != $1.lista_str.size()-1)
                    $$.codigo += ", ";
                }
              }
            | { $$ = Atributos(); }
            ;

C_PARAMS :  E ',' C_PARAMS
            {
              $$.lista_str.push_back($1.valor);
              $$.lista_str.insert($$.lista_str.end(),
                                  $3.lista_str.begin(),
                                  $3.lista_str.end());
              $$.lista_tipo.push_back($1.tipo);
              $$.lista_tipo.insert($$.lista_tipo.end(),
                                  $3.lista_tipo.begin(),
                                  $3.lista_tipo.end());
            }
         |  E
            {
              $$.lista_str.push_back($1.valor);
              $$.lista_tipo.push_back($1.tipo);
            }
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

CMD_FOR : TK_FOR '(' ATRIB_FOR ';' E ';' PULO_FOR ')' SUB_BLOCO
          {
            $$ = gera_codigo_for($3, $5, $7, $9);
          }
        | TK_FOR '(' ';' E ';' ')' SUB_BLOCO
          {
            $$ = gera_codigo_while($4, $7);
          }
        ;

ATRIB_FOR : TIPO TK_ID TK_ATRIB E
            {
              $$ = Atributos($2.valor, $1.tipo);
              vars_bloco[vars_bloco.size()-1] += "  "
                                              + declara_variavel($2.valor,
                                                                 $1.tipo)
                                              + ";\n";
              insere_var_ts($2.valor, $1.tipo);
              $2.tipo = $1.tipo;
              $$.codigo = atribuicao_var($2, $4);
            }
          ;

// acho que pra verificar tipos isso fica melhor separado!
PULO_FOR : TK_ID TK_ATRIB E
           {
             $$.codigo = $3.codigo + "\n" + "  "
                       + $1.valor + " = " + $3.valor + ";\n";
           }
         ;


CMD_WHILE : TK_WHILE '(' E ')' SUB_BLOCO
            {
              $$ = gera_codigo_while($3, $5);
            }
          ;

CMD_DO_WHILE : TK_DO SUB_BLOCO TK_WHILE '(' E ')'
               {
                 $$ = gera_codigo_do_while($2, $5);
               }
              ;

CMD_SWITCH : TK_SWITCH '(' E ')' BLOCO_SWITCH
             {
               //$3.tipo = consulta_ts($3.valor);
               $$.codigo = atribuicao_var(Atributos(compara_switch_var,
                                                    $3.tipo.tipo_base),
                                                    $3);
               $$.codigo += gera_codigo_switch($3, $5).codigo;
             }
           ;

BLOCO_SWITCH : TK_BEGIN CASOS TK_END
               {
                 $$.codigo += $2.codigo + "\n";
               }
             ;

CASOS : CASO CASOS
        {
          $$.codigo = $1.codigo + $2.codigo;
          $$.valor = $1.valor + $2.valor; //sobe o padrao
        }
      | CASO_PADRAO
      |
        {
          $$ = Atributos();
        }
      ;

CASO : TK_CASE F ':' CMDS
       {
         $$ = gera_codigo_casos($2, $4, 0);
       }
     | TK_CASE F ':' CMDS TK_BREAK ';'
       {
         $$ = gera_codigo_casos($2, $4, 1);
       }
     ;

CASO_PADRAO : TK_DEFAULT ':' CMDS
              {
                $$ = $3;
              }
            | TK_DEFAULT ':' CMDS TK_BREAK ';'
              {
                $$ = $3; // sobe o padrao para ele ser o ultimo
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
  | E TK_AND E
    {
      $$ = gera_codigo_operador($1, "&&", $3);
    }
  | E TK_OR E
    {
      $$ = gera_codigo_operador($1, "||", $3);
    }
  | E TK_IN F
    {
      $$ = gera_codigo_operador_in($1, $3);
    }
  | E TK_MOD E
    {
      $$ = gera_codigo_operador($1, "%", $3);
    }
  | TK_NOT E
    {
      $$ = gera_codigo_operador_unario("!", $2);
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
  | TK_ID '[' E ']'
    {
      $$ = acessa_array($1, $3);
      $$.codigo = $3.codigo
                + testa_limites_array($1, $3)
                + $$.codigo;
    }
  | TK_ID '[' E ']' '[' E ']'
    {
      // Chama o teste de limites antes de mais nada.
      string teste_limites = testa_limites_matriz($1, $3, $6);
      string indice_temp = gera_nome_var_temp("i");

      Tipo t_matriz = consulta_ts($1.valor);

      $$.tipo = Tipo(t_matriz.tipo_base);
      $$.valor = gera_nome_var_temp($$.tipo.tipo_base);

      Atributos s3(indice_temp, Tipo("i"));
      $$ = acessa_array($1, s3);
      $$.codigo = $3.codigo + $6.codigo + teste_limites
                + "  " + indice_temp + " = " + $3.valor + "*"
                + toString(t_matriz.tam[1]) + ";\n"
                + "  " + indice_temp + " = "
                + indice_temp + " + " + $6.valor + ";\n"
                + $$.codigo;

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
      $$ = Atributos($1.valor, Tipo("s"));
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
int nColuna = 0;

#include "lex.yy.c"

int yyparse();

void yyerror(const char* st){
  puts( st );
  printf( "Linha: %d, Coluna: %d [%s]\n", nlinha, nColuna-1, yytext );
}

void erro(string msg){
  cerr << "Erro: " << msg << endl;
  fprintf(stderr, "Linha: %d, Coluna: %d [%s]\n", nlinha, nColuna-1, yytext );
  exit(1);
}

void inicializa_operadores() {
  // Operador +
  tipo_opr["i+i"] = "i";
  tipo_opr["i+d"] = "d";
  tipo_opr["d+i"] = "d";
  tipo_opr["d+d"] = "d";
  tipo_opr["s+s"] = "s";
  tipo_opr["s+i"] = "s";
  tipo_opr["i+s"] = "s";
  tipo_opr["s+d"] = "s";
  tipo_opr["d+s"] = "s";
  tipo_opr["s+c"] = "s";
  tipo_opr["c+s"] = "s";

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

  // Operador >
  tipo_opr["i>i"] = "b";
  tipo_opr["i>d"] = "b";
  tipo_opr["d>i"] = "b";
  tipo_opr["d>d"] = "b";
  tipo_opr["c>c"] = "b";
  tipo_opr["i>c"] = "b";
  tipo_opr["c>i"] = "b";
  tipo_opr["s>s"] = "b";

  // Operador <
  tipo_opr["i<i"] = "b";
  tipo_opr["i<d"] = "b";
  tipo_opr["d<i"] = "b";
  tipo_opr["d<d"] = "b";
  tipo_opr["c<c"] = "b";
  tipo_opr["i<c"] = "b";
  tipo_opr["c<i"] = "b";
  tipo_opr["s<s"] = "b";

  // Operador >=
  tipo_opr["i>=i"] = "b";
  tipo_opr["i>=d"] = "b";
  tipo_opr["d>=i"] = "b";
  tipo_opr["d>=d"] = "b";
  tipo_opr["c>=c"] = "b";
  tipo_opr["i>=c"] = "b";
  tipo_opr["c>=i"] = "b";
  tipo_opr["s>=s"] = "b";

  // Operador <=
  tipo_opr["i<=i"] = "b";
  tipo_opr["i<=d"] = "b";
  tipo_opr["d<=i"] = "b";
  tipo_opr["d<=d"] = "b";
  tipo_opr["c<=c"] = "b";
  tipo_opr["i<=c"] = "b";
  tipo_opr["c<=i"] = "b";
  tipo_opr["s<=s"] = "b";

  // Operador ==
  tipo_opr["i==i"] = "b";
  tipo_opr["i==d"] = "b";
  tipo_opr["d==i"] = "b";
  tipo_opr["d==d"] = "b";
  tipo_opr["c==c"] = "b";
  tipo_opr["i==c"] = "b";
  tipo_opr["c==i"] = "b";
  tipo_opr["s==s"] = "b";

  // Operador <>
  tipo_opr["i!=i"] = "b";
  tipo_opr["i!=d"] = "b";
  tipo_opr["d!=i"] = "b";
  tipo_opr["d!=d"] = "b";
  tipo_opr["c!=c"] = "b";
  tipo_opr["i!=c"] = "b";
  tipo_opr["c!=i"] = "b";
  tipo_opr["s!=s"] = "b";

  // Operador =
  tipo_opr["i=i"] = "i";
  tipo_opr["b=b"] = "b";
  tipo_opr["b=i"] = "b";
  tipo_opr["d=d"] = "d";
  tipo_opr["d=i"] = "d";
  tipo_opr["c=c"] = "c";
  tipo_opr["s=s"] = "s";
  tipo_opr["s=c"] = "s";

  // Operador e
  tipo_opr["b&&b"] = "b";
  tipo_opr["i&&i"] = "b";
  tipo_opr["i&&d"] = "b";
  tipo_opr["d&&i"] = "b";
  tipo_opr["d&&d"] = "b";

  // Operador ou
  tipo_opr["b||b"] = "b";
  tipo_opr["i||i"] = "b";
  tipo_opr["i||d"] = "b";
  tipo_opr["d||i"] = "b";
  tipo_opr["d||d"] = "b";

  // Operador naum
  tipo_opr["!i"] = "i";
  tipo_opr["!b"] = "b";
  tipo_opr["!c"] = "c";
  tipo_opr["!d"] = "d";

  // Operador modis
  tipo_opr["i%i"] = "i";

}

void empilha_ts() {
  map< string, Tipo > novo;
  ts.push_back(novo);
}

void desempilha_ts() {
  ts.pop_back();
}

void inicializa_verificacao_tipos(){
  //tipos aceitos pelo if
  tipo_expr["if"].push_back("b");
  tipo_expr["if"].push_back("i");

  //tipos aceitos pelo while
  tipo_expr["while"].push_back("b");
  tipo_expr["while"].push_back("i");

  //tipos aceitos pelo switch
  //mudar os tipos aceitos pelo switch nao vai dar mto certo
  tipo_expr["switch"].push_back("b");
  tipo_expr["switch"].push_back("i");

  tipo_expr["for"].push_back("b");
  tipo_expr["for"].push_back("i");

}

void insere_var_ts(string nome, Tipo tipo){
  if(ts[ts.size()-1].find(nome) != ts[ts.size()-1].end()){
    erro("Variavel ja declarada: " + nome);
  }
  ts[ts.size()-1][nome] = tipo;
}

void insere_func_ts(string nome, Tipo tipo){
  if(ts[ts.size()-2].find(nome) != ts[ts.size()-2].end()){
    erro("Funcao ja declarada: " + nome);
  }
  ts[ts.size()-2][nome] = tipo;
}

Tipo consulta_ts(string nome) {
  for(int i = ts.size()-1; i >= 0; i--)
    if(ts[i].find(nome) != ts[i].end())
      return ts[i][nome];

  erro("Variavel nao declarada: " + nome);

  return Tipo();
}

string toString(int n){
  char buff[100];

  sprintf(buff, "%d", n);

  return buff;
}

string declara_variavel(string nome, Tipo tipo){
  if(tipo.tipo_base == "s"){
    int tam_vet = MAX_STRING_SIZE;
    switch(tipo.ndim){
      // As dimensoes do array sao constantes, sempre
      case 2:
        tam_vet *= tipo.tam[1];
      case 1:
        tam_vet *= tipo.tam[0];
    }
    return "char " + nome + "[" + toString(tam_vet) + "]";
  }

  string declaracao = traduz_interno_para_C(tipo.tipo_base) + " " + nome;
  switch(tipo.ndim){
    case 0:
      return declaracao;
    case 1:
      return declaracao + "[" + toString(tipo.tam[0]) + "]";
    case 2:
      int tam_vet = tipo.tam[0]*tipo.tam[1];
      return declaracao + "[" + toString(tam_vet) + "]";
  }
  // Nao deveria chegar aqui
  return "";
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

string traduz_operador_C_para_gueto(string opr_c){
  if(opr_c == "!=")
    return "<>";
  if(opr_c == "&&")
    return "e";
  if(opr_c == "||")
    return "ou";
  if(opr_c == "!")
    return "naum";
  if(opr_c == "%")
    return "modis";
  return opr_c;
}

string renomeia_variavel_usuario(string nome){
  return "_" + nome;
}

string gera_nome_var_temp(string tipo_interno){
  string nome = gera_nome_var_temp_sem_declarar(tipo_interno);

  vars_bloco[vars_bloco.size()-1] += "  "
                                  + declara_variavel(nome, Tipo(tipo_interno))
                                  + ";\n";

  return nome;
}

string gera_nome_var_temp_sem_declarar(string tipo_interno){
  static int n = 1;
  string nome = "t" + tipo_interno + "_" + toString(n++);
  return nome;
}

string gera_cabecalho_funcao(Tipo retorno,
                             string funcao,
                             vector<string> params,
                             vector<Tipo> tipos){
  string codigo = traduz_interno_para_C(retorno.tipo_base)
                + " " + funcao + "(";

  for(int i = 0; i < tipos.size(); i++){
    codigo += declara_variavel(params[i], tipos[i]);
    if(i != tipos.size()-1)
      codigo += ", ";
  }
  codigo += ")";
  return codigo;
}

string atribuicao_var(Atributos s1, Atributos s3){
  // Verifica se estamos trabalhando com dimensao zero
  // como era esperado se chamamos essa funcao.
  if(s1.tipo.ndim != 0 || s3.tipo.ndim != 0)
    erro("Atribuicao nao permitida! Variavel " + s1.valor
          + ", dimensao " + toString(s1.tipo.ndim)
          + " nao e' compativel com variavel " + s3.valor
          + ", dimensao " + toString(s3.tipo.ndim));

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

string atribuicao_array(Atributos id,
                        Atributos indice,
                        Atributos resultado){
  Tipo t_array(consulta_ts(id.valor).tipo_base);
  if(t_array.tipo_base == "s")
    return gera_codigo_atribuicao_string(id, indice, resultado);

  return "  " + id.valor + "[" + indice.valor + "] = "
            + resultado.valor + ";\n";
}

string gera_codigo_atribuicao_string(Atributos id,
                                     Atributos indice,
                                     Atributos resultado){
  string a_copiar = gera_nome_var_temp("s");
  string codigo = "  strncpy(" + a_copiar + ", " + resultado.valor + ", "
                + toString(MAX_STRING_SIZE) + ");\n";

  string label_teste = gera_label("teste_substring");
  string label_fim = gera_label("fim_substring");

  string condicao = gera_nome_var_temp("b");
  string inicio = gera_nome_var_temp("i");
  string fim = gera_nome_var_temp("i");

  string indice_mais_um = gera_nome_var_temp("i");
  string indice_loop = gera_nome_var_temp("i");
  string indice_loop_menos_inicio = gera_nome_var_temp("i");

  string char_copiado = gera_nome_var_temp("c");

  // Inicializa inicio e fim
  codigo += "  " + inicio + " = " + toString(MAX_STRING_SIZE)
         + " * " + indice.valor + ";\n"
         + "  " + indice_mais_um + " = " + indice.valor + " + 1;\n"
         + "  " + fim + " = " + toString(MAX_STRING_SIZE)
         + " * " + indice_mais_um + ";\n";

  // Inicializa o indice do loop
  codigo += "  " + indice_loop + " = " + inicio + ";\n";

  // Cria o teste se ainda estamos no loop
  codigo += label_teste + ":;\n"
         + "  " + condicao + " = " + indice_loop + " < " + fim + ";\n"
         + "  " + condicao + " = !" + condicao + ";\n"
         + "  if(" + condicao + ") goto " + label_fim + ";\n";

  // A copia de fato acontece aqui
  codigo += "  " + indice_loop_menos_inicio + " = " + indice_loop
         + " - " + inicio + ";\n"
         + "  " + char_copiado + " = " + a_copiar + "["
         + indice_loop_menos_inicio + "];\n"
         + "  " + id.valor + "[" + indice_loop + "] = "
         + char_copiado + ";\n"
         + "  " + indice_loop + " = " + indice_loop + " + 1;\n"
         + "goto " + label_teste + ";\n";

  codigo += label_fim + ":;\n";

  return codigo;
}

string gera_codigo_acesso_string(Atributos id,
                                 Atributos indice,
                                 string nome){
  string codigo = "";

  string label_teste = gera_label("teste_substring");
  string label_fim = gera_label("fim_substring");

  string condicao = gera_nome_var_temp("b");
  string inicio = gera_nome_var_temp("i");
  string fim = gera_nome_var_temp("i");

  string indice_mais_um = gera_nome_var_temp("i");
  string indice_loop = gera_nome_var_temp("i");
  string indice_loop_menos_inicio = gera_nome_var_temp("i");

  string char_copiado = gera_nome_var_temp("c");

  // Inicializa inicio e fim
  codigo += "  " + inicio + " = " + toString(MAX_STRING_SIZE)
         + " * " + indice.valor + ";\n"
         + "  " + indice_mais_um + " = " + indice.valor + " + 1;\n"
         + "  " + fim + " = " + toString(MAX_STRING_SIZE)
         + " * " + indice_mais_um + ";\n";

  // Inicializa o indice do loop
  codigo += "  " + indice_loop + " = " + inicio + ";\n";

  // Cria o teste se ainda estamos no loop
  codigo += label_teste + ":;\n"
         + "  " + condicao + " = " + indice_loop + " < " + fim + ";\n"
         + "  " + condicao + " = !" + condicao + ";\n"
         + "  if(" + condicao + ") goto " + label_fim + ";\n";

  // A copia de fato acontece aqui
  codigo += "  " + indice_loop_menos_inicio + " = " + indice_loop
         + " - " + inicio + ";\n"
         + "  " + char_copiado + " = " + id.valor + "["
         + indice_loop + "];\n"
         + "  " + nome + "[" + indice_loop_menos_inicio + "] = "
         + char_copiado + ";\n"
         + "  " + indice_loop + " = " + indice_loop + " + 1;\n"
         + "goto " + label_teste + ";\n";

  codigo += label_fim + ":;\n";

  return codigo;
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

string testa_limites_array(Atributos id, Atributos indice){
  Tipo t_array = consulta_ts(id.valor);

  // Verifica o tipo do indice
  if(indice.tipo.tipo_base != "i" || indice.tipo.ndim != 0)
    erro("Indice de arrei deve ser intero.");

  // Verifica se a variavel e' mesmo um array de dimensao 1
  if(t_array.ndim != 1)
    erro("Variavel " + id.valor + " nao e' arrei de dimensao um.");

  // TODO(jullytta): verificar se o limite do array foi ultrapassado
  // Isso deve ser feito dinamicamente, temos que gerar codigo.
  // Retornar esse codigo gerado.
  return "";
}

string testa_limites_matriz(Atributos id,
                            Atributos indice1,
                            Atributos indice2){
  Tipo t_matriz = consulta_ts(id.valor);

  // Verifica o tipo dos indices
  if(indice1.tipo.tipo_base != "i" || indice2.tipo.tipo_base != "i" ||
     indice1.tipo.ndim != 0 || indice2.tipo.ndim != 0)
    erro("Indice de arrei deve ser intero.");

  // Verifica se a variavel e' mesmo um array de dimensao 2
  if(t_matriz.ndim != 2)
    erro("Variavel " + id.valor + " nao e' arrei de dimensao dois.");

  // TODO(jullytta): codigo do teste dinamico retornado
  return "";
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

int aceita_tipo(string opr, Atributos expr){
  if (tipo_expr.count(opr)){
    for(int a = 0; a < tipo_expr[opr].size(); a++)
      if (tipo_expr[opr].at(a) == expr.tipo.tipo_base){
        return 1;
      }
  }
  return 0;
}

int sizeof_tipo_interno(string tipo_interno){
  int tipo_tam;
  if (tipo_interno == "i"){
    tipo_tam = sizeof(int);
  }else if (tipo_interno == "c"){
    tipo_tam = sizeof(char);
  }else if (tipo_interno == "s"){
    tipo_tam = sizeof(string);
  }else if (tipo_interno == "d"){
    tipo_tam = sizeof(double);
  }else if (tipo_interno == "b"){
    tipo_tam = sizeof(int);
  }else{
    tipo_tam = sizeof(int);
  }
  return tipo_tam;
}

Atributos acessa_array(Atributos id, Atributos indice){
  Atributos ss;

  ss.tipo = Tipo(consulta_ts(id.valor).tipo_base);
  ss.valor = gera_nome_var_temp(ss.tipo.tipo_base);
  if(ss.tipo.tipo_base == "s")
    ss.codigo = gera_codigo_acesso_string(id, indice, ss.valor);
  else
    ss.codigo = "  " + ss.valor + " = " + id.valor
              + "[" + indice.valor + "];\n";

  return ss;
}

string atributoToString(Atributos s, string buff){
  string codigo;
  if (s.tipo.tipo_base == "i"){
    codigo = "  sprintf(" + buff + ", \"%d\", " + s.valor + ");\n";
  }else if (s.tipo.tipo_base  == "c"){
    codigo = "  sprintf(" + buff + ", \"%c\", " + s.valor + ");\n";
  }else if (s.tipo.tipo_base  == "d"){
    codigo = "  sprintf(" + buff + ", \"%f\", " + s.valor + ");\n";
  }else if (s.tipo.tipo_base  == "s"){
    //sprintf desnecessario, mas deixa o codigo mais simples
    codigo = "  sprintf(" + buff + ", \"%s\", " + s.valor + ");\n";
  }
  return codigo;
}

Atributos gera_codigo_operador(Atributos s1, string opr, Atributos s3){
  Atributos ss;

  string tipo1 = s1.tipo.tipo_base;
  string tipo3 = s3.tipo.tipo_base;
  string tipo_resultado = tipo_opr[tipo1 + opr + tipo3];

  if(tipo_resultado == "")
    erro("Operacao nao permitida. "
       + traduz_interno_para_gueto(tipo1)
       + " " + traduz_operador_C_para_gueto(opr) + " "
       + traduz_interno_para_gueto(tipo3));

  // operacoes com arreis
  if (s1.tipo.ndim > 0 && s3.tipo.ndim > 0){
    if (opr == "==" || opr == "!="){
      ss = gera_operador_vetores(s1, opr, s3);
      return ss;
    }
  }

 // operacoes com strings
  if (s1.tipo.tipo_base == "s"
      && s3.tipo.tipo_base == "s"
      && tipo_resultado == "b"){
    return gera_codigo_operador_strings(s1, opr, s3);
  }

  ss.valor = gera_nome_var_temp(tipo_resultado);
  ss.tipo = Tipo(tipo_resultado);
  ss.codigo = s1.codigo + s3.codigo;

  // Strings
  if(tipo_resultado == "s" && opr == "+"){
    string buff = gera_nome_var_temp("s");
    // concatena strings com tudo menos boolean
    if (s1.tipo.tipo_base == "s"){
      ss.codigo += atributoToString(s3, buff);
      ss.codigo += "  strncpy(" + ss.valor + ", " + s1.valor + ", "
                + toString(MAX_STRING_SIZE) + ");\n"
                + "  strncat(" + ss.valor + ", " + buff + ", "
                + toString(MAX_STRING_SIZE) + ");\n";
    }else if (s3.tipo.tipo_base == "s"){
      ss.codigo += atributoToString(s1, buff);
      ss.codigo += "  strncpy(" + ss.valor + ", " + buff + ", "
                + toString(MAX_STRING_SIZE) + ");\n"
                + "  strncat(" + ss.valor + ", " + s3.valor + ", "
                + toString(MAX_STRING_SIZE) + ");\n";
    }

  }
  // Tipo basico
  else {
    ss.codigo += "  " + ss.valor + " = "
              + s1.valor + " " + opr + " " + s3.valor
              + ";\n";
  }

  return ss;
}

Atributos gera_codigo_operador_unario(string opr, Atributos s2){
  Atributos ss;

  string tipo2 = s2.tipo.tipo_base;
  string tipo_resultado = tipo_opr[opr + tipo2];

  if(tipo_resultado == "")
    erro("Operacao nao permitida. "
       + traduz_operador_C_para_gueto(opr)
       + traduz_interno_para_gueto(tipo2));

  ss.valor = gera_nome_var_temp(tipo_resultado);
  ss.tipo = Tipo(tipo_resultado);

  ss.codigo = s2.codigo + "  "
            + ss.valor + " = "
            + opr + s2.valor
            + ";\n";

  return ss;
}

Atributos gera_codigo_if(Atributos expr,
                         Atributos bloco_if,
                        Atributos bloco_else){
  Atributos ss;
  if (aceita_tipo("if", expr)){
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
  }else{
    erro("Condicao nao permitida! O tipo ["
         + traduz_interno_para_gueto(expr.tipo.tipo_base)
         +"] nao e um tipo valido pro if");
  }
  return ss;
}

Atributos gera_codigo_while(Atributos expr, Atributos bloco){
  Atributos ss;
  if (aceita_tipo("while", expr)){
    string label_teste = gera_label( "teste_while" );
    string label_end = gera_label( "fim_while" );
    // o zizi coloca "b" ao inves de tipo_base, mas acho tipo_base melhor pra
    // verificar erros
    string condicao_var = gera_nome_var_temp(expr.tipo.tipo_base);

    ss.codigo = label_teste + ":;\n"
              + expr.codigo + "  "
              + condicao_var + " = !" + expr.valor + ";\n\n"
              + "if ("+ condicao_var +") goto " + label_end
              + ";\n" + desbloquifica(bloco.codigo)
              + "goto " + label_teste + ";\n"
              + label_end + ":;\n"
              ;
  }else{
    erro("Condicao nao permitida! O tipo ["
         + traduz_interno_para_gueto(expr.tipo.tipo_base)
         +"] nao e um tipo valido pro while");
  }
  return ss;
}

Atributos gera_codigo_do_while(Atributos bloco, Atributos expr){
  Atributos ss;
  if (aceita_tipo("while", expr)){
    string label_teste = gera_label( "teste_dowhile" );
    string label_end = gera_label( "fim_dowhile" );
    // o zizi coloca "b" ao inves de tipo_base, mas acho tipo_base melhor pra
    // verificar erros
    string condicao_var = gera_nome_var_temp(expr.tipo.tipo_base);

    ss.codigo = label_teste + ":;\n"
              + desbloquifica(bloco.codigo)
              + expr.codigo + "  "
              + condicao_var + " = !" + expr.valor + ";\n\n"
              + "if ("+ condicao_var +") goto " + label_end + ";\n"
              + "goto " + label_teste + ";\n"
              + label_end + ":;\n"
              ;
  }else{
    erro("Condicao nao permitida! O tipo ["
         + traduz_interno_para_gueto(expr.tipo.tipo_base)
         +"] nao e um tipo valido pro do while");
  }
  return ss;
}

Atributos gera_codigo_for(Atributos atrib,
                          Atributos condicao,
                          Atributos pulo,
                          Atributos bloco){
  Atributos ss;
  if (aceita_tipo("for", condicao)){
    string var_fim = gera_nome_var_temp( atrib.tipo.tipo_base );
    string label_teste = gera_label( "teste_for" );
    string label_end = gera_label( "fim_for" );
    string condicao_var = gera_nome_var_temp(condicao.tipo.tipo_base);

    ss.codigo = atrib.codigo
              + label_teste + ":;\n"
              + condicao.codigo + "  "
              + condicao_var + " = !" + condicao.valor + ";\n\n"
              + "if ("+ condicao_var +") goto " + label_end
              + ";\n" + desbloquifica(bloco.codigo)
              + pulo.codigo
              + "  goto " + label_teste + ";\n"
              + label_end + ":;\n"
              ;
  }else{
    erro("Condicao nao permitida! O tipo ["
         + traduz_interno_para_gueto(condicao.tipo.tipo_base)
         +"] nao e um tipo valido pro do for");
  }
  return ss;
}

Atributos gera_codigo_casos(Atributos expr,
                            Atributos cmds, int tem_break){
  Atributos expr_if;
  Atributos expr_else = Atributos();
  string switch_var = gera_nome_var_temp(expr.tipo.tipo_base);
  expr_if.codigo = "  " + switch_var + " = "
                 + compara_switch_var + " == " + expr.valor + ";\n";
  expr_if.tipo = Tipo("b");
  expr_if.valor = switch_var;
  Atributos bloco = cmds;

  Atributos ss;
  string label_case = gera_label("else_case");
  string condicao_var = gera_nome_var_temp("b"); //deveria ser so boolean?

  string goto_break = (tem_break == 1 ? "  goto " + label_break + ";\n" : "");

  ss.codigo = "\n\n"+expr_if.codigo + "  "
            + condicao_var + " = !" + expr_if.valor + ";\n\n"
            + "  if( " + condicao_var + " ) goto "
            + label_case + ";\n"
            + label_passthrough
            + (label_passthrough == "" ? "" : ":;\n")
            + bloco.codigo
            + goto_break;
  label_passthrough = gera_label("passthrough");
  ss.codigo += "  goto " + label_passthrough + ";\n"
            + label_case + ":;\n";
  return ss;
}

Atributos gera_codigo_switch(Atributos cond, Atributos bloco){
  Atributos ss;
  if (aceita_tipo("switch", cond)){
    string label_inutil = label_passthrough
                        + (label_passthrough == "" ? "" : ":;\n");
    ss.codigo = cond.codigo + bloco.codigo
              + label_inutil + label_break + ":;\n";
    label_break = gera_label("break");
    label_passthrough = "";
  }else{
    erro("Condicao nao permitida! O tipo ["
         + traduz_interno_para_gueto(cond.tipo.tipo_base)
         +"] nao e um tipo valido pro do switch");
  }
  return ss;
}

Atributos atribuicao_var_global(Atributos tipo, Atributos id,
                                string i, string j){
  Atributos ss = Atributos(id.valor, tipo.tipo);
  if (i != ""){
    ss = Atributos(id.valor, Tipo(tipo.tipo.tipo_base, toInt(i)));
    if (j != ""){
      ss = Atributos(id.valor, Tipo(tipo.tipo.tipo_base, toInt(i), toInt(j)));
    }
  }
  vars_globais += declara_variavel(ss.valor, ss.tipo)
                                      + ";\n";
  insere_var_ts(ss.valor, ss.tipo);
  //ss.codigo = id.codigo;
  return ss;
}

Atributos gera_codigo_operador_in(Atributos var, Atributos vetor){
  Atributos ss;
  if (is_atribuivel(var, vetor)){ //faz sentido x in tab
    if (vetor.tipo.ndim > 0){
      string resultado = gera_nome_var_temp("b");
      string vetor_tmp = gera_nome_var_temp(vetor.tipo.tipo_base);
      ss.tipo = Tipo("b");
      int tam_x = (vetor.tipo.ndim == 1
                ? vetor.tipo.tam[0]
                : vetor.tipo.tam[0]*vetor.tipo.tam[1]);
      string label_in = gera_label( "in" );
      int indice = 0;
      ss.codigo = "\n\n  " + resultado + " = 0;\n";
      for (int i = 0; i < tam_x; i++){
          string valor_vetor = vetor.valor + "["+ toString(i) +"]";
          string label_not_in = gera_label( "not_in" );
          string tmp_var = gera_nome_var_temp(var.tipo.tipo_base);
          ss.codigo += var.codigo + vetor.codigo +
                    + "  " + vetor_tmp + " = " + valor_vetor + ";\n"
                    + "  " + tmp_var + " = " + var.valor
                    + " == " + vetor_tmp + ";\n"
                    + "  " + tmp_var + " = !" + tmp_var + ";\n"
                    + "  if ("+ tmp_var +") goto " + label_not_in + ";\n"
                    + "    " + resultado + " = 1;\n"
                    + "  goto " + label_in + ";\n"
                    + label_not_in + ":;\n\n"
                    ;
      }
      ss.codigo += label_in + ":;\n";
      ss.valor = resultado;
    }else{
      erro("Esperado arrei porem encontrado ["
           +traduz_interno_para_gueto(vetor.tipo.tipo_base)+"]");
    }
  }else{
    erro("Tipo ["+traduz_interno_para_gueto(var.tipo.tipo_base)
         +"] nao compativel com ["+
         traduz_interno_para_gueto(vetor.tipo.tipo_base)
         +"] para o operador 'em'");
  }
  return ss;
}

Atributos gera_codigo_operador_strings(Atributos s1,
                                       string opr,
                                       Atributos s3){
  Atributos ss;
  string ret = gera_nome_var_temp("b");
  ss.codigo = s1.codigo + s3.codigo
            + "  " + ret
            + " = strcmp("+ s1.valor + ", "
            + s3.valor + ");\n"
            + "  " + ret + " = " + ret + " " + opr + " 0;\n";
            ;
  ss.valor = ret;
  ss.tipo = Tipo("b");
  return ss;
}

Atributos gera_operador_vetores(Atributos s1, string opr, Atributos s3){
  Atributos ss;
  string ret = gera_nome_var_temp("i");

  int tipo_tam = sizeof_tipo_interno(s1.tipo.tipo_base);

  int tam = (s1.tipo.ndim == 1
          ? s1.tipo.tam[0]
          : s1.tipo.tam[0]*s1.tipo.tam[1]);
  ss.codigo = s1.codigo + s3.codigo
            + "  " + ret
            + " = memcmp("+ s1.valor + ", "
            + s3.valor + ", "
            + toString(tam*tipo_tam) +");\n"
            + "  " + ret + " = " + ret + " == 0;\n"
            ;
  if (opr == "!=") ss.codigo += "  " + ret + " = !" + ret + ";\n";
  ss.valor = ret;
  ss.tipo = Tipo("i");
  return ss;
}

int main(int argc, char* argv[]){
  inicializa_operadores();
  inicializa_verificacao_tipos();
  cabecalhos_funcao = "";
  vars_globais = declara_variavel(compara_switch_var, Tipo("b")) + ";\n";
  yyparse();
}
