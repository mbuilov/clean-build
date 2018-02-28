# the first goal will be the default
all:

# define target-specific variable 'c_dir' - path to the directory of this makefile
all clean distclean: c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

# test 'shell_escape' macro
all clean distclean:
	$(MAKE) -f $(c_dir)shell_escape/Makefile $@

.PHONY: all clean distclean
