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
# VC_VER        - version of Visual C++ we are using - see $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk 'MSVC++ versions' table
# {,T}VCCL      - path to cl.exe, must be in double-quotes if contains spaces
# {,T}VCLIB     - path to lib.exe, must be in double-quotes if contains spaces
# {,T}VCLINK    - path to link.exe, must be in double-quotes if contains spaces
# {,T}VCLIBPATH - paths to Visual C++ libraries, spaces must be replaced with ?
# VCINCLUDE     - paths to Visual C++ headers, spaces must be replaced with ?
ifeq (,$(filter-out undefined environment,$(origin VC_TOOL_PREFIX_2017)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_conf.mk
endif

# configure paths to system libraries/headers:
# (variables prefixed with T - are for the tool mode)
# {,T}UMLIBPATH - paths to user-mode libraries, spaces must be replaced with ?
# UMINCLUDE     - paths to user-mode headers, spaces must be replaced with ?
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

# default values of user-defined C compiler flags
# note: may be taken from the environment in project configuration makefile
# note: used by EXE_CFLAGS, LIB_CFLAGS, DLL_CFLAGS (from $(CLEAN_BUILD_DIR)/impl/_c.mk)
# /W3 - warning level 3
CFLAGS := /W3

# determine if may build multiple sources at once
MP_BUILD:=
ifndef SEQ_BUILD
ifeq (,$(call is_less_float,$(VC_VER),$(VS2008)))
# >= Visual Studio 2008
# /MP - compile all sources of a module at once
MP_BUILD := /MP
endif
endif

# When using the /Zi option, the debug info of all compiled sources is stored in a single .pdb,
#  but this can lead to contentions accessing that .pdb during parallel compilation.
# To cope this problem, the /FS option was introduced in Visual Studio 2013.
ifeq (,$(call is_less_float,$(VC_VER),$(VS2013)))
# >= Visual Studio 2013
FORCE_SYNC_PDB := /FS
else
FORCE_SYNC_PDB:=
endif

ifdef DEBUG

# set debug info format
ifdef MP_BUILD
# compiling sources of a module with /MP option:
#  - groups of sources of a module are compiled sequentially, one group after each other
#  - sources in a group are compiled in parallel by compiler threads, via single compiler invocation.
# note: /MP option implies /FS option, if it's supported
# /Zi option - store debug info (in new format) in single .pdb, assume compiler internally will serialize access to the .pdb
CFLAGS += /Zi
else ifndef FORCE_SYNC_PDB
# /Z7 option - store debug info (in old format) in each .obj to avoid contention accessing .pdb during parallel compilation
CFLAGS += /Z7
else
# /Zi option - store debug info (in new format) in single .pdb, compiler will serialize access to the .pdb via mspdbsrv.exe
CFLAGS += $(FORCE_SYNC_PDB) /Zi
endif

# /Od - disable optimizations
CFLAGS += /Od

ifeq (,$(call is_less_float,$(VC_VER),$(VS2002)))
# >= Visual Studio 2002
# /RTCs - enables stack frame run-time error checking
# /RTCu - reports when a variable is used without having been initialized
# /GS   - buffer security check
CFLAGS += /RTCsu /GS
else
# Visual Studio 6.0
# /GZ - catch release-build errors in debug build
CFLAGS += /GZ
endif

ifeq (,$(call is_less_float,$(VC_VER),$(VS2012)))
# >= Visual Studio 2012
# /sdl - additional security checks
CFLAGS += /sdl
endif

else # !DEBUG

# /Ox - maximum optimization
# /GF - pool strings and place them in read-only memory
# /Gy - enable function level linking
CFLAGS += /Ox /GF /Gy

ifeq (,$(call is_less_float,$(VC_VER),$(VS2002)))
# >= Visual Studio 2002
# /GS - buffer security check
# /GL - whole program optimization, linker must be invoked with /LTCG
CFLAGS += /GS- /GL
endif

ifeq (,$(call is_less_float,$(VC_VER),$(VS2013)))
# >= Visual Studio 2013
# /Zc:inline - remove unreferenced internal functions from objs
# /Gw         - package global data in individual comdat sections
# note: /Zc:inline is ignored if /GL is specified
CFLAGS += /Zc:inline /Gw
endif

endif # !DEBUG

ifeq (,$(call is_less_float,$(VC_VER),$(VS2005)))
# >= Visual Studio 2005
# /errorReport - report internal compiler errors
CFLAGS += /errorReport:none
endif

# default values of user-defined C++ compiler flags
# /Gm - enable minimal rebuild
# note: may be taken from the environment in project configuration makefile
# note: used by EXE_CXXFLAGS, LIB_CXXFLAGS, DLL_CXXFLAGS (from $(CLEAN_BUILD_DIR)/impl/_c.mk)
CXXFLAGS := $(CFLAGS) /Gm-

# /GR - enable run-time type information
CFLAGS += /GR-

ifdef DEBUG
ifeq (,$(call is_less_float,$(VC_VER),$(VS2002)))
# >= Visual Studio 2002
# /RTCc - reports when a value is assigned to a smaller data type and results in a data loss
# note: for C++ code, it may be needed to define /D_ALLOW_RTCc_IN_STL (starting with Visual Studio 2015)
CFLAGS += /RTCc
endif
endif

# lib.exe flags for linking a LIB
# /LTCG - link-time code generation
# note: may be taken from the environment in project configuration makefile
# note: used by LIB_LD
ARFLAGS := $(if $(DEBUG),,$(if $(filter /GL,$(CFLAGS)),/LTCG))

# default values of user-defined link.exe flags for linking executables and shared libraries
# note: may be taken from the environment in project configuration makefile
# note: used by EXE_LDFLAGS, LIB_LDFLAGS, DLL_LDFLAGS from $(CLEAN_BUILD_DIR)/impl/_c.mk
# /DEBUG   - generate debug info (in separate .pdb)
# /RELEASE - set the checksum in PE-header
# /LTCG    - link-time code generation
LDFLAGS := $(if $(DEBUG),/DEBUG,/RELEASE$(if $(filter /GL,$(CFLAGS)), /LTCG))

# flags for the tool mode
TCFLAGS   := $(CFLAGS)
TCXXFLAGS := $(CXXFLAGS)
TARFLAGS  := $(ARFLAGS)
TLDFLAGS  := $(LDFLAGS)

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
#  1) with unicode support - normally built in 2 variants, e.g. mylib.lib and mylib_u.lib or mylib_s.lib and mylib_su.lib
#  2) without unicode support - normally built in 1 variant, e.g. mylib.lib or mylib_s.lib
#  so, for unicode (RU or SU) variant of target EXE or DLL, if dependent library is not specified with 'uni' flag
#  - dependent library do not have unicode variant, so convert needed variant of library to non-unicode one: RU->R or SU->S
LIB_DEP_MAP = $(if $(filter uni,$(subst /, ,$3)),$2,$(2:U=))

# determine which variant of dynamic library to link with EXE or DLL
# the same logic as for the static library
DLL_DEP_MAP = $(LIB_DEP_MAP)

# define target-specific SUBSYSTEM variable
# makefile-modifiable variable: SUBSYSTEM_TYPE
# note: SUBSYSTEM_VER may be empty
# note: do not specify subsystem version when building tools
TRG_SUBSYSTEM = $(SUBSYSTEM_TYPE)$(if $(TMD),,$(addprefix $(comma),$(SUBSYSTEM_VER)))

# subsystem for EXE or DLL
# target-specific: SUBSYSTEM
SUBSYSTEM_OPTION = /SUBSYSTEM:$(SUBSYSTEM)

# how to embed manifest into EXE or DLL
ifeq (,$(call is_less_float,$(VC_VER),$(VS2012)))
# >= Visual Studio 2012, linker may call mt.exe internally
MANIFEST_EMBED_OPTION := /MANIFEST:EMBED
else
MANIFEST_EMBED_OPTION:=
endif

# common link.exe flags for linking executables and dynamic libraries
CMN_LDFLAGS := /INCREMENTAL:NO

# default link.exe flags for linking an EXE
DEF_EXE_LDFLAGS := $(CMN_LDFLAGS)

# default link.exe flags for linking a DLL
DEF_DLL_LDFLAGS := /DLL $(CMN_LDFLAGS)

# paths to application-level system libraries
APPLIBPATH := $(VCLIBPATH) $(UMLIBPATH)
TAPPLIBPATH := $(TVCLIBPATH) $(TUMLIBPATH)

# common linker options for EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects
# $3 - target type: EXE or DLL
# $4 - non-empty variant: R,S,RU,SU
# target-specific: IMP, DEF, LIBS, DLLS, LIB_DIR, TMD
CMN_LIBS = /nologo /OUT:$(call ospath,$1 $2 $(filter %.res,$^)) $(VERSION_OPTION) $(SUBSYSTEM_OPTION) $(MANIFEST_EMBED_OPTION) \
  $(addprefix /IMPLIB:,$(call ospath,$(IMP))) $(addprefix /DEF:,$(call ospath,$(DEF))) $(if $(firstword $(LIBS)$(DLLS)),/LIBPATH:$(call \
  ospath,$(LIB_DIR)) $(call DEP_LIBS,$3,$4) $(call DEP_IMPS,$3,$4)) $(call qpath,$($(TMD)APPLIBPATH),/LIBPATH:)

# regular expression string for findstr.exe to match diagnostic linker message to strip-off
# default value, may be overridden either in project configuration makefile or in command line
LINKER_STRIP_STRINGS := $(LINKER_STRIP_STRINGS_en)

# define WRAP_LINKER - link.exe wrapper
$(call MSVC_DEFINE_LINKER_WRAPPER,WRAP_LINKER,$(LINKER_STRIP_STRINGS))

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
EXE_LD = $(call SUP,$(TMD)EXE,$1)$(call WRAP_LINKER,$($(TMD)VCLINK) $(CMN_LIBS) $(DEF_EXE_LDFLAGS) $(VLDFLAGS))$(CHECK_EXP_CREATED)
DLL_LD = $(call SUP,$(TMD)DLL,$1)$(call WRAP_LINKER,$($(TMD)VCLINK) $(CMN_LIBS) $(DEF_DLL_LDFLAGS) $(VLDFLAGS))$(CHECK_EXP_CREATED)

# manifest embedding
# $1 - path to target EXE or DLL
# note: in Visual Studio 2012 and above, linker may call mt.exe internally
ifndef MANIFEST_EMBED_OPTION
ifeq (,$(call is_less_float,$(VC_VER),$(VS2005)))
# >= Visual Studio 2005
EMBED_EXE_MANIFEST = if exist $(ospath).manifest $(MT) -nologo \
  -manifest $(ospath).manifest -outputresource:$(ospath);1 && del $(ospath).manifest
EMBED_DLL_MANIFEST = if exist $(ospath).manifest $(MT) -nologo \
  -manifest $(ospath).manifest -outputresource:$(ospath);2 && del $(ospath).manifest
$(call define_append,EXE_LD,$(newline)$(QUIET)$$(EMBED_EXE_MANIFEST))
$(call define_append,DLL_LD,$(newline)$(QUIET)$$(EMBED_DLL_MANIFEST))
endif
endif

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
LIB_LD = $(call SUP,$(TMD)LIB,$1)$($(TMD)VCLIB) /nologo /OUT:$(call ospath,$1 $2) $($(TMD)ARFLAGS)

# check that LIB do not includes resources (.res - files)
ifdef MCHECK
$(eval LIB_LD = $$(if $$(filter %.res,$$^),$$(warning \
  $$1: static library cannot contain resources: $$(filter %.res,$$^)))$(value LIB_LD))
endif

# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifdef VERBOSE
$(eval LIB_LD = $(value LIB_LD) >&2)
endif

# regular expression used to match paths to included headers from /showIncludes option output
# default value, may be overridden either in project configuration makefile or in command line
INCLUDING_FILE_PATTERN := $(INCLUDING_FILE_PATTERN_en)

# prefixes of system include paths to filter-out while dependencies generation
# note: may be overridden either in project configuration makefile or in command line
# c:\\program?files?(x86)\\microsoft?visual?studio?10.0\\vc\\include\\
UDEPS_INCLUDE_FILTER := $(subst \,\\,$(VCINCLUDE) $(UMINCLUDE))

# define WRAP_CCN and WRAP_CCD - cl.exe wrappers
$(call MSVC_DEFINE_COMPILER_WRAPPERS,WRAP_CCN,WRAP_CCD,$(INCLUDING_FILE_PATTERN),$(UDEPS_INCLUDE_FILTER))

# common flags for application-level C/C++ compilers
# /EHsc - synchronous exception handling model, extern C functions never throw an exception
# /X    - do not search include files in directories specified in the PATH and INCLUDE environment variables
CMN_CFLAGS := /EHsc /X

ifeq (,$(call is_less_float,$(VC_VER),$(VS2002)))
# >= Visual Studio 2002
# /Zc:wchar_t - wchar_t is native type
CMN_CFLAGS += /Zc:wchar_t
endif

ifeq (,$(call is_less_float,$(VC_VER),$(VS2013)))
# >= Visual Studio 2013
# /Zc:rvalueCast    - enforce type conversion rules
# /Zc:strictStrings - disable string literal type conversion 
CMN_CFLAGS += /Zc:rvalueCast /Zc:strictStrings
endif

ifeq (,$(call is_less_float,$(VC_VER),$(VS2005)))
# >= Visual Studio 2005
# /D_CRT_SECURE_NO_DEPRECATE - disable warnings about use of 'non-secure' functions like strcpy()
# note: add /D_CRT_NONSTDC_NO_DEPRECATE - to disable warnings about use of POSIX functions like access()
CMN_CFLAGS += /D_CRT_SECURE_NO_DEPRECATE
endif

# paths to application-level system headers
APPINCLUDE := $(VCINCLUDE) $(UMINCLUDE)

# add standard include paths
CMN_CFLAGS += $(call qpath,$(APPINCLUDE),/I)

# common flags for the tool mode
# note: do not define WINVER and _WIN32_WINNT when building tools
TCMN_CFLAGS := $(CMN_CFLAGS)

# specify windows api version
# note: WINVER_DEFINES may be empty
CMN_CFLAGS += $(addprefix /D,$(WINVER_DEFINES))

# default flags for application-level C compiler
DEF_CFLAGS = $($(TMD)CMN_CFLAGS)

ifneq (,$(call is_less_float,$(VC_VER),$(VS2015)))
# < Visual Studio 2015
# allow 'inline' keyword in C code
DEF_CFLAGS += /Dinline=__inline
endif

# default flags for application-level C++ compiler
DEF_CXXFLAGS = $($(TMD)CMN_CFLAGS)

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
CC_PARAMS = $(CMN_PARAMS) $(DEF_CFLAGS) $(VCFLAGS)
CXX_PARAMS = $(CMN_PARAMS) $(DEF_CXXFLAGS) $(VCXXFLAGS)

ifndef MP_BUILD

# C/C++ compilers for each variant of EXE,DLL,LIB
# $1 - target object file
# $2 - source
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: TMD
# note: used by OBJ_RULES_BODY macro from $(CLEAN_BUILD_DIR)/impl/c_base.mk
# note: auto-generate dependencies
OBJ_CC  = $(call SUP,$(TMD)CC,$2)$(call WRAP_CCD,$($(TMD)VCCL) $(CC_PARAMS),$2,$1)
OBJ_CXX = $(call SUP,$(TMD)CXX,$2)$(call WRAP_CCD,$($(TMD)VCCL) $(CXX_PARAMS),$2,$1)

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
OBJ_PCC  = $(call SUP,$(TMD)PCC,$2)$(call WRAP_CCD,$($(TMD)VCCL) $(call MSVC_USE_PCH,$(dir $1),c) $(CC_PARAMS),$2,$1)
OBJ_PCXX = $(call SUP,$(TMD)PCXX,$2)$(call WRAP_CCD,$($(TMD)VCCL) $(call MSVC_USE_PCH,$(dir $1),cpp) $(CXX_PARAMS),$2,$1)

# override C++ and C compilers to support compiling with precompiled header
# $1 - target object file
# $2 - source
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: CC_WITH_PCH, CXX_WITH_PCH
OBJ_CC  = $(if $(filter $2,$(CC_WITH_PCH)),$(OBJ_PCC),$(OBJ_NCC))
OBJ_CXX = $(if $(filter $2,$(CXX_WITH_PCH)),$(OBJ_PCXX),$(OBJ_NCXX))

endif # !NO_PCH

else ifndef TOCLEAN # MP_BUILD

# override templates defined in $(CLEAN_BUILD_DIR)/_c.mk:
#  EXE_TEMPLATE, DLL_TEMPLATE and LIB_TEMPLATE will not call OBJ_RULES for C/C++ sources,
#  instead, we will build the target module directly from sources,
#  object files will be generated as a side-effect of this process
# note: $(C_BASE_TEMPLATE_MP) defines target-specific variables: SRC, SDEPS, OBJ_DIR
$(eval define EXE_TEMPLATE$(newline)$(subst $$(C_BASE_TEMPLATE),$$(C_BASE_TEMPLATE_MP),$(value EXE_TEMPLATE))$(newline)endef)
$(eval define DLL_TEMPLATE$(newline)$(subst $$(C_BASE_TEMPLATE),$$(C_BASE_TEMPLATE_MP),$(value DLL_TEMPLATE))$(newline)endef)
$(eval define LIB_TEMPLATE$(newline)$(subst $$(C_BASE_TEMPLATE),$$(C_BASE_TEMPLATE_MP),$(value LIB_TEMPLATE))$(newline)endef)

# save original linkers
$(eval EXE_LD1 = $(value EXE_LD))
$(eval DLL_LD1 = $(value DLL_LD))
$(eval LIB_LD1 = $(value LIB_LD))

# pass sources converted to objects to the linker
# $1 - path to target EXE,DLL,LIB
# $2 - objects for linking the target (may be empty, if no .asm sources were assembled and pch is not used)
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: OBJ_DIR, SRC
EXE_LD2 = $(call EXE_LD1,$1,$(addprefix $(OBJ_DIR)/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $(SRC))))) $2,$3,$4)
DLL_LD2 = $(call DLL_LD1,$1,$(addprefix $(OBJ_DIR)/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $(SRC))))) $2,$3,$4)
LIB_LD2 = $(call LIB_LD1,$1,$(addprefix $(OBJ_DIR)/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $(SRC))))) $2,$3,$4)

