#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# auxiliary templates to simplify library installation

ifndef INSTALL_LIBS_TEMPLATE

# this file is likely included in target makefile after $(DEFINE_TARGETS) which builds:
# LIB - static library name with variants and/or
# DLL - dynamic library name with variants

# anyway, LIB and DLL variables _must_ be defined before expanding INSTALL_LIBS_TEMPLATE

# DESTDIR must be defined as empty in all clean-build makefiles where DESTDIR is used
DESTDIR:=

# set defaults
# note: next NO_... variables may be defined in project configuration makefile before including this file via override directive

# non-empty if do not install development files and headers
NO_DEVEL:=

# non-empty if do not install/uninstall header files
NO_INSTALL_HEADERS = $(LIBRARY_NO_DEVEL)
# non-empty if do not install/uninstall libtool .la-files (UNIX)
NO_INSTALL_LA      = $(LIBRARY_NO_DEVEL)
# non-empty if do not install/uninstall pkg-config .pc-files (UNIX)
NO_INSTALL_PC      = $(LIBRARY_NO_DEVEL)
# non-empty if do not install/uninstall dll import libraries (WINDOWS)
NO_INSTALL_IMPS    = $(LIBRARY_NO_DEVEL)

# $1 - library name (mylib for libmylib.a)
# note: this macro is expanded after $(DEFINE_TARGETS) in target makefile, so LIB/DLL - are defined
# note: to install libraries, them must be built first
define DEFINE_INSTALL_VARIABLES
BUILT_LIB_VARIANTS := $(if $(LIB),$(call GET_VARIANTS,LIB))
BUILT_DLL_VARIANTS := $(if $(DLL),$(call GET_VARIANTS,DLL))
BUILT_LIBS         := $$(foreach v,$$(BUILT_LIB_VARIANTS),$$(call FORM_TRG,LIB,$$v))
BUILT_DLLS         := $$(foreach v,$$(BUILT_DLL_VARIANTS),$$(call FORM_TRG,DLL,$$v))
LIBRARY_HEADERS    := $(call fixpath,$(LIBRARY_HEADERS))
LIBRARY_HDIR       := $(addprefix /,$(LIBRARY_HDIR))
install_$1: $$(BUILT_LIBS) $$(BUILT_DLLS)
install: install_$1
uninstall: uninstall_$1
$(call SET_MAKEFILE_INFO,install_$1_headers uninstall_$1_headers install_$1 uninstall_$1)
.PHONY: install_$1_headers uninstall_$1_headers install_$1 uninstall_$1
endef

#=========================================================
ifeq (UNIX,$(OSTYPE))
#=========================================================

# defaults, may be overridden in project configuration makefile before including this makefile via override directive
PREFIX         := /usr/local
EXEC_PREFIX    := $(PREFIX)
LIBDIR         := $(EXEC_PREFIX)/lib
INCLUDEDIR     := $(PREFIX)/include
PKG_CONFIG_DIR := $(LIBDIR)/pkgconfig
INSTALL        := $(if $(filter SOLARIS,$(OS)),/usr/ucb/install,install)
LDCONFIG       := $(if $(filter LINUX,$(OS)),/sbin/ldconfig)

# uninstall files
# $1 - files to delete
# $2 - r or <empty>
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
UNINSTALL_RM = $(call SUP,RM,$1,1,1)rm -f$2$(if $(filter LINUX,$(OS)),$(if \
  $(VERBOSE),v)) $1$(if $(filter LINUX,$(OS)),$(if $(VERBOSE), >&2))

# create symbolic link while installing files
# $1 - target
# $2 - simlink
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_LN = $(call SUP,LN,'$2' -> $1,1,1)$(call LN,$1,'$2')

