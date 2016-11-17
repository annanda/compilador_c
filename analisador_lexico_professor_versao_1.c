#include <stdlib.h>
#include <stdio.h>

#define ID 1
#define NUM 2

char tokenVal[65000];

int isDigit( int ch ) {
    return ch >= '0' && ch <= '9';
}

int isWS( int ch ) {
    return ch == ' ' || ch == '\n'|| ch == '\t';
}

void erro( const char* msg ) {
    printf( "%s\n", msg );
      exit( 1 );
}

int nextToken() {
      int lookAhead = getchar();
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
}

int main() {
    int token = nextToken();

    printf( "%d\n", token );
    printf( "%s\n", tokenVal );

    return 0;
}
