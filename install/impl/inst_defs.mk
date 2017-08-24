#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# installation definitions

# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk

# source definitions of standard installation directories, such as DESTDIR, PREFIX, BINDIR, LIBDIR, INCLUDEDIR, etc.
include $(dir $(lastword $(MAKEFILE_LIST)))inst_dirs.mk

# INST_UTILS_MK - definitions of installation/deinstallation macros
INST_UTILS_MK := $(dir $(lastword $(MAKEFILE_LIST)))inst_utils.mk

ifeq (,$(wildcard $(INST_UTILS_MK)))
$(error file $(INST_UTILS_MK) was not found, check value of INST_UTILS_MK variable)
endif

# include definitions of installation/deinstallation macros
include $(INST_UTILS_MK)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INST_UTILS_MK)
