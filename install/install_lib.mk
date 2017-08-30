#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# auxiliary templates to simplify installation of libraries, defines INSTALL_LIB macro

ifeq (,$(filter-out undefined environment,$(origin INSTALL_LIB)))
include $(dir $(lastword $(MAKEFILE_LIST)))/impl/_install_lib.mk
endif

# install/install_lib.mk
#         |
#         +-impl/_install_lib.mk
#                |
#                +-inst_utils.mk
#                | |
#                | +-inst_dirs.mk
#                |
#                +-inst_text.mk
#                |
#                +-pkgconf_gen.mk
#                |
#                +-libtool_gen.mk
#                |
#                +-install_lib_windows.mk

# this file is likely included in target makefile after $(DEFINE_TARGETS) which builds (and/or):
# LIB - static library name (with variants)
# DLL - dynamic library name (with variants)

# anyway, LIB and DLL variables are _must_ be defined before expanding INSTALL_LIB

# reset variables - they may be redefined in target makefile before expanding INSTALL_LIB
LIBRARY_NO_DEVEL           := $(NO_DEVEL)
LIBRARY_NO_INSTALL_HEADERS  = $(NO_INSTALL_HEADERS)
LIBRARY_NO_INSTALL_STATIC   = $(NO_INSTALL_STATIC)
LIBRARY_NO_INSTALL_SHARED   = $(NO_INSTALL_SHARED)
LIBRARY_NO_INSTALL_IMPORT   = $(NO_INSTALL_IMPORT)
LIBRARY_NO_INSTALL_LIBTOOL  = $(NO_INSTALL_LIBTOOL)
LIBRARY_NO_INSTALL_PKGCONF  = $(NO_INSTALL_PKGCONF)

# list of header files to install, may be empty
LIBRARY_HEADERS:=

# name of installed headers directory, may be empty, must not contain spaces
LIBRARY_HDIR:=

# pkg-config file generator macro, must be defined if $(LIBRARY_NO_INSTALL_PKGCONF) is empty
LIBRARY_PKGCONF_GEN:=

# directory where to generate pkg-config file:
# $(PKG_LIBDIR)  - for ordinary libraries
# $(PKG_DATADIR) - for header-only libraries
LIBRARY_PKGCONF_DIR = $(PKG_LIBDIR)

# after (re-)defining above variables, expand INSTALL_LIB macro via just $(INSTALL_LIB)
