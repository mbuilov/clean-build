#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic definitions
include $(dir $(lastword $(MAKEFILE_LIST)))make/defs.mk

# define 'seq'          - sequence of numbers: 0 1 2 ...
# define 'generated'    - list of generated sources: $(gen_dir)/tests/c/many_sources/f0.c $(gen_dir)/tests/c/many_sources/f1.c ...
# define 'test_gen_dir' - where test sources are generated
include $(top)/n.mk

ifndef toclean

# source template
# $1 - number: 0,1,2...
define src_text_templ
int bar(void);
int foo$1(void)
{
	return bar();
}
endef

# define target makefile-specific variables 'src_text_templ' and 'seq'
# note: 'seq' - defined in $(top)/n.mk
$(call set_makefile_specific,src_text_templ seq)

# define rules
# note: use target makefile-specific variable 'src_text_templ' defined above
# note: 'generated' - defined in $(top)/n.mk
$(call add_generated_r,$(generated)):
	$(call suppress,GEN,$@)$(call sh_print_some_lines,$(call src_text_templ,$(patsubst f%,%,$(basename $(notdir $@))))) > $@

# foo.c template
# note: 'seq' - target makefile-specific variable registered above via 'set_makefile_specific'
define foo_templ
int foo$(subst $(space),(void);$(newline)int foo,$(seq))(void);
int foo() {return 0
+ foo$(subst $(space),()$(newline)+ foo,$(seq))()
;}
endef

# 1) define target-specific recursive variable 'foo_templ'
# 2) register generated source $(test_gen_dir)/foo.c
# 3) define a rules for generating $(test_gen_dir)/foo.c
# note: 'test_gen_dir' - defined in $(top)/n.mk
$(test_gen_dir)/foo.c: $(call define_target_specific,foo_templ)
$(call add_generated_r,$(test_gen_dir)/foo.c):
	$(call suppress,GEN,$@)$(call sh_write_lines,$(foo_templ),$@,$(CBLD_MAX_PATH_ARGS))

else # toclean

# delete whole directory with generated sources on cleanup
$(call toclean,$(test_gen_dir))

endif # toclean

# define targets and rules how to build them
$(define_targets)
