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
