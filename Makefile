export NO_CUSTOM=1

SOURCES=mysql.mli mysql.ml mysql_stubs.c
RESULT=mysql
VERSION=1.2.2

LIBINSTALL_FILES=$(wildcard *.mli *.cmi *.cma *.cmx *.cmxa *.a *.so *.cmxs)

CFLAGS=-g -O2 -DHAVE_CONFIG_H -Wall -Wextra
CPPFLAGS=-I/usr/include/mysql
CLIBS=$(foreach x, $(filter -l%, -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -ldl ), $(patsubst -l%,%,${x}))
LDFLAGS=$(filter-out -l%, -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -ldl )
OCAMLMKLIB_FLAGS=$(LDFLAGS)
OCAMLFIND_INSTFLAGS=-patch-version "$(VERSION)"
OBJS1=httpServer.cmo
OBJS2=api.cmo
NAME=server
OFIND=ocamlfind ocamlc -thread -package cohttp.lwt,cohttp.async,lwt.ppx



$(NAME).byte: $(OBJS1) $(OBJS2)
		$(OFIND) -linkpkg -o $@ $(OBJS1) $(OBJS2) $(NAME).ml

%.cmo: %.ml
		$(OFIND) -c $<i
		$(OFIND) -c $<

		build: all opt
		all: byte-code-library

		ifeq (yes,yes)
		CMXS=mysql.cmxs

		clean::
			rm -f mysql.cmxs
		endif

		opt: native-code-library $(CMXS)
		reallyall: byte-code-library native-code-library $(CMXS) htdoc

		install: libinstall
		uninstall: libuninstall

		db: reallyall
			ocamlc -custom -I . -thread unix.cma threads.cma mysql.cma db.ml -o db.byte
			$(OCAMLOPT) -I . -thread unix.cmxa threads.cmxa mysql.cmxa db.ml -o db.native
clean:
		ocamlbuild -clean
		rm *.cm*
		rm *.byte

server:
	make && ./server.byte

compile:
	ocamlbuild -use-ocamlfind db.cmo api.cmo backend_lib.cmo httpServer.cmo loml_client.cmo main.cmo oclient.cmo pool.cmo server.cmo student.cmo swipe.cmo professor.cmo command.cmo match.cmo

play:
	ocamlbuild -use-ocamlfind main.byte && ./main.byte

all: $(PROJECT)
