# look at <https://gist.github.come/postmodern/3224049>, especially for PKGBUILD

NAME=utility

SRCS  := `basename -a src/*`
DESKS := `basename -a data/*`

PREFIX := /usr/local

SRCDIR  := $(PREFIX)/bin
DESKDIR := $(PREFIX)/share/applications

install:
	mkdir -p $(SRCDIR) $(DESKDIR)
	for f in $(SRCS);  do cp src/$$f  $(SRCDIR);  done
	for f in $(DESKS); do cp data/$$f $(DESKDIR); done

uninstall:
	for f in $(SRCS);  do rm $(SRCDIR)/$$f;  done
	for f in $(DESKS); do rm $(DESKDIR)/$$f; done

.PHONY: install uninstall