# INSTALL tool color
INSTALL_COLOR := [01;31m

# post-install/uninstall shared libraries
# $1 - inst/uninst
ifdef LDCONFIG

# LDCONFIG tool color
LDCONF_COLOR := [01;33m

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
install_$1 uninstall_$1: BUILT_LIBS := $(BUILT_LIBS)
install_$1 uninstall_$1: BUILT_DLLS := $(BUILT_DLLS)
install_$1 uninstall_$1: ALL_BUILT_LIBS := $(call GET_ALL_LIBS,$(BUILT_LIBS),$(BUILT_LIB_VARIANTS),$(BUILT_DLLS),$(BUILT_DLL_VARIANTS))
install_$1_headers uninstall_$1_headers: HEADERS := $(LIBRARY_HEADERS)

install_$1_headers:$(if $(LIBRARY_HEADERS),$(newline)$(tab)$$(call \
  SUP,MKDIR,'$$(DESTDIR)$$(INCLUDEDIR)$(LIBRARY_HDIR)',1,1)$$(INSTALL) -d\
 '$$(DESTDIR)$$(INCLUDEDIR)$(LIBRARY_HDIR)'$(newline)$(tab)$$(call \
  SUP,INSTALL,$$(HEADERS) -> '$$(DESTDIR)$$(INCLUDEDIR)$(LIBRARY_HDIR)',1,1)$$(INSTALL) -m 644\
 $$(HEADERS) '$$(DESTDIR)$$(INCLUDEDIR)$(LIBRARY_HDIR)')

uninstall_$1_headers:$(if $(LIBRARY_HEADERS),$(newline)$(tab)$$(call \
  UNINSTALL_RM,$(if $(LIBRARY_HDIR),'$$(DESTDIR)$$(INCLUDEDIR)$(LIBRARY_HDIR)',$$(addprefix \
 '$$(DESTDIR)$$(INCLUDEDIR)/,$$(addsuffix ',$$(notdir $$(HEADERS))))),r))

install_$1:$(if $(LIBRARY_NO_INSTALL_HEADERS),,install_$1_headers)$(if \
  $(BUILT_LIBS)$(BUILT_DLLS),$(newline)$(tab)$$(call \
 SUP,MKDIR,'$$(DESTDIR)$$(LIBDIR)',1,1)$$(INSTALL) -d '$$(DESTDIR)$$(LIBDIR)'$(newline)$(tab)$$(foreach \
  l,$$(BUILT_LIBS),$$(newline)$$(call \
 SUP,INSTALL,'$$(DESTDIR)$$(LIBDIR)/$$(notdir $$l)',1,1)$$(INSTALL) -m 644 $$l '$$(DESTDIR)$$(LIBDIR)')$(newline)$(tab)$$(foreach \
  d,$$(BUILT_DLLS),$$(newline)$$(call \
 SUP,INSTALL,'$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d).$(MODVER)',1,1)$$(INSTALL) -m 755 $$d '$$(DESTDIR)$$(LIBDIR)/$$(notdir \
  $$d).$(MODVER)')$(newline)$(tab)$$(foreach \
 d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call INSTALL_LN,$$d.$(MODVER),$$(DESTDIR)$$(LIBDIR)/$$d))$(if \
  $(LIBRARY_NO_INSTALL_LA),,$(newline)$(tab)$$(call INSTALL_LIBTOOL_ARCHIVES,$$(ALL_BUILT_LIBS),$$(BUILT_LIBS),$$(BUILT_DLLS)))$(if \
  $(LIBRARY_NO_INSTALL_PC),,$(newline)$(tab)$$(call \
 SUP,MKDIR,'$$(DESTDIR)$$(PKG_CONFIG_DIR)',1,1)$$(INSTALL) -d '$$(DESTDIR)$$(PKG_CONFIG_DIR)')$(if \
  $(LIBRARY_NO_INSTALL_PC),,$(newline)$(tab)$$(call INSTALL_PKGCONFS,$$(ALL_BUILT_LIBS),$(LIBRARY_PC_GEN)))$(call LDCONFIG_TEMPLATE,inst))

uninstall_$1:$(if $(LIBRARY_NO_INSTALL_HEADERS),,uninstall_$1_headers)$(if \
  $(BUILT_LIBS)$(BUILT_DLLS),$(newline)$(tab)$$(call UNINSTALL_RM,$$(addprefix \
  '$$(DESTDIR)$$(LIBDIR)/,$$(addsuffix ',$$(notdir $$(BUILT_LIBS))))$(space)$$(foreach \
  d,$$(notdir $$(BUILT_DLLS)),'$$(DESTDIR)$$(LIBDIR)/$$d' '$$(DESTDIR)$$(LIBDIR)/$$d.$(MODVER)')$(space)$(if \
  $(LIBRARY_NO_INSTALL_LA),,$$(call INSTALLED_LIBTOOL_ARCHIVES,$$(ALL_BUILT_LIBS),$$(BUILT_LIBS),$$(BUILT_DLLS)))$(space)$(if \
  $(LIBRARY_NO_INSTALL_PC),,$$(call INSTALLED_PKGCONFS,$$(ALL_BUILT_LIBS))))$(call LDCONFIG_TEMPLATE,uninst))

