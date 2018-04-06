#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# the first goal will be the default
all:

# define target-specific variable 'c_dir' - path to the directory of this makefile
all clean distclean: c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

# tests
all clean distclean:
	$(MAKE) -f $(c_dir)shell_escape/Makefile $@
	$(MAKE) -f $(c_dir)touch/Makefile $@

# these targets are not files
.PHONY: all clean distclean
