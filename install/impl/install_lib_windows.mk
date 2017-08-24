#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define windows-specific INSTALL_LIB macro

# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk
# after including $(CLEAN_BUILD_DIR)/install/impl/inst_utils.mk
# and $(CLEAN_BUILD_DIR)/install/impl/inst_dirs.mk

# $1 - library name (mylib for libmylib.a)
# note: $(DEFINE_INSTALL_LIB_VARS) is evaluated before expanding this macro
# note: define target-specific variable BUILT_IMPS
# note: MAKE_IMP_PATH macro defined in $(CLEAN_BUILD_DIR)/compilers/msvc.mk
# note: use target-specific variables defined by DEFINE_INSTALL_LIB_VARS: BUILT_LIBS, BUILT_DLLS, HEADERS

todo: install pkg-config files

define INSTALL_LIB_WINDOWS

install_$1 uninstall_$1: BUILT_IMPS := $(if $($1_LIBRARY_NO_INSTALL_IMPS),,$(foreach \
  d,$(call GET_TARGET_NAME,DLL),$(foreach v,$($1_BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$d,$v))))

ifneq (,$$($1_LIBRARY_HEADERS))

install_$1_headers:
	$$(call INSTALL_FILES,$$(HEADERS),$$(D_INCLUDEDIR)$($1_LIBRARY_HDIR),644)

uninstall_$1_headers:
	$(if $($1_LIBRARY_HDIR),$$(call UNINSTALL_RMDIR,$$(D_INCLUDEDIR)$($1_LIBRARY_HDIR)),$$(call \
  UNINSTALL_DELIN,$$(D_INCLUDEDIR),$$(notdir $$(HEADERS))))

endif

ifneq (,$($1_BUILT_LIBS)$($1_BUILT_DLLS))

install_$1:$(if \
  $($1_BUILT_LIBS)$(if $($1_LIBRARY_NO_INSTALL_IMPS),,$($1_BUILT_DLLS)),$(newline)$(tab)$$(call \
   INSTALL_FILES,$$(BUILT_LIBS) $$(BUILT_IMPS),$$(D_LIBDIR),644))$(if \
  $($1_BUILT_DLLS),$(newline)$(tab)$$(call \
   INSTALL_FILES,$$(BUILT_DLLS),$$(D_LIBDIR),755))

uninstall_$1:
	$$(call UNINSTALL_DELIN,$$(D_LIBDIR),$$(notdir $$(BUILT_LIBS) $$(BUILT_DLLS) $$(BUILT_IMPS)))

endif

endef

# define rules for installing/uninstalling library and its headers
# $1 - library name (mylib for libmylib.a)
# note: assume LIB and DLL variables are defined before expanding this template
INSTALL_LIB = $(eval $(DEFINE_INSTALL_LIB_VARS))$(eval $(INSTALL_LIB_WINDOWS))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INSTALL_LIB_WINDOWS INSTALL_LIB)