endef

# $1 - library name (mylib for libmylib.a)
# note: this macro is expanded after $(DEFINE_TARGETS) in target makefile, so LIB/DLL - are defined
INSTALL_LIBS_TEMPLATE = $(eval $(DEFINE_INSTALL_VARIABLES))$(eval $(INSTALL_LIBS_TEMPLATE_UNIX))

#=========================================================
else ifeq (WINDOWS,$(OSTYPE))
#=========================================================

# defaults, may be overridden in project configuration makefile before including this makefile via override directive
# note: $(DESTDIR), $(PREFIX), $(LIBDIR) and $(INCLUDEDIR) _may_ contain spaces
PREFIX     := artifacts
LIBDIR     := $(PREFIX)/lib
INCLUDEDIR := $(PREFIX)/include

# make full paths to installed include/library directories
# this macro must be expanded after evaluating $(DEFINE_INSTALL_VARIABLES)
define DEFINE_INSTALL_VARIABLES_WIN
DST_INC_DIR := $(subst $(space),\ ,$(DESTDIR)$(INCLUDEDIR))$(LIBRARY_HDIR)
DST_LIB_DIR := $(subst $(space),\ ,$(DESTDIR)$(LIBDIR))
endef

# $1 - "$(subst \ , ,$@)"
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
INSTALL_MKDIR = $(call SUP,MKDIR,$(ospath),,1)$(MKDIR)

# directories to install
NEEDED_INSTALL_DIRS:=

# $1 - result of $(call split_dirs,$1) on directories to install (spaces are replaced with ?)
define ADD_INSTALL_DIRS
ifneq (,$1)
$(subst ?,\ ,$(call mk_dir_deps,$1))
$(subst ?,\ ,$1):
	$$(call INSTALL_MKDIR,"$$(subst \ , ,$$@)")
NEEDED_INSTALL_DIRS += $1
endif
endef

# add rule for creating directories
# $1 - directory to install, spaces in path are prefixed with backslash
ADD_INSTALL_DIR = $(eval $(call ADD_INSTALL_DIRS,$(filter-out $(NEEDED_INSTALL_DIRS),$(call split_dirs,$(subst \ ,?,$1)))))

# $1 - library name (mylib for libmylib.a)
# note: pass non-empty 3-d argument to SUP function to not colorize tool arguments
# note: pass non-empty 4-th argument to SUP function to not update percents of executed makefiles
# note: define some variables as target-specific
# note: $(DEFINE_INSTALL_VARIABLES) and then $(DEFINE_INSTALL_VARIABLES_WIN) must be evaluated before expanding this macro
define INSTALL_LIBS_TEMPLATE_WINDOWS

ifneq (,$(BUILT_LIBS)$(BUILT_DLLS))
$(call ADD_INSTALL_DIR,$(DST_LIB_DIR))
endif

ifndef LIBRARY_NO_INSTALL_HEADERS
ifdef LIBRARY_HEADERS
$(call ADD_INSTALL_DIR,$(DST_INC_DIR))
endif
endif

install_$1 uninstall_$1: BUILT_LIBS := $(BUILT_LIBS)
install_$1 uninstall_$1: BUILT_DLLS := $(BUILT_DLLS)
install_$1 uninstall_$1: BUILT_IMPS := $(foreach v,$(BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$(call GET_TARGET_NAME,DLL),$v))
install_$1_headers uninstall_$1_headers: HEADERS := $(LIBRARY_HEADERS)

install_$1_headers:$(if $(LIBRARY_HEADERS),| $(DST_INC_DIR)$(newline)$(tab)$$(call \
  SUP,COPY,$$(call ospath,$$(HEADERS)) -> "$$(call ospath,$$(DESTDIR)$$(INCLUDEDIR)$(LIBRARY_HDIR))",1,1)$$(foreach \
  h,$$(HEADERS),$$(newline)$(QUIET)$$(call CP,$$h,"$$(DESTDIR)$$(INCLUDEDIR)$(LIBRARY_HDIR)")))

uninstall_$1_headers:$(if $(LIBRARY_HEADERS),$(newline)$(tab)$(if $(LIBRARY_HDIR),$$(call \
  SUP,RD,"$$(call ospath,$$(DESTDIR)$$(INCLUDEDIR)$(LIBRARY_HDIR))",1,1)$$(call \
  DEL_DIR,"$$(DESTDIR)$$(INCLUDEDIR)$(LIBRARY_HDIR)"),$$(foreach h,$$(notdir $$(HEADERS)),$$(newline)$$(call \
  SUP,DEL,"$$(call ospath,$$(DESTDIR)$$(INCLUDEDIR)/$$h)",1,1)$$(call DEL,"$$(DESTDIR)$$(INCLUDEDIR)/$$h"))))

