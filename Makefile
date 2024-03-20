SRC := bump.fnl

README.md: $(SRC:fnl=md)
	mv $< $@
	sed -Ei $@ -e 's@^## (Function|Macro)@### \1@' -e 's@^### (Example)@#### \1@'

%.md: %.fnl
	fnldoc $<
