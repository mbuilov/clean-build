#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# auxiliary templates to simplify library installation
# this file should be included in target makefile after $(DEFINE_TARGETS)
# which builds:
# LIB - target static library name with variants
# DLL - target dynamic library name with variants

# next variables must be defined before including this file:
# LIBRARY_NAME    - install/uninstall target name and name of installed headers directory
# LIBRARY_HEADERS - header files of installed library
# LIBRARY_PC_GEN  - name of pkg-config file generator macro (see $(MTOP)/UNIX/pc.mk)

# do not install/uninstall header files
NO_INSTALL_HEADERS1 := $(NO_INSTALL_HEADERS)
# do not install/uninstall libtool .la-files (UNIX)
NO_INSTALL_LA1      := $(NO_INSTALL_LA)
# do not install/uninstall pkg-config .pc-files (UNIX)
NO_INSTALL_PC1      := $(NO_INSTALL_PC)
# do not install/uninstall dll import libraries (WINDOWS)
NO_INSTALL_IMPS1    := $(NO_INSTALL_IMPS)

ifdef NO_DEV
NO_INSTALL_HEADERS1 := 1
NO_INSTALL_LA1      := 1
NO_INSTALL_PC1      := 1
NO_INSTALL_IMPS1    := 1
endif

# also, if defined
# NO_STATIC - static libraries are not installed/uninstalled
# NO_SHARED - dynamic libraries are not installed/uninstalled

BUILT_LIB_VARIANTS := $(if $(LIB),$(call GET_VARIANTS,LIB))
BUILT_DLL_VARIANTS := $(if $(DLL),$(call GET_VARIANTS,DLL))
BUILT_LIBS         := $(foreach v,$(BUILT_LIB_VARIANTS),$(call FORM_TRG,LIB,$v))
BUILT_DLLS         := $(foreach v,$(BUILT_DLL_VARIANTS),$(call FORM_TRG,DLL,$v))

# to install libraries, them must be built first
$(eval install_$(LIBRARY_NAME): $(BUILT_LIBS) $(BUILT_DLLS)\
$(newline)install: install_$(LIBRARY_NAME)\
$(newline)uninstall: uninstall_$(LIBRARY_NAME))

ifdef OSTYPE_UNIX

# uninstall files
# $1 - files to delete
# $2 - r or <empty>
# note: pass non-empty 3-d argument to SUP function to not update percents
# note: pass non-empty 4-d argument to SUP function to not colorize tool arguments
ifndef UNINSTALL_RM
UNINSTALL_RM = $(call SUP,RM,$1,@,1)rm -f$2$(if $(OS_LINUX),$(if $(VERBOSE),v)) $1
$(call CLEAN_BUILD_PROTECT_VARS,UNINSTALL_RM)
endif

# create symbolic link while installing files
# $1 - target
# $2 - simlink
# note: pass non-empty 3-d argument to SUP function to not update percents
# note: pass non-empty 4-d argument to SUP function to not colorize tool arguments
ifndef INSTALL_LN
INSTALL_LN = $(call SUP,LN,$2 -> $1,@,1)$(call LN,$1,$2)
$(call CLEAN_BUILD_PROTECT_VARS,INSTALL_LN)
endif

