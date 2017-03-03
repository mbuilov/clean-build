#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# auxiliary templates to simplify library installation
# this file should be included in target makefile after $(DEFINE_TARGETS)

# these variables must be defined before including this file:
# LIBRARY_NAME    - name of installed library
# LIBRARY_HEADERS - header files of installed library
# PC_GENERATOR    - pkg-config file generator macro (see $(MTOP)/UNIX/pc.mk)

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

ALL_BUILT_LIBS := $(call GET_ALL_LIBS,$(BUILT_LIBS),$(BUILT_LIB_VARIANTS),$(BUILT_DLLS),$(BUILT_DLL_VARIANTS))

ifndef INSTALL_LIB_TEMPLATE_LINUX

include $(MTOP)/exts/all_libs.mk
include $(MTOP)/exts/pc.mk
include $(MTOP)/exts/la.mk

# this macro may be usable for $(PC_GENERATOR)
# choose CFLAGS option for static library variant $1
VARIANT_CFLAGS ?= $(if \
  $(filter P,$1), $(PIE_OPTION),$(if \
  $(filter D,$1), $(PIC_OPTION)))

define INSTALL_LIB_TEMPLATE_LINUX

# define these variables as target-specific to be able to use them in $(PC_GENERATOR)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): MODVER  := $$(MODVER)
install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME): DEFINES := $$(DEFINES)

install_$(LIBRARY_NAME)_headers:
	$$(INSTALL) -d '$$(DESTDIR)$$(PREFIX)/include/$(LIBRARY_NAME)'
	$$(INSTALL) -m 644 $$(addprefix $(TOP)/$(LIBRARY_NAME)/,$(LIBRARY_HEADERS)) '$$(DESTDIR)$$(PREFIX)/include/$(LIBRARY_NAME)'

install_$(LIBRARY_NAME): $(if $(NO_INSTALL_HEADERS1),,install_$(LIBRARY_NAME)_headers)
	$(if $(BUILT_LIBS)$(BUILT_DLLS),$$(INSTALL) -d '$$(DESTDIR)$$(LIBDIR)')
	$(foreach l,$(BUILT_LIBS),$(newline)$$(INSTALL) -m 644 $l '$$(DESTDIR)$$(LIBDIR)')
	$(foreach d,$(BUILT_DLLS),$(newline)$$(INSTALL) -m 755 $d '$$(DESTDIR)$$(LIBDIR)/$(notdir $d).$(MODVER)')
	$(foreach d,$(BUILT_DLLS),$(newline)ln -sf$(if $(VERBOSE),v) $(notdir $d).$(MODVER) '$$(DESTDIR)$$(LIBDIR)/$(notdir $d)')
	$(if $(NO_INSTALL_LA1),,$$(call INSTALL_LIBTOOL_ARCHIVES,$(ALL_BUILT_LIBS),$(BUILT_LIBS),$(BUILT_DLLS)))
	$(if $(NO_INSTALL_PC1),,$(if $(BUILT_LIBS)$(BUILT_DLLS),$$(INSTALL) -d '$$(DESTDIR)$$(PKG_CONFIG_DIR)'))
	$(if $(NO_INSTALL_PC1),,$$(call INSTALL_PKGCONFS,$(ALL_BUILT_LIBS),$(PC_GENERATOR)))
	$(if $(BUILT_DLLS),$$(LDCONFIG) -n$(if $(VERBOSE),v) '$$(DESTDIR)$$(LIBDIR)')

uninstall_$(LIBRARY_NAME):
	rm -rf$(if $(VERBOSE),v) $(if \
  $(NO_INSTALL_HEADERS1),,'$$(DESTDIR)$$(PREFIX)/include/$(LIBRARY_NAME)') $(foreach \
  l,$(BUILT_LIBS),'$$(DESTDIR)$$(LIBDIR)/$(notdir $l)') $(foreach \
  d,$(BUILT_DLLS),'$$(DESTDIR)$$(LIBDIR)/$(notdir $d)' '$$(DESTDIR)$$(LIBDIR)/$(notdir $d).$(MODVER)') $(if \
  $(NO_INSTALL_LA1),,$$(call INSTALLED_LIBTOOL_ARCHIVES,$(ALL_BUILT_LIBS),$(BUILT_LIBS),$(BUILT_DLLS))) $(if \
  $(NO_INSTALL_PC1),,$$(call INSTALLED_PKGCONFS,$(ALL_BUILT_LIBS)))
	$(if $(BUILT_DLLS),$$(LDCONFIG) -n$(if $(VERBOSE),v) '$$(DESTDIR)$$(LIBDIR)')

endef

endif # INSTALL_LIB_TEMPLATE_LINUX

$(eval $(INSTALL_LIB_TEMPLATE_LINUX))

else ifeq (WINXX,$(OS))

DST_INC_DIR := $(subst $(space),\$(space),$(DESTDIR)$(PREFIX)/$(LIBRARY_NAME))
DST_LIB_DIR := $(subst $(space),\$(space),$(DESTDIR)$(LIBDIR))

$(DST_LIB_DIR): | $(if $(NO_INSTALL_HEADERS1),,$(DST_INC_DIR))
$(DST_INC_DIR) $(DST_LIB_DIR):
	$(call MKDIR,"$(subst \ , ,$@)")

BUILT_IMPS := $(foreach v,$(BUILT_DLL_VARIANTS),$(call MAKE_IMP_PATH,$(call FORM_TRG,DLL,$v),$v))

ifndef INSTALL_LIB_TEMPLATE_WINDOWS

install_$(LIBRARY_NAME)_headers: | $(DST_INC_DIR)
	$(foreach f,$(LIBRARY_HEADERS),$$(call CP,$(TOP)/$(LIBRARY_NAME)/$f,"$(DESTDIR)$(PREFIX)/$(LIBRARY_NAME)")$(newline))

install_$(LIBRARY_NAME): $(if $(NO_INSTALL_HEADERS1),,install_$(LIBRARY_NAME)_headers) | $(DST_LIB_DIR)
	$(foreach l,$(BUILT_LIBS),$(newline)$$(call CP,$l,"$(DESTDIR)$(LIBDIR)"))
	$(foreach d,$(BUILT_DLLS),$(newline)$$(call CP,$d,"$(DESTDIR)$(LIBDIR)"))
	$(if $(NO_INSTALL_IMPS1),,$(foreach i,$(BUILT_IMPS),$(newline)$$(call CP,$i,"$(DESTDIR)$(LIBDIR)")))

uninstall_$(LIBRARY_NAME):
	$(if $(NO_INSTALL_HEADERS1),,$$(call DEL_DIR,"$(DESTDIR)$(PREFIX)/$(LIBRARY_NAME)"))
	$(foreach l,$(notdir $(BUILT_LIBS)),$(newline)$$(call DEL,"$(DESTDIR)$(LIBDIR)/$l"))
	$(foreach d,$(notdir $(BUILT_DLLS)),$(newline)$$(call DEL,"$(DESTDIR)$(LIBDIR)/$d"))
	$(if $(NO_INSTALL_IMPS1),,$(foreach i,$(notdir $(BUILT_IMPS)),$(newline)$$(call DEL,"$(DESTDIR)$(LIBDIR)/$i")))

endef INSTALL_LIB_TEMPLATE_WINDOWS

$(eval $(INSTALL_LIB_TEMPLATE_WINDOWS))

endif # WINXX

$(eval .PHONY: install_$(LIBRARY_NAME)_headers install_$(LIBRARY_NAME) uninstall_$(LIBRARY_NAME))
