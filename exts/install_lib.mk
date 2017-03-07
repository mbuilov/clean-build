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
$(eval install_$(LIBRARY_NAME): $(BUILT_LIBS) $(BUILT_DLLS))

ifeq (LINUX,$(OS))

ifndef INSTALL_LIB_TEMPLATE_LINUX

include $(MTOP)/exts/all_libs.mk
include $(MTOP)/exts/pc.mk
include $(MTOP)/exts/la.mk

# this macro may be usable for $(LIBRARY_PC_GEN)
# choose CFLAGS option for static library variant $1
VARIANT_CFLAGS ?= $(if \
  $(filter P,$1), $(PIE_OPTION),$(if \
  $(filter D,$1), $(PIC_OPTION)))

# $1 - $(call GET_ALL_LIBS,$(BUILT_LIBS),$(BUILT_LIB_VARIANTS),$(BUILT_DLLS),$(BUILT_DLL_VARIANTS))
define INSTALL_LIB_TEMPLATE_LINUX

# define these variables as target-specific to be able to use them in $(LIBRARY_PC_GEN)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): MODVER  := $(MODVER)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): DEFINES := $(DEFINES)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_LIBS := $(BUILT_LIBS)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_DLLS := $(BUILT_DLLS)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): ALL_BUILT_LIBS := $1
install_$(LIBRARY_NAME): HEADERS := $(LIBRARY_HEADERS)

install_$(LIBRARY_NAME)_headers:
	$$(INSTALL) -d '$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)'
	$$(INSTALL) -m 644 $$(addprefix $(TOP)/$(LIBRARY_NAME)/,$$(HEADERS)) '$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)'

install_$(LIBRARY_NAME): $(if $(NO_INSTALL_HEADERS1),,install_$(LIBRARY_NAME)_headers)$(if \
  $(BUILT_LIBS)$(BUILT_DLLS),$(newline)$(tab)$$(INSTALL) -d '$$(DESTDIR)$$(LIBDIR)')
	$$(foreach l,$$(BUILT_LIBS),$$(newline)$$(INSTALL) -m 644 $$l '$$(DESTDIR)$$(LIBDIR)')
	$$(foreach d,$$(BUILT_DLLS),$$(newline)$$(INSTALL) -m 755 $$d '$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d).$(MODVER)')
	$$(foreach d,$$(BUILT_DLLS),$$(newline)ln -sf$(if $(VERBOSE),v) $$(notdir $$d).$(MODVER) '$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d)') $(if \
  $(NO_INSTALL_LA1),,$(newline)$(tab)$$(call INSTALL_LIBTOOL_ARCHIVES,$$(ALL_BUILT_LIBS),$$(BUILT_LIBS),$$(BUILT_DLLS)))$(if \
  $(NO_INSTALL_PC1),,$(if $(BUILT_LIBS)$(BUILT_DLLS),$(newline)$(tab)$$(INSTALL) -d '$$(DESTDIR)$$(PKG_CONFIG_DIR)'))$(if \
  $(NO_INSTALL_PC1),,$(newline)$(tab)$$(call INSTALL_PKGCONFS,$$(ALL_BUILT_LIBS),$(LIBRARY_PC_GEN)))$(if \
  $(BUILT_DLLS),$(newline)$(tab)$$(LDCONFIG) -n$(if $(VERBOSE),v) '$$(DESTDIR)$$(LIBDIR)')

uninstall_$(LIBRARY_NAME):
	rm -rf$(if $(VERBOSE),v) $(if \
  $(NO_INSTALL_HEADERS1),,'$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)') $$(foreach \
  l,$$(BUILT_LIBS),'$$(DESTDIR)$$(LIBDIR)/$$(notdir $$l)') $$(foreach \
  d,$$(BUILT_DLLS),'$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d)' '$$(DESTDIR)$$(LIBDIR)/$$(notdir $$d).$(MODVER)') $(if \
  $(NO_INSTALL_LA1),,$$(call INSTALLED_LIBTOOL_ARCHIVES,$$(ALL_BUILT_LIBS),$$(BUILT_LIBS),$$(BUILT_DLLS))) $(if \
  $(NO_INSTALL_PC1),,$$(call INSTALLED_PKGCONFS,$$(ALL_BUILT_LIBS)))$(if \
  $(BUILT_DLLS),$(newline)$(tab)$$(LDCONFIG) -n$(if $(VERBOSE),v) '$$(DESTDIR)$$(LIBDIR)')

