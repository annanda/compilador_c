# Como compilar?
Suponha que você tenha um arquivo `programa.gueto` que você quer compilar. Basta fazer: 
```
make PROGRAM="programa"
```
Um executável de mesmo nome será compilado para a pasta `bin`. O código gerado em C-- assembly estará na pasta `src`. Ambas as pastas estão no git-ignore, portanto código gerado e executáveis não devem ser enviados para o repositório.

Opcionalmente, adicione "run" para rodar o programa após a compilação ou "clean" para remover o executável e o código gerado.
```
make PROGRAM="programa" run
make PROGRAM="programa" clean
```
Por default, o programa compilado/executado é `relou_mundo`.

# Problemas conhecidos
* As dependências do executável estão mal definidas. Por isso, ele não detecta quando alterações foram feitas no código e precisamos recompilar. A solução é, por enquanto, sempre rodar `clean` antes de recompilar. O makefile será consertado quando os requisitos do trabalho estiverem preenchidos (prioridades).