# redefine linkers to compile & link in one rule
# $1 - path to target EXE,DLL,LIB
# $2 - objects for linking the target (may be empty, if no .asm sources were assembled and pch is not used)
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,S,RU,SU
# note: used by redefined above EXE_TEMPLATE, DLL_TEMPLATE and LIB_TEMPLATE
EXE_LD = $(call MULTISOURCE_CL,$3,$4)$(EXE_LD2)
DLL_LD = $(call MULTISOURCE_CL,$3,$4)$(DLL_LD2)
LIB_LD = $(call MULTISOURCE_CL,$3,$4)$(LIB_LD2)

# compile multiple sources at once
# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU,...
MULTISOURCE_CL = $(call CMN_MCL,$1,$2,OBJ_MCC,OBJ_MCXX)

# parameters of multi-source application-level C and C++ compilers
# $1 - sources
# $2 - target type: EXE,DLL,LIB
# $3 - non-empty variant: R,S,RU,SU
# target-specific: OBJ_DIR
CC_PARAMS_MP = $(MP_BUILD) $(call CC_PARAMS,$(OBJ_DIR)/,$1,$2,$3)
CXX_PARAMS_MP = $(MP_BUILD) $(call CXX_PARAMS,$(OBJ_DIR)/,$1,$2,$3)

