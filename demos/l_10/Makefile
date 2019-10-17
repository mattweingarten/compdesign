OCBFLAGS := -use-menhir -yaccflags --explain
OCB := ocamlbuild $(OCBFLAGS)

.PHONY: all debug clean top profile

all: main.byte
debug: all 

%.cma: .FORCE
	$(OCB) $@

%.cmxa: .FORCE
	$(OCB) $@

%.native: .FORCE
	$(OCB) $@

%.byte: .FORCE
	$(OCB) $@

.FORCE:

clean:
	$(OCB) -clean

top: main.byte
	utop

