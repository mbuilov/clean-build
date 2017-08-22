#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define unix-specific INSTALL_LIBS_TEMPLATE macro

# included by $(CLEAN_BUILD_DIR)/exts/_install_lib.mk

# defaults, may be overridden either in command line or in project configuration makefile
# note: assume PREFIX, EXEC_PREFIX, LIBDIR, INCLUDEDIR and PKG_CONFIG_DIR _may_ contain spaces
PREFIX         := /usr/local
EXEC_PREFIX    := $(PREFIX)
LIBDIR         := $(EXEC_PREFIX)/lib
INCLUDEDIR     := $(PREFIX)/include
PKG_CONFIG_DIR := $(LIBDIR)/pkgconfig
INSTALL        := $(if $(filter SOLARIS,$(OS)),/usr/ucb/install,install)
LDCONFIG       := $(if $(filter LINUX,$(OS)),/sbin/ldconfig)

# uninstall files
# $1 - files to delete
# $2 - r (to delete recursively) or <empty>
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
UNINSTALL_RM = $(call SUP,$(if $2,RM,DEL),$1,1,1)$(call $(if $2,RM,DEL),$1)

# create symbolic link while installing files
# $1 - target
# $2 - simlink
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_LN = $(call SUP,LN,'$2' -> $1,1,1)$(call LN,$1,'$2')

# INSTALL tool color
INSTALL_COLOR := [1;31m

# post-install/uninstall shared libraries
# $1 - inst/uninst
ifdef LDCONFIG

# LDCONFIG tool color
LDCONF_COLOR := [1;33m

# $1 - inst/uninst
# $2 - full paths to built dlls
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
LDCONFIG_TEMPLATE = $(if $2,$(newline)$(tab)$$(call \
  SUP,LDCONF,'$$(DESTDIR)$$(LIBDIR)',1,1)$$(LDCONFIG) -n$(if $(VERBOSE),v) '$$(DESTDIR)$$(LIBDIR)'$(if $(VERBOSE), >&2))

else # !LDCONFIG

# $1 - inst/uninst
# $2 - full paths to built dlls
# note: $j in template - major version
LDCONFIG_TEMPLATE = $(foreach j,$(filter-out $(MODVER),$(firstword $(subst ., ,$(MODVER)))),$(if $(filter inst,$1),$$(foreach \
  d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call INSTALL_LN,$$d.$(MODVER),$$(DESTDIR)$$(LIBDIR)/$$d.$j)),$(if \
  $2,$(newline)$(tab)$$(call UNINSTALL_RM,$$(foreach d,$$(notdir $$(BUILT_DLLS)),'$$(DESTDIR)$$(LIBDIR)/$$d.$j')))))

endif # !LDCONFIG

include $(CLEAN_BUILD_DIR)/exts/all_libs.mk
include $(CLEAN_BUILD_DIR)/exts/pc.mk
include $(CLEAN_BUILD_DIR)/exts/la.mk

# this macro may be usable for .pc-file contents generator macro,
# which name is passed to INSTALL_PKGCONFS from $(CLEAN_BUILD_DIR)/exts/pc.mk
# choose CFLAGS option for static library variant $1
# note: PIE_OPTION/PIC_OPTION - should be defined in $(OSDIR)/$(OS)/c.mk
VARIANT_CFLAGS = $(if \
  $(filter P,$1), $(PIE_OPTION),$(if \
  $(filter D,$1), $(PIC_OPTION)))

# $1 - library name (mylib for libmylib.a)
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
# note: define some variables as target-specific to be able to use them in .pc-file contents generator macro $(LIBRARY_PC_GEN)
# note: $(DEFINE_INSTALL_VARIABLES) must be evaluated before expanding this macro
define INSTALL_LIBS_TEMPLATE_UNIX

install_$1 uninstall_$1: MODVER  := $(MODVER)
install_$1 uninstall_$1: DEFINES := $(DEFINES)
install_$1 uninstall_$1: BUILT_LIBS := $($1_BUILT_LIBS)
install_$1 uninstall_$1: BUILT_DLLS := $($1_BUILT_DLLS)
install_$1 uninstall_$1: ALL_BUILT_LIBS := $(call \
  GET_ALL_LIBS,$($1_BUILT_LIBS),$($1_BUILT_LIB_VARIANTS),$($1_BUILT_DLLS),$($1_BUILT_DLL_VARIANTS))
install_$1_headers uninstall_$1_headers: HEADERS := $($1_LIBRARY_HEADERS)

install_$1_headers:$(if $($1_LIBRARY_HEADERS),$(newline)$(tab)$$(call \
  SUP,MKDIR,'$$(DESTDIR)$$(INCLUDEDIR)$($1_LIBRARY_HDIR)',1,1)$$(INSTALL) -d\
 '$$(DESTDIR)$$(INCLUDEDIR)$($1_LIBRARY_HDIR)'$(newline)$(tab)$$(call \
  SUP,INSTALL,$$(HEADERS) -> '$$(DESTDIR)$$(INCLUDEDIR)$($1_LIBRARY_HDIR)',1,1)$$(INSTALL) -m 644\
 $$(HEADERS) '$$(DESTDIR)$$(INCLUDEDIR)$($1_LIBRARY_HDIR)')

uninstall_$1_headers:$(if $($1_LIBRARY_HEADERS),$(newline)$(tab)$$(call \
  UNINSTALL_RM,$(if $($1_LIBRARY_HDIR),'$$(DESTDIR)$$(INCLUDEDIR)$($1_LIBRARY_HDIR)',$$(addprefix \
 '$$(DESTDIR)$$(INCLUDEDIR)/,$$(addsuffix ',$$(notdir $$(HEADERS))))),r))

