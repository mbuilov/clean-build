#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# common part of unix compiler toolchain (app-level), included by
# $(CLEAN_BUILD_DIR)/compilers/gcc.mk and $(CLEAN_BUILD_DIR)/compilers/suncc.mk

# global variable: INST_RPATH - location where to search for external dependency libraries at runtime: /opt/lib or $ORIGIN/../lib
# note: INST_RPATH may be overridden either in project configuration makefile or in command line
INST_RPATH:=

# reset additional variables at beginning of target makefile
# RPATH - runtime path for dynamic linker to search for shared libraries
# MAP   - linker map file (used mostly to list exported symbols)
define C_PREPARE_UNIX_APP_VARS
RPATH := $(INST_RPATH)
MAP:=
endef

# optimization
$(call try_make_simple,C_PREPARE_UNIX_APP_VARS,INST_RPATH)

# patch code executed at beginning of target makefile
$(call define_append,C_PREPARE_APP_VARS,$(newline)$$(C_PREPARE_UNIX_APP_VARS))

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_UNIX_APP_VARS)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INST_RPATH C_PREPARE_UNIX_APP_VARS)
