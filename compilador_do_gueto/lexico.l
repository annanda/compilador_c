%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define ID 256
#define NUM 257
#define IF 258
#define FOR 259
#define STRING 260

#define NUM_PR 2

void erro( const char* msg );

%}

D 	[0-9]
L 	[a-zA-Z_]
NUM	{D}+(\.{D}+)?([Ee][+\-]?{D}+)?
ID	{L}({L}|{D})*
WS	[ \n\t]
OPR	[+\-*/()]
STR     \"([^\n"]|\\\")*\"

%%

{WS}	{ }
{NUM}	{ return NUM; }
{STR}	{ return STRING; }
"if"	{ return IF; }
"for"	{ return FOR; }
{OPR}	{ return yytext[0]; }

{ID}	{  // ID deve vir depois de todas as palavras reservadas
           return ID;
        }

.	{ return  *yytext; }

%%

void erro( const char* msg ) {
  printf( "%s\n", msg );
  exit( 1 );
}

int main() {
  int token = yylex();

  while( token != 0 ) {
    printf( "%d : %s\n", token, yytext );
    token = yylex();
  }

  return 0;
}
