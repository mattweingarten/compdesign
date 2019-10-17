OCBFLAGS := 
OCB := ocamlbuild $(OCBFLAGS)

.PHONY: all debug clean top profile

all: handlex.byte 
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

top: handlex.byte
	utop

