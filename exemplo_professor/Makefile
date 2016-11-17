all: saida entrada.txt
	./saida < entrada.txt

lex.yy.c: lexico.l
	lex lexico.l

saida: lex.yy.c
	g++ lex.yy.c -o saida -lfl