endef

endif # INSTALL_LIB_TEMPLATE_LINUX

$(eval $(call INSTALL_LIB_TEMPLATE_LINUX,$(call GET_ALL_LIBS,$(BUILT_LIBS),$(BUILT_LIB_VARIANTS),$(BUILT_DLLS),$(BUILT_DLL_VARIANTS))))

else ifeq (WINXX,$(OS))

DST_INC_DIR := $(subst $(space),\$(space),$(DESTDIR)$(INCLUDEDIR)/$(LIBRARY_NAME))
DST_LIB_DIR := $(subst $(space),\$(space),$(DESTDIR)$(LIBDIR))

$(DST_LIB_DIR): | $(if $(NO_INSTALL_HEADERS1),,$(DST_INC_DIR))
$(DST_INC_DIR) $(DST_LIB_DIR):
	$(call MKDIR,"$(subst \ , ,$@)")

# $1 - $(foreach v,$(BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$(call FORM_TRG,DLL,$v),$v))
ifndef INSTALL_LIB_TEMPLATE_WINDOWS
define INSTALL_LIB_TEMPLATE_WINDOWS

install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_LIBS := $(BUILT_LIBS)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_DLLS := $(BUILT_DLLS)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): BUILT_IMPS := $1
install_$(LIBRARY_NAME): HEADERS := $(LIBRARY_HEADERS)

install_$(LIBRARY_NAME)_headers: | $(DST_INC_DIR)
	$$(foreach f,$$(HEADERS),$$(newline)$$(call CP,$(TOP)/$(LIBRARY_NAME)/$$f,"$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)"))

install_$(LIBRARY_NAME): $(if $(NO_INSTALL_HEADERS1),,install_$(LIBRARY_NAME)_headers) | $(DST_LIB_DIR)
	$$(foreach l,$$(BUILT_LIBS),$$(newline)$$(call CP,$$l,"$$(DESTDIR)$$(LIBDIR)"))
	$$(foreach d,$$(BUILT_DLLS),$$(newline)$$(call CP,$$d,"$$(DESTDIR)$$(LIBDIR)"))$(if \
  $(NO_INSTALL_IMPS1),,$(newline)$(tab)$$(foreach i,$$(BUILT_IMPS),$$(newline)$$(call CP,$$i,"$$(DESTDIR)$$(LIBDIR)")))

uninstall_$(LIBRARY_NAME):$(if \
  $(NO_INSTALL_HEADERS1),,$(newline)$(tab)$$(call DEL_DIR,"$$(DESTDIR)$$(INCLUDEDIR)/$(LIBRARY_NAME)"))
	$$(foreach l,$$(notdir $$(BUILT_LIBS)),$$(newline)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$l"))
	$$(foreach d,$$(notdir $$(BUILT_DLLS)),$$(newline)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$d"))$(if \
  $(NO_INSTALL_IMPS1),,$(newline)$(tab)$$(foreach i,$$(notdir $$(BUILT_IMPS)),$$(newline)$$(call DEL,"$$(DESTDIR)$$(LIBDIR)/$$i")))

endef
endif # INSTALL_LIB_TEMPLATE_WINDOWS

$(eval $(call INSTALL_LIB_TEMPLATE_WINDOWS,$(foreach v,$(BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$(call FORM_TRG,DLL,$v),$v))))

endif # WINXX

$(eval .PHONY: install_$(LIBRARY_NAME)_headers install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME))
