#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define ID 256
#define NUM 257
#define IF 258
#define FOR 259

#define NUM_PR 2

struct PalavraReservada {
  const char *valor;
  int token;
};

PalavraReservada pr[NUM_PR] = {
  { "if", IF },
  { "for", FOR }  // instalar os outros tokens
};


int classificaID( const char *lexema ) {
  for( int i = 0; i < NUM_PR; i++ )
    if( strcmp( lexema, pr[i].valor ) == 0 )
      return pr[i].token;

  return ID;
}

char tokenVal[16000];

int isDigit( int ch ) {
  return ch >= '0' && ch <= '9';
}

int isAlpha( int ch ) {
  return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || ch == '_';
}

int isWS( int ch ) {
  return ch == ' ' || ch == '\n'|| ch == '\t';
}

void erro( const char* msg ) {
  printf( "%s\n", msg );
  exit( 1 );
}

int nextToken() {
  static int lookAhead = ' ';
  int pos = 0;

  while( isWS( lookAhead ) )
    lookAhead = getchar();

  if( isDigit( lookAhead ) ) {
    while( isDigit( lookAhead ) ) {
      tokenVal[pos++] = lookAhead;
      lookAhead = getchar();
    }

    if( lookAhead == '.' ) {
      tokenVal[pos++] = lookAhead;
      lookAhead = getchar();

      if( isDigit( lookAhead ) ) {
        while( isDigit( lookAhead ) ) {
          tokenVal[pos++] = lookAhead;
          lookAhead = getchar();
	}
      }
      else
	erro( "Erro no numero: depois do ponto tem de "
	      "ter pelo menos um digito" );
    }

    tokenVal[pos] = '\0';
    return NUM;
  }
  else if( isAlpha( lookAhead ) ) {
    tokenVal[pos++] = lookAhead;
    lookAhead = getchar();

    while( isAlpha( lookAhead ) || isDigit( lookAhead ) ) {
      tokenVal[pos++] = lookAhead;
      lookAhead = getchar();
    }

    tokenVal[pos] = '\0';
    return classificaID( tokenVal );
  }
  else switch( lookAhead ) {
    case '(' :
    case ')' :
    case '-' :
    case '/' :
    case '*' :
    case '+' : tokenVal[0] = lookAhead;
               tokenVal[1] = '\0';
               lookAhead = getchar();
	       return tokenVal[0];

    case -1 : return -1;
    default:
      erro( "Caractere inválido" );
  }
}

int main() {
  int token = nextToken();

  while( token != -1 ) {
    printf( "%d : %s\n", token, tokenVal );
    token = nextToken();
  }

  return 0;
}
