#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building application-level C/C++ libs, dlls and executables

# include generic rules for building C/C++ targets
ifeq (,$(filter-out undefined environment,$(origin CLEAN_BUILD_C_EVAL)))
include $(dir $(lastword $(MAKEFILE_LIST)))c_defs.mk
endif

# C_COMPILER - application-level compiler to use for the build (gcc, clang, msvc, etc.)
# note: C_COMPILER may be overridden by specifying either in in command line or in project configuration makefile
ifeq (LINUX,$(OS))
C_COMPILER := $(CLEAN_BUILD_DIR)/compilers/gcc.mk
else ifneq (WINDOWS,$(OS))
C_COMPILER:=
else ifneq (,$(filter /cygdrive/%,$(CURDIR)))
C_COMPILER := $(CLEAN_BUILD_DIR)/compilers/gcc.mk
else
C_COMPILER := $(CLEAN_BUILD_DIR)/compilers/msvc.mk
endif

# ensure C_COMPILER variable is non-recursive (simple)
override C_COMPILER := $(C_COMPILER)

ifndef C_COMPILER
$(error C_COMPILER - application-level C/C++ complier is not defined)
endif

ifeq (,$(wildcard $(C_COMPILER)))
$(error file $(C_COMPILER) was not found, check value of C_COMPILER variable)
endif

# add compiler-specific definitions
include $(C_COMPILER)

$(eval CLEAN_BUILD_APP_C_EVAL = $(value CLEAN_BUILD_C_EVAL))

# protect variables from modifications in target makefiles
# note: do not trace calls to C_COMPILER variable because it is used in ifdefs
$(call SET_GLOBAL,C_COMPILER,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,CLEAN_BUILD_APP_C_EVAL)
