#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define windows-specific INSTALL_LIBS_TEMPLATE macro

# included by $(CLEAN_BUILD_DIR)/exts/_install_lib.mk
# after including $(CLEAN_BUILD_DIR)/exts/inst_vars.mk

# make full paths to installed include/library directories
# note: this macro must be expanded after evaluating $(DEFINE_INSTALL_LIB_VARIABLES)
# note: $(STD_INCLUDEDIR), $(STD_LIBDIR) _may_ return paths with spaces, but $($1_LIBRARY_HDIR) must not contain spaces
# $1 - library name (mylib for libmylib.a)
define DEFINE_INSTALL_VARIABLES_WIN
DST_INC_DIR := $(subst $(space),\ ,$(STD_INCLUDEDIR))$($1_LIBRARY_HDIR)
DST_LIB_DIR := $(subst $(space),\ ,$(STD_LIBDIR))
endef

# $1 - library name (mylib for libmylib.a)
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
# note: define some variables as target-specific ones
# note: $(DEFINE_INSTALL_LIB_VARIABLES) and then $(DEFINE_INSTALL_VARIABLES_WIN) must be evaluated before expanding this macro
define INSTALL_LIBS_TEMPLATE_WINDOWS

$(if $($1_BUILT_LIBS)$($1_BUILT_DLLS),$(call ADD_INSTALL_DIR,$(DST_LIB_DIR)))
$(if $($1_LIBRARY_NO_INSTALL_HEADERS),,$(if $($1_LIBRARY_HEADERS),$(call ADD_INSTALL_DIR,$(DST_INC_DIR))))

install_$1 uninstall_$1: BUILT_LIBS := $($1_BUILT_LIBS)
install_$1 uninstall_$1: BUILT_DLLS := $($1_BUILT_DLLS)
install_$1 uninstall_$1: BUILT_IMPS := $(foreach v,$($1_BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$(call GET_TARGET_NAME,DLL),$v))
install_$1_headers uninstall_$1_headers: HEADERS := $$($1_LIBRARY_HEADERS)

install_$1_headers:$(if $($1_LIBRARY_HEADERS),| $(DST_INC_DIR)$(newline)$(tab)$$(call \
  SUP,COPY,$$(call ospath,$$(HEADERS)) -> "$$(call ospath,$$(DESTDIR)$$(INCLUDEDIR)$($1_LIBRARY_HDIR))",1,1)$$(foreach \
  h,$$(HEADERS),$$(newline)$(QUIET)$$(call CP,$$h,"$$(DESTDIR)$$(INCLUDEDIR)$($1_LIBRARY_HDIR)")))

uninstall_$1_headers:$(if $($1_LIBRARY_HEADERS),$(newline)$(tab)$(if $($1_LIBRARY_HDIR),$$(call \
  SUP,RD,"$$(call ospath,$$(DESTDIR)$$(INCLUDEDIR)$($1_LIBRARY_HDIR))",1,1)$$(call \
  DEL_DIR,"$$(DESTDIR)$$(INCLUDEDIR)$($1_LIBRARY_HDIR)"),$$(foreach h,$$(notdir $$(HEADERS)),$$(newline)$$(call \
  SUP,DEL,"$$(call ospath,$$(DESTDIR)$$(INCLUDEDIR)/$$h)",1,1)$$(call DEL,"$$(DESTDIR)$$(INCLUDEDIR)/$$h"))))

install_$1:$(if $($1_LIBRARY_NO_INSTALL_HEADERS),,install_$1_headers)$(if \
  $($1_BUILT_LIBS)$($1_BUILT_DLLS), | $(DST_LIB_DIR)$(newline)$(tab)$$(foreach l,$$(BUILT_LIBS),$$(newline)$$(call \
 SUP,INSTALL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$(notdir $$l))",1,1)$$(call CP,$$l,"$$(DESTDIR)$$(LIBDIR)"))$(newline)$(tab)$$(foreach \
  d,$$(BUILT_DLLS),$$(newline)$$(call \
 SUP,INSTALL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d))",1,1)$$(call CP,$$d,"$$(DESTDIR)$$(LIBDIR)"))$(if \
  $($1_LIBRARY_NO_INSTALL_IMPS),,$(newline)$(tab)$$(foreach i,$$(BUILT_IMPS),$$(newline)$$(call \
 SUP,INSTALL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$(notdir $$i))",1,1)$$(call CP,$$i,"$$(DESTDIR)$$(LIBDIR)"))))

uninstall_$1:$(if $($1_LIBRARY_NO_INSTALL_HEADERS),,uninstall_$1_headers)$(if \
  $($1_BUILT_LIBS)$($1_BUILT_DLLS),$(newline)$(tab)$$(foreach l,$$(notdir $$(BUILT_LIBS)),$$(newline)$$(call \
 SUP,DEL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$l)",1,1)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$l"))$(newline)$(tab)$$(foreach \
  d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call \
 SUP,DEL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$d)",1,1)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$d"))$(if \
  $($1_LIBRARY_NO_INSTALL_IMPS),,$(newline)$(tab)$$(foreach i,$$(notdir $$(BUILT_IMPS)),$$(newline)$$(call \
 SUP,DEL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$i)",1,1)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$i"))))

endef

# define rules for installing/uninstalling libraries and headers
# $1 - library name (mylib for libmylib.a)
# note: assume LIB and DLL variables are defined before expanding this template
INSTALL_LIBS_TEMPLATE = $(eval \
  $(DEFINE_INSTALL_LIB_VARIABLES))$(eval \
  $(DEFINE_INSTALL_VARIABLES_WIN))$(eval \
  $(INSTALL_LIBS_TEMPLATE_WINDOWS))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,DEFINE_INSTALL_VARIABLES_WIN INSTALL_LIBS_TEMPLATE_WINDOWS INSTALL_LIBS_TEMPLATE)
