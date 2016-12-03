all: gueto simples.gueto
	./gueto < simples.gueto

lex.yy.c: gueto.lex
	lex gueto.lex

y.tab.c: gueto.y
	yacc gueto.y

gueto: lex.yy.c y.tab.c
	g++ -o gueto y.tab.c -lfl
