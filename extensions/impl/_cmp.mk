#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rule templates for comparing outputs of tested executables with given file, for the 'check' goal

ifeq (,$(filter check clean,$(MAKECMDGOALS)))

# do something only for the 'check' or 'clean' goals
gen_cmp_text:=

else # check or clean

CBLD_CMP_COLOR ?= [1;36m

# $1 - $(addsuffix .cmp,$2)
# $2 - list of outputs of tested executables (absolute paths)
# $3 - absolute path to the file to compare outputs with
# note: 'compare_files' - defined in $(utils_mk) makefile
define gen_cmp_text_templ
$(std_target_vars)
$(subst $(space),$(newline),$(join $(addsuffix :,$1),$2))
$1:
	$$(call suppress,CMP,$$@)$$(call compare_files,$$<,$3) > $$@
endef

# for the 'check' goal, compare outputs of tested executables with given file:
#  - if there is a difference, rule fails, else .cmp files are created.
# $1 - list of outputs of executables (absolute paths)
# $2 - path to the file to compare executable(s) outputs with (if path is makefile-relative - it will be fixed)
gen_cmp_text = $(eval $(call gen_cmp_text_templ,$(addsuffix .cmp,$1),$1,$(call fixpath,$2)))

endif # check or clean

# makefile parsing first phase variables
cb_first_phase_vars += gen_cmp_text gen_cmp_text_templ

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_CMP_COLOR cb_first_phase_vars)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: cmp
$(call set_global,gen_cmp_text gen_cmp_text_templ,cmp)
