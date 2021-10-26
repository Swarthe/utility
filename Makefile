# look at <https://gist.github.com/postmodern/3224049>, especially for PKGBUILD

NAME=utility

BIN_FILES=`basename -a src/*`
DESK_FILES=`basename -a data/*`

PREFIX=/usr/local

BIN_DIR=$(PREFIX)/bin
DESK_DIR=$(PREFIX)/share/applications

install:
	mkdir -p $(BIN_DIR) $(DESK_DIR)
	for f in $(BIN_FILES);  do cp src/$$f $(BIN_DIR);   done
	for f in $(DESK_FILES);	do cp data/$$f $(DESK_DIR);	done

uninstall:
	for f in $(BIN_FILES); 	do rm $(BIN_DIR)/$$f; 	done
	for f in $(DESK_FILES);	do rm $(DESK_DIR)/$$f;	done

.PHONY: install uninstall
