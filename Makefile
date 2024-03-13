# look at <https://gist.github.come/postmodern/3224049>, especially for PKGBUILD

SRCS      := src/*
DESKS     := data/*

PREFIX    := /usr/local
BINDIR    := $(PREFIX)/bin
DESKDIR   := $(PREFIX)/share/applications

SRCNAMES  := `basename -a src/*`
DESKNAMES := `basename -a data/*`

INSTALL   := install -vCDt
UNINSTALL := rm

install:
	$(INSTALL) $(BINDIR) $(SRCS)
	$(INSTALL) $(DESKDIR) $(DESKS)

uninstall:
	for f in $(SRCNAMES);  do $(UNINSTALL) $(BINDIR)/$$f;  done
	for f in $(DESKNAMES); do $(UNINSTALL) $(DESKDIR)/$$f; done

.PHONY: install uninstall
