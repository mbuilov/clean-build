#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# auxiliary templates to simplify installation of libraries, defines INSTALL_LIB macro

ifeq (,$(filter-out undefined environment,$(origin INSTALL_LIB)))
include $(dir $(lastword $(MAKEFILE_LIST)))/impl/_install_lib.mk
endif

# this file is likely included in target makefile after $(DEFINE_TARGETS) which builds (and/or):
# LIB - static variants of the library
# DLL - dynamic variants of the library

# anyway, LIB and DLL variables are _must_ be defined before expanding INSTALL_LIB

# reset variables - they may be redefined in target makefile before expanding INSTALL_LIB
LIBRARY_NO_DEVEL           := $(NO_DEVEL)
LIBRARY_NO_INSTALL_HEADERS  = $(NO_INSTALL_HEADERS)
LIBRARY_NO_INSTALL_STATIC   = $(NO_INSTALL_STATIC)
LIBRARY_NO_INSTALL_SHARED   = $(NO_INSTALL_SHARED)
LIBRARY_NO_INSTALL_IMPORT   = $(NO_INSTALL_IMPORT)
LIBRARY_NO_INSTALL_PKGCONF  = $(NO_INSTALL_PKGCONF)
LIBRARY_NO_INSTALL_LIBTOOL  = $(NO_INSTALL_LIBTOOL)

# list of header files to install, may be empty
LIBRARY_HEADERS:=

# name of installed headers directory, may be empty, must not contain spaces
LIBRARY_HDIR:=

# .pc - pkg-config file generator macro, must be defined if $(LIBRARY_NO_INSTALL_PKGCONF) is empty
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - static variant of the library in form name/variant, e.g. mylib_pie/P ($2 may be empty, if $3 is not empty)
# $3 - dynamic variant of the library in form name/variant, e.g. mylib_st/S ($3 may be empty, if $2 is not empty)
# $4 - full name of generating configuration file, e.g. mylib_pie.pc for mylib_pie/P+mylib/R
# $5 - where to generate configuration file, may be $$(D_PKG_LIBDIR) or $$(D_PKG_DATADIR)
# note: use helper macros from $(CLEAN_BUILD_DIR)/install/pkgconf_gen.mk
LIBRARY_PC_GENERATOR:=

# directory where to generate pkg-config .pc files:
# $$(PKG_LIBDIR)  - for ordinary libraries
# $$(PKG_DATADIR) - for header-only libraries
LIBRARY_PC_DIR := $$(PKG_LIBDIR)

# .la - libtool archive file generator macro, must be defined if $(LIBRARY_NO_INSTALL_LIBTOOL) is empty
# $1 - library name without variant suffix (mylib for libmylib_pie.a)
# $2 - static variant of the library in form name/variant, e.g. mylib_pie/P ($2 may be empty, if $3 is not empty)
# $3 - dynamic variant of the library in form name/variant, e.g. mylib_st/S ($3 may be empty, if $2 is not empty)
# $4 - full name of generating configuration file, e.g. libmylib_pie.la for mylib_pie/P+mylib/R
# $5 - where to generate configuration file, should be $$(D_LIBDIR)
# note: use helper macros from $(CLEAN_BUILD_DIR)/install/libtool_gen.mk
LIBRARY_LA_GENERATOR:=

# directory where to generate libtool archive .la files:
LIBRARY_LA_DIR := $$(LIBDIR)

# after (re-)defining above variables, just $(call INSTALL_LIB,mylib) to define targets:
#
# install_lib_mylib
# install_lib_mylib_static
# install_lib_mylib_shared
# install_lib_mylib_headers
# install_lib_mylib_pkgconf
# install_lib_mylib_libtool
#
# and their uninstall_... counterparts,
#
# also install_lib_mylib/uninstall_lib_mylib targets are added as dependencies for standard install/uninstall goals.