# C/C++ multi-source compilers for each variant of EXE,DLL,LIB
# $1 - sources (non-empty list)
# $2 - target type: EXE,DLL,LIB
# $3 - non-empty variant: R,S,RU,SU
# target-specific: TMD
# note: called by CMN_MCL macro from $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk
# note: do not auto-generate dependencies
OBJ_MCC  = $(call SUP,$(TMD)CC,$1)$(call WRAP_CCN,$($(TMD)VCCL) $(CC_PARAMS_MP),$1)
OBJ_MCXX = $(call SUP,$(TMD)CXX,$1)$(call WRAP_CCN,$($(TMD)VCCL) $(CXX_PARAMS_MP),$1)

ifndef NO_PCH

# compile multiple sources at once
# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU,...
MULTISOURCE_CL = $(call CMN_PMCL,$1,$2,OBJ_MCC,OBJ_MCXX,OBJ_PMCC,OBJ_PMCXX)

# C/C++ multi-source compilers for compiling using precompiled header
# $1 - sources (non-empty list)
# $2 - target type: EXE,DLL,LIB
# $3 - non-empty variant: R,S,RU,SU
# target-specific: TMD, OBJ_DIR
# note: do not auto-generate dependencies
OBJ_PMCC  = $(call SUP,$(TMD)PCC,$1)$(call WRAP_CCN,$($(TMD)VCCL) $(call MSVC_USE_PCH,$(OBJ_DIR)/,c) $(CC_PARAMS_MP),$1)
OBJ_PMCXX = $(call SUP,$(TMD)PCXX,$1)$(call WRAP_CCN,$($(TMD)VCCL) $(call MSVC_USE_PCH,$(OBJ_DIR)/,cpp) $(CXX_PARAMS_MP),$1)

