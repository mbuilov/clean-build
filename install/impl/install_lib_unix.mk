#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define unix-specific INSTALL_LIB macro

# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk

# install shared libs and soname simlinks: libmylib.so.1 -> libmylib.so.1.2.3
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $3 - where to install shared libraries, should be $$(D_LIBDIR)
# note: override INSTALL_LIB_SHARED template from $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk
# note: assume $(MODVER) may be empty
define INSTALL_LIB_SHARED
install_lib_$1_shared uninstall_lib_$1_shared: BUILT_DLLS := $$($1_BUILT_DLLS)
install_lib_$1_shared: $$($1_BUILT_DLLS) | $$(call NEED_INSTALL_DIR_RET,$3)
	$$(foreach d,$$(BUILT_DLLS),$$(call \
  DO_INSTALL_FILES,$$d,$3/$$(notdir $$d)$(MODVER:%=.%),$(SHARED_LIB_FILE_ACCESS_MODE))$$(newline))$(foreach \
  n,$(filter-out $(firstword $(subst ., ,$(MODVER))),$(MODVER)),$$(foreach d,$$(notdir $$(BUILT_DLLS)),$$(call \
  DO_INSTALL_SIMLINK,$$d.$(MODVER),$3/$$d.$n)$$(newline)))
uninstall_lib_$1_shared:
	$$(call DO_UNINSTALL_FILES_IN,$3,$$(addsuffix $(MODVER:%=.%),$$(notdir $$(BUILT_DLLS)))$(foreach \
  n,$(filter-out $(firstword $(subst ., ,$(MODVER))),$(MODVER)), $$(addsuffix .$n,$$(notdir $$(BUILT_DLLS)))))
install_lib_$1:   install_lib_$1_shared
uninstall_lib_$1: uninstall_lib_$1_shared
$(call MAKEFILE_INFO_TEMPL,install_lib_$1_shared uninstall_lib_$1_shared)
endef

# install compile-time development simlinks to shared libs
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - where to install compile-time simlinks to shared libraries, should be $$(D_DEVLIBDIR)
# $3 - where to install shared libraries, should be $$(D_LIBDIR)
# note: $(MODVER) must be non-empty
define INSTALL_LIB_SIMLINKS
install_lib_$1_simlinks uninstall_lib_$1_simlinks: BUILT_DLLS := $$(notdir $$($1_BUILT_DLLS))
install_lib_$1_simlinks uninstall_lib_$1_simlinks: REL_PREFIX := $$(call \
  tospaces,$$(call relpath,$$(call unspaces,$2),$$(call unspaces,$3)))
install_lib_$1_simlinks: install_lib_$1_shared | $$(call NEED_INSTALL_DIR_RET,$2)
	$$(foreach d,$$(BUILT_DLLS),$$(call \
  DO_INSTALL_SIMLINK,$$(REL_PREFIX)$$d.$(MODVER),$2/$$d)$$(newline))
uninstall_lib_$1_simlinks:
	$$(call DO_UNINSTALL_FILES_IN,$2,$$(BUILT_DLLS))
install_lib_$1:   install_lib_$1_simlinks
uninstall_lib_$1: uninstall_lib_$1_simlinks
$(call MAKEFILE_INFO_TEMPL,install_lib_$1_simlinks uninstall_lib_$1_simlinks)
endef

# $1 - library name (mylib for libmylib.a)
# $2 - where to install static libraries, should be $$(D_DEVLIBDIR)
# $3 - where to install shared libraries, should be $$(D_LIBDIR)
# $4 - where to install pkg-configs, should be $(D_PKG_LIBDIR) or $(D_PKG_DATADIR)
# note: $(DEFINE_INSTALL_LIB_VARS) was evaluated before expanding this macro, so $1_... macros are defined
define INSTALL_LIB_UNIX
$(INSTALL_LIB_BASE)
$(if $($1_LIBRARY_NO_INSTALL_SHARED),,$(if $($1_LIBRARY_NO_DEVEL),,$(if $(MODVER),$(if $($1_BUILT_DLLS),$(INSTALL_LIB_SIMLINKS)))))
CLEAN_BUILD_GOALS += install_lib_$1_simlinks uninstall_lib_$1_simlinks
endef

# define rules for installing/uninstalling library and its headers
# $1 - library name (mylib for libmylib.a)
# note: assume LIB and DLL variables are defined before expanding this template
# note: install LIBs to $(D_DEVLIBDIR), DLLs - to $(D_LIBDIR)
INSTALL_LIB = $(eval $(DEFINE_INSTALL_LIB_VARS))$(eval $(call \
  INSTALL_LIB_UNIX,$1,$$(D_DEVLIBDIR),$$(D_LIBDIR),$$(call \
  DESTDIR_NORMALIZE,$(LIBRARY_PKGCONF_DIR))))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INSTALL_LIB_SIMLINKS INSTALL_LIB_UNIX INSTALL_LIB)
