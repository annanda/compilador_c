%{
#include <string>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>

using namespace std;

int yylex();
void yyerror( const char* st );

struct Atributos {
  string e, d; // uma expressão e sua derivada
};

#define YYSTYPE Atributos

%}

%token TK_ID TK_CINT TK_CDOUBLE X

%left '+' '-'
%left '*' '/'

%%

S : E { cout << "Expressao: " << $1.e << endl;
        cout << "Derivada : " << $1.d << endl; }

E : E '+' E 
    { $$.e = $1.e + " + " +  $3.e; $$.d = $1.d + " + " +  $3.d; }
  | E '-' E 
    { $$.e = $1.e + " - " +  $3.e; $$.d = $1.d + " - " +  $3.d; }
  | E '*' E 
    { $$.e = $1.e + "*" +  $3.e; 
      $$.d = $1.d + "*" + $3.e + " + " + $1.e + "*" + $3.d; }
  | E '/' E 
    { $$.e = $1.e + "/" +  $3.e; 
      $$.d = "(" + $1.d + "*" + $3.e + " - " + $1.e + "*" + $3.d + ")/" +
              "(" + $3.e + "*" + $3.e + ")"; }
  | '(' E ')' 
    { $$.e = "("+ $2.e + ")"; 
      $$.d = "("+ $2.d + ")"; }
  | F  
  ;

F : TK_ID  
  | X 
  | TK_CINT  
  | TK_CDOUBLE 
  ;
  
  
%%
int nlinha = 1;

#include "lex.yy.c"

int yyparse();

void yyerror( const char* st )
{
  puts( st );string
  printf( "Linha: %d\n", nlinha );
}

int main( int argc, char* argv[] )
{
  yyparse();
}
