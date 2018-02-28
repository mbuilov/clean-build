c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

all:

many_sources:
	$(MAKE) -f $(c_dir)many_sources/Makefile

all: \
  many_sources
	@echo all tests passed

.PHONY: all \
  many_sources
