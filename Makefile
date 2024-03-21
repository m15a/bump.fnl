FNLDOC ?= fnldoc
SRC := bump.fnl

README.md: $(SRC:fnl=md)
	mv $< $@
	sed -Ei $@ -e 's@^(#+) (Function|Macro|Example)@\1# \2@'

%.md: %.fnl
	$(FNLDOC) $<

.PHONY: test
test: $(SRC)
	$(FNLDOC) --mode check $<
