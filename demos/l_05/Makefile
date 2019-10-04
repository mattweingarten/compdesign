OCBFLAGS := -Is util,x86
OCB := ocamlbuild $(OCBFLAGS)

.PHONY: all debug clean top profile

all: ir1.byte ir2.byte ir3.byte
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

top: ir1.byte ir2.byte 
	utop

