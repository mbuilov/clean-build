#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rule templates for comparing outputs of tested executables with given file, for the 'check' goal

ifndef cb_target_makefile
$(error 'defs.mk' must be included prior this file)
endif

ifeq (,$(filter check clean,$(MAKECMDGOALS)))

# do something only for the 'check' or 'clean' goals
cmp_text_rule:=

else # check or clean

# tool color for the 'suppress' macro
CBLD_CMP_COLOR ?= [1;36m

# $1 - $(addsuffix .cmp,$2)
# $2 - list of outputs of tested executables (absolute paths)
# $3 - absolute path to the file to compare outputs with
# note: 'compare_files' - defined in $(utils_mk) makefile (such as $(cb_dir)/utils/unix.mk)
define cmp_text_rule_templ
$(std_target_vars)
$(subst $(space),$(newline),$(join $(addsuffix :,$1),$2))
$1:
	$$(call suppress,CMP,$$@)$$(call compare_files,$$<,$3) > $$@
endef

# for the 'check' goal, compare outputs of tested executables with given file:
#  - if there is a difference, rule fails, else .cmp files are created.
# $1 - list of outputs of executables (absolute paths)
# $2 - path to the file to compare executable(s) outputs with (if path is makefile-relative - it will be fixed)
cmp_text_rule = $(eval $(call cmp_text_rule_templ,$(addsuffix .cmp,$1),$1,$(call fixpath,$2)))

endif # check or clean

# makefile parsing first phase variables
cb_first_phase_vars += cmp_text_rule cmp_text_rule_templ

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_CMP_COLOR cb_first_phase_vars)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: cmp
$(call set_global,cmp_text_rule cmp_text_rule_templ,cmp)