install_$1:$(if $($1_LIBRARY_NO_INSTALL_HEADERS),,install_$1_headers)$(if \
  $($1_BUILT_LIBS)$($1_BUILT_DLLS),$(newline)$(tab)$$(call \
 SUP,MKDIR,'$$(DESTDIR)$$(LIBDIR)',1,1)$$(INSTALL) -d '$$(DESTDIR)$$(LIBDIR)'$(newline)$(tab)$$(foreach \
  l,$$(BUILT_LIBS),$$(newline)$$(call \
 SUP,INSTALL,'$$(DESTDIR)$$(LIBDIR)/$$(notdir $$l)',1,1)$$(INSTALL) -m 644 $$l '$$(DESTDIR)$$(LIBDIR)')$(newline)$(tab)$$(foreach \
  d,$$(BUILT_DLLS),$$(newline)$$(call \
 SUP,INSTALL,'$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d).$(MODVER)',1,1)$$(INSTALL) -m 755 $$d '$$(DESTDIR)$$(LIBDIR)/$$(notdir \
  $$d).$(MODVER)')$(newline)$(tab)$$(foreach \
 d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call INSTALL_LN,$$d.$(MODVER),$$(DESTDIR)$$(LIBDIR)/$$d))$(if \
  $($1_LIBRARY_NO_INSTALL_LA),,$(newline)$(tab)$$(call INSTALL_LIBTOOL_ARCHIVES,$$(ALL_BUILT_LIBS),$$(BUILT_LIBS),$$(BUILT_DLLS)))$(if \
  $($1_LIBRARY_NO_INSTALL_PC),,$(newline)$(tab)$$(call \
 SUP,MKDIR,'$$(DESTDIR)$$(PKG_CONFIG_DIR)',1,1)$$(INSTALL) -d '$$(DESTDIR)$$(PKG_CONFIG_DIR)'$(newline)$(tab)$$(call \
  INSTALL_PKGCONFS,$$(ALL_BUILT_LIBS),$(LIBRARY_PC_GEN)))$(call LDCONFIG_TEMPLATE,inst))

uninstall_$1:$(if $($1_LIBRARY_NO_INSTALL_HEADERS),,uninstall_$1_headers)$(if \
  $($1_BUILT_LIBS)$($1_BUILT_DLLS),$(newline)$(tab)$$(call UNINSTALL_RM,$$(addprefix \
  '$$(DESTDIR)$$(LIBDIR)/,$$(addsuffix ',$$(notdir $$(BUILT_LIBS))))$(space)$$(foreach \
  d,$$(notdir $$(BUILT_DLLS)),'$$(DESTDIR)$$(LIBDIR)/$$d' '$$(DESTDIR)$$(LIBDIR)/$$d.$(MODVER)')$(space)$(if \
  $($1_LIBRARY_NO_INSTALL_LA),,$$(call INSTALLED_LIBTOOL_ARCHIVES,$$(ALL_BUILT_LIBS),$$(BUILT_LIBS),$$(BUILT_DLLS)))$(space)$(if \
  $($1_LIBRARY_NO_INSTALL_PC),,$$(call INSTALLED_PKGCONFS,$$(ALL_BUILT_LIBS))))$(call LDCONFIG_TEMPLATE,uninst))

endef

# $1 - library name (mylib for libmylib.a)
# note: this macro is expanded after $(DEFINE_TARGETS) in target makefile, so LIB/DLL - are defined
INSTALL_LIBS_TEMPLATE = $(eval $(DEFINE_INSTALL_VARIABLES))$(eval $(INSTALL_LIBS_TEMPLATE_UNIX))

