LUA ?= lua
FENNEL ?= fennel
FNLDOC ?= fnldoc
FAITH ?= faith
DOCKER ?= docker

API_SRC := bump.fnl
MAIN_SRC := bump/main.fnl
SRCS := $(API_SRC) $(shell find bump -name '*.fnl')
TESTS := $(shell find t -regex '^t/api/[^/]+\.fnl$$' \
		 -o -regex '^t/int/[^/]+\.fnl$$')

FENNEL_BUILD_FLAGS = --no-metadata --require-as-include --compile
EXECUTABLE := bin/bump
VERSION ?= $(shell $(FENNEL) -e '(. (require :bump) :version)')

DESTDIR ?=
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

DOCKERDIR := docker
DOCKER_SRCS := $(foreach s,$(SRCS) Makefile,$(DOCKERDIR)/$(s))

.PHONY: build
build: $(EXECUTABLE)

$(EXECUTABLE): $(SRCS) $(dir $(EXECUTABLE))
	echo '#!/usr/bin/env $(LUA)' > $@
	$(FENNEL) $(FENNEL_BUILD_FLAGS) $(MAIN_SRC) >> $@
	sed -i $@ -Ee '1,+5s#^(\s*local version = ")[^"]+#\1$(VERSION)#'
	chmod +x $@

$(dir $(EXECUTABLE)):
	mkdir -p $@

.PHONY: install
install: $(EXECUTABLE)
	install -pm755 -Dt $(DESTDIR)$(BINDIR) $<

.PHONY: clean
clean:
	rm -f $(EXECUTABLE) $(DOCKER_SRCS)

.PHONY: docker-image
docker-image: $(DOCKER_SRCS)
	$(DOCKER) build -t bump.fnl $(DOCKERDIR)

$(DOCKERDIR)/%: %
	cp $< $@
$(DOCKERDIR)/bump/%: bump/% $(DOCKERDIR)/bump
	cp $< $@
$(DOCKERDIR)/bump/utils/%: bump/utils/% $(DOCKERDIR)/bump/utils
	cp $< $@
$(DOCKERDIR)/bump:
	mkdir -p $@
$(DOCKERDIR)/bump/utils:
	mkdir -p $@

.PHONY: readme
readme: README.md

README.md: $(API_SRC:fnl=md)
	mv $< $@
	sed -Ei $@ -e 's@^(#+) (Function|Macro|Example)@\1# \2@'

%.md: %.fnl
	$(FNLDOC) $<

.PHONY: check
check: test doctest

.PHONY: test
test: $(SRCS) $(TESTS)
	@$(FENNEL) --version
	$(FAITH) --tests $(subst /,.,$(patsubst %.fnl,%,$(TESTS)))

.PHONY: doctest
doctest: $(API_SRC)
	$(FNLDOC) --mode check $<
