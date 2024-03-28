FENNEL ?= fennel
FNLDOC ?= fnldoc
FAITH ?= faith

API_SRC := bump.fnl
SRCS := $(API_SRC) $(shell find bump -name '*.fnl')
TESTS := $(shell find t -name '*.fnl' ! -name 'init*' ! -name 'bump.fnl' \
		 ! -iregex '^t/[fp]/.*')

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
	$(FAITH) --tests $(subst /,.,$(patsubst %.fnl,%,$(TESTS)))

.PHONY: doctest
doctest: $(API_SRC)
	$(FNLDOC) --mode check $<
