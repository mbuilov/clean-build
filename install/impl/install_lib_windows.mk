#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define windows-specific INSTALL_LIB macro

# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk

# file access mode of installed import libraries (rw-r--r--)
IMPORT_LIB_FILE_ACCESS_MODE := 644

# install import libs
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - where to install import libraries, should be $$(D_DEVLIBDIR)
# note: $(DEFINE_INSTALL_LIB_VARS) was evaluated before expanding this macro, so $1_BUILT_DLL_VARIANTS is defined
# note: MAKE_IMP_PATH macro defined in $(CLEAN_BUILD_DIR)/compilers/msvc.mk
define INSTALL_LIB_IMPORT
$1_BUILT_IMPS := $(foreach d,$(call GET_TARGET_NAME,DLL),$(foreach v,$($1_BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$d,$v)))
install_lib_$1_import uninstall_lib_$1_import: BUILT_IMPS := $$($1_BUILT_IMPS)
install_lib_$1_import: $$($1_BUILT_IMPS) | $$(call NEED_INSTALL_DIR_RET,$2)
	$$(call DO_INSTALL_FILES,$$(BUILT_IMPS),$2,$(IMPORT_LIB_FILE_ACCESS_MODE))
uninstall_lib_$1_import:
	$$(call DO_UNINSTALL_FILES_IN,$2,$$(notdir $$(BUILT_IMPS)))
install_lib_$1:   install_lib_$1_import
uninstall_lib_$1: uninstall_lib_$1_import
$(call MAKEFILE_INFO_TEMPL,install_lib_$1_import uninstall_lib_$1_import)
endef

# $1 - library name (mylib for libmylib.a)
# $2 - where to install static libraries, should be $$(D_DEVLIBDIR)
# $3 - where to install shared libraries, should be $$(D_BINDIR)
# $4 - where to install pkg-configs, should be $(D_PKG_LIBDIR) or $(D_PKG_DATADIR)
# note: $(DEFINE_INSTALL_LIB_VARS) was evaluated before expanding this macro, so $1_... macros are defined
define INSTALL_LIB_WINDOWS
$(INSTALL_LIB_BASE)
$(if $($1_LIBRARY_NO_INSTALL_IMPORT),,$(if $($1_BUILT_DLLS),$(INSTALL_LIB_IMPORT)))
CLEAN_BUILD_GOALS += install_lib_$1_import uninstall_lib_$1_import
endef

# define rules for installing/uninstalling library and its headers
# $1 - library name (mylib for libmylib.a)
# note: assume LIB and DLL variables are defined before expanding this template
# note: install LIBs to $(D_DEVLIBDIR), DLLs - to $(D_BINDIR)
INSTALL_LIB = $(eval $(DEFINE_INSTALL_LIB_VARS))$(eval $(call \
  INSTALL_LIB_WINDOWS,$1,$$(D_DEVLIBDIR),$$(D_BINDIR),$$(call \
  DESTDIR_NORMALIZE,$(LIBRARY_PKGCONF_DIR))))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,IMPORT_LIB_FILE_ACCESS_MODE INSTALL_LIB_IMPORT INSTALL_LIB_WINDOWS INSTALL_LIB)
