#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# included by $(CLEAN_BUILD_DIR)/install/install_lib.mk

ifeq (,$(filter-out undefined environment,$(origin NEED_INSTALL_DIR)))
include $(dir $(lastword $(MAKEFILE_LIST)))inst_utils.mk
endif

ifeq (,$(filter-out undefined environment,$(origin INSTALL_TEXT)))
include $(dir $(lastword $(MAKEFILE_LIST)))inst_text.mk
endif

ifeq (,$(filter-out undefined environment,$(origin PKGCONF_GEN)))
include $(dir $(lastword $(MAKEFILE_LIST)))pkgconf_gen.mk
endif

ifeq (,$(filter-out undefined environment,$(origin LIBTOOL_GEN)))
include $(dir $(lastword $(MAKEFILE_LIST)))libtool_gen.mk
endif

# next NO_... macros are used to form default configuration of libraries installation,
# for example, setting NO_INSTALL_HEADERS:=1 in command line prevents installation of headers for all libraries
# $1 - library name (mylib for libmylib.a)

# non-empty if do not install/uninstall header files
NO_INSTALL_HEADERS = $($1_LIBRARY_NO_DEVEL)

# non-empty if do not install/uninstall static libraries
# note: by default, do not install static libraries
NO_INSTALL_STATIC  = $($1_LIBRARY_NO_DEVEL)

# non-empty if do not install/uninstall shared libraries
# note: by default, install shared libraries if they are built (e.g. NO_SHARED is not set)
NO_INSTALL_SHARED:=

# non-empty if do not install/uninstall dll import libraries (WINDOWS)
NO_INSTALL_IMPORT  = $($1_LIBRARY_NO_DEVEL)

# non-empty if do not install/uninstall libtool .la-files (UNIX)
NO_INSTALL_LIBTOOL = $($1_LIBRARY_NO_DEVEL)

# non-empty if do not install/uninstall pkg-config .pc-files
NO_INSTALL_PKGCONF = $($1_LIBRARY_NO_DEVEL)

# define library-specific variables for use in installation templates
# $1 - library name (mylib for libmylib.a)
# note: assume LIB and DLL variables are defined before expanding this template
# note: variable LIBRARY_NO_DEVEL and other LIBRARY_NO_... variables are may be set
#  in target makefile before expanding INSTALL_LIB to specify per-library installation configuration
# note: it is possible to override library-specific options either in command line or in project configuration makefile,
#  for example: mylib_LIBRARY_NO_DEVEL:=1 prevents installing development files for library 'mylib'
# note: use $(addprefix /) to make empty $($1_LIBRARY_HDIR) value if $(LIBRARY_HDIR) is empty (by default)
define DEFINE_INSTALL_LIB_VARS
$1_BUILT_LIB_VARIANTS         := $(if $(LIB),$(call GET_VARIANTS,LIB))
$1_BUILT_DLL_VARIANTS         := $(if $(DLL),$(call GET_VARIANTS,DLL))
$1_BUILT_LIBS                 := $$(foreach v,$$($1_BUILT_LIB_VARIANTS),$$(call FORM_TRG,LIB,$$v))
$1_BUILT_DLLS                 := $$(foreach v,$$($1_BUILT_DLL_VARIANTS),$$(call FORM_TRG,DLL,$$v))
$1_LIBRARY_NO_DEVEL           := $$(LIBRARY_NO_DEVEL)
$1_LIBRARY_NO_INSTALL_HEADERS := $$(LIBRARY_NO_INSTALL_HEADERS)
$1_LIBRARY_NO_INSTALL_STATIC  := $$(LIBRARY_NO_INSTALL_STATIC)
$1_LIBRARY_NO_INSTALL_SHARED  := $$(LIBRARY_NO_INSTALL_SHARED)
$1_LIBRARY_NO_INSTALL_IMPORT  := $$(LIBRARY_NO_INSTALL_IMPORT)
$1_LIBRARY_NO_INSTALL_LIBTOOL := $$(LIBRARY_NO_INSTALL_LIBTOOL)
$1_LIBRARY_NO_INSTALL_PKGCONF := $$(LIBRARY_NO_INSTALL_PKGCONF)
ifeq (,$$($1_LIBRARY_NO_INSTALL_HEADERS))
$1_LIBRARY_HEADERS            := $$(call fixpath,$$(LIBRARY_HEADERS))
$1_LIBRARY_HDIR               := $$(addprefix /,$$(LIBRARY_HDIR))
endif
endef

