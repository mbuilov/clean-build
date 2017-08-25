#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# included by $(CLEAN_BUILD_DIR)/install/install_lib.mk

ifeq (,$(filter-out undefined environment,$(origin NEED_INSTALL_DIR)))
include $(dir $(lastword $(MAKEFILE_LIST)))inst_utils.mk
endif

# next NO_... macros are used to form default configuration of libraries installation,
# for example, setting NO_INSTALL_HEADERS:=1 in command line prevents installation of headers for all libraries
# $1 - library name (mylib for libmylib.a)

# non-empty if do not install/uninstall header files
NO_INSTALL_HEADERS = $($1_LIBRARY_NO_DEVEL)

# non-empty if do not install/uninstall libtool .la-files (UNIX)
NO_INSTALL_LA      = $($1_LIBRARY_NO_DEVEL)

# non-empty if do not install/uninstall pkg-config .pc-files
NO_INSTALL_PC      = $($1_LIBRARY_NO_DEVEL)

# non-empty if do not install/uninstall dll import libraries (WINDOWS)
NO_INSTALL_IMPS    = $($1_LIBRARY_NO_DEVEL)

# define variables for use in library installation template
# $1 - library name (mylib for libmylib.a)
# note: assume LIB and DLL variables are defined before expanding this template
# note: variables LIBRARY_NO_DEVEL, LIBRARY_NO_INSTALL_HEADERS, LIBRARY_NO_INSTALL_LA, LIBRARY_NO_INSTALL_PC, LIBRARY_NO_INSTALL_IMPS
#  may be set in target makefile before expanding INSTALL_LIB to specify per-library installation configuration
# note: it is possible to override library-specific options either in command line or in project configuration makefile,
#  for example: mylib_LIBRARY_NO_DEVEL:=1 prevents installing development files for library 'mylib'
# note: use $(addprefix /) to get empty $($1_LIBRARY_HDIR) if $(LIBRARY_HDIR) is empty
# note: define target-specific variables: BUILT_LIBS, BUILT_DLLS, HEADERS
define DEFINE_INSTALL_LIB_VARS

$1_BUILT_LIB_VARIANTS         := $(if $(LIB),$(call GET_VARIANTS,LIB))
$1_BUILT_DLL_VARIANTS         := $(if $(DLL),$(call GET_VARIANTS,DLL))
$1_BUILT_LIBS                 := $$(foreach v,$$($1_BUILT_LIB_VARIANTS),$$(call FORM_TRG,LIB,$$v))
$1_BUILT_DLLS                 := $$(foreach v,$$($1_BUILT_DLL_VARIANTS),$$(call FORM_TRG,DLL,$$v))
$1_LIBRARY_HEADERS            := $$(call fixpath,$$(LIBRARY_HEADERS))
$1_LIBRARY_HDIR               := $$(addprefix /,$$(LIBRARY_HDIR))
$1_LIBRARY_NO_DEVEL           := $$(LIBRARY_NO_DEVEL)
$1_LIBRARY_NO_INSTALL_HEADERS := $$(LIBRARY_NO_INSTALL_HEADERS)
$1_LIBRARY_NO_INSTALL_LA      := $$(LIBRARY_NO_INSTALL_LA)
$1_LIBRARY_NO_INSTALL_PC      := $$(LIBRARY_NO_INSTALL_PC)
$1_LIBRARY_NO_INSTALL_IMPS    := $$(LIBRARY_NO_INSTALL_IMPS)

install_$1 uninstall_$1: BUILT_LIBS := $$($1_BUILT_LIBS)
install_$1 uninstall_$1: BUILT_DLLS := $$($1_BUILT_DLLS)

install_$1_headers uninstall_$1_headers: HEADERS := $$($1_LIBRARY_HEADERS)

ifneq (,$$($1_BUILT_LIBS)$$($1_BUILT_DLLS))
install_$1: $$($1_BUILT_LIBS) $$($1_BUILT_DLLS) | $$(call NEED_INSTALL_DIR_RET,$$(subst $$(space),\ ,$$(D_LIBDIR)))
endif

ifeq (,$$($1_LIBRARY_NO_INSTALL_HEADERS))
ifneq (,$$($1_LIBRARY_HEADERS))
install_$1_headers: $$($1_LIBRARY_HEADERS) | $$(call NEED_INSTALL_DIR_RET,$$(subst $$(space),\ ,$$(D_INCLUDEDIR)$$($1_LIBRARY_HDIR)))
install_$1: install_$1_headers
uninstall_$1: uninstall_$1_headers
endif
endif

install: install_$1
uninstall: uninstall_$1

install_$1_headers uninstall_$1_headers install_$1 uninstall_$1:
.PHONY: install_$1_headers uninstall_$1_headers install_$1 uninstall_$1
$(call SET_MAKEFILE_INFO,install_$1_headers uninstall_$1_headers install_$1 uninstall_$1)

endef

# OS_INSTALL_LIB - type of library installation
# note: normally OS_INSTALL_LIB get overridden by specifying it in command line
OS_INSTALL_LIB := $(if $(filter WIN%,$(OS)),windows,unix)

# OS_INSTALL_LIB_MK - makefile with definition of $(OS)-specific INSTALL_LIB macro
OS_INSTALL_LIB_MK := $(dir $(lastword $(MAKEFILE_LIST)))install_lib_$(OS_INSTALL_LIB).mk

ifeq (,$(wildcard $(OS_INSTALL_LIB_MK)))
$(error file $(OS_INSTALL_LIB_MK) was not found, check value of OS_INSTALL_LIB_MK variable)
endif

# define $(OS)-specific INSTALL_LIB macro
include $(OS_INSTALL_LIB_MK)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,NO_INSTALL_HEADERS NO_INSTALL_LA NO_INSTALL_PC NO_INSTALL_IMPS \
  DEFINE_INSTALL_LIB_VARS OS_INSTALL_LIB OS_INSTALL_LIB_MK)
