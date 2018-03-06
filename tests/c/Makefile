# the first goal will be the default
all:

# define target-specific variable 'c_dir' - path to the directory of this makefile
all clean distclean: c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

# tests
all clean distclean:
	$(MAKE) -f $(c_dir)many_sources/Makefile $@

.PHONY: all clean distclean
