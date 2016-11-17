%{
#include <string>
#include <iostream>
#include <vector>
#include <stdio.h>
#include <stdlib.h>

using namespace std;

int yylex();
void yyerror( const char* st );

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

#define YYSTYPE Atributos

%}

%token TK_ID TK_CINT TK_CDOUBLE TK_VAR TK_PROGRAM TK_BEGIN TK_END TK_ATRIB
%token TK_WRITELN TK_CSTRING

%left '+' '-'
%left '*' '/'

%%

S : PROGRAM DECLS MAIN 
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
      { for( string x : $1.lista )
          cout << x << endl;
        cout << $3.v << endl;   }
    ;
    
IDS : IDS ',' TK_ID 
      { $$  = $1;
        $$.lista.push_back( $3.v ); }
    | TK_ID 
      { $$ = Atributos();
        $$.lista.push_back( $1.v ); }
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
