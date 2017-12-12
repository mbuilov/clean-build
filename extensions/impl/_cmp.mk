#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rule templates for comparing outputs of tested executables with given file, for the 'check' goal

ifeq (,$(filter check clean,$(MAKECMDGOALS)))

# do something only for the 'check' or 'clean' goals
DO_CMP_TEXT:=

else # check or clean

CMP_COLOR := [1;36m

# $1 - $(addsuffix .cmp,$2)
# $2 - list of outputs of tested executables (absolute paths)
# $3 - absolute path to the file to compare outputs with
define DO_CMP_TEXT_TEMPLATE
$(STD_TARGET_VARS)
$(subst $(space),$(newline),$(join $(addsuffix :,$1),$2))
$1:
	$$(call SUP,CMP,$$@)$$(call COMPARE_FILES,$$<,$3) > $$@
endef

# for the 'check' goal, compare outputs of tested executables with given file:
#  - if there is a difference, rule fails, else .cmp files are created.
# $1 - list of outputs of executables (absolute paths)
# $2 - path to file to compare executable(s) outputs with (path may be makefile-relative and will be fixed)
DO_CMP_TEXT = $(eval $(call DO_CMP_TEXT_TEMPLATE,$(addsuffix .cmp,$1),$1,$(call fixpath,$2)))

endif # check or clean

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,DO_CMP_TEXT CMP_COLOR DO_CMP_TEXT_TEMPLATE)
