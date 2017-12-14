#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# common part of unix compiler toolchain (app-level), included by:
#  $(CLEAN_BUILD_DIR)/compilers/gcc.mk
#  $(CLEAN_BUILD_DIR)/compilers/suncc.mk

# RPATH - location where to search for external dependency libraries at runtime, e.g.: /opt/lib or $ORIGIN/../lib
# note: RPATH may be overridden either in project configuration makefile or in command line
# note: to define target-specific RPATH variable - use C_REDEFINE macro from $(CLEAN_BUILD_DIR)/types/c/c_base.mk, e.g.:
#  EXE := my_exe
#  $(call C_REDEFINE,RPATH,$(RPATH) my_rpath)
RPATH:=

# reset additional user-modifiable variables at beginning of target makefile
# MAP - linker map file (used mostly to list exported symbols)
C_PREPARE_UNIX_APP_VARS = $(newline)MAP:=

# patch code executed at beginning of target makefile
$(call define_append,C_PREPARE_APP_VARS,$$(C_PREPARE_UNIX_APP_VARS))

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_UNIX_APP_VARS)

# auxiliary defines for EXE
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(MAP))
# $t - EXE
# $v - R,P
# note: target-specific MAP variable is inherited by the DLLs this EXE depends on,
#  so DLLs _must_ define their own target-specific MAP variable to override inherited EXE's one
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
# note: define DLL's own target-specific MAP variable to override inherited target-specific
#  MAP variable of EXE (or another DLL) which depends on this DLL
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

# MAP variable is used only when building EXE or DLL
ifdef CB_CHECKING
MAP_VARIABLE_CHECK = $(if $(MAP),$(if $(LIB),$(if $(EXE)$(DLL),,$(warning MAP variable is not used when building a LIB))))
$(call define_prepend,UNIX_MOD_AUX_APP,$$(MAP_VARIABLE_CHECK))
endif

# for DLL:         define target-specific variable MODVER
# for DLL and EXE: define target-specific variables RPATH and MAP
$(call define_prepend,C_DEFINE_APP_RULES,$$(eval $$(UNIX_MOD_AUX_APP)))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,RPATH C_PREPARE_UNIX_APP_VARS \
  EXE_AUX_TEMPLATEv=t;v DLL_AUX_TEMPLATEv=t;v UNIX_MOD_AUX_APPt=t UNIX_MOD_AUX_APP MAP_VARIABLE_CHECK)
