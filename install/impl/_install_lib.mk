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

# next NO_... macros are used to form default configuration of libraries installation,
# for example, setting NO_INSTALL_HEADERS:=1 in command line prevents installation of headers for all libraries
# note: here $1 - library name without variant suffix (mylib for libmylib_pie.a)

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

# write result of $(LIBRARY_PC_GENERATOR)/$(LIBRARY_LA_GENERATOR) by fixed number of lines at a time
# note: command line length is limited (by 8191 chars on Windows),
#  so must not write more than that number of chars (lines * max_chars_in_line) at a time.
CONF_WRITE_BY_LINES := 35

# define library-specific variables for use in installation templates
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
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
$1_LIBRARY_NO_INSTALL_PKGCONF := $$(LIBRARY_NO_INSTALL_PKGCONF)
$1_LIBRARY_NO_INSTALL_LIBTOOL := $$(LIBRARY_NO_INSTALL_LIBTOOL)
ifeq (,$$($1_LIBRARY_NO_INSTALL_HEADERS))
$1_LIBRARY_HEADERS            := $$(call fixpath,$$(LIBRARY_HEADERS))
$1_LIBRARY_HDIR               := $$(addprefix /,$$(LIBRARY_HDIR))
endif
endef

# install static libs
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - where to install static libraries, should be $$(D_LIBDIR)
define INSTALL_LIB_STATIC
install_lib_$1_static uninstall_lib_$1_static: BUILT_LIBS := $$($1_BUILT_LIBS)
install_lib_$1_static: $$($1_BUILT_LIBS) | $$(call NEED_INSTALL_DIR_RET,$2)
	$$(call DO_INSTALL_FILES,$$(BUILT_LIBS),$2,644)
uninstall_lib_$1_static:
	$$(call DO_UNINSTALL_FILES_IN,$2,$$(notdir $$(BUILT_LIBS)))
install_lib_$1:   install_lib_$1_static
uninstall_lib_$1: uninstall_lib_$1_static
$(call SET_MAKEFILE_INFO,install_lib_$1_static uninstall_lib_$1_static)
endef

# install shared libs
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $3 - where to install shared libraries, may be $$(D_LIBDIR) (Unix) or $$(D_BINDIR) (Windows)
define INSTALL_LIB_SHARED
install_lib_$1_shared uninstall_lib_$1_shared: BUILT_DLLS := $$($1_BUILT_DLLS)
install_lib_$1_shared: $$($1_BUILT_DLLS) | $$(call NEED_INSTALL_DIR_RET,$3)
	$$(call DO_INSTALL_FILES,$$(BUILT_DLLS),$3,755)
uninstall_lib_$1_shared:
	$$(call DO_UNINSTALL_FILES_IN,$3,$$(notdir $$(BUILT_DLLS)))
install_lib_$1:   install_lib_$1_shared
uninstall_lib_$1: uninstall_lib_$1_shared
$(call SET_MAKEFILE_INFO,install_lib_$1_shared uninstall_lib_$1_shared)
endef

# library headers installation template
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# note: $(DEFINE_INSTALL_LIB_VARS) must be evaluated before expanding this template, so $1_LIBRARY_HDIR is defined
define INSTALL_LIB_HEADERS
install_lib_$1_headers uninstall_lib_$1_headers: HEADERS := $$($1_LIBRARY_HEADERS)
install_lib_$1_headers: $$($1_LIBRARY_HEADERS) | $$(call NEED_INSTALL_DIR_RET,$$(D_INCLUDEDIR)$($1_LIBRARY_HDIR))
	$$(call DO_INSTALL_FILES,$$(HEADERS),$$(D_INCLUDEDIR)$($1_LIBRARY_HDIR),644)
uninstall_lib_$1_headers:
	$$(call DO_UNINSTALL_FILES_IN,$$(D_INCLUDEDIR)$($1_LIBRARY_HDIR),$$(notdir $$(HEADERS)))
install_lib_$1:   install_lib_$1_headers
uninstall_lib_$1: uninstall_lib_$1_headers
$(call SET_MAKEFILE_INFO,install_lib_$1_headers uninstall_lib_$1_headers)
endef

# select dynamic variant of the library which may be specified together with given static variant
# $1 - static variant, in form name/variant, e.g. mylib_pie/P
# $2 - list of dynamic variants, in form name/variant, e.g. mylib_st/S
# note: STATIC_LIB_SELECT_DYNAMIC defined in $(CLEAN_BUILD_DIR)/impl/_c.mk
INSTALL_LIB_SELECT_DYN = $(filter %/$(patsubst ,R,$(call \
  STATIC_LIB_SELECT_DYNAMIC,$(filter-out R,$(word 2,$(subst /, ,$1))))),$2)

# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - name of configuration template
# $3 - parameter for configuration template $2
# $4 - static variant of the library in form name/variant, e.g. mylib_pie/P ($4 may be empty, if $5 is not empty)
# $5 - dynamic variant of the library in form name/variant, e.g. mylib_st/S ($5 may be empty, if $4 is not empty)
# call template $2 with parameters:
#  $1 - library name without variant suffix (mylib for libmylib_pie.a)
#  $2 - static variant of the library in form name/variant, e.g. mylib_pie/P ($2 may be empty, if $3 is not empty)
#  $3 - dynamic variant of the library in form name/variant, e.g. mylib_st/S ($3 may be empty, if $2 is not empty)
#  $4 - base name of generating configuration file, e.g. mylib_pie for mylib_pie/P+mylib/R
#  $5 - parameter
INSTALL_LIB_CONFIGS2 = $(call $2,$1,$4,$5,$(firstword $(subst /, ,$(firstword $4 $5))),$3)$(newline)

# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - name of configuration template
# $3 - parameter for configuration template $2
# $4 - list of built libs+variants, in form name/variant, e.g. mylib_pie/P
# $5 - list of built dlls+variants, in form name/variant, e.g. mylib_st/S
# 1) call template $2 for each built static variant of the library with selected dynamic variant 
# 2) call template $2 for each built dynamic variant of the library with empty static variant
INSTALL_LIB_CONFIGS1 = $(foreach l,$4,$(call INSTALL_LIB_CONFIGS2,$1,$2,$3,$l,$(call \
  INSTALL_LIB_SELECT_DYN,$l,$5)))$(foreach d,$(filter-out $4,$5),$(call INSTALL_LIB_CONFIGS2,$1,$2,$3,,$d))

# helper for generating library configurations
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - name of configuration template
# $3 - parameter for configuration template $2
# note: $(INSTALL_LIB_BASE) must be evaluated before expanding this macro, so
#  $1_BUILT_LIB_VARIANTS, $1_BUILT_DLL_VARIANTS, $1_BUILT_LIBS and $1_BUILT_DLLS are defined
INSTALL_LIB_CONFIGS = $(call INSTALL_LIB_CONFIGS1,$1,$2,$3,$(join \
  $(patsubst $(LIB_PREFIX)%$(LIB_SUFFIX),%/,$(notdir $($1_BUILT_LIBS))),$($1_BUILT_LIB_VARIANTS)),$(join \
  $(patsubst $(DLL_PREFIX)%$(DLL_SUFFIX),%/,$(notdir $($1_BUILT_DLLS))),$($1_BUILT_DLL_VARIANTS)))

# generate configuration file for a combination of static+dynamic variants of the library $1
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - static variant of the library in form name/variant, e.g. mylib_pie/P ($2 may be empty, if $3 is not empty)
# $3 - dynamic variant of the library in form name/variant, e.g. mylib_st/S ($3 may be empty, if $2 is not empty)
# $4 - full name of generating configuration file, e.g. libmylib_pie.pc for mylib_pie/P+mylib/R
# $5 - where to generate configuration file, may be $$(D_LIBDIR), $$(D_PKG_LIBDIR) or $$(D_PKG_DATADIR)
# $6 - target suffix, e.g pkfconf or libtool
# $7 - name of configuration generator macro, e.g. LIBRARY_PC_GENERATOR or LIBRARY_LA_GENERATOR
define INSTALL_LIB_CONFIG_ONE
tmp_CONF_TEXT := $$($7)
ifdef tmp_CONF_TEXT
install_lib_$1_$6_$4 uninstall_lib_$1_$6_$4: CONF_TEXT := $$(tmp_CONF_TEXT)
install_lib_$1_$6_$4 uninstall_lib_$1_$6_$4: CONF_FILE := $5/$4
install_lib_$1_$6_$4:| $$(call NEED_INSTALL_DIR_RET,$5)
	$$(call INSTALL_TEXT,$$(CONF_TEXT),$$(CONF_FILE),$(CONF_WRITE_BY_LINES),644)
uninstall_lib_$1_$6_$4:
	$$(call DO_UNINSTALL_FILE,$$(CONF_FILE))
install_lib_$1_$6:   install_lib_$1_$6_$4
uninstall_lib_$1_$6: uninstall_lib_$1_$6_$4
.PHONY: install_lib_$1_$6_$4 uninstall_lib_$1_$6_$4
endif
endef

# called from INSTALL_LIB_CONFIGS2 with parameters:
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - static variant of the library in form name/variant, e.g. mylib_pie/P ($2 may be empty, if $3 is not empty)
# $3 - dynamic variant of the library in form name/variant, e.g. mylib_st/S ($3 may be empty, if $2 is not empty)
# $4 - base name of generating configuration file, e.g. mylib_pie for mylib_pie/P+mylib/R
# $5 - parameter, should be $$(D_PKG_LIBDIR) or $$(D_PKG_DATADIR)
INSTALL_LIB_PKGCONF_ONE = $(call INSTALL_LIB_CONFIG_ONE,$1,$2,$3,$4.pc,$5,pkgconf,LIBRARY_PC_GENERATOR)