endif # !NO_PCH

endif # MP_BUILD

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
PCH_CC  = $(call SUP,$(TMD)PCHCC,$2)$(call WRAP_CCD,$($(TMD)VCCL) $(MSVC_CREATE_PCH) /TC $(call CC_PARAMS,$1,$2,$4,$5),$2,$1)
PCH_CXX = $(call SUP,$(TMD)PCHCXX,$2)$(call WRAP_CCD,$($(TMD)VCCL) $(MSVC_CREATE_PCH) /TP $(call CXX_PARAMS,$1,$2,$4,$5),$2,$1)

# reset additional variables
$(call define_append,C_PREPARE_APP_VARS,$(C_PREPARE_PCH_VARS))

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_PCH_VARS)

# choose pch template for application-level targets (EXE,DLL,LIB)
$(eval define MSVC_APP_PCH_TEMPLATE$(newline)$(value $(if $(MP_BUILD),MSVC_PCH_TEMPLATE_MPt,MSVC_PCH_TEMPLATEt))$(newline)endef)

# for all application-level targets: add support for precompiled headers
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,$(C_APP_TARGETS),$$(if $$($$t),$$(MSVC_APP_PCH_TEMPLATE)))))

endif # !NO_PCH

# add standard version info resource to the target EXE or DLL
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,EXE DLL,$$(call STD_RES_TEMPLATE,$$t))))