# library base installation template
# $1 - library name (mylib for libmylib.a)
# $2 - where to install static libraries, should be $$(D_LIBDIR)
# $3 - where to install shared libraries, may be $$(D_LIBDIR) or $$(D_BINDIR)
# note: defines target-specific variables: BUILT_LIBS BUILT_DLLS
# note: do not try to install $(D_LIBDIR) if no LIBS/DLLS were built
define INSTALL_LIB_BASE

$(DEFINE_INSTALL_LIB_VARS)

ifeq (,$$($1_LIBRARY_NO_INSTALL_STATIC))
ifneq (,$$($1_BUILT_LIBS))
install_lib_$1_static uninstall_lib_$1_static: BUILT_LIBS := $$($1_BUILT_LIBS)
install_lib_$1_static: $$($1_BUILT_LIBS) | $$(call NEED_INSTALL_DIR_RET,$2)
install_lib_$1:   install_lib_$1_static
uninstall_lib_$1: uninstall_lib_$1_static
$(call SET_MAKEFILE_INFO,install_lib_$1_static uninstall_lib_$1_static)
endif
endif

ifeq (,$$($1_LIBRARY_NO_INSTALL_SHARED))
ifneq (,$$($1_BUILT_DLLS))
install_lib_$1_shared uninstall_lib_$1_shared: BUILT_DLLS := $$($1_BUILT_DLLS)
install_lib_$1_shared: $$($1_BUILT_DLLS) | $$(call NEED_INSTALL_DIR_RET,$3)
install_lib_$1:   install_lib_$1_shared
uninstall_lib_$1: uninstall_lib_$1_shared
$(call SET_MAKEFILE_INFO,install_lib_$1_shared uninstall_lib_$1_shared)
endif
endif

.PHONY: \
  install_lib_$1_static uninstall_lib_$1_static \
  install_lib_$1_shared uninstall_lib_$1_shared \
  install_lib_$1 uninstall_lib_$1

install:   install_lib_$1
uninstall: uninstall_lib_$1

endef # INSTALL_LIB_BASE

# library headers installation template
# $1 - library name (mylib for libmylib.a)
# note: $(INSTALL_LIB_BASE) must be evaluated before expanding this template, so $1_LIBRARY_HDIR is defined
# note: defines target-specific variable: HEADERS
define INSTALL_LIB_HEADERS

ifeq (,$$($1_LIBRARY_NO_INSTALL_HEADERS))
ifneq (,$$($1_LIBRARY_HEADERS))

install_lib_$1_headers uninstall_lib_$1_headers: HEADERS := $$($1_LIBRARY_HEADERS)

install_lib_$1_headers: $$($1_LIBRARY_HEADERS) | $$(call NEED_INSTALL_DIR_RET,$$(D_INCLUDEDIR)$($1_LIBRARY_HDIR))
	$$(call DO_INSTALL_FILES,$$(HEADERS),$$(D_INCLUDEDIR)$($1_LIBRARY_HDIR),644)

uninstall_lib_$1_headers:
	$$(call DO_UNINSTALL_FILES_IN,$$(D_INCLUDEDIR)$($1_LIBRARY_HDIR),$$(notdir $$(HEADERS)))

install_lib_$1:   install_lib_$1_headers
uninstall_lib_$1: uninstall_lib_$1_headers

$(call SET_MAKEFILE_INFO,install_lib_$1_headers uninstall_lib_$1_headers)

endif
endif

.PHONY: install_lib_$1_headers uninstall_lib_$1_headers

endef # INSTALL_LIB_HEADERS

# INSTALL_LIB_MK - makefile with definition of $(OS)-specific INSTALL_LIB macro
INSTALL_LIB_MK := $(dir $(lastword $(MAKEFILE_LIST)))install_lib_$(INSTALL_OS_TYPE).mk

ifeq (,$(wildcard $(INSTALL_LIB_MK)))
$(error file $(INSTALL_LIB_MK) was not found, check value of INSTALL_LIB_MK variable)
endif

# define $(OS)-specific INSTALL_LIB macro
include $(INSTALL_LIB_MK)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,NO_INSTALL_HEADERS NO_INSTALL_LIBTOOL NO_INSTALL_PKGCONF NO_INSTALL_IMPS \
  DEFINE_INSTALL_LIB_VARS INSTALL_LIB_BASE INSTALL_LIB_HEADERS INSTALL_LIB_MK)
