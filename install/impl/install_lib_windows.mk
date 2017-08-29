#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------


todo: install pkg-config files

# define windows-specific INSTALL_LIB macro

# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk

# $1 - library name (mylib for libmylib.a)
# note: $(INSTALL_LIB_BASE) is evaluated before expanding this macro, so $1_LIBRARY_NO_INSTALL_IMPORT is defined
# note: MAKE_IMP_PATH macro defined in $(CLEAN_BUILD_DIR)/compilers/msvc.mk
# note: use target-specific variables defined in INSTALL_LIB_BASE: BUILT_LIBS, BUILT_DLLS
# note: define target-specific variable: BUILT_IMPS
define INSTALL_LIB_WINDOWS

$(INSTALL_LIB_HEADERS)

ifeq (,$$($1_LIBRARY_NO_INSTALL_IMPORT))
ifneq (,$$($1_BUILT_DLLS))
$1_BUILT_IMPS := $(foreach d,$(call GET_TARGET_NAME,DLL),$(foreach v,$($1_BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$d,$v)))
install_lib_$1_import uninstall_lib_$1_import: BUILT_IMPS := $$($1_BUILT_IMPS)
install_lib_$1_import: $$($1_BUILT_IMPS)
install_lib_$1:   install_lib_$1_import
uninstall_lib_$1: uninstall_lib_$1_import
$(call SET_MAKEFILE_INFO,install_lib_$1_import uninstall_lib_$1_import)
endif
endif

ifeq (,$$($1_LIBRARY_NO_INSTALL_STATIC))
ifneq (,$$($1_BUILT_LIBS))
install_lib_$1_static:
	$$(call DO_INSTALL_FILES,$$(BUILT_LIBS),$$(D_LIBDIR),644)
uninstall_lib_$1_static:
	$$(call DO_UNINSTALL_FILES_IN,$$(D_LIBDIR),$$(notdir $$(BUILT_LIBS)))
endif
endif

ifeq (,$$($1_LIBRARY_NO_INSTALL_SHARED))
ifneq (,$$($1_BUILT_DLLS))
install_lib_$1_shared:
	$$(call DO_INSTALL_FILES,$$(BUILT_DLLS),$$(D_LIBDIR),755)
uninstall_lib_$1_shared:
	$$(call DO_UNINSTALL_FILES_IN,$$(D_LIBDIR),$$(notdir $$(BUILT_DLLS)))
endif
endif

ifeq (,$$($1_LIBRARY_NO_INSTALL_IMPORT))
ifneq (,$$($1_BUILT_IMPS))
install_lib_$1_import:
	$$(call INSTALL_FILES,$$(BUILT_IMPS),$$(D_LIBDIR),644)
uninstall_lib_$1_import:
	$$(call DO_UNINSTALL_FILES_IN,$$(D_LIBDIR),$$(notdir $$(BUILT_IMPS)))
endif
endif

endef

# define rules for installing/uninstalling library and its headers
# $1 - library name (mylib for libmylib.a)
# note: assume LIB and DLL variables are defined before expanding this template
INSTALL_LIB = $(eval $(INSTALL_LIB_BASE))$(eval $(INSTALL_LIB_WINDOWS))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INSTALL_LIB_WINDOWS INSTALL_LIB)
