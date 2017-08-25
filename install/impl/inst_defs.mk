remove this file

# installation definitions


# included by $(CLEAN_BUILD_DIR)/install/impl/_install_lib.mk

# INST_UTILS_MK - definitions of installation/deinstallation utility macros
INST_UTILS_MK := $(dir $(lastword $(MAKEFILE_LIST)))inst_utils.mk

ifeq (,$(wildcard $(INST_UTILS_MK)))
$(error file $(INST_UTILS_MK) was not found, check value of INST_UTILS_MK variable)
endif

# source definitions of standard installation directories, such as DESTDIR, PREFIX, BINDIR, LIBDIR, INCLUDEDIR, etc.
include $(dir $(lastword $(MAKEFILE_LIST)))inst_dirs.mk

# include definitions of installation/deinstallation macros
include $(INST_UTILS_MK)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INST_UTILS_MK)
