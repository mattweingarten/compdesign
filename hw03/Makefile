all: main.native

.PHONY: test
test: main.native
	./main.native --test

.PHONY: main.native
main.native: cinterop.c
	ocamlbuild -Is util,x86,ll,grading -libs unix,str,nums main.native -use-menhir

.PHONY: clean
clean:
	ocamlbuild -clean
	rm -rf output a.out
