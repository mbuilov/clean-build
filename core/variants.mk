#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for target variants, e.g.: EXE := my_exe A B C
# - defines that it's needed to build 'my_exe' in 3 variants: A, B, C

# get target name - first word, next words - variants (e.g. LIB := my_lib R P D S)
# note: target file name (generated by FORM_TRG) may be different, depending on target variant
# $1 - EXE,LIB,...
GET_TARGET_NAME = $(firstword $($1))

# list of supported by selected toolchain non-regular variants of given target type
# $1 - target type: LIB,EXE,DLL,...
# example:
#  EXE_SUPPORTED_VARIANTS := P
#  LIB_SUPPORTED_VARIANTS := P D
#  ...
SUPPORTED_VARIANTS = $($1_SUPPORTED_VARIANTS)

# filter-out unsupported variants of the target and return only supported ones (at least R)
# $1 - target type: EXE,LIB,...
# $2 - list of specified variants of the target (may be empty)
FILTER_VARIANTS_LIST = $(call FILTER_VARIANTS_LIST_F,$1,$2,SUPPORTED_VARIANTS)

# extended version of FILTER_VARIANTS_LIST
# $1 - target type: EXE,LIB,...
# $2 - list of specified variants of the target (may be empty)
# $3 - name of function which returns list of supported by selected toolchain non-regular variants
#  of given target type, function must be defined at time of $(eval)
# note: add R to filter pattern to not filter-out default variant R, if it was specified for the target
# note: if $(filter ...) gives no variants, return default variant R (regular), which is always supported
FILTER_VARIANTS_LIST_F = $(patsubst ,R,$(filter R $($3),$2))

# if target may be specified with variants, like LIB := my_lib R S
#  then get variants of the target supported by selected toolchain
# note: returns non-empty variants list, containing at least R (regular) variant
# $1 - target type: EXE,LIB,...
GET_VARIANTS = $(call GET_VARIANTS_F,$1,SUPPORTED_VARIANTS)

# extended version of GET_VARIANTS
# $1 - target type: EXE,LIB,...
# $2 - name of function which returns list of supported by selected toolchain non-regular variants
#  of given target type, function must be defined at time of $(eval)
GET_VARIANTS_F = $(call FILTER_VARIANTS_LIST_F,$1,$(wordlist 2,999999,$($1)),$2)

# determine target name suffix (in case if building multiple variants of the target, each variant must have unique file name)
# $1 - target type: EXE,LIB,...
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
# note: no suffix if building R (regular) variant or variant is not specified (then assume R variant)
# example:
#  LIB_VARIANT_SUFFIX = _$1
#  where: argument $1 - non-empty, not R
VARIANT_SUFFIX = $(if $(filter-out R,$2),$(call $1_VARIANT_SUFFIX,$2))

# get absolute path to target file - call appropriate .._FORM_TRG macro
# $1 - EXE,LIB,...
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
# example:
#  $1 - target name, e.g. my_exe, may be empty
#  $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
#  EXE_FORM_TRG = $(1:%=$(BIN_DIR)/%$(call VARIANT_SUFFIX,EXE,$2)$(EXE_SUFFIX))
#  LIB_FORM_TRG = $(1:%=$(LIB_DIR)/$(LIB_PREFIX)%$(call VARIANT_SUFFIX,LIB,$2)$(LIB_SUFFIX))
#  ...
#  note: use $(patsubst...) to return empty value if $1 is empty
FORM_TRG = $(call $1_FORM_TRG,$(GET_TARGET_NAME),$2)

# get filenames of all built variants of the target
# $1 - EXE,LIB,DLL,...
ALL_TARGETS = $(foreach v,$(GET_VARIANTS),$(call FORM_TRG,$1,$v))

# form name of target objects directory
# $1 - EXE,LIB,...
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
# add target-specific suffix (_EXE,_LIB,_DLL,...) to distinguish objects for the targets with equal names
FORM_OBJ_DIR = $(OBJ_DIR)/$(GET_TARGET_NAME)$(if $(filter-out R,$2),_$2)_$1

# construct full path to the target
# $1 - target type: EXE,LIB,...
# $2 - target name, e.g. my_exe
# $3 - target variant, e.g. S
# note: unsupported variant $3 will be substituted with variant R (regular)
MAKE_TRG_PATH = $(call $1_FORM_TRG,$2,$(call FILTER_VARIANTS_LIST,$1,$3))

# makefile parsing first phase variables
CB_FIRST_PHASE_VARS += GET_TARGET_NAME GET_VARIANTS GET_VARIANTS_F FORM_TRG ALL_TARGETS FORM_OBJ_DIR

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call SET_GLOBAL,CB_FIRST_PHASE_VARS,0)

# protect macros from modifications in target makefiles, allow tracing calls to them
$(call SET_GLOBAL,GET_TARGET_NAME SUPPORTED_VARIANTS FILTER_VARIANTS_LIST FILTER_VARIANTS_LIST_F \
  GET_VARIANTS GET_VARIANTS_F VARIANT_SUFFIX FORM_TRG ALL_TARGETS FORM_OBJ_DIR MAKE_TRG_PATH)
