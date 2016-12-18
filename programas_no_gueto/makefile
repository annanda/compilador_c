PROGRAM="relou_mundo"

bin/${PROGRAM}:	bin src
	./../compilador_do_gueto/gueto < ${PROGRAM}.gueto > src/${PROGRAM}.cc
	./../gabarito/gabarito < src/${PROGRAM}.cc
	g++ -o bin/${PROGRAM} src/${PROGRAM}.cc

run:	./bin/${PROGRAM}
	./bin/${PROGRAM}

bin:
	mkdir -p bin/

src:
	mkdir -p src/

clean:
	rm bin/${PROGRAM} src/${PROGRAM}.cc