# INSTALL tool color
ifndef INSTALL_COLOR
INSTALL_COLOR := [01;31m
$(call CLEAN_BUILD_PROTECT_VARS,INSTALL_COLOR)
endif

# RM tool color
ifndef RM_COLOR
RM_COLOR := [01;31m
$(call CLEAN_BUILD_PROTECT_VARS,RM_COLOR)
endif

# post-install/uninstall shared libraries
# $1 - inst/uninst
# note: pass non-empty 3-d argument to SUP function to not update percents
# note: pass non-empty 4-d argument to SUP function to not colorize tool arguments
ifndef LDCONFIG_TEMPLATE

ifdef OS_LINUX

# LDCONFIG tool color
ifndef LDCONF_COLOR
LDCONF_COLOR := [01;33m
$(call CLEAN_BUILD_PROTECT_VARS,LDCONF_COLOR)
endif

LDCONFIG_TEMPLATE = $(if $(BUILT_DLLS),$(newline)$(tab)$$(call \
  SUP,LDCONF,'$$(DESTDIR)$$(LIBDIR)',@,1)$$(LDCONFIG) -n$(if $(VERBOSE),v) '$$(DESTDIR)$$(LIBDIR)')

else ifdef OS_SOLARIS

# $j - major version
LDCONFIG_TEMPLATE = $(foreach j,$(filter-out $(MODVER),$(firstword $(subst ., ,$(MODVER)))),$(if $(filter inst,$1),$$(foreach \
  d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call INSTALL_LN,$$d.$(MODVER),'$$(DESTDIR)$$(LIBDIR)/$$d.$j')),$(if \
  $(BUILT_DLLS),$(newline)$(tab)$$(call UNINSTALL_RM,$$(foreach d,$$(notdir $$(BUILT_DLLS)),'$$(DESTDIR)$$(LIBDIR)/$$d.$j')))))

endif

$(call CLEAN_BUILD_PROTECT_VARS,LDCONFIG_TEMPLATE)
endif # LDCONFIG_TEMPLATE

ifndef INSTALL_LIB_TEMPLATE_UNIX

include $(MTOP)/exts/all_libs.mk
include $(MTOP)/exts/pc.mk
include $(MTOP)/exts/la.mk

# this macro may be usable for $(LIBRARY_PC_GEN)
# choose CFLAGS option for static library variant $1
ifndef VARIANT_CFLAGS
VARIANT_CFLAGS = $(if \
  $(filter P,$1), $(PIE_OPTION),$(if \
  $(filter D,$1), $(PIC_OPTION)))
$(call CLEAN_BUILD_PROTECT_VARS,VARIANT_CFLAGS)
endif

# $1 - $(call GET_ALL_LIBS,$(BUILT_LIBS),$(BUILT_LIB_VARIANTS),$(BUILT_DLLS),$(BUILT_DLL_VARIANTS))
# note: pass non-empty 3-d argument to SUP function to not update percents
# note: pass non-empty 4-d argument to SUP function to not colorize tool arguments
define INSTALL_LIB_TEMPLATE_UNIX

# define these variables as target-specific to be able to use them in $(LIBRARY_PC_GEN)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): MODVER  := $(MODVER)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): DEFINES := $(DEFINES)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_LIBS := $(BUILT_LIBS)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_DLLS := $(BUILT_DLLS)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): ALL_BUILT_LIBS := $1
install_$(LIBRARY_NAME): HEADERS := $(LIBRARY_HEADERS)

install_$(LIBRARY_NAME)_headers:
	$$(call SUP,MKDIR,'$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)',@,1)$$(INSTALL) -d '$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)'
	$$(call SUP,INSTALL,$$(HEADERS) -> '$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)',@,1)$$(INSTALL) -m 644 $$(addprefix \
  $(TOP)/$(LIBRARY_NAME)/,$$(HEADERS)) '$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)'

install_$(LIBRARY_NAME): $(if $(NO_INSTALL_HEADERS1),,install_$(LIBRARY_NAME)_headers)$(if \
  $(BUILT_LIBS)$(BUILT_DLLS),$(newline)$(tab)$$(call \
 SUP,MKDIR,'$$(DESTDIR)$$(LIBDIR)',@,1)$$(INSTALL) -d '$$(DESTDIR)$$(LIBDIR)')
	$$(foreach l,$$(BUILT_LIBS),$$(newline)$$(call \
 SUP,INSTALL,'$$(DESTDIR)$$(LIBDIR)/$$(notdir $$l)',@,1)$$(INSTALL) -m 644 $$l '$$(DESTDIR)$$(LIBDIR)')
	$$(foreach d,$$(BUILT_DLLS),$$(newline)$$(call \
 SUP,INSTALL,'$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d).$(MODVER)',@,1)$$(INSTALL) -m 755 $$d '$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d).$(MODVER)')
	$$(foreach d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call INSTALL_LN,$$d.$(MODVER),'$$(DESTDIR)$$(LIBDIR)/$$d'))$(if \
  $(NO_INSTALL_LA1),,$(newline)$(tab)$$(call INSTALL_LIBTOOL_ARCHIVES,$$(ALL_BUILT_LIBS),$$(BUILT_LIBS),$$(BUILT_DLLS)))$(if \
  $(NO_INSTALL_PC1),,$(if $(BUILT_LIBS)$(BUILT_DLLS),$(newline)$(tab)$$(call \
 SUP,MKDIR,'$$(DESTDIR)$$(PKG_CONFIG_DIR)',@,1)$$(INSTALL) -d '$$(DESTDIR)$$(PKG_CONFIG_DIR)'))$(if \
  $(NO_INSTALL_PC1),,$(newline)$(tab)$$(call INSTALL_PKGCONFS,$$(ALL_BUILT_LIBS),$(LIBRARY_PC_GEN)))$(call LDCONFIG_TEMPLATE,inst)

uninstall_$(LIBRARY_NAME):
	$$(call UNINSTALL_RM,$(if \
  $(NO_INSTALL_HEADERS1),,'$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)') $$(foreach \
  l,$$(BUILT_LIBS),'$$(DESTDIR)$$(LIBDIR)/$$(notdir $$l)') $$(foreach \
  d,$$(notdir $$(BUILT_DLLS)),'$$(DESTDIR)$$(LIBDIR)/$$d' '$$(DESTDIR)$$(LIBDIR)/$$d.$(MODVER)') $(if \
  $(NO_INSTALL_LA1),,$$(call INSTALLED_LIBTOOL_ARCHIVES,$$(ALL_BUILT_LIBS),$$(BUILT_LIBS),$$(BUILT_DLLS))) $(if \
  $(NO_INSTALL_PC1),,$$(call INSTALLED_PKGCONFS,$$(ALL_BUILT_LIBS))),r)$(call LDCONFIG_TEMPLATE,uninst)

endef

$(call CLEAN_BUILD_PROTECT_VARS,INSTALL_LIB_TEMPLATE_UNIX)
endif # INSTALL_LIB_TEMPLATE_UNIX

$(eval $(call INSTALL_LIB_TEMPLATE_UNIX,$(call GET_ALL_LIBS,$(BUILT_LIBS),$(BUILT_LIB_VARIANTS),$(BUILT_DLLS),$(BUILT_DLL_VARIANTS))))

else ifdef OSTYPE_WINDOWS

DST_INC_DIR := $(subst $(space),\ ,$(DESTDIR)$(INCLUDEDIR)/$(LIBRARY_NAME))
DST_LIB_DIR := $(subst $(space),\ ,$(DESTDIR)$(LIBDIR))

ifndef INSTALL_MKDIR
# $1 - "$(subst /,\,$(subst \ , ,$@))"
# note: pass non-empty 3-d argument to SUP function to not update percents
INSTALL_MKDIR = $(call SUP,MKDIR,$1,@)$(call MKDIR,$1)
$(call CLEAN_BUILD_PROTECT_VARS,INSTALL_MKDIR)
endif

$(DST_LIB_DIR): | $(if $(NO_INSTALL_HEADERS1),,$(DST_INC_DIR))
$(DST_INC_DIR) $(DST_LIB_DIR):
	$(call INSTALL_MKDIR,"$(subst /,\,$(subst \ , ,$@))")

# $1 - $(foreach v,$(BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$(call GET_TARGET_NAME,DLL),$v))
# note: pass non-empty 3-d argument to SUP function to not update percents
ifndef INSTALL_LIB_TEMPLATE_WINDOWS
define INSTALL_LIB_TEMPLATE_WINDOWS

install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_LIBS := $(BUILT_LIBS)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_DLLS := $(BUILT_DLLS)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_IMPS := $1
install_$(LIBRARY_NAME): HEADERS := $(LIBRARY_HEADERS)

install_$(LIBRARY_NAME)_headers: | $(DST_INC_DIR)
	$$(call SUP,COPY,$$(HEADERS) -> "$$(DESTDIR)$$(INCLUDEDIR)\$(LIBRARY_NAME)\",@)$$(foreach \
  f,$$(HEADERS),$$(newline)$(if $(VERBOSE),,@)$$(call CP,$(TOP)/$(LIBRARY_NAME)/$$f,"$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)"))

install_$(LIBRARY_NAME): $(if $(NO_INSTALL_HEADERS1),,install_$(LIBRARY_NAME)_headers) $(if $(BUILT_LIBS)$(BUILT_DLLS), | $(DST_LIB_DIR))
	$$(foreach l,$$(BUILT_LIBS),$$(newline)$$(call \
  SUP,INSTALL,"$$(DESTDIR)$$(LIBDIR)\$$(notdir $$l)",@)$$(call CP,$$l,"$$(DESTDIR)$$(LIBDIR)"))
	$$(foreach d,$$(BUILT_DLLS),$$(newline)$$(call \
  SUP,INSTALL,"$$(DESTDIR)$$(LIBDIR)\$$(notdir $$d)",@)$$(call CP,$$d,"$$(DESTDIR)$$(LIBDIR)"))$(if \
  $(NO_INSTALL_IMPS1),,$(newline)$(tab)$$(foreach i,$$(BUILT_IMPS),$$(newline)$$(call \
  SUP,INSTALL,"$$(DESTDIR)$$(LIBDIR)\$$(notdir $$i)",@)$$(call CP,$$i,"$$(DESTDIR)$$(LIBDIR)")))

uninstall_$(LIBRARY_NAME):$(if \
  $(NO_INSTALL_HEADERS1),,$(newline)$(tab)$$(call \
  SUP,RD,"$$(DESTDIR)$$(INCLUDEDIR)\$(LIBRARY_NAME)\",@)$$(call DEL_DIR,"$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)"))
	$$(foreach l,$$(notdir $$(BUILT_LIBS)),$$(newline)$$(call \
  SUP,DEL,"$$(DESTDIR)$$(LIBDIR)\$$l",@)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$l"))
	$$(foreach d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call \
  SUP,DEL,"$$(DESTDIR)$$(LIBDIR)\$$d",@)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$d"))$(if \
  $(NO_INSTALL_IMPS1),,$(newline)$(tab)$$(foreach i,$$(notdir $$(BUILT_IMPS)),$$(newline)$$(call \
  SUP,DEL,"$$(DESTDIR)$$(LIBDIR)\$$i",@)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$i")))

endef
$(call CLEAN_BUILD_PROTECT_VARS,INSTALL_LIB_TEMPLATE_WINDOWS)
endif # INSTALL_LIB_TEMPLATE_WINDOWS

$(eval $(call INSTALL_LIB_TEMPLATE_WINDOWS,$(foreach v,$(BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$(call GET_TARGET_NAME,DLL),$v))))

endif # OSTYPE_WINDOWS

$(eval .PHONY: install_$(LIBRARY_NAME)_headers install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME))