# cleanup generated vc*.pdb (if building with /Zi or /ZI option) and .pdb (for EXE or DLL, if /DEBUG is passed to link.exe)
ifdef TOCLEAN

# $t - EXE,DLL,LIB
# $v - R,S,RU,SU
EXE_DLL_LIB_PDB_CLEANUP = $(call FORM_OBJ_DIR,$t,$v)/vc*.pdb

# $t - EXE,DLL,LIB
# $v - R,S,RU,SU
EXE_PDB_CLEANUP = $(EXE_DLL_LIB_PDB_CLEANUP)$(basename $(call FORM_TRG,EXE,$v)).pdb
DLL_PDB_CLEANUP = $(EXE_DLL_LIB_PDB_CLEANUP)$(basename $(call FORM_TRG,DLL,$v)).pdb
LIB_PDB_CLEANUP = $(EXE_DLL_LIB_PDB_CLEANUP)

$(call define_prepend,DEFINE_C_APP_EVAL,$$(call \
  TOCLEAN,$$(foreach t,$$(C_APP_TARGETS),$$(if $$($$t),$$(foreach v,$$(call GET_VARIANTS,$$t),$$($$t_PDB_CLEANUP))))))

endif # clean

# protect variables from modifications in target makefiles
# note: do not trace calls to these variables because they are used in ifdefs
$(call SET_GLOBAL,MP_BUILD FORCE_SYNC_PDB,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,DEF_SUBSYSTEM_TYPE C_PREPARE_MSVC_APP_VARS \
  CFLAGS CXXFLAGS ARFLAGS LDFLAGS TCFLAGS TCXXFLAGS TARFLAGS TLDFLAGS \
  WIN_SUPPORTED_VARIANTS WIN_VARIANT_SUFFIX WIN_VARIANT_CFLAGS \
  TRG_SUBSYSTEM SUBSYSTEM_OPTION MANIFEST_EMBED_OPTION CMN_LDFLAGS DEF_EXE_LDFLAGS DEF_DLL_LDFLAGS APPLIBPATH TAPPLIBPATH \
  CMN_LIBS LINKER_STRIP_STRINGS WRAP_LINKER EXE_LD DLL_LD EMBED_EXE_MANIFEST EMBED_DLL_MANIFEST EXE_DLL_FORM_IMPORT_LIB=t;v \
  EXE_DLL_AUX_TEMPLATE EXE_AUX_TEMPLATE=t;v DLL_AUX_TEMPLATE=t;v EXE_EXP_TOCLEAN=t;v DLL_EXP_TOCLEAN=t;v \
  LIB_DEF_VARIABLE_CHECK=DEF;LIB;EXE;DLL LIB_LD INCLUDING_FILE_PATTERN UDEPS_INCLUDE_FILTER CMN_CFLAGS APPINCLUDE TCMN_CFLAGS \
  DEF_CFLAGS DEF_CXXFLAGS CMN_PARAMS CC_PARAMS CXX_PARAMS OBJ_CC OBJ_CXX OBJ_NCC OBJ_NCXX OBJ_PCC OBJ_PCXX \
  EXE_TEMPLATE DLL_TEMPLATE LIB_TEMPLATE EXE_LD1 DLL_LD1 LIB_LD1 EXE_LD2 DLL_LD2 LIB_LD2 MULTISOURCE_CL \
  CC_PARAMS_MP CXX_PARAMS_MP OBJ_MCC OBJ_MCXX OBJ_PMCC OBJ_PMCXX PCH_CC PCH_CXX EXE_DLL_LIB_PDB_CLEANUP=t;v \
  EXE_PDB_CLEANUP=t;v DLL_PDB_CLEANUP=t;v LIB_PDB_CLEANUP=t;v)
