#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# add rules for building C/C++ sources
include $(dir $(lastword $(MAKEFILE_LIST)))make/c.mk

# define 'generated'    - list of generated sources: $(gen_dir)/tests/c/many_sources/f0.c $(gen_dir)/tests/c/many_sources/f1.c ...
# define 'test_gen_dir' - where test sources are generated
include $(top)/n.mk

dll := test
src := bar.c $(generated) $(test_gen_dir)/foo.c

# define targets and rules how to build them
$(define_targets)
