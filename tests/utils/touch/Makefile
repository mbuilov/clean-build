#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

$(info ================ sh_touch =================)

# the first goal will be the default
all:

# define target-specific variable 'c_dir' - path to the directory of this makefile
all clean distclean: c_dir := $(dir $(lastword $(MAKEFILE_LIST)))

# test 'sh_touch' shell utility macro
all clean distclean:
	$(MAKE) -f $(c_dir)touch.mk $@
	$(if $(filter all,$@),$(MAKE) -f $(c_dir)check.mk)
	$(if $(filter all clean,$@),$(MAKE) -f $(c_dir)touch.mk test_phase:=2 $@)
	$(if $(filter all,$@),$(MAKE) -f $(c_dir)check.mk test_phase:=2)

# these targets are not files
.PHONY: all clean distclean