install_$1:$(if $(LIBRARY_NO_INSTALL_HEADERS),,install_$1_headers)$(if \
  $(BUILT_LIBS)$(BUILT_DLLS), | $(DST_LIB_DIR)$(newline)$(tab)$$(foreach l,$$(BUILT_LIBS),$$(newline)$$(call \
 SUP,INSTALL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$(notdir $$l))",1,1)$$(call CP,$$l,"$$(DESTDIR)$$(LIBDIR)"))$(newline)$(tab)$$(foreach \
  d,$$(BUILT_DLLS),$$(newline)$$(call \
 SUP,INSTALL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d))",1,1)$$(call CP,$$d,"$$(DESTDIR)$$(LIBDIR)"))$(if \
  $(LIBRARY_NO_INSTALL_IMPS),,$(newline)$(tab)$$(foreach i,$$(BUILT_IMPS),$$(newline)$$(call \
 SUP,INSTALL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$(notdir $$i))",1,1)$$(call CP,$$i,"$$(DESTDIR)$$(LIBDIR)"))))

uninstall_$1:$(if $(LIBRARY_NO_INSTALL_HEADERS),,uninstall_$1_headers)$(if \
  $(BUILT_LIBS)$(BUILT_DLLS),$(newline)$(tab)$$(foreach l,$$(notdir $$(BUILT_LIBS)),$$(newline)$$(call \
 SUP,DEL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$l)",1,1)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$l"))$(newline)$(tab)$$(foreach \
  d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call \
 SUP,DEL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$d)",1,1)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$d"))$(if \
  $(LIBRARY_NO_INSTALL_IMPS),,$(newline)$(tab)$$(foreach i,$$(notdir $$(BUILT_IMPS)),$$(newline)$$(call \
 SUP,DEL,"$$(call ospath,$$(DESTDIR)$$(LIBDIR)/$$i)",1,1)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$i"))))

endef

# $1 - library name (mylib for libmylib.a)
# note: this macro is expanded after $(DEFINE_TARGETS) in target makefile, so LIB/DLL - are defined
INSTALL_LIBS_TEMPLATE = $(eval $(DEFINE_INSTALL_VARIABLES))$(eval $(DEFINE_INSTALL_VARIABLES_WIN))$(eval $(INSTALL_LIBS_TEMPLATE_WINDOWS))

#=========================================================
endif # WINDOWS
#=========================================================

$(call CLEAN_BUILD_PROTECT_VARS,INSTALL_LIBS_TEMPLATE DESTDIR \
  NO_DEVEL NO_INSTALL_HEADERS NO_INSTALL_LA NO_INSTALL_PC NO_INSTALL_IMPS \
  DEFINE_INSTALL_VARIABLES PREFIX EXEC_PREFIX LIBDIR INCLUDEDIR PKG_CONFIG_DIR INSTALL LDCONFIG \
  UNINSTALL_RM INSTALL_LN INSTALL_COLOR LDCONF_COLOR LDCONFIG_TEMPLATE VARIANT_CFLAGS INSTALL_LIBS_TEMPLATE_UNIX \
  DEFINE_INSTALL_VARIABLES_WIN INSTALL_MKDIR ADD_INSTALL_DIR INSTALL_LIBS_TEMPLATE_WINDOWS)

endif # INSTALL_LIBS_TEMPLATE

# reset variables - they may be redefined in target makefile before expanding INSTALL_LIBS_TEMPLATE
LIBRARY_NO_DEVEL           := $(NO_DEVEL)
LIBRARY_NO_INSTALL_HEADERS  = $(NO_INSTALL_HEADERS)
LIBRARY_NO_INSTALL_LA       = $(NO_INSTALL_LA)
LIBRARY_NO_INSTALL_PC       = $(NO_INSTALL_PC)
LIBRARY_NO_INSTALL_IMPS     = $(NO_INSTALL_IMPS)

# list of header files to install, may be empty
LIBRARY_HEADERS:=

# name of installed headers directory, may be empty
LIBRARY_HDIR:=

# name of pkg-config file generator macro, must be defined if $(LIBRARY_NO_INSTALL_PC) is empty
LIBRARY_PC_GEN:=
