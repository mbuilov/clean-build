#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rule templates for creating symbolic links to built shared libraries
# (so runtime library linker may find them by their SONAMEs)

# remember all created simlinks in one global list - to not try to create the same simlink twice
cb_test_shlib_simlinks:=

ifndef toclean

# $1 - $(lib_dir)/$(dll_prefix)$(subst .,$(dll_suffix).,$d)         e.g.: /project/lib/libmylb.so.1
# $2 - $(dll_prefix)<library_name>$(dll_suffix)                     e.g.: libmylb.so
# $d - built shared library in form <library_name>.<major_number>   e.g.: mylib.1
# note: do not use 'cb_target_vars' macro because rule target (simlink) is a prerequisite for the result of tested executable
#  - needed target-specific variables will be inherited from that result
# note: 'test_form_shlib_simlinks' macro should be used to form a list of such prerequisites
# note: 'create_simlink' - defined in $(cb_dir)/utils/unix.mk
define so_softlink_template
$(suppress_targets_r):| $(dir $1)$2
	$$(call suppress,LN,$$@)$$(call create_simlink,$2,$$@)
cb_test_shlib_simlinks += $d
endef

# remember new value of 'cb_test_shlib_simlinks' list
# note: do not trace calls to variables modified via operator +=
ifdef cb_checking
$(call define_append,so_softlink_template,$(newline)$$(call set_global1,cb_test_shlib_simlinks))
endif

else # toclean

# just clean generated simlinks
so_softlink_template = $(toclean)

endif # toclean

# get full paths to created simlinks
# $1 - built shared libraries in form <library_name>.<major_number>
# note: convert: <library_name>.<major_number> -> $(lib_dir)/$(dll_prefix)<library_name>.$(dll_suffix).<major_number>
test_form_shlib_simlinks = $(addprefix $(lib_dir)/$(dll_prefix),$(subst .,$(dll_suffix).,$1))

# generate rules for creating simlinks to shared libraries
# $1 - built shared libraries, in form <library_name>.<major_number>
# note: convert: <library_name>.<major_number> -> $(dll_prefix)<library_name>$(dll_suffix)
test_create_shlib_simlinks = $(foreach d,$(filter-out $(cb_test_shlib_simlinks),$1),$(eval $(call \
  so_softlink_template,$(call test_form_shlib_simlinks,$d),$(dll_prefix)$(firstword $(subst ., ,$d))$(dll_suffix))))

# makefile parsing first phase variables
cb_first_phase_vars += cb_test_shlib_simlinks so_softlink_template test_form_shlib_simlinks test_create_shlib_simlinks

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_test_shlib_simlinks)

# protect variables from modifications in target makefiles
# note: trace namespace: simlinks
$(call set_global,so_softlink_template=d test_form_shlib_simlinks test_create_shlib_simlinks=cb_test_shlib_simlinks,simlinks)
