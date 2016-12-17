all: gueto teste.gueto
	./gueto < teste.gueto > gerado.cc
	./../gabarito/gabarito < gerado.cc
	g++ gerado.cc -o gerado

lex.yy.c: gueto.lex
	lex gueto.lex

y.tab.c: gueto.y
	yacc gueto.y

gueto: lex.yy.c y.tab.c
	g++ -o gueto y.tab.c -lfl

gerado: gerado.cc
	g++ -o gerado gerado.cc
	./gerado
