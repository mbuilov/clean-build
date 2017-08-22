#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# auxiliary templates to simplify installation of libraries

ifeq (,$(filter-out undefined environment,$(origin INSTALL_LIBS)))
include $(dir $(lastword $(MAKEFILE_LIST)))_install_lib.mk
endif

# this file is likely included in target makefile after $(DEFINE_TARGETS) which builds (and/or):
# LIB - static library name (with variants)
# DLL - dynamic library name (with variants)

# anyway, LIB and DLL variables are _must_ be defined before expanding INSTALL_LIBS

# reset variables - they may be redefined in target makefile before expanding INSTALL_LIBS
LIBRARY_NO_DEVEL           := $(NO_DEVEL)
LIBRARY_NO_INSTALL_HEADERS  = $(NO_INSTALL_HEADERS)
LIBRARY_NO_INSTALL_LA       = $(NO_INSTALL_LA)
LIBRARY_NO_INSTALL_PC       = $(NO_INSTALL_PC)
LIBRARY_NO_INSTALL_IMPS     = $(NO_INSTALL_IMPS)

# list of header files to install, may be empty
LIBRARY_HEADERS:=

# name of installed headers directory, may be empty
LIBRARY_HDIR:=

# name of pkg-config file generator macro, must be defined if $(LIBRARY_NO_INSTALL_PC) is empty
LIBRARY_PC_GEN:=

# after (re-)defining above variables, expand INSTALL_LIBS macro via just $(INSTALL_LIBS)
