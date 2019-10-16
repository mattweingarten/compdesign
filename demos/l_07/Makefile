OCBFLAGS := -lib nums
OCB := ocamlbuild $(OCBFLAGS)

.PHONY: all debug clean top profile

all: struct32.ll struct64.ll
debug: all 

%.cma: .FORCE
	$(OCB) $@

%.cmxa: .FORCE
	$(OCB) $@

%.native: .FORCE
	$(OCB) $@

%.byte: .FORCE
	$(OCB) $@

struct32.ll: struct.c
	gcc -O0 -m32 -fno-asynchronous-unwind-tables -S -emit-llvm struct.c
	cp struct.ll struct32.ll

struct64.ll: struct.c
	gcc -O0 -fno-asynchronous-unwind-tables -S -emit-llvm struct.c
	cp struct.ll struct64.ll


.FORCE:

clean:
	$(OCB) -clean
	rm struct.ll struct32.ll struct64.ll

top: x86.byte
	utop

