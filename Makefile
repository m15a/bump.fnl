FENNEL ?= fennel
FNLDOC ?= fnldoc
FAITH ?= faith

SRC := bump.fnl
TESTS := $(shell find t -name '*.fnl' ! -name 'init*' ! -name 'bump.fnl' \
		 ! -iregex '^t/[fp]/.*')

.PHONY: readme
readme: README.md

README.md: $(SRC:fnl=md)
	mv $< $@
	sed -Ei $@ -e 's@^(#+) (Function|Macro|Example)@\1# \2@'

%.md: %.fnl
	$(FNLDOC) $<

.PHONY: check
check: test doctest

.PHONY: test
test: t/$(SRC) $(TESTS)
	$(FAITH) --tests $(subst /,.,$(patsubst %.fnl,%,$(TESTS)))

.PHONY: doctest
doctest: $(SRC)
	$(FNLDOC) --mode check $<

t/$(SRC): $(SRC)
	cat $< | sed -E 's@^(\s*);INTERNAL :@\1:@' > $@
