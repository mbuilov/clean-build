#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# common part of unix compiler toolchain (app-level), included by
# $(CLEAN_BUILD_DIR)/compilers/gcc.mk and $(CLEAN_BUILD_DIR)/compilers/suncc.mk

# RPATH - location where to search for external dependency libraries at runtime: /opt/lib or $ORIGIN/../lib
# note: RPATH may be overridden either in project configuration makefile or in command line
RPATH:=

# reset additional variables at beginning of target makefile
# MAP - linker map file (used mostly to list exported symbols)
C_PREPARE_UNIX_APP_VARS = MAP:=

# patch code executed at beginning of target makefile
$(call define_append,C_PREPARE_APP_VARS,$(newline)$$(C_PREPARE_UNIX_APP_VARS))

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_UNIX_APP_VARS)

# auxiliary defines for EXE
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(MAP))
# $t - EXE
# $v - R,P
# note: target-specific MAP variable may be inherited by the DLLs this EXE depends on,
#  so _must_ define DLL's own target-specific MAP variables, even with empty value, to override EXE's one
# note: last line must be empty
define EXE_AUX_TEMPLATEv
$1:MAP := $2
$1:$2

endef

# auxiliary defines for DLL
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(MAP))
# $t - DLL
# $v - R
# note: _must_ define DLL's own target-specific MAP variable, even with empty value,
#  to override possibly inherited target-specific MAP variable of EXE which depends on this DLL
# note: last line must be empty
define DLL_AUX_TEMPLATEv
$1:MODVER := $(MODVER)
$1:MAP := $2
$1:$2

endef

# $1 - $(call fixpath,$(MAP))
# $t - EXE or DLL
UNIX_MOD_AUX_APPt = $(foreach v,$(call GET_VARIANTS,$t),$(call $t_AUX_TEMPLATEv,$(call FORM_TRG,$t,$v),$1))

# auxiliary defines for EXE or DLL
# define target-specific variables: MAP, MODVER (only for DLL)
UNIX_MOD_AUX_APP = $(foreach t,EXE DLL,$(if $($t),$(call UNIX_MOD_AUX_APPt,$(call fixpath,$(MAP)))))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,RPATH C_PREPARE_UNIX_APP_VARS EXE_AUX_TEMPLATEv=t;v DLL_AUX_TEMPLATEv=t;v UNIX_MOD_AUX_APPt=t UNIX_MOD_AUX_APP)