# called from INSTALL_LIB_CONFIGS2 with parameters:
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - static variant of the library in form name/variant, e.g. mylib_pie/P ($2 may be empty, if $3 is not empty)
# $3 - dynamic variant of the library in form name/variant, e.g. mylib_st/S ($3 may be empty, if $2 is not empty)
# $4 - base name of generating configuration file, e.g. mylib_pie for mylib_pie/P+mylib/R
# $5 - parameter, should be $$(D_LIBDIR)
INSTALL_LIB_LIBTOOL_ONE = $(call INSTALL_LIB_CONFIG_ONE,$1,$2,$3,lib$4.la,$5,libtool,LIBRARY_LA_GENERATOR)

# install pkg-config files
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $4 - where to install pkg-configs, should be $$(D_PKG_LIBDIR) or $$(D_PKG_DATADIR)
INSTALL_LIB_PKGCONF = $(call INSTALL_LIB_CONFIGS,$1,INSTALL_LIB_PKGCONF_ONE,$4)

# install libtool archive files
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $5 - where to install libtool archives, should be $$(D_LIBDIR)
INSTALL_LIB_LIBTOOL = $(call INSTALL_LIB_CONFIGS,$1,INSTALL_LIB_LIBTOOL_ONE,$5)

# library base installation template
# $1 - library name (mylib for libmylib.a)
# $2 - where to install static libraries, should be $$(D_LIBDIR)
# $3 - where to install shared libraries, may be $$(D_LIBDIR) or $$(D_BINDIR)
# $4 - where to install pkg-configs, should be $$(D_PKG_LIBDIR) or $$(D_PKG_DATADIR)
# $5 - where to install libtool archives, should be $$(D_LIBDIR)
# note: $(DEFINE_INSTALL_LIB_VARS) must be evaluated before expanding this template, so some of $1_... macros are defined
define INSTALL_LIB_BASE
$(if $($1_LIBRARY_NO_INSTALL_STATIC),,$(if $($1_BUILT_LIBS),$(INSTALL_LIB_STATIC)))
$(if $($1_LIBRARY_NO_INSTALL_SHARED),,$(if $($1_BUILT_DLLS),$(INSTALL_LIB_SHARED)))
$(if $($1_LIBRARY_NO_INSTALL_HEADERS),,$(if $($1_LIBRARY_HEADERS),$(INSTALL_LIB_HEADERS)))
$(if $($1_LIBRARY_NO_INSTALL_PKGCONF),,$(INSTALL_LIB_PKGCONF))
$(if $($1_LIBRARY_NO_INSTALL_LIBTOOL),,$(INSTALL_LIB_LIBTOOL))
.PHONY: \
  install_lib_$1_static uninstall_lib_$1_static \
  install_lib_$1_shared uninstall_lib_$1_shared \
  install_lib_$1_headers uninstall_lib_$1_headers \
  install_lib_$1_pkgconf uninstall_lib_$1_pkgconf \
  install_lib_$1_libtool uninstall_lib_$1_libtool \
  install_lib_$1 uninstall_lib_$1
install_lib_$1:   install_lib_$1_pkgconf   install_lib_$1_libtool
uninstall_lib_$1: uninstall_lib_$1_pkgconf uninstall_lib_$1_libtool
$(call SET_MAKEFILE_INFO, \
  install_lib_$1_pkgconf uninstall_lib_$1_pkgconf \
  install_lib_$1_libtool uninstall_lib_$1_libtool)
install:   install_lib_$1
uninstall: uninstall_lib_$1
endef

# INSTALL_LIB_MK - makefile with definition of $(OS)-specific INSTALL_LIB macro
# note: INSTALL_OS_TYPE defined in $(CLEAN_BUILD_DIR)/install/impl/inst_dirs.mk
INSTALL_LIB_MK := $(dir $(lastword $(MAKEFILE_LIST)))install_lib_$(INSTALL_OS_TYPE).mk

ifeq (,$(wildcard $(INSTALL_LIB_MK)))
$(error file $(INSTALL_LIB_MK) was not found, check value of INSTALL_LIB_MK variable)
endif

# define $(OS)-specific INSTALL_LIB macro
include $(INSTALL_LIB_MK)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,NO_INSTALL_HEADERS NO_INSTALL_STATIC NO_INSTALL_SHARED NO_INSTALL_IMPORT NO_INSTALL_LIBTOOL NO_INSTALL_PKGCONF \
  CONF_WRITE_BY_LINES DEFINE_INSTALL_LIB_VARS INSTALL_LIB_STATIC INSTALL_LIB_SHARED INSTALL_LIB_HEADERS INSTALL_LIB_SELECT_DYN \
  INSTALL_LIB_CONFIGS2 INSTALL_LIB_CONFIGS1 INSTALL_LIB_CONFIGS INSTALL_LIB_CONFIG_ONE INSTALL_LIB_PKGCONF_ONE INSTALL_LIB_LIBTOOL_ONE \
  INSTALL_LIB_PKGCONF INSTALL_LIB_LIBTOOL INSTALL_LIB_BASE INSTALL_LIB_MK)
