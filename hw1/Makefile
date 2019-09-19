.PHONY: all test clean

SUBMIT := hellocaml.ml providedtests.ml

main.native: $(SUBMIT)
	ocamlbuild -Is util -libs unix,str main.native

main.byte:
	ocamlbuild -Is util -libs unix,str main.byte

all: main.native

test: main.native
	./main.native --test

clean:
	ocamlbuild -clean
