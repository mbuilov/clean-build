#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define windows-specific INSTALL_LIB macro

# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk
# after including $(CLEAN_BUILD_DIR)/install/impl/inst_utils.mk
# and $(CLEAN_BUILD_DIR)/install/impl/inst_vars.mk

# $1 - library name (mylib for libmylib.a)
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
# note: define target-specific variable BUILT_IMPS
# note: $(DEFINE_INSTALL_LIB_VARS) is evaluated before expanding this macro
# note: MAKE_IMP_PATH defined in $(CLEAN_BUILD_DIR)/compilers/msvc.mk
# note: use target-specific variables: HEADERS
define INSTALL_LIB_WINDOWS

install_$1 uninstall_$1: BUILT_IMPS := $(if $($1_LIBRARY_NO_INSTALL_IMPS),,$(foreach \
  v,$($1_BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$(call GET_TARGET_NAME,DLL),$v)))

install_$1_headers:
	$$(call INSTALL_CP,$$(HEADERS),$$(D_INCLUDEDIR)/$($1_LIBRARY_HDIR))

uninstall_$1_headers:$(if $($1_LIBRARY_HEADERS),$(newline)$(tab)$(if $($1_LIBRARY_HDIR),$$(call \
  UNINSTALL_DEL_DIR,,$$(D_INCLUDEDIR)/$($1_LIBRARY_HDIR)),

  SUP,RD,$$(call ospath,$$(call ifaddq,$$(D_INCLUDEDIR)/$($1_LIBRARY_HDIR))),1,1)$$(call \
  DEL_DIR,$$(call ifaddq,$$(D_INCLUDEDIR)/$($1_LIBRARY_HDIR))),$$(foreach h,$$(notdir $$(HEADERS)),$$(newline)$$(call \
  SUP,DEL,$$(call ospath,$$(call ifaddq,$$(D_INCLUDEDIR)/$$h)),1,1)$$(call DEL,$$(call ifaddq,$$(D_INCLUDEDIR)/$$h)))))

install_$1:$(if $($1_LIBRARY_NO_INSTALL_HEADERS),,install_$1_headers)$(if \
  $($1_BUILT_LIBS)$($1_BUILT_DLLS), | $(DST_LIB_DIR)$(newline)$(tab)$$(foreach l,$$(BUILT_LIBS),$$(newline)$$(call \
 SUP,INSTALL,$$(call ospath,$$(call ifaddq,$$(D_LIBDIR)/$$(notdir $$l))),1,1)$$(call CP,$$l,$$(call ifaddq,$$(D_LIBDIR))))$(if \
  ,)$(newline)$(tab)$$(foreach d,$$(BUILT_DLLS),$$(newline)$$(call \
 SUP,INSTALL,$$(call ospath,$$(call ifaddq,$$(D_LIBDIR)/$$(notdir $$d))),1,1)$$(call CP,$$d,$$(call ifaddq,$$(D_LIBDIR))))$(if \
  $($1_LIBRARY_NO_INSTALL_IMPS),,$(newline)$(tab)$$(foreach i,$$(BUILT_IMPS),$$(newline)$$(call \
 SUP,INSTALL,$$(call ospath,$$(call ifaddq,$$(D_LIBDIR)/$$(notdir $$i))),1,1)$$(call CP,$$i,$$(call ifaddq,$$(D_LIBDIR))))))

uninstall_$1:$(if $($1_LIBRARY_NO_INSTALL_HEADERS),,uninstall_$1_headers)$(if \
  $($1_BUILT_LIBS)$($1_BUILT_DLLS),$(newline)$(tab)$$(foreach l,$$(notdir $$(BUILT_LIBS)),$$(newline)$$(call \
 SUP,DEL,$$(call ospath,$$(call ifaddq,$$(D_LIBDIR)/$$l)),1,1)$$(call DEL,$$(call ifaddq,$$(D_LIBDIR)/$$l)))$(if \
  ,)$(newline)$(tab)$$(foreach d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call \
 SUP,DEL,$$(call ospath,$$(call ifaddq,$$(D_LIBDIR)/$$d)),1,1)$$(call DEL,$$(call ifaddq,$$(D_LIBDIR)/$$d)))$(if \
  $($1_LIBRARY_NO_INSTALL_IMPS),,$(newline)$(tab)$$(foreach i,$$(notdir $$(BUILT_IMPS)),$$(newline)$$(call \
 SUP,DEL,$$(call ospath,$$(call ifaddq,$$(D_LIBDIR)/$$i)),1,1)$$(call DEL,$$(call ifaddq,$$(D_LIBDIR)/$$i)))))

endef

# define rules for installing/uninstalling library and its headers
# $1 - library name (mylib for libmylib.a)
# note: assume LIB and DLL variables are defined before expanding this template
INSTALL_LIB = $(eval \
  $(DEFINE_INSTALL_LIB_VARS))$(eval \
  $(DEFINE_INSTALL_LIB_VARS_WIN))$(eval \
  $(INSTALL_LIB_WINDOWS))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,DEFINE_INSTALL_LIB_VARS_WIN INSTALL_LIB_WINDOWS INSTALL_LIB)
