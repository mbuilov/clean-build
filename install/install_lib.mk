#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define INSTALL_LIB - library installation macro

# this file is likely included in target makefile after $(DEFINE_TARGETS) which builds (and/or):
# LIB - static variants of the library
# DLL - dynamic variants of the library

# anyway, LIB and DLL variables are _must_ be defined before expanding INSTALL_LIB

ifeq (,$(filter-out undefined environment,$(origin INSTALL_LIB)))
include $(dir $(lastword $(MAKEFILE_LIST)))/impl/_install_lib.mk
endif

# reset variables - they may be redefined in target makefile before expanding INSTALL_LIB
LIBRARY_NO_DEVEL           := $(NO_DEVEL)
LIBRARY_NO_INSTALL_HEADERS  = $(NO_INSTALL_HEADERS)
LIBRARY_NO_INSTALL_STATIC   = $(NO_INSTALL_STATIC)
LIBRARY_NO_INSTALL_SHARED   = $(NO_INSTALL_SHARED)
LIBRARY_NO_INSTALL_IMPORT   = $(NO_INSTALL_IMPORT)
LIBRARY_NO_INSTALL_PKGCONF  = $(NO_INSTALL_PKGCONF)

# list of header files to install, may be empty
LIBRARY_HEADERS:=

# name of installed headers sub-directory, may be empty, must not contain spaces
LIBRARY_HDIR:=

# pkg-config file generator macro, must be defined if $(LIBRARY_NO_INSTALL_PKGCONF) is empty
# $1 - library name without variant suffix, as specified in $(LIB) or $(DLL), e.g. mylib for built libmylib_pie.a
# $2 - library name with variant suffix and names of static/dynamic variants, e.g. mylib_pie/P/P, where:
#  mylib_pie - library name 'mylib' with variant suffix '_pie',
#  P/P - static/dynamic variants of the library, each variant may be optional, but not both:
#   mylib_pie/P/  - only static variant P of the library was built,
#   mylib_pie//P  - only dynamic variant P of the library was built,
#   mylib_pie/P/P - both static variant P and dynamic variant P of the library were built.
# $3 - name of generating configuration file, e.g. mylib_pie.pc for mylib_pie/P/P
# $4 - directory where to install configuration file, should be $(D_PKG_LIBDIR) or $(D_PKG_DATADIR)
# note: for implementing this macro use helper macros from $(CLEAN_BUILD_DIR)/install/pkgconf_gen.mk
LIBRARY_PC_GENERATOR:=

# directory where to install pkg-config files:
# $$(PKG_LIBDIR)  - for ordinary libraries
# $$(PKG_DATADIR) - for header-only libraries
LIBRARY_PC_DIR := $$(PKG_LIBDIR)

# after (re-)defining above variables, just expand $(INSTALL_LIB) to define next targets based on values of $(LIB) and $(DLL):
#
# for LIB := mylib
# or  DLL := mylib
# or  LIB := mylib and DLL := mylib         for LIB := mylibS and DLL := mylibD
#
# (if names of LIB and DLL are the same,    (if names of LIB and DLL do not match,
#  this means that one library is built      this means that two different libraries were built:
#  in two forms: static and dynamic)         one static and one - dynamic)
#
# install_lib_mylib                         install_lib_mylibS               install_lib_mylibD
# install_lib_mylib_static                  install_lib_mylibS_static        install_lib_mylibD_static
# install_lib_mylib_shared                  install_lib_mylibS_shared   and  install_lib_mylibD_shared
# install_lib_mylib_headers                 install_lib_mylibS_headers       install_lib_mylibD_headers
# install_lib_mylib_pkgconf                 install_lib_mylibS_pkgconf       install_lib_mylibD_pkgconf
#
# and their uninstall_... counterparts,
#
# also install_lib_mylib/uninstall_lib_mylib targets are added as dependencies for standard install/uninstall goals.
