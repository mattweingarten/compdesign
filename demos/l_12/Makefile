INCLUDES= util,x86,grading,ll
LIBS = unix,str,nums

all: main.native

.PHONY: test
test: main.native
	./main.native --test

.PHONY: main.native
main.native:
	ocamlbuild -Is $(INCLUDES) -libs $(LIBS) main.native -use-menhir -yaccflag --explain -yaccflag --dump

.PHONY: clean
clean:
	ocamlbuild -clean
