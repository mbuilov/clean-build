xxx := aaa bbb

.PHONY: all clean $(xxx)

aaa: bbb

aaa: a.1
	@echo $@

a.1: | bbb

bbb: b.1
	@echo $@

all: $(xxx)
	@echo done

clean:
	rm a.1 b.1

a.1 b.1:
	@echo $@
	sleep 1
	touch $@

.DEFAULT_GOAL := all
.SUFFIXES:

