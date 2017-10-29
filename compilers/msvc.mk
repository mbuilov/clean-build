#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler toolchain (app-level), included by $(CLEAN_BUILD_DIR)/impl/_c.mk

# common msvc compiler definitions
ifeq (,$(filter-out undefined environment,$(origin INCLUDING_FILE_PATTERN_en)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_cmn.mk
endif

# add definitions of RC_COMPILER (needed by STD_RES_TEMPLATE) and MC_COMPILER
ifeq (,$(filter-out undefined environment,$(origin MC_COMPILER)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_tools.mk
endif

# add definitions of standard resource with module version information
ifeq (,$(filter-out undefined environment,$(origin STD_RES_TEMPLATE)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_stdres.mk
endif

# add support for exporting symbols (from a dll or exe)
ifeq (,$(filter-out undefined environment,$(origin EXPORTS_TEMPLATE)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_exp.mk
endif

# define variables:
# WINVER_DEFINES - version of Windows API to compile with, e.g.: WINVER=0x0501 _WIN32_WINNT=0x0501, may be empty
# SUBSYSTEM_VER  - minimum Windows version required to run built targets, e.g.: SUBSYSTEM_VER=5.01, may be empty
ifneq (,$(filter undefined environment,$(origin WINVER_DEFINES) $(origin SUBSYSTEM_VER)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_winver.mk
endif

# configure Visual C++ version, paths to compiler, linker and C/C++ libraries and headers:
# (variables prefixed with T - are for the tool mode)
# {,T}VC_VER    - version of Visual C++ we are using - see $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk 'MSVC++ versions' table
# {,T}VCCL      - path to cl.exe, must be in double-quotes if contains spaces
# {,T}VCLIB     - path to lib.exe, must be in double-quotes if contains spaces
# {,T}VCLINK    - path to link.exe, must be in double-quotes if contains spaces
# {,T}VCLIBPATH - paths to Visual C++ libraries, spaces must be replaced with ?
# {,T}VCINCLUDE - paths to Visual C++ headers, spaces must be replaced with ?
# note: assume target and tool compilers are of the same version and differ only by the architecture of produced binaries
ifeq (,$(filter-out undefined environment,$(origin GET_PROGRAM_FILES_DIRS)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_conf.mk
endif

# configure paths to system libraries/headers:
# (variables prefixed with T - are for the tool mode)
# {,T}UMLIBPATH - paths to user-mode libraries, spaces must be replaced with ?
# {,T}UMINCLUDE - paths to user-mode headers, spaces must be replaced with ?
ifeq (,$(filter-out undefined environment,$(origin ???)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_sdk.mk
endif

# default subsystem type for EXE and DLL: CONSOLE, WINDOWS, etc.
DEF_SUBSYSTEM_TYPE := CONSOLE

# reset additional variables
# EXE_EXPORTS    - non-empty if EXE exports symbols
# DLL_NO_EXPORTS - non-empty if DLL do not exports symbols (e.g. resource DLL)
# SUBSYSTEM_TYPE - environment for the executable: CONSOLE, WINDOWS, etc.
# note: first line must be empty
define C_PREPARE_MSVC_APP_VARS

EXE_EXPORTS:=
DLL_NO_EXPORTS:=
SUBSYSTEM_TYPE:=$(DEF_SUBSYSTEM_TYPE)
endef

# optimization
$(call try_make_simple,C_PREPARE_MSVC_APP_VARS,DEF_SUBSYSTEM_TYPE)

# patch code executed at beginning of target makefile
$(call define_append,C_PREPARE_APP_VARS,$$(C_PREPARE_MSVC_APP_VARS)$$(C_PREPARE_MSVC_STDRES_VARS)$$(C_PREPARE_MSVC_EXP_VARS))

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_MSVC_APP_VARS C_PREPARE_MSVC_STDRES_VARS C_PREPARE_MSVC_EXP_VARS)

# how to mark symbols exported from a DLL
# note: override definition in $(CLEAN_BUILD_DIR)/impl/_c.mk
DLL_EXPORTS_DEFINE := __declspec(dllexport)

# how to mark symbols imported from a DLL
# note: override definition in $(CLEAN_BUILD_DIR)/impl/_c.mk
DLL_IMPORTS_DEFINE := __declspec(dllimport)

# executable file suffix
# note: override defaults in $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_SUFFIX := .exe

# static library (archive) prefix/suffix
# note: override defaults in $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_PREFIX:=

# dynamically loaded library (shared object) prefix/suffix
# note: override defaults in $(CLEAN_BUILD_DIR)/impl/_c.mk
DLL_PREFIX:=
DLL_SUFFIX := .dll

# import library for dll prefix/suffix
# note: override defaults in $(CLEAN_BUILD_DIR)/impl/_c.mk
IMP_PREFIX:=
IMP_SUFFIX := .lib

# define:
# {,T}CFLAGS
# {,T}CXXFLAGS
# {,T}ARFLAGS
# {,T}LDFLAGS
# {,T}MP_BUILD
# {,T}FORCE_SYNC_PDB
# {,T}MANIFEST_EMBED_OPTION
# {,T}EMBED_EXE_MANIFEST
# {,T}EMBED_DLL_MANIFEST
# {,T}CMN_CFLAGS
# {,T}APPINCLUDE
# {,T}APPLIBPATH
# {,T}DEF_CFLAGS
# {,T}DEF_CXXFLAGS
# {,T}LINKER_STRIP_STRINGS
# {,T}WRAP_LINKER
# {,T}INCLUDING_FILE_PATTERN
# {,T}UDEPS_INCLUDE_FILTER
# {,T}WRAP_CCN
# {,T}WRAP_CCD
# note: TMD was reset in $(CLEAN_BUILD_DIR)/core/_defs.mk and must be empty after we temporary redefine it below
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_cflags.mk
TMD:=T
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_cflags.mk
TMD:=

# supported non-regular target variants:
# (R - dynamically linked multi-threaded libc - default variant)
# S - statically linked multi-threaded libc
# RU - same as R, but with unicode support
# SU - same as S, but with unicode support
WIN_SUPPORTED_VARIANTS := S RU SU

# target name suffix for each non-regular variant of the target
# $1 - one of $(WIN_SUPPORTED_VARIANTS)
WIN_VARIANT_SUFFIX = $(if $(findstring \
  RU,$1),_u,$(if $(findstring \
  SU,$1),_su,_s))

# C/C++ compiler options for each target variant
# $1 - one of R,$(WIN_SUPPORTED_VARIANTS)
WIN_VARIANT_CFLAGS = $(if $(filter S%,$1),/MT,/MD)$(if $(DEBUG),d)$(if $(filter %U,$1), /DUNICODE /D_UNICODE)

# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_SUPPORTED_VARIANTS := $(WIN_SUPPORTED_VARIANTS)
LIB_SUPPORTED_VARIANTS := $(WIN_SUPPORTED_VARIANTS)
DLL_SUPPORTED_VARIANTS := $(WIN_SUPPORTED_VARIANTS)

# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_SUFFIX = $(WIN_VARIANT_SUFFIX)
LIB_VARIANT_SUFFIX = $(WIN_VARIANT_SUFFIX)
DLL_VARIANT_SUFFIX = $(WIN_VARIANT_SUFFIX)

# C/C++ compiler options for each target variant
# $1 - one of R,$(WIN_SUPPORTED_VARIANTS)
# $(TMD) - T in tool mode, empty otherwise
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_CFLAGS   = $(WIN_VARIANT_CFLAGS) $($(TMD)CFLAGS)
EXE_CXXFLAGS = $(WIN_VARIANT_CFLAGS) $($(TMD)CXXFLAGS)
LIB_CFLAGS   = $(WIN_VARIANT_CFLAGS) $($(TMD)CFLAGS)
LIB_CXXFLAGS = $(WIN_VARIANT_CFLAGS) $($(TMD)CXXFLAGS)
DLL_CFLAGS   = $(WIN_VARIANT_CFLAGS) $($(TMD)CFLAGS)
DLL_CXXFLAGS = $(WIN_VARIANT_CFLAGS) $($(TMD)CXXFLAGS)

# determine which variant of static library to link with EXE or DLL
# $1 - target type: EXE,DLL
# $2 - variant of target EXE or DLL: R,S,RU or SU, if empty, then assume R
# $3 - dependency name, e.g. mylib or mylib/flag1/flag2/...
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
# note: use the same variant of dependent static library as target EXE or DLL (for example for S-EXE use S-LIB)
# note: unicode variants of the target EXE or DLL may link with two kinds of libraries:
#  1) with unicode support - normally built in x2 variants, e.g. mylib.lib and mylib_u.lib or mylib_s.lib and mylib_su.lib
#  2) without unicode support - normally built in x1 variant, e.g. mylib.lib or mylib_s.lib
#  so, for unicode (RU or SU) variant of target EXE or DLL, if dependent library is not specified with 'uni' flag
#  - dependent library do not have unicode variant, so convert needed variant of library to non-unicode one: RU->R or SU->S
LIB_DEP_MAP = $(if $(filter uni,$(subst /, ,$3)),$2,$(2:U=))

# determine which variant of dynamic library to link with EXE or DLL
# the same logic as for the static library
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
DLL_DEP_MAP = $(LIB_DEP_MAP)

# used to define target-specific SUBSYSTEM variable
# makefile-modifiable variable: SUBSYSTEM_TYPE
# note: SUBSYSTEM_VER may be empty
# note: do not specify subsystem version when building tools
TRG_SUBSYSTEM = $(SUBSYSTEM_TYPE)$(if $(TMD),,$(addprefix $(comma),$(SUBSYSTEM_VER)))

# subsystem for EXE or DLL
# target-specific: SUBSYSTEM
MK_SUBSYSTEM_OPTION = /SUBSYSTEM:$(SUBSYSTEM)

# common link.exe flags for linking executables and dynamic libraries
CMN_LDFLAGS := /INCREMENTAL:NO

# default link.exe flags for linking an EXE
DEF_EXE_LDFLAGS := $(CMN_LDFLAGS)

# default link.exe flags for linking a DLL
DEF_DLL_LDFLAGS := /DLL $(CMN_LDFLAGS)

# common linker options for EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects
# $3 - target type: EXE or DLL
# $4 - non-empty variant: R,S,RU,SU
# target-specific: IMP, DEF, LIBS, DLLS, LIB_DIR, TMD
CMN_LIBS = /nologo /OUT:$(call ospath,$1 $2 $(filter %.res,$^)) $(MK_VERSION_OPTION) $(MK_SUBSYSTEM_OPTION) $($(TMD)MANIFEST_EMBED_OPTION) \
  $(addprefix /IMPLIB:,$(call ospath,$(IMP))) $(addprefix /DEF:,$(call ospath,$(DEF))) $(if $(firstword $(LIBS)$(DLLS)),/LIBPATH:$(call \
  ospath,$(LIB_DIR)) $(call DEP_LIBS,$3,$4) $(call DEP_IMPS,$3,$4)) $(call qpath,$($(TMD)APPLIBPATH),/LIBPATH:)

# linkers for each variant of EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects for linking the target
# $3 - target type: EXE or DLL
# $4 - non-empty variant: R,S,RU,SU
# target-specific: TMD, VLDFLAGS
# note: used by EXE_TEMPLATE and DLL_TEMPLATE from $(CLEAN_BUILD_DIR)/impl/_c.mk
# note: link.exe will not delete generated manifest file if failed to build target exe/dll, for example because of invalid DEF file
# note: if EXE do not exports symbols (as usual), do not set in target makefile EXE_EXPORTS (empty by default)
# note: if DLL do not exports symbols (unusual), set in target makefile DLL_NO_EXPORTS to non-empty value
EXE_LD1 = $(call SUP,$(TMD)EXE,$1)$(call \
  $(TMD)WRAP_LINKER,$($(TMD)VCLINK) $(CMN_LIBS) $(DEF_EXE_LDFLAGS) $(VLDFLAGS))$(CHECK_EXP_CREATED)$($(TMD)EMBED_EXE_MANIFEST)
DLL_LD1 = $(call SUP,$(TMD)DLL,$1)$(call \
  $(TMD)WRAP_LINKER,$($(TMD)VCLINK) $(CMN_LIBS) $(DEF_DLL_LDFLAGS) $(VLDFLAGS))$(CHECK_EXP_CREATED)$($(TMD)EMBED_DLL_MANIFEST)

# form path to the import library (if target exports symbols)
# $t - EXE or DLL
# $v - variant: R,S,RU,SU
EXE_DLL_FORM_IMPORT_LIB = $(LIB_DIR)/$(IMP_PREFIX)$(call GET_TARGET_NAME,$t)$(call LIB_VARIANT_SUFFIX,$v)$(IMP_SUFFIX)

ifndef TOCLEAN

# for DLL and EXE, define target-specific variables: SUBSYSTEM, MODVER, IMP, DEF
# $1 - $(call FORM_TRG,$t,$v)
# $2 - path to import library if target exports symbols, <empty> - otherwise
# $t - EXE or DLL
# $v - variant: R,S,RU,SU
define EXE_DLL_AUX_TEMPLATE
$1:SUBSYSTEM := $(TRG_SUBSYSTEM)
$1:MODVER    := $(MODVER)
$(EXPORTS_TEMPLATE)
endef

# $t - EXE or DLL
# $v - variant: R,S,RU,SU
EXE_AUX_TEMPLATE = $(call EXE_DLL_AUX_TEMPLATE,$(call FORM_TRG,EXE,$v),$(if $(EXE_EXPORTS),$(EXE_DLL_FORM_IMPORT_LIB)))
DLL_AUX_TEMPLATE = $(call EXE_DLL_AUX_TEMPLATE,$(call FORM_TRG,DLL,$v),$(if $(DLL_NO_EXPORTS),,$(EXE_DLL_FORM_IMPORT_LIB)))

# for DLL and EXE, define target-specific variables: SUBSYSTEM, MODVER, IMP, DEF
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval \
  $$(foreach t,EXE DLL,$$(if $$($$t),$$(foreach v,$$(call GET_VARIANTS,$$t),$$($$t_AUX_TEMPLATE))))))

else # clean

# $t - EXE or DLL
# $v - variant: R,S,RU,SU
EXE_EXP_TOCLEAN = $(if $(EXE_EXPORTS),$(call EXPORTS_TO_CLEANUP,$(EXE_DLL_FORM_IMPORT_LIB)))
DLL_EXP_TOCLEAN = $(if $(DLL_NO_EXPORTS),,$(call EXPORTS_TO_CLEANUP,$(EXE_DLL_FORM_IMPORT_LIB)))

# for DLL and EXE, cleanup import library and .exp file
$(call define_prepend,DEFINE_C_APP_EVAL,$$(call \
  TOCLEAN,$$(foreach t,EXE DLL,$$(if $$($$t),$$(foreach v,$$(call GET_VARIANTS,$$t),$$($$t_EXP_TOCLEAN))))))

endif # clean

# DEF variable is used only when building EXE or DLL
ifdef MCHECK
LIB_DEF_VARIABLE_CHECK = $(if $(DEF),$(if $(LIB),$(if $(EXE)$(DLL),,$(warning DEF variable is not used when building a LIB))))
$(call define_prepend,DEFINE_C_APP_EVAL,$$(LIB_DEF_VARIABLE_CHECK))
endif

# linker for each variant of LIB
# $1 - path to target LIB
# $2 - objects for linking the target
# $3 - target type: LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: TMD
# note: used by LIB_TEMPLATE from $(CLEAN_BUILD_DIR)/impl/_c.mk
# note: lib.exe does not support linking resources (.res - files) to a static library
LIB_LD1 = $(call SUP,$(TMD)LIB,$1)$($(TMD)VCLIB) /nologo /OUT:$(call ospath,$1 $2) $($(TMD)ARFLAGS)

# check that LIB do not includes resources (.res-files)
ifdef MCHECK
$(eval LIB_LD1 = $$(if $$(filter %.res,$$^),$$(warning \
  $$1: static library cannot contain resources: $$(filter %.res,$$^)))$(value LIB_LD1))
endif

# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifdef VERBOSE
$(eval LIB_LD1 = $(value LIB_LD1) >&2)
endif

# common options for application-level C/C++ compilers
# $1 - outdir/ or obj file
# $2 - sources
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: VDEFINES, VINCLUDE
CMN_PARAMS = /nologo /c /Fo$(ospath) /Fd$(call ospath,$(dir $1) $2) $(VDEFINES) $(VINCLUDE)

# parameters of application-level C and C++ compilers
# $1 - outdir/ or obj file
# $2 - sources
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: TMD, VCFLAGS, VCXXFLAGS
CC_PARAMS  = $(CMN_PARAMS) $($(TMD)DEF_CFLAGS) $(VCFLAGS)
CXX_PARAMS = $(CMN_PARAMS) $($(TMD)DEF_CXXFLAGS) $(VCXXFLAGS)

# C/C++ compilers for each variant of EXE,DLL,LIB
# $1 - target object file
# $2 - source
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: TMD
# note: used by OBJ_RULES_BODY macro from $(CLEAN_BUILD_DIR)/impl/c_base.mk
# note: auto-generate dependencies
OBJ_CC  = $(call SUP,$(TMD)CC,$2)$(call $(TMD)WRAP_CCD,$($(TMD)VCCL) $(CC_PARAMS),$2,$1)
OBJ_CXX = $(call SUP,$(TMD)CXX,$2)$(call $(TMD)WRAP_CCD,$($(TMD)VCCL) $(CXX_PARAMS),$2,$1)

ifndef NO_PCH

# C/C++ compilers for compiling without precompiled header
$(eval OBJ_NCC  = $(value OBJ_CC))
$(eval OBJ_NCXX = $(value OBJ_CXX))

# C/C++ compilers for compiling using precompiled header
# $1 - target object file
# $2 - source
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: TMD
# note: auto-generate dependencies
OBJ_PCC  = $(call SUP,$(TMD)PCC,$2)$(call $(TMD)WRAP_CCD,$($(TMD)VCCL) $(call MSVC_USE_PCH,$(dir $1),c) $(CC_PARAMS),$2,$1)
OBJ_PCXX = $(call SUP,$(TMD)PCXX,$2)$(call $(TMD)WRAP_CCD,$($(TMD)VCCL) $(call MSVC_USE_PCH,$(dir $1),cpp) $(CXX_PARAMS),$2,$1)

# override C++ and C compilers to support compiling with precompiled header
# $1 - target object file
# $2 - source
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: CC_WITH_PCH, CXX_WITH_PCH
OBJ_CC  = $(if $(filter $2,$(CC_WITH_PCH)),$(OBJ_PCC),$(OBJ_NCC))
OBJ_CXX = $(if $(filter $2,$(CXX_WITH_PCH)),$(OBJ_PCXX),$(OBJ_NCXX))

endif # !NO_PCH

# override templates defined in $(CLEAN_BUILD_DIR)/impl/_c.mk:
#  EXE_TEMPLATE, DLL_TEMPLATE and LIB_TEMPLATE will not call OBJ_RULES for C/C++ sources if $(TMD)MP_BUILD is defined,
#  instead, we will build the target module directly from sources, ignoring object files that are generated as a side-effect
# note: $(C_BASE_TEMPLATE_MP) defines target-specific variables: SRC, SDEPS, OBJ_DIR
# note: here TMD - makefile variable defined by DEF_HEAD_CODE template from $(CLEAN_BUILD_DIR)/core/_defs.mk
# note: {,T}MP_BUILD - global constant variable
C_BASE_TEMPLATE_OR_MP = $(if $($(TMD)MP_BUILD),$(C_BASE_TEMPLATE_MP),$(C_BASE_TEMPLATE))
$(eval define EXE_TEMPLATE$(newline)$(subst $$(C_BASE_TEMPLATE),$$(C_BASE_TEMPLATE_OR_MP),$(value EXE_TEMPLATE))$(newline)endef)
$(eval define DLL_TEMPLATE$(newline)$(subst $$(C_BASE_TEMPLATE),$$(C_BASE_TEMPLATE_OR_MP),$(value DLL_TEMPLATE))$(newline)endef)
$(eval define LIB_TEMPLATE$(newline)$(subst $$(C_BASE_TEMPLATE),$$(C_BASE_TEMPLATE_OR_MP),$(value LIB_TEMPLATE))$(newline)endef)

# compile & link in one rule
# $1 - path to target EXE,DLL,LIB
# $2 - objects for linking the target (may be empty, if no .asm sources were assembled and pch is not used)
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: OBJ_DIR, SRC (defined by C_BASE_TEMPLATE_MP)
EXE_LD_MP = $(call MULTISOURCE_CL,$3,$4)$(call EXE_LD1,$1,$(patsubst %,$(OBJ_DIR)/%$(OBJ_SUFFIX),$(basename $(notdir $(SRC)))) $2,$3,$4)
DLL_LD_MP = $(call MULTISOURCE_CL,$3,$4)$(call DLL_LD1,$1,$(patsubst %,$(OBJ_DIR)/%$(OBJ_SUFFIX),$(basename $(notdir $(SRC)))) $2,$3,$4)
LIB_LD_MP = $(call MULTISOURCE_CL,$3,$4)$(call LIB_LD1,$1,$(patsubst %,$(OBJ_DIR)/%$(OBJ_SUFFIX),$(basename $(notdir $(SRC)))) $2,$3,$4)

# define linkers
# $1 - path to target EXE,DLL,LIB
# $2 - objects for linking the target (may be empty, if no .asm sources were assembled and pch is not used)
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: TMD
# note: {,T}MP_BUILD - global constant variable
# note: used by redefined above EXE_TEMPLATE, DLL_TEMPLATE and LIB_TEMPLATE
EXE_LD = $(if $($(TMD)MP_BUILD),$(EXE_LD_MP),$(EXE_LD1))
DLL_LD = $(if $($(TMD)MP_BUILD),$(DLL_LD_MP),$(DLL_LD1))
LIB_LD = $(if $($(TMD)MP_BUILD),$(LIB_LD_MP),$(LIB_LD1))

# parameters of multi-source application-level C and C++ compilers
# $1 - sources
# $2 - target type: EXE,DLL,LIB
# $3 - non-empty variant: R,S,RU,SU
# target-specific: TMD, OBJ_DIR (defined by C_BASE_TEMPLATE_MP)
# note: {,T}MP_BUILD - global constant variable
CC_PARAMS_MP  = $($(TMD)MP_BUILD) $(call CC_PARAMS,$(OBJ_DIR)/,$1,$2,$3)
CXX_PARAMS_MP = $($(TMD)MP_BUILD) $(call CXX_PARAMS,$(OBJ_DIR)/,$1,$2,$3)

# C/C++ multi-source compilers for each variant of EXE,DLL,LIB
# $1 - sources (non-empty list)
# $2 - target type: EXE,DLL,LIB
# $3 - non-empty variant: R,S,RU,SU
# target-specific: TMD
# note: called by CMN_MCL macro from $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk
# note: do not auto-generate dependencies (because /showIncludes option conflicts with /MP)
OBJ_MCC  = $(call SUP,$(TMD)CC,$1)$(call $(TMD)WRAP_CCN,$($(TMD)VCCL) $(CC_PARAMS_MP),$1)
OBJ_MCXX = $(call SUP,$(TMD)CXX,$1)$(call $(TMD)WRAP_CCN,$($(TMD)VCCL) $(CXX_PARAMS_MP),$1)

ifdef NO_PCH

# compile multiple sources at once
# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU,...
MULTISOURCE_CL = $(call CMN_MCL,$1,$2,OBJ_MCC,OBJ_MCXX)

else # !NO_PCH

# C/C++ multi-source compilers for compiling using precompiled header
# $1 - sources (non-empty list)
# $2 - target type: EXE,DLL,LIB
# $3 - non-empty variant: R,S,RU,SU
# target-specific: TMD, OBJ_DIR (defined by C_BASE_TEMPLATE_MP)
# note: do not auto-generate dependencies
OBJ_PMCC  = $(call SUP,$(TMD)PCC,$1)$(call $(TMD)WRAP_CCN,$($(TMD)VCCL) $(call MSVC_USE_PCH,$(OBJ_DIR)/,c) $(CC_PARAMS_MP),$1)
OBJ_PMCXX = $(call SUP,$(TMD)PCXX,$1)$(call $(TMD)WRAP_CCN,$($(TMD)VCCL) $(call MSVC_USE_PCH,$(OBJ_DIR)/,cpp) $(CXX_PARAMS_MP),$1)

# compile multiple sources at once
# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU,...
MULTISOURCE_CL = $(call CMN_PMCL,$1,$2,OBJ_MCC,OBJ_MCXX,OBJ_PMCC,OBJ_PMCXX)

endif # !NO_PCH

# add support for precompiled headers
ifndef NO_PCH

ifeq (,$(filter-out undefined environment,$(origin MSVC_USE_PCH)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_pch.mk
endif

# compilers of C/C++ precompiled header
# $1 - pch object (e.g. C:/build/obj/xxx_pch_c.obj or C:/build/obj/xxx_pch_cpp.obj)
# $2 - pch header (e.g. C:/project/include/xxx.h)
# $3 - pch        (e.g. C:/build/obj/xxx_c.pch or C:/build/obj/xxx_cpp.pch)
# $4 - target type: EXE,DLL,LIB
# $5 - non-empty variant: R,S,RU,SU
# target-specific: TMD
# note: precompiled header xxx_c.pch or xxx_cpp.pch will be created as a side-effect of this compilation
# note: used by MSVC_PCH_RULE_TEMPL_BASE macro from $(CLEAN_BUILD_DIR)/compilers/msvc_pch.mk
PCH_CC  = $(call SUP,$(TMD)PCHCC,$2)$(call $(TMD)WRAP_CCD,$($(TMD)VCCL) $(MSVC_CREATE_PCH) /TC $(call CC_PARAMS,$1,$2,$4,$5),$2,$1)
PCH_CXX = $(call SUP,$(TMD)PCHCXX,$2)$(call $(TMD)WRAP_CCD,$($(TMD)VCCL) $(MSVC_CREATE_PCH) /TP $(call CXX_PARAMS,$1,$2,$4,$5),$2,$1)

# reset additional variables
$(call define_append,C_PREPARE_APP_VARS,$(C_PREPARE_PCH_VARS))

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_PCH_VARS)

# choose pch template for application-level targets (EXE,DLL,LIB)
# note: here TMD - makefile variable defined by DEF_HEAD_CODE template from $(CLEAN_BUILD_DIR)/core/_defs.mk
MSVC_APP_PCH_TEMPLATE = $(if $($(TMD)MP_BUILD),$(MSVC_PCH_TEMPLATE_MPt),$(MSVC_PCH_TEMPLATEt))

# for all application-level targets: add support for precompiled headers
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,$(C_APP_TARGETS),$$(if $$($$t),$$(MSVC_APP_PCH_TEMPLATE)))))

endif # !NO_PCH

# add standard version info resource to the target EXE or DLL
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,EXE DLL,$$(call STD_RES_TEMPLATE,$$t))))

ifdef TOCLEAN

# cleanup generated vc*0.pdb (if building with /Zi or /ZI option)
# $t - EXE,DLL,LIB
# $v - R,S,RU,SU
APP_PDB_CLEANUP = $(call FORM_OBJ_DIR,$t,$v)/vc*0.pdb

# cleanup generated .pdb (for EXE or DLL, if /DEBUG is passed to link.exe)
# $t - EXE,DLL,LIB
# $v - R,S,RU,SU
EXE_PDB_CLEANUP = $(APP_PDB_CLEANUP) $(basename $(call FORM_TRG,EXE,$v)).pdb
DLL_PDB_CLEANUP = $(APP_PDB_CLEANUP) $(basename $(call FORM_TRG,DLL,$v)).pdb
LIB_PDB_CLEANUP = $(APP_PDB_CLEANUP)

$(call define_prepend,DEFINE_C_APP_EVAL,$$(call \
  TOCLEAN,$$(foreach t,$(C_APP_TARGETS),$$(if $$($$t),$$(foreach v,$$(call GET_VARIANTS,$$t),$$($$t_PDB_CLEANUP))))))

endif # TOCLEAN

# protect variables from modifications in target makefiles
# note: do not trace calls to these variables because they are used in ifdefs
$(call SET_GLOBAL,MP_BUILD FORCE_SYNC_PDB,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,DEF_SUBSYSTEM_TYPE C_PREPARE_MSVC_APP_VARS WIN_SUPPORTED_VARIANTS WIN_VARIANT_SUFFIX WIN_VARIANT_CFLAGS \
  TRG_SUBSYSTEM MK_SUBSYSTEM_OPTION CMN_LDFLAGS DEF_EXE_LDFLAGS DEF_DLL_LDFLAGS CMN_LIBS EXE_LD1 DLL_LD1 EXE_DLL_FORM_IMPORT_LIB=t;v \
  EXE_DLL_AUX_TEMPLATE EXE_AUX_TEMPLATE=t;v DLL_AUX_TEMPLATE=t;v EXE_EXP_TOCLEAN=t;v DLL_EXP_TOCLEAN=t;v \
  LIB_DEF_VARIABLE_CHECK=DEF;LIB;EXE;DLL LIB_LD1 CMN_PARAMS CC_PARAMS CXX_PARAMS OBJ_CC OBJ_CXX OBJ_NCC OBJ_NCXX OBJ_PCC OBJ_PCXX \
  C_BASE_TEMPLATE_OR_MP EXE_LD_MP DLL_LD_MP LIB_LD_MP EXE_LD DLL_LD LIB_LD CC_PARAMS_MP CXX_PARAMS_MP OBJ_MCC OBJ_MCXX MULTISOURCE_CL \
  OBJ_PMCC OBJ_PMCXX PCH_CC PCH_CXX MSVC_APP_PCH_TEMPLATE APP_PDB_CLEANUP=t;v EXE_PDB_CLEANUP=t;v DLL_PDB_CLEANUP=t;v LIB_PDB_CLEANUP=t;v)
