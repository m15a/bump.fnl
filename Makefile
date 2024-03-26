FNLDOC ?= fnldoc
SRC := bump.fnl

.PHONY: readme
readme: README.md

README.md: $(SRC:fnl=md)
	mv $< $@
	sed -Ei $@ -e 's@^(#+) (Function|Macro|Example)@\1# \2@'

%.md: %.fnl
	$(FNLDOC) $<

.PHONY: test
test: $(SRC)
	$(FNLDOC) --mode check $<
