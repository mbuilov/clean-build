#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rule for comparing test executable(s) outputs with given file, for 'check' goal

ifeq (,$(filter check clean,$(MAKECMDGOALS)))

# do something only for 'check' or 'clean' goals
DO_CMP_OUT:=

else # check or clean

CMP_COLOR := [1;36m

# $1 - $(addsuffix .cmp,$2)
# $2 - list of executable(s) outputs (absolute paths)
# $3 - absolute path to file to compare outputs with
define DO_CMP_OUT_TEMPLATE
$(ADD_GENERATED)
$1: CMP_WITH := $3
$(subst $(space),$(newline),$(join $(addsuffix :,$1),$2))
$1:
	$$(call SUP,CMP,$$@)$$(call CMP,$$<,$$(CMP_WITH)) > $$@ 2>&1
endef

# for 'check' goal, compare tested executable(s) outputs with given file;
# if there is difference, rule fails, else .cmp file(s) are created.
# $1 - list of executable(s) outputs (absolute paths)
# $2 - path to file to compare executable(s) outputs with (path may be makefile-relative and will be fixed)
DO_CMP_OUT = $(eval $(call DO_CMP_OUT_TEMPLATE,$(addsuffix .cmp,$1),$1,$(call fixpath,$2)))

endif # check or clean

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,CMP_COLOR DO_CMP_OUT_TEMPLATE DO_CMP_OUT)
