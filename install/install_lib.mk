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
# LIB - static library name (with variants)
# DLL - dynamic library name (with variants)

# anyway, LIB and DLL variables are _must_ be defined before expanding INSTALL_LIB

# reset variables - they may be redefined in target makefile before expanding INSTALL_LIB
LIBRARY_NO_DEVEL           := $(NO_DEVEL)
LIBRARY_NO_INSTALL_HEADERS  = $(NO_INSTALL_HEADERS)
LIBRARY_NO_INSTALL_STATIC   = $(NO_INSTALL_STATIC)
LIBRARY_NO_INSTALL_SHARED   = $(NO_INSTALL_SHARED)
LIBRARY_NO_INSTALL_IMPORT   = $(NO_INSTALL_IMPORT)
LIBRARY_NO_INSTALL_LA       = $(NO_INSTALL_LA)
LIBRARY_NO_INSTALL_PC       = $(NO_INSTALL_PC)

# list of header files to install, may be empty
LIBRARY_HEADERS:=

# name of installed headers directory, may be empty, must not contain spaces
LIBRARY_HDIR:=

# name of pkg-config file generator macro, must be defined if $(LIBRARY_NO_INSTALL_PC) is empty
LIBRARY_PC_GEN:=

# after (re-)defining above variables, expand INSTALL_LIB macro via just $(INSTALL_LIB)
