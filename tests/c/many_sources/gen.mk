#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic definitions
include $(dir $(lastword $(MAKEFILE_LIST)))make/defs.mk

# define 'generated' - list of generated sources: $(gen_dir)/tests/c/many_sources/f0.c $(gen_dir)/tests/c/many_sources/f1.c ...
include $(top)/n.mk

# source template
# $1 - number: 0,1,2...
define src_text_templ
int bar(void);
int foo$1(void)
{
	return bar();
}
endef

# define target makefile-specific variable 'src_text_templ'
$(call set_makefile_specific,src_text_templ)

# define rules
# note: use target makefile-specific variable 'src_text_templ' defined above
$(call add_generated_ret,$(generated)):
	$(call suppress,GEN,$@)$(call print_some_lines,$(call src_text_templ,$(patsubst f%,%,$(basename $(notdir $@))))) > $@

# define targets and rules how to build them
$(define_targets)
