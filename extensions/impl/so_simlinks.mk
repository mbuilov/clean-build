#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# templates for creating simlinks to built shared libraries
# (so runtime library linker may find them by their SONAMEs)

ifndef TOCLEAN

# remember all created simlinks in one global list - to not try to create the same simlink twice
CB_TEST_SHLIB_SIMLINKS_LIST:=

# $1 - $(LIB_DIR)/$(DLL_PREFIX)$(subst .,$(DLL_SUFFIX).,$d)         e.g.: /project/lib/libmylb.so.1
# $2 - $(DLL_PREFIX)<library_name>$(DLL_SUFFIX)                     e.g.: libmylb.so
# $d - built shared library in form <library_name>.<major_number>   e.g.: mylib.1
# note: optimize: do not use ADD_GENERATED/STD_TARGET_VARS
define SO_SOFTLINK_TEMPLATE
$1:| $(LIB_DIR)/$2
	$$(call SUP,LN,$$@)$$(call CREATE_SIMLINK,$2,$$@)
CB_TEST_SHLIB_SIMLINKS_LIST += $d
endef

# remember new value of CB_TEST_SHLIB_SIMLINKS_LIST
ifdef MCHECK
$(call define_append,SO_SOFTLINK_TEMPLATE,$(newline)$$(call SET_GLOBAL1,CB_TEST_SHLIB_SIMLINKS_LIST,0))
endif

else # TOCLEAN

# just clean generated simlinks
SO_SOFTLINK_TEMPLATE = $(TOCLEAN)

endif # TOCLEAN

# get full paths to simlinks
# $1 - built shared libraries needed by the executable, in form <library_name>.<major_number>
TEST_FORM_SHLIB_SIMLINKS = $(addprefix $(LIB_DIR)/$(DLL_PREFIX),$(subst .,$(DLL_SUFFIX).,$1))

# generate rules for creating simlinks to shared libraries
# $1 - built shared libraries, in form <library_name>.<major_number>
# note: convert: <library_name>.<major_number> -> $(LIB_DIR)/$(DLL_PREFIX)<library_name>.$(DLL_SUFFIX).<major_number>
# note: convert: <library_name>.<major_number> -> $(DLL_PREFIX)<library_name>$(DLL_SUFFIX)
TEST_CREATE_SHLIB_SIMLINKS = $(foreach d,$(filter-out $(CB_TEST_SHLIB_SIMLINKS_LIST),$1),$(eval $(call \
  SO_SOFTLINK_TEMPLATE,$(call TEST_FORM_SHLIB_SIMLINKS,$d),$(DLL_PREFIX)$(firstword $(subst ., ,$d))$(DLL_SUFFIX))))

# protect variables from modifications in target makefiles
# note: do not trace calls to CB_TEST_SHLIB_SIMLINKS_LIST because it is incremented
$(call SET_GLOBAL,CB_TEST_SHLIB_SIMLINKS_LIST,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,SO_SOFTLINK_TEMPLATE=d TEST_FORM_SHLIB_SIMLINKS TEST_CREATE_SHLIB_SIMLINKS=CB_TEST_SHLIB_SIMLINKS_LIST)
