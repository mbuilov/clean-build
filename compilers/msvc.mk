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

# add definitions of MC_COMPILER and RC_COMPILER (needed by STD_RES_TEMPLATE)
ifeq (,$(filter-out undefined environment,$(origin MC_COMPILER)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_tools.mk
endif

# add definitions of standard resource with module version information
ifeq (,$(filter-out undefined environment,$(origin STD_RES_TEMPLATE)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc_res.mk
endif

# reset additional variables
# RES - resources to link to EXE or DLL
# DEF - linker definitions file (used mostly to list exported symbols)
define C_PREPARE_MSVC_APP_VARS
RES:=
DEF:=
endef
C_PREPARE_MSVC_APP_VARS := $(C_PREPARE_MSVC_APP_VARS)

# patch code executed at beginning of target makefile
$(call define_append,C_PREPARE_APP_VARS,$(newline)$$(C_PREPARE_MSVC_APP_VARS))

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_MSVC_APP_VARS)

# paths compiler/linker and system libraries/headers - must be defined in project configuration makefile
VSLIBPATH = $(error VSLIBPATH is not defined - paths to Visual Studio libraries, spaces must be replaced with ?)
VSINCLUDE = $(error VSINCLUDE is not defined - paths to Visual Studio headers, spaces must be replaced with ?)
VSLINK    = $(error VSLINK is not defined - path to link.exe, should be in double-quotes if contains spaces)
VSLIB     = $(error VSLIB is not defined - path to lib.exe, should be in double-quotes if contains spaces)
VSCL      = $(error VSCL is not defined - path to cl.exe, should be in double-quotes if contains spaces)
UMLIBPATH = $(error UMLIBPATH is not defined - paths to user-mode libraries, spaces must be replaced with ?)
UMINCLUDE = $(error UMINCLUDE is not defined - paths to user-mode headers, spaces must be replaced with ?)

# utilities for the tool mode, may be overridden by specifying them in project configuration makefile
TVSLIBPATH = $(VSLIBPATH)
TVSINCLUDE = $(VSINCLUDE)
TVSLINK    = $(VSLINK)
TVSLIB     = $(VSLIB)
TVSCL      = $(VSCL)
TUMLIBPATH = $(UMLIBPATH)
TUMINCLUDE = $(UMINCLUDE)

# supported non-regular target variants:
# (R - dynamically linked multi-threaded libc - default variant)
# S - statically linked multi-threaded libc
# RU - same as R, but with unicode support
# SU - same as S, but with unicode support
WIN_SUPPORTED_VARIANTS := S RU SU

# for each non-regular target variant from $(WIN_NONREGULAR_VARIANTS): RU,SU,S
WIN_VARIANT_SUFFIX := $(if $(findstring \
  RU,$1),_u,$(if $(findstring \
  SU,$1),_su,_s))

# options for each target variant: R,S,RU,SU
WIN_VARIANT_COPTS = $(if $(filter S%,$1),/MT,/MD)$(if $(DEBUG),d)$(if $(filter %U,$1), /DUNICODE /D_UNICODE)

# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_SUPPORTED_VARIANTS = $(WIN_SUPPORTED_VARIANTS)
LIB_SUPPORTED_VARIANTS = $(WIN_SUPPORTED_VARIANTS)
DLL_SUPPORTED_VARIANTS = $(WIN_SUPPORTED_VARIANTS)

# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_SUFFIX = $(WIN_VARIANT_SUFFIX)
LIB_VARIANT_SUFFIX = $(WIN_VARIANT_SUFFIX)
DLL_VARIANT_SUFFIX = $(WIN_VARIANT_SUFFIX)

# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_COPTS   = $(WIN_VARIANT_COPTS)
EXE_VARIANT_CXXOPTS = $(EXE_VARIANT_COPTS)

# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_COPTS   = $(WIN_VARIANT_COPTS)
LIB_VARIANT_CXXOPTS = $(LIB_VARIANT_COPTS)

# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
DLL_VARIANT_COPTS   = $(WIN_VARIANT_COPTS)
DLL_VARIANT_CXXOPTS = $(DLL_VARIANT_COPTS)

# determine which variant of static library to link with EXE or DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,S,RU or SU, if empty, then assume R
# $3 - dependency name, e.g. mylib
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
# note: use the same variant of dependent static library as target EXE or DLL (for example for S-EXE use S-LIB)
# note: unicode variants of the target EXE or DLL may link with two kinds of libraries:
#  1) with unicode support - name begins with UNI_ prefix, normally built in 2 variants, e.g. UNI_mylib.lib and UNI_mylib_u.lib
#  2) without unicode support - name do not begin with UNI_ prefix, normally built in 1 variant, e.g. mylib.lib
#  so, for RU or SU variant of target EXE or DLL, if dependent library name do not starts with UNI_ prefix
#  - dependent library do not have unicode variant, so convert needed variant to non-unicode one: RU->R or SU->S
LIB_DEP_MAP = $(if $(3:UNI_%=),$(2:U=),$2)

# same for dependent dynamic library (via it's import library)
DLL_DEP_MAP = $(if $(3:UNI_%=),$(2:U=),$2)

# user-modifiable link.exe flags for linking executables and shared libraries
LDFLAGS := $(if $(DEBUG),/DEBUG,/RELEASE /LTCG)

# common link.exe flags for linking executables and dynamic libraries
CMN_LDFLAGS := /INCREMENTAL:NO

# link.exe flags for linking an EXE
EXE_LDFLAGS:=

# link.exe flags for linking a DLL
DLL_LDFLAGS := /DLL

# lib.exe flags for linking a LIB
ARFLAGS := $(if $(DEBUG),,/LTCG)

# how to mark exported symbols from a DLL
DLL_EXPORTS_DEFINE := "__declspec(dllexport)"

# how to mark imported symbols from a DLL
DLL_IMPORTS_DEFINE := "__declspec(dllimport)"

# make version string: major.minor.patch -> major.minor
# target-specific: MODVER
MODVER_MAJOR_MINOR = $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(MODVER)) 0 0))

# paths to application-level system libraries 
# target-specific: TMD
SYS_APPLIBPATH = $($(TMD)VSLIBPATH) $($(TMD)UMLIBPATH)

# minimum required version of the operating system subsystem
# note: 5.01 - WinXP(x86), 5.02 - WinXP(x64)
SUBSYSTEM_VER := $(if $(CPU:%64=),5.01,5.02)

# default subsystem for EXE or DLL
# $1 - path to target EXE or DLL
# note: do not add /SUBSYSTEM option if $(LOPTS) have already specified one, e.g.: /SUBSYSTEM:WINDOWS,$(SUBSYSTEM_VER)
# note: do not specify subsystem version when building tools (in tool mode)
# target-specific: TMD, LOPTS
DEF_SUBSYSTEM = $(if $(filter /SUBSYSTEM:%,$(LOPTS)),,/SUBSYSTEM:CONSOLE$(if $(TMD),,,$(SUBSYSTEM_VER)))

# how to embed manifest into EXE or DLL
# Note: starting from Visual Studio 2012, linker supports /MANIFEST:EMBED option - linker may call mt.exe internally
EMBED_MANIFEST_OPTION:=

# common linker options for EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects
# $3 - target: EXE or DLL
# $4 - non-empty variant: R,P,D
# target-specific: RES, IMP, DEF, LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS
CMN_LIBS = /nologo /OUT:$(call ospath,$1 $2 $(RES)) /VERSION:$(MODVER_MAJOR_MINOR) $(DEF_SUBSYSTEM) $(EMBED_MANIFEST_OPTION) \
  $(addprefix /IMPLIB:,$(call ospath,$(IMP))) $(addprefix /DEF:,$(call ospath,$(DEF))) $(if \
  $(firstword $(LIBS)$(DLLS)),/LIBPATH:$(call ospath,$(LIB_DIR)) $(call DEP_LIBS,$3,$4) $(call DEP_IMPS,$3,$4)) $(call \
  qpath,$(SYSLIBPATH) $(SYS_APPLIBPATH),/LIBPATH:) $(SYSLIBS) $(CMN_LDFLAGS)

# default value, may be overridden either in project configuration makefile or in command line
LINKER_STRIP_STRINGS := $(LINKER_STRIP_STRINGS_en)

# call exe/drv linker and strip-off diagnostic message and message about generated .exp-file
# $1 - linker with options
# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifdef VERBOSE
WRAP_LINKER = $1 >&2
else
WRAP_LINKER = $1
endif

# $1 - linker with options
# note: FILTER_OUTPUT sends command output to stderr
# note: in debug, diagnostic message is not printed
# target-specific: IMP
ifndef NO_WRAP
$(eval WRAP_LINKER = $$(if $$(IMP),$$(call FILTER_OUTPUT,$$1,|findstr /VC:$$(basename $$(notdir $$(IMP))).exp),$(value WRAP_LINKER)))
ifndef DEBUG
ifdef LINKER_STRIP_STRINGS
WRAP_LINKER = $(call FILTER_OUTPUT,$1,$(call qpath,$(LINKER_STRIP_STRINGS),|findstr /VBRC:)$(patsubst \
  %, |findstr /VC:%.exp,$(basename $(notdir $(IMP)))))
endif
endif
endif

# check that target exe/dll exports symbols - linker has created .exp file
# $1 - path to target EXE or DLL
# note: if EXE do not exports symbols (as usual), do not set EXE_EXPORTS (empty by default)
# note: if DLL do not exports symbols (unusual), set DLL_NO_EXPORTS to non-empty value
# target-specific: IMP, LIB_DIR
CHECK_EXP_CREATED = $(if $(IMP),$(newline)$(QUIET)if not exist $(call ospath,$(LIB_DIR)/$(basename \
  $(notdir $(IMP))).exp) (echo $(notdir $1) does not exports any symbols!) && cmd /c exit 1)

# linkers for each variant of EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects for linking the target
# $3 - target: EXE or DLL
# $4 - non-empty variant: R,S,RU,SU
# target-specific: TMD, LOPTS
# note: used by EXE_TEMPLATE and DLL_TEMPLATE from $(CLEAN_BUILD_DIR)/impl/_c.mk
# note: link.exe will not delete generated manifest file if failed to build target exe/dll, e.g. because of invalid DEF file
EXE_LD = $(call SUP,$(TMD)EXE,$1)$(call WRAP_LINKER,$($(TMD)VSLINK) $(CMN_LIBS) $(EXE_LDFLAGS) $(LOPTS) $(LDFLAGS))$(CHECK_EXP_CREATED)
DLL_LD = $(call SUP,$(TMD)DLL,$1)$(call WRAP_LINKER,$($(TMD)VSLINK) $(CMN_LIBS) $(DLL_LDFLAGS) $(LOPTS) $(LDFLAGS))$(CHECK_EXP_CREATED)

# manifest embedding
# $1 - path to target EXE or DLL
ifndef EMBED_MANIFEST_OPTION
EMBED_EXE_MANIFEST = if exist $(ospath).manifest $(MT) -nologo \
  -manifest $(ospath).manifest -outputresource:$(ospath);1 && del $(ospath).manifest
EMBED_DLL_MANIFEST = if exist $(ospath).manifest $(MT) -nologo \
  -manifest $(ospath).manifest -outputresource:$(ospath);2 && del $(ospath).manifest
$(call define_append,EXE_LD,$(newline)$(QUIET)$$(EMBED_EXE_MANIFEST))
$(call define_append,DLL_LD,$(newline)$(QUIET)$$(EMBED_DLL_MANIFEST))
endif

# linker for each variant of LIB
# $1 - path to target LIB
# $2 - objects for linking the target
# $3 - target: LIB
# $4 - non-empty variant: R,S,RU,SU
# target-specific: TMD, LOPTS
LIB_LD = $(call SUP,$(TMD)LIB,$1)$($(TMD)VSLIB) /nologo /OUT:$(call ospath,$1 $2) $(ARFLAGS)

# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifdef VERBOSE
$(eval LIB_LD = $(value LIB_LD) >&2)
endif

# stip-off names of compiled sources
# $1 - compiler with options
# $2 - target object file
# $3 - source(s)
# note: FILTER_OUTPUT sends command output to stderr
# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifndef NO_WRAP
WRAP_CC = $(call FILTER_OUTPUT,$1,$(addprefix |findstr /VXC:,$(notdir $3)))
else ifdef VERBOSE
WRAP_CC = $1 >&2
else
WRAP_CC = $1
endif

# may auto-generate dependencies only if building sequentially, because /showIncludes option conflicts with /MP
ifdef SEQ_BUILD

# default value, may be overridden either in project configuration makefile or in command line
INCLUDING_FILE_PATTERN := $(INCLUDING_FILE_PATTERN_en)

# prefixes of system include paths to filter-out while dependencies generation
# note: may be overridden either in project configuration makefile or in command line
# c:\\program?files?(x86)\\microsoft?visual?studio?10.0\\vc\\include\\
UDEPS_INCLUDE_FILTER := $(subst \,\\,$(VSINCLUDE) $(UMINCLUDE))

# call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target object file
# $3 - source
# note: FILTER_OUTPUT sends command output to stderr
# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifndef NO_WRAP
ifndef NO_DEPS
WRAP_CC = (($1 /showIncludes 2>&1 && set/p="C">&2<NUL)|$(SED) -n \
  $(SED_DEPS_SCRIPT) 2>&1 && set/p="S">&2<NUL)3>&2 2>&1 1>&3|findstr /BC:CS>NUL
endif
endif

# user-modifiable C/C++ compiler flags
CFLAGS   := $(if $(DEBUG),-g,-fast)
CXXFLAGS := $(CFLAGS)

# common flags for application-level C/C++-compilers
CMN_CFLAGS := -v -xldscope=hidden

# default flags for application-level C compiler
DEF_CFLAGS := $(CMN_CFLAGS)

# default flags for application-level C++ compiler
# disable some C++ warnings:
# badargtype2w - (Anachronism) when passing pointers to functions
# wbadasg      - (Anachronism) assigning extern "C" ...
DEF_CXXFLAGS := -erroff=badargtype2w,wbadasg $(CMN_CFLAGS)

# application-level defines
APP_DEFINES:=

# call C compiler
# $1 - outdir/
# $2 - sources
# $3 - flags
# target-specific: TMD, DEFINES, INCLUDE, COMPILER
CMN_CL1 = $(VS$(TMD)CL) /nologo /c $(APP_FLAGS) $(call SUBST_DEFINES,$(addprefix /D,$(APP_DEFINES) $(DEFINES))) $(call \
  qpath,$(call ospath,$(INCLUDE)) $(VS$(TMD)INC) $(UM$(TMD)INC),/I) /Fo$(ospath) /Fd$(ospath) $3 $(call ospath,$2)

# C compilers for different variants (R,S,RU,SU)
# $1 - outdir/
# $2 - sources
# $3 - flags
CMN_RCL  = $(CMN_CL1) /MD$(if $(DEBUG),d)
CMN_SCL  = $(CMN_CL1) /MT$(if $(DEBUG),d)
CMN_RUCL = $(CMN_RCL) /DUNICODE /D_UNICODE
CMN_SUCL = $(CMN_SCL) /DUNICODE /D_UNICODE








# check that library name built as RU/SU variant begins with UNI_ prefix
# $1 - library name
# $v - variant name: RU,SU
CHECK_LIB_UNI_NAME1 = $(if $(filter-out UNI_%,$1),$(error library '$1' name must begin with UNI_ prefix to build it as $v variant))

# check that library name built as RU/SU variant begins with UNI_ prefix
# $1 - IMP or LIB
# $v - variant name: R,S,RU,SU
# note: $$1 - target library name
CHECK_LIB_UNI_NAME = $(if $(filter %U,$v),$$(call CHECK_LIB_UNI_NAME1,$$(patsubst \
  %$(call LIB_VARIANT_SUFFIX,$v)$($1_SUFFIX),%,$$(notdir $$1))))







# exe file suffix
EXE_SUFFIX := .exe

# object file suffix
OBJ_SUFFIX := .obj

# static library (archive) prefix/suffix
LIB_PREFIX:=
LIB_SUFFIX := .a

# dynamically loaded library (shared object) prefix/suffix
DLL_PREFIX:=
DLL_SUFFIX := .dll

# import library for dll prefix/suffix
IMP_PREFIX:=
IMP_SUFFIX := .lib

# dll and import file for dll - different files
# place dll to $(BIN_DIR), import lib for dll - to $(LIB_DIR)
# NOTE: DLL_DIR must be recursive because $(BIN_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(BIN_DIR)

# variants filter function - get possible variants for the target, needed by $(CLEAN_BUILD_DIR)/c.mk
# $1 - LIB,EXE,DLL
# R  - dynamically linked multi-threaded libc (regular, default variant)
# S  - statically linked multi-threaded libc
# RU - same as R, but with unicode support (exe or dll may be linked with UNI_-prefixed static/dynamic library)
# SU - same as S, but with unicode support (exe or dll may be linked with UNI_-prefixed static/dynamic library)
VARIANTS_FILTER := S RU SU

# determine suffix for static LIB or for import library of DLL
# $1 - target variant R,S,RU,SU,<empty>
# note: overrides value from $(CLEAN_BUILD_DIR)/c.mk
LIB_VAR_SUFFIX = $(if \
                 $(findstring RU,$1),_u,$(if \
                 $(findstring SU,$1),_mtu,$(if \
                 $(findstring S,$1),_mt)))

# for $(EXE_VAR_SUFFIX) from $(CLEAN_BUILD_DIR)/c.mk:
# get target name suffix for EXE,DRV in case of multiple target variants
# $1 - EXE,DRV
# $2 - target variant S,RU,SU (not R or <empty>)
# $3 - list of variants of target $1 to build (filtered by target platform specific $(VARIANTS_FILTER))
# note: overrides value from $(CLEAN_BUILD_DIR)/c.mk
EXE_SUFFIX_GEN = $(if $(word 2,$3),$(if \
                 $(findstring RU,$2),_u,$(if \
                 $(findstring SU,$2),_mtu,$(if \
                 $(findstring S,$2),_mt))))

# for $(DEP_LIB_SUFFIX) from $(CLEAN_BUILD_DIR)/c.mk:
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,S,RU,SU,<empty>
# $3 - dependent static library name
# use the same variant of dependent static library as target EXE or DLL (for example for S-EXE use S-LIB)
# NOTE: for RU or SU variant of target EXE or DLL, if dependent library name do not starts with UNI_
#  - dependent library do not have unicode variant, so convert needed variant to non-unicode one: RU->R or SU->S
VARIANT_LIB_MAP = $(if $(3:UNI_%=),$(2:U=),$2)

# for $(DEP_IMP_SUFFIX) from $(CLEAN_BUILD_DIR)/c.mk:
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,S,RU,SU,<empty>
# $3 - dependent dynamic library name
# use the same variant of dependent dynamic library as target EXE or DLL (for example for S-EXE use S-DLL)
# NOTE: for RU or SU variant of target EXE or DLL, if dependent library name do not starts with UNI_
#  - dependent library do not have unicode variant, so convert needed variant to non-unicode one: RU->R or SU->S
VARIANT_IMP_MAP = $(if $(3:UNI_%=),$(2:U=),$2)

# standard defines
# for example, WINVER_DEFINES = WINVER=0x0501 _WIN32_WINNT=0x0501
OS_PREDEFINES := $(WINVER_DEFINES)

# make version string: maj.min.patch -> maj.min
MK_MAJ_MIN_VER = $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$1) 0 0))

# default linker flags for LIB
# $$1 - target lib
# $$2 - objects
# $v - variant
DEF_LIB_LDFLAGS := $(if $(DEBUG),,/LTCG)

# define LIB linker for variant $v
# $$1 - target lib
# $$2 - objects
# $v - variant
# target-specific: TMD, LDFLAGS
# note: send linker output to stderr
define LIB_LD_TEMPLATE
$(empty)
LIB_$v_LD1 = $(call CHECK_LIB_UNI_NAME,LIB)$$(call SUP,$$(TMD)LIB,$$1)$$(VS$$(TMD)LD) \
  /lib /nologo /OUT:$$(call ospath,$$1 $$2) $(DEF_LIB_LDFLAGS) $$(LDFLAGS) >&2
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(LIB_LD_TEMPLATE)))

# common linker flags for EXE or DLL
# $$1 - target EXE or DLL
# $$2 - objects
# $v - variant
CMN_LIBS_LDFLAGS := /INCREMENTAL:NO $(if $(DEBUG),/DEBUG,/RELEASE /LTCG /OPT:REF)

# common parts of linker options for built EXE or DLL
# $$1 - target EXE or DLL
# $$2 - objects
# $v - variant
# note: because target variable (EXE or DLL) is not used in VARIANT_LIB_MAP and VARIANT_IMP_MAP,
#  may pass any value as first parameter to MAKE_DEP_LIBS and MAKE_DEP_IMPS (macros from $(CLEAN_BUILD_DIR)/c.mk)
# target-specific: TMD, MODVER, DEF, RES, LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS
CMN_LIBS = /OUT:$$(ospath) /VERSION:$$(call MK_MAJ_MIN_VER,$$(MODVER)) $$(addprefix \
  /DEF:,$$(call ospath,$$(DEF))) $(CMN_LIBS_LDFLAGS) $$(call ospath,$$2 $$(RES)) $$(if \
  $$(firstword $$(LIBS)$$(DLLS)),/LIBPATH:$$(call ospath,$$(LIB_DIR))) $$(call MAKE_DEP_LIBS,XXX,$v,$$(LIBS)) $$(call \
  MAKE_DEP_IMPS,XXX,$v,$$(DLLS)) $$(call qpath,$$(VS$$(TMD)LIB) $$(UM$$(TMD)LIB) $$(call \
  ospath,$$(SYSLIBPATH)),/LIBPATH:) $$(SYSLIBS)

# wrap linker call to strip-off diagnostic linker messages
# $1 - linker command with arguments
# note: send linker output to stderr
# note: in debug, no diagnostic messages in the stdout
ifdef DEBUG
WRAP_LINKER = $1 >&2
else ifndef LINKER_STRIP_STRINGS
WRAP_LINKER = $1 >&2
else
WRAP_LINKER = $(call FILTER_OUTPUT,$1,$(call qpath,$(LINKER_STRIP_STRINGS),|findstr /VBRC:))
endif

# Link.exe has a bug/feature:
# - it may not delete target exe/dll if DEF was specified and were errors while building the exe/dll
# - also it will not delete generated manifest file if failed to build target exe/dll
# $1 - target EXE or DLL
# $2 - $(EMBED_EXE_MANIFEST) or $(EMBED_DLL_MANIFEST)
# target-specific: DEF
DEL_DEF_MANIFEST_ON_FAIL = $(if $(DEF)$2,$(call DEL_ON_FAIL,$(if $(DEF),$1) $(if $2,$1.manifest)))$2

# call exe/drv linker and strip-off message about generated .exp-file
# $1 - linker with options
# $2 - $(basename $(notdir $(IMP))).exp
# note: send linker output to stderr
# note: in debug, no diagnostic messages in the stdout
WRAP_EXE_EXPORTS_LINKER = $(call FILTER_OUTPUT,$1,|findstr /VC:$2
ifndef DEBUG
ifdef LINKER_STRIP_STRINGS
WRAP_EXE_EXPORTS_LINKER += $(call qpath,$(LINKER_STRIP_STRINGS),|findstr /VBRC:)
endif
endif
WRAP_EXE_EXPORTS_LINKER += )

# wrap exe/drv linker call to strip-off message about generated .exp-file
# $1 - non-<empty> if exe/drv exports symbols, <empty> - otherwise
# $2 - linker with options
# target-specific: IMP
# note: send linker output to stderr
ifdef NO_WRAP
WRAP_EXE_LINKER = $2 >&2
else
WRAP_EXE_LINKER = $(if $1,$(call WRAP_EXE_EXPORTS_LINKER,$2,$(basename $(notdir $(IMP))).exp),$(call WRAP_LINKER,$2))
endif

# define EXE linker for variant $v
# $$1 - target EXE
# $$2 - objects
# $v - variant
# target-specific: TMD, LDFLAGS, IMP, EXE_EXPORTS
define EXE_LD_TEMPLATE
$(empty)
EXE_$v_LD1 = $$(call SUP,$$(TMD)XLINK,$$1)$$(call \
  WRAP_EXE_LINKER,$$(EXE_EXPORTS),$$(VS$$(TMD)LD) /nologo $(CMN_LIBS) $$(if $$(EXE_EXPORTS),/IMPLIB:$$(call \
  ospath,$$(IMP))) $(DEF_SUBSYSTEM) $(EMBED_MANIFEST_OPTION) $$(LDFLAGS))$$(call \
  DEL_DEF_MANIFEST_ON_FAIL,$$1,$$(EMBED_EXE_MANIFEST))
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(EXE_LD_TEMPLATE)))

# call dll/kdll linker and check that dll/kdll exports symbols, then strip-off message about generated .exp-file
# $1 - target DLL or KDLL
# $2 - linker with options
# $3 - $(basename $(notdir $(IMP))).exp
# target-specific: LIB_DIR
# note: send linker output to stderr
# note: in debug, no diagnostic messages in the stdout
WRAP_DLL_EXPORTS_LINKER = $(call FILTER_OUTPUT,($2 && (dir $(call ospath,$(LIB_DIR)/$3)>NUL 2>&1 || ((echo $(notdir \
  $1) does not exports any symbols!) & del $(ospath) & exit /b 1))),|findstr /VC:$3
ifndef DEBUG
ifdef LINKER_STRIP_STRINGS
WRAP_DLL_EXPORTS_LINKER += $(call qpath,$(LINKER_STRIP_STRINGS),|findstr /VBRC:)
endif
endif
WRAP_DLL_EXPORTS_LINKER += )

# wrap dll linker call to check that dll exports symbols, then strip-off message about .exp-file
# $1 - non-<empty> if dll/kdll do not exports symbols, <empty> - otherwise
# $2 - target DLL or KDLL
# $3 - linker with options
# target-specific: IMP
# note: send linker output to stderr
ifdef NO_WRAP
WRAP_DLL_LINKER = $3 >&2
else
WRAP_DLL_LINKER = $(if $1,$(call WRAP_LINKER,$3),$(call WRAP_DLL_EXPORTS_LINKER,$2,$3,$(basename $(notdir $(IMP))).exp))
endif

# define DLL linker for variant $v
# $$1 - target DLL
# $$2 - objects
# $v - variant
# target-specific: TMD, LDFLAGS, IMP, DLL_NO_EXPORTS
define DLL_LD_TEMPLATE
$(empty)
DLL_$v_LD1 = $$(call SUP,$$(TMD)LINK,$$1)$$(call \
  WRAP_DLL_LINKER,$$(DLL_NO_EXPORTS),$$1,$$(VS$$(TMD)LD) /nologo /DLL $(CMN_LIBS) $$(if $$(DLL_NO_EXPORTS),,/IMPLIB:$$(call \
  ospath,$$(IMP))) $(DEF_SUBSYSTEM) $(EMBED_MANIFEST_OPTION) $$(LDFLAGS))$$(call \
  DEL_DEF_MANIFEST_ON_FAIL,$$1,$$(EMBED_DLL_MANIFEST))
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(DLL_LD_TEMPLATE)))












# flags for application-level C/C++-compiler
OS_APP_FLAGS := /X /GF /W3 /EHsc
ifdef DEBUG
OS_APP_FLAGS += /Od /RTCc /RTCsu /GS
else
OS_APP_FLAGS += /Ox /GL /Gy
endif

ifneq (,$(call is_less,10,$(VS_VER)))
# >= Visual Studio 2012
ifdef DEBUG
OS_APP_FLAGS += /sdl # Enable additional security checks
endif
endif

ifneq (,$(call is_less,11,$(VS_VER)))
# >= Visual Studio 2013
OS_APP_FLAGS += /Zc:inline # Remove unreferenced COMDAT
OS_APP_FLAGS += /Zc:strictStrings # Disable string literal type conversion
OS_APP_FLAGS += /Zc:rvalueCast # Enforce type conversion rules
endif

ifneq (,$(call is_less,13,$(VS_VER)))
# >= Visual Studio 2015
ifdef DEBUG
OS_APP_FLAGS += /D_ALLOW_RTCc_IN_STL
endif
endif

# option /Zi is used to store debug info in one .pdb for all compiled sources
# for parallel builds, it's needed to synchronize access to this .pdb
# if FORCE_SYNC_PDB is defined (as /FS, starting with Visual Studio 2013),
# then may use /Zi, else - use old /Z7 to store debug info in each .obj
# note: no debug info in release build if /FS option is not supported
ifdef FORCE_SYNC_PDB
OS_APP_FLAGS += $(FORCE_SYNC_PDB) /Zi
else ifdef DEBUG
OS_APP_FLAGS += /Z7
endif

# APP_FLAGS may be overridden in project makefile
APP_FLAGS := $(OS_APP_FLAGS)

# application-level defines for C/C++-compiler
# note: some external sources want WIN32 to be defined
OS_APP_DEFINES := WIN32 _CRT_SECURE_NO_DEPRECATE _CRT_NONSTDC_NO_DEPRECATE

ifneq (,$(call is_less,$(VS_VER),14))
OS_APP_DEFINES += inline=__inline
endif

# APP_DEFINES may be overridden in project makefile
APP_DEFINES := $(OS_PREDEFINES) $(OS_APP_DEFINES)

# call C compiler
# $1 - outdir/
# $2 - sources
# $3 - flags
# target-specific: TMD, DEFINES, INCLUDE, COMPILER
CMN_CL1 = $(VS$(TMD)CL) /nologo /c $(APP_FLAGS) $(call SUBST_DEFINES,$(addprefix /D,$(APP_DEFINES) $(DEFINES))) $(call \
  qpath,$(call ospath,$(INCLUDE)) $(VS$(TMD)INC) $(UM$(TMD)INC),/I) /Fo$(ospath) /Fd$(ospath) $3 $(call ospath,$2)

# C compilers for different variants (R,S,RU,SU)
# $1 - outdir/
# $2 - sources
# $3 - flags
CMN_RCL  = $(CMN_CL1) /MD$(if $(DEBUG),d)
CMN_SCL  = $(CMN_CL1) /MT$(if $(DEBUG),d)
CMN_RUCL = $(CMN_RCL) /DUNICODE /D_UNICODE
CMN_SUCL = $(CMN_SCL) /DUNICODE /D_UNICODE

# stip-off names of compiled sources
# $1 - compiler with options
# $2 - target object file (unused)
# $3 - sources
# note: send compiler output to stderr
ifdef NO_WRAP
WRAP_CC_COMPILER = $1 >&2
else
WRAP_CC_COMPILER = $(call FILTER_OUTPUT,$1,$(addprefix |findstr /VXC:,$(notdir $3)))
endif

# $(SED) expression to match C compiler messages about included files
INCLUDING_FILE_PATTERN_en := Note: including file:
# utf8 "Примечание: включение файла:"
INCLUDING_FILE_PATTERN_ru_utf8 := Примечание: включение файла:
INCLUDING_FILE_PATTERN_ru_utf8_bytes := \xd0\x9f\xd1\x80\xd0\xb8\xd0\xbc\xd0\xb5\xd1\x87\xd0\xb0\xd0\xbd\xd0\xb8\xd0\xb5: \xd0\xb2\xd0\xba\xd0\xbb\xd1\x8e\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5 \xd1\x84\xd0\xb0\xd0\xb9\xd0\xbb\xd0\xb0:
# cp1251 "Примечание: включение файла:"
INCLUDING_FILE_PATTERN_ru_cp1251 := ����������: ��������� �����:
INCLUDING_FILE_PATTERN_ru_cp1251_bytes := \xcf\xf0\xe8\xec\xe5\xf7\xe0\xed\xe8\xe5: \xe2\xea\xeb\xfe\xf7\xe5\xed\xe8\xe5 \xf4\xe0\xe9\xeb\xe0:
# cp866 "Примечание: включение файла:"
INCLUDING_FILE_PATTERN_ru_cp866 := �ਬ�砭��: ����祭�� 䠩��:
INCLUDING_FILE_PATTERN_ru_cp866_bytes := \x8f\xe0\xa8\xac\xa5\xe7\xa0\xad\xa8\xa5: \xa2\xaa\xab\xee\xe7\xa5\xad\xa8\xa5 \xe4\xa0\xa9\xab\xa0:
# default value, may be overridden either in project configuration makefile or in command line
INCLUDING_FILE_PATTERN := $(INCLUDING_FILE_PATTERN_en)

# $(SED) expression to filter-out system files while dependencies generation
# note: may be overridden either in project configuration makefile or in command line
# c:\\program?files?(x86)\\microsoft?visual?studio?10.0\\vc\\include\\
UDEPS_INCLUDE_FILTER := $(subst \,\\,$(VSINC) $(UMINC))

# $(SED) script to generate dependencies file from C compiler output
# $1 - compiler with options (unused)
# $2 - target object file
# $3 - source
# $4 - name of variale with prefixes of system includes to filter out (UDEPS_INCLUDE_FILTER/KDEPS_INCLUDE_FILTER)

# s/\x0d//;                                   - fix line endings - remove CR
# /^$(notdir $3)$$/d;                         - delete compiled file name printed by cl, start new circle
# /^$(INCLUDING_FILE_PATTERN) /!{p;d;}        - print all lines not started with $(INCLUDING_FILE_PATTERN) and space, start new circle
# s/^$(INCLUDING_FILE_PATTERN)  *//;          - strip-off leading $(INCLUDING_FILE_PATTERN) with spaces
# $(subst ?, ,$(foreach x,$($4),\@^$x.*@Id;)) - delete lines started with system include paths, start new circle
# s/ /\\ /g;                                  - escape spaces in included file path
# s@.*@&:\n$2: &@;w $(basename $2).d          - make dependencies, then write to generated dep-file

SED_DEPS_SCRIPT = \
-e "s/\x0d//;/^$(notdir $3)$$/d;/^$(INCLUDING_FILE_PATTERN) /!{p;d;}" \
-e "s/^$(INCLUDING_FILE_PATTERN)  *//;$(subst ?, ,$(foreach x,$($4),\@^$x.*@Id;))s/ /\\ /g;s@.*@&:\n$2: &@;w $(basename $2).d"

# call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target object file
# $3 - source
# $4 - name of variale with prefixes of system includes to filter out
# note: send compiler output to stderr
ifdef NO_WRAP
WRAP_CC_COMPILER_DEPS = $1 >&2
else ifdef NO_DEPS
WRAP_CC_COMPILER_DEPS = $(WRAP_CC_COMPILER)
else
WRAP_CC_COMPILER_DEPS = (($1 /showIncludes 2>&1 && set/p="C">&2<NUL)|$(SED)\
  -n $(SED_DEPS_SCRIPT) 2>&1 && set/p="S">&2<NUL)3>&2 2>&1 1>&3|findstr /BC:CS>NUL
endif

# override template defined in $(CLEAN_BUILD_DIR)/_c.mk
# do not need rules for building objects, we will build exe, lib or dll directly from sources
# note: object files are generated as a side-effect of compiling sources
ifndef SEQ_BUILD
ifndef TOCLEAN
OBJ_RULES:=
$(call CLEAN_BUILD_PROTECT_VARS,OBJ_RULES)
endif
endif

ifdef SEQ_BUILD

# sequential build: don't add /MP option to Visual Studio C compiler
# note: auto-dependencies generation is available only in sequential mode - /MP conflicts with /showIncludes
# note: precompiled headers are not supported in sequential mode (but support may be added later)

# common C/C++ compiler
# $1 - target object file
# $2 - source
# $3 - compiler
# target-specific: TMD, CFLAGS, CXXFLAGS
CMN_CC = $(call SUP,$(TMD)CC,$2)$(call WRAP_CC_COMPILER_DEPS,$(call $3,$(dir $1),$2,$(CFLAGS)),$1,$2,UDEPS_INCLUDE_FILTER)
CMN_CXX = $(call SUP,$(TMD)CXX,$2)$(call WRAP_CC_COMPILER_DEPS,$(call $3,$(dir $1),$2,$(CXXFLAGS)),$1,$2,UDEPS_INCLUDE_FILTER)

# define compilers for different target variants
# $$1 - target object/exe/dll/lib, $$2 - source for compilers, objects for linkers
define SEQ_COMPILERS_TEMPLATE
$(empty)
LIB_$v_CC  = $$(call CMN_CC,$$1,$$2,CMN_$vCL)
LIB_$v_CXX = $$(call CMN_CXX,$$1,$$2,CMN_$vCL)
EXE_$v_CC  = $$(LIB_$v_CC)
EXE_$v_CXX = $$(LIB_$v_CXX)
DLL_$v_CC  = $$(EXE_$v_CC)
DLL_$v_CXX = $$(EXE_$v_CXX)
LIB_$v_LD  = $$(LIB_$v_LD1)
EXE_$v_LD  = $$(EXE_$v_LD1)
DLL_$v_LD  = $$(DLL_$v_LD1)
$(empty)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(SEQ_COMPILERS_TEMPLATE)))

else # !SEQ_BUILD

# multi-source build: build multiple sources at one CL call - using /MP option
# note: auto-dependencies generation is not supported in this mode - /MP conflicts with /showIncludes
# note: precompiled headers are supported in this mode

# $1 - sources
# $2 - outdir/
# $3 - compiler (CMN_RCL or CMN_SCL)
# $4 - aux compiler flags
# $5 - pch header
# target-specific: TMD, CFLAGS, CXXFLAGS
CALL_MCC   = $(call SUP,$(TMD)MCC,$1)$(call WRAP_CC_COMPILER,$(call $3,$2,$1,$4/MP $(CFLAGS)),,$1)
CALL_MCXX  = $(call SUP,$(TMD)MCXX,$1)$(call WRAP_CC_COMPILER,$(call $3,$2,$1,$4/MP $(CXXFLAGS)),,$1)
CALL_MPCC  = $(call SUP,$(TMD)MPCC,$1)$(call WRAP_CC_COMPILER,$(call $3,$2,$1,$4/MP /Yu$5 /Fp$2$(basename \
  $(notdir $5))_c.pch /FI$5 $(CFLAGS)),,$1)
CALL_MPCXX = $(call SUP,$(TMD)MPCXX,$1)$(call WRAP_CC_COMPILER,$(call $3,$2,$1,$4/MP /Yu$5 /Fp$2$(basename \
  $(notdir $5))_cpp.pch /FI$5 $(CXXFLAGS)),,$1)

# $1 - outdir/
# $2 - compiler (CMN_RCL or CMN_SCL)
# $3 - aux compiler flags
# $4 - pch header
# $5 - non-pch C
# $6 - non-pch CXX
# $7 - pch C
# $8 - pch CXX
# target-specific: TMD, CFLAGS, CXXFLAGS
CMN_MCL2 = $(if \
  $5,$(call xcmd,CALL_MCC,$5,$(MCL_MAX_COUNT),$1,$2,$3,$4)$(newline))$(if \
  $6,$(call xcmd,CALL_MCXX,$6,$(MCL_MAX_COUNT),$1,$2,$3,$4)$(newline))$(if \
  $7,$(call xcmd,CALL_MPCC,$7,$(MCL_MAX_COUNT),$1,$2,$3,$4)$(newline))$(if \
  $8,$(call xcmd,CALL_MPCXX,$8,$(MCL_MAX_COUNT),$1,$2,$3,$4)$(newline))

# $1 - outdir/
# $2 - compiler (CMN_RCL or CMN_SCL)
# $3 - aux compiler flags (either empty or '/DUNICODE /D_UNICODE ')
# $4 - C-sources
# $5 - CXX-sources
# target-specific: PCH, WITH_PCH
CMN_MCL1 = $(call CMN_MCL2,$1,$2,$3,$(PCH),$(filter-out $(WITH_PCH),$4),$(filter-out \
  $(WITH_PCH),$5),$(filter $(WITH_PCH),$4),$(filter $(WITH_PCH),$5))

# $1 - outdir/
# $2 - sources
# $3 - aux compiler flags (either empty or '/DUNICODE /D_UNICODE ')
CMN_RMCL  = $(call CMN_MCL1,$1,CMN_RCL,$3,$(filter %.c,$2),$(filter %.cpp,$2))
CMN_SMCL  = $(call CMN_MCL1,$1,CMN_SCL,$3,$(filter %.c,$2),$(filter %.cpp,$2))
CMN_RUMCL = $(call CMN_RMCL,$1,$2,/DUNICODE /D_UNICODE )
CMN_SUMCL = $(call CMN_SMCL,$1,$2,/DUNICODE /D_UNICODE )

# also recompile sources that are dependent on changed sources
# $1 - $(SDEPS) - list of sdeps: <source file>|<dependency1>|<dependency2>|...
FILTER_SDEPS1 = $(if $(filter $(wordlist 2,999999,$1),$?),$(firstword $1))
FILTER_SDEPS = $(foreach d,$1,$(call FILTER_SDEPS1,$(subst |, ,$d)))

# $1 - target EXE, DLL or LIB
# $2 - CMN_RMCL, CMN_SMCL, CMN_RUMCL, CMN_SUMCL
# target-specific: SRC, SDEPS, OBJ_DIR
CMN_MCL = $(call $2,$(OBJ_DIR)/,$(sort $(filter $(SRC),$? $(call FILTER_SDEPS,$(SDEPS)))))

define MULTI_COMPILERS_TEMPLATE
# $$1 - target EXE, DLL or LIB, $$2 - objects (of precompiled headers), target-specific: SRC, OBJ_DIR
LIB_$v_LD = $$(call CMN_MCL,$$1,CMN_$vMCL)$$(call \
  LIB_$v_LD1,$$1,$$2 $$(addprefix $$(OBJ_DIR)/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(SRC))))))
EXE_$v_LD = $$(call CMN_MCL,$$1,CMN_$vMCL)$$(call \
  EXE_$v_LD1,$$1,$$2 $$(addprefix $$(OBJ_DIR)/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(SRC))))))
DLL_$v_LD = $$(call CMN_MCL,$$1,CMN_$vMCL)$$(call \
  DLL_$v_LD1,$$1,$$2 $$(addprefix $$(OBJ_DIR)/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(SRC))))))
# $$1 - target pch object, $$2 - pch-source, $$3 - pch header name
# target-specific: TMD, CFLAGS, CXXFLAGS
PCH_$v_CC  = $$(call SUP,$$(TMD)PCHCC,$$2)$$(call WRAP_CC_COMPILER_DEPS,$$(call CMN_$vCL,$$(dir $$1),$$2,/Yc$$3 /Yl$$(basename \
  $$(notdir $$2)) /Fp$$(dir $$1)$$(basename $$(notdir $$3))_c.pch $$(CFLAGS)),$$1,$$2,UDEPS_INCLUDE_FILTER)
PCH_$v_CXX = $$(call SUP,$$(TMD)PCHCXX,$$2)$$(call WRAP_CC_COMPILER_DEPS,$$(call CMN_$vCL,$$(dir $$1),$$2,/Yc$$3 /Yl$$(basename \
  $$(notdir $$2)) /Fp$$(dir $$1)$$(basename $$(notdir $$3))_cpp.pch $$(CXXFLAGS)),$$1,$$2,UDEPS_INCLUDE_FILTER)
$(empty)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(MULTI_COMPILERS_TEMPLATE)))

# tools colors
MCC_COLOR     := $(CC_COLOR)
MCXX_COLOR    := $(CXX_COLOR)
MPCC_COLOR    := $(MCC_COLOR)
MPCXX_COLOR   := $(MCXX_COLOR)
PCHCC_COLOR   := $(MCC_COLOR)
PCHCXX_COLOR  := $(MCXX_COLOR)
TMCC_COLOR    := $(MCC_COLOR)
TMCXX_COLOR   := $(MCXX_COLOR)
TMPCC_COLOR   := $(MPCC_COLOR)
TMPCXX_COLOR  := $(MPCXX_COLOR)
TPCHCC_COLOR  := $(PCHCC_COLOR)
TPCHCXX_COLOR := $(PCHCXX_COLOR)

endif # !SEQ_BUILD

# tools colors
LINK_COLOR   := $(LD_COLOR)
XLINK_COLOR  := $(LD_COLOR)
LIB_COLOR    := $(AR_COLOR)
TLINK_COLOR  := $(LINK_COLOR)
TXLINK_COLOR := $(XLINK_COLOR)
TLIB_COLOR   := $(LIB_COLOR)


ifdef SEQ_BUILD

# no precompiled headers support in sequential build
PCH_TEMPLATE:=

else # !SEQ_BUILD

# templates to create precompiled header
# note: for now implemented only for multi-source build
# NOTE: $(PCH) - makefile-related path to header to precompile

# $1 - $(call GET_TARGET_NAME,$t)
# $2 - $$(basename $$(notdir $$(TRG_PCH)))
# $t - EXE,LIB,DLL,DRV,KLIB,KDLL
# target-specific: $$(PCH)
define PCH_TEMPLATEt
TRG_PCH      := $(call fixpath,$(PCH))
TRG_WITH_PCH := $(call fixpath,$(WITH_PCH))
PCH_C_SRC    := $(GEN_DIR)/pch/$1_$t_$2_c.c
PCH_CXX_SRC  := $(GEN_DIR)/pch/$1_$t_$2_cpp.cpp
NEEDED_DIRS  += $(GEN_DIR)/pch
$$(PCH_C_SRC) $$(PCH_CXX_SRC): | $(GEN_DIR)/pch
	$(QUIET)echo #include "$$(PCH)" > $$@
$$(call TOCLEAN,$$(if $$(filter %.c,$$(TRG_WITH_PCH)),$$(PCH_C_SRC)) $$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(PCH_CXX_SRC)))
endef

# $1 - $(call GET_TARGET_NAME,$t)
# $2 - $$(basename $$(notdir $$(TRG_PCH)))
# $3 - $(call FORM_TRG,$t,$v)
# $4 - $(call FORM_OBJ_DIR,$t,$v)
# $5 - K or <empty>
# $t - EXE,LIB,DLL,DRV,KLIB,KDLL
# $v - R,S,RU,SU
# note: $$(PCH_OBJS) will be built before link phase - before sources are compiled with MCL
define PCH_TEMPLATEv
PCH_C_OBJ := $4/$1_$t_$2_c$(OBJ_SUFFIX)
PCH_CXX_OBJ := $4/$1_$t_$2_cpp$(OBJ_SUFFIX)
PCH_OBJS := $$(if $$(filter %.c,$$(TRG_WITH_PCH)),$$(PCH_C_OBJ)) $$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(PCH_CXX_OBJ))
$3: PCH := $$(TRG_PCH)
$3: WITH_PCH := $$(TRG_WITH_PCH)
$3: $$(PCH_OBJS)
$$(PCH_C_OBJ): $$(PCH_C_SRC) $$(TRG_PCH) | $4 $$(ORDER_DEPS)
	$$(call PCH_$v_$5CC,$$@,$$<,$$(PCH))
$$(PCH_CXX_OBJ): $$(PCH_CXX_SRC) $$(TRG_PCH) | $4 $$(ORDER_DEPS)
	$$(call PCH_$v_$5CXX,$$@,$$<,$$(PCH))
ifndef NO_DEPS
-include $$(addprefix $4/,$$(if \
  $$(filter %.c,$$(TRG_WITH_PCH)),$$(basename $$(notdir $$(PCH_C_SRC))).d) $$(if \
  $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(basename $$(notdir $$(PCH_CXX_SRC))).d))
endif
$$(call TOCLEAN,$$(PCH_OBJS))
$$(call TOCLEAN,$$(if $$(filter %.c,$$(TRG_WITH_PCH)),$4/$2_c.pch $4/$$(basename $$(notdir $$(PCH_C_SRC))).d))
$$(call TOCLEAN,$$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$4/$2_cpp.pch $4/$$(basename $$(notdir $$(PCH_CXX_SRC))).d))
endef

# $1 - $(call GET_TARGET_NAME,$t)
# $2 - $$(basename $$(notdir $$(TRG_PCH)))
# $3 - K or <empty>
# $t - EXE,LIB,DLL,DRV,KLIB,KDLL
PCH_TEMPLATE3 = $(PCH_TEMPLATEt)$(foreach v,$(call GET_VARIANTS,$t),$(newline)$(call \
  PCH_TEMPLATEv,$1,$2,$(call FORM_TRG,$t,$v),$(call FORM_OBJ_DIR,$t,$v),$3))

# $t - EXE,LIB,DLL,DRV,KLIB,KDLL
# note: must reset target-specific WITH_PCH if not using precompiled header, otherwise:
# - DLL or LIB target may inherit WITH_PCH value from EXE,
# - LIB target may inherit WITH_PCH value from DLL
PCH_TEMPLATE = $(if $(word 2,$(PCH) $(WITH_PCH)),$(call PCH_TEMPLATE3,$(call GET_TARGET_NAME,$t),$$(basename \
  $$(notdir $$(TRG_PCH))),$(if $(filter DRV KLIB KDLL,$t),K)),$(call ALL_TARGETS,$t): WITH_PCH:=)

endif # !SEQ_BUILD

# function to add (generated?) sources to $(WITH_PCH) list - to compile sources with pch header
# $1 - EXE,LIB,DLL,...
# $2 - sources
ADD_WITH_PCH = $(eval WITH_PCH += $2)

# auxiliary dependencies

# get dependencies of all sources
ifdef SEQ_BUILD
TRG_ALL_SDEPS:=
else
TRG_ALL_SDEPS = $(call fixpath,$(sort $(foreach d,$(SDEPS),$(wordlist 2,999999,$(subst |, ,$d)))))
endif

# generate import library path
# $1 - built dll name without optional variant suffix
# $2 - built dll variant
MAKE_IMP_PATH = $(LIB_DIR)/$(IMP_PREFIX)$1$(call LIB_VAR_SUFFIX,$2)$(IMP_SUFFIX)

# for DLL or EXE that exports symbols
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(DEF))
# $3 - $(call MAKE_IMP_PATH,$n,$v)
# $t - EXE,DLL,DRV or KDLL
# $n - $(call GET_TARGET_NAME,$t)
ifndef TOCLEAN
define EXPORTS_TEMPLATEn
$1: IMP := $3
$1: DEF := $2
$1: $2 | $(LIB_DIR)
NEEDED_DIRS += $(LIB_DIR)
$3: $1
endef
else ifdef DEBUG
# cleanup generated .exp file in debug
EXPORTS_TEMPLATEn = $(call TOCLEAN,$3 $(3:$(IMP_SUFFIX)=.exp))
else
EXPORTS_TEMPLATEn:=
endif

# for DLL or EXE that do not exports symbols
# $1 - $(call FORM_TRG,$t,$v)
# $t - EXE,DLL,DRV or KDLL
# $n - $(call GET_TARGET_NAME,$t)
ifndef TOCLEAN
define NO_EXPORTS_TEMPLATE
$1: IMP:=
$1: DEF:=
endef
else
NO_EXPORTS_TEMPLATE:=
endif

# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(DEF))
# $3 - non-<empty> if target exports symbols, <empty> - otherwise
# $t - EXE,DLL,DRV or KDLL
# $n - $(call GET_TARGET_NAME,$t)
# $v - R,S
EXPORTS_TEMPLATE = $(if $3,$(call EXPORTS_TEMPLATEn,$1,$2,$(call MAKE_IMP_PATH,$n,$v)),$(NO_EXPORTS_TEMPLATE))

# add dependency on sources for the target,
# define target-specific variables: SRC, SDEPS, OBJ_DIR
# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $3 - $(TRG_ALL_SDEPS)
# $4 - $(call FORM_TRG,$t,$v)
# $5 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,DRV or KDLL
# $v - R,S
ifndef SEQ_BUILD
define MULTISOURCE_AUX
$(empty)
$4: SRC := $1
$4: SDEPS := $2
$4: OBJ_DIR := $5
$4: $1 $3 | $5
endef
endif

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $3 - $(TRG_ALL_SDEPS)
# $4 - $(call FORM_TRG,$t,$v)
# $5 - $(call FORM_OBJ_DIR,$t,$v)
# $6 - $(call fixpath,$(DEF))
# $t - EXE,DRV
# $n - $(call GET_TARGET_NAME,$t)
# $v - R,S
define EXE_AUX_TEMPLATEv
$(empty)
$4: MODVER := $(MODVER)
$4: $t_EXPORTS := $($t_EXPORTS)
$(call EXPORTS_TEMPLATE,$4,$6,$($t_EXPORTS))
endef

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $3 - $(TRG_ALL_SDEPS)
# $4 - $(call FORM_TRG,$t,$v)
# $5 - $(call FORM_OBJ_DIR,$t,$v)
# $6 - $(call fixpath,$(DEF))
# $t - DLL,KDLL
# $n - $(call GET_TARGET_NAME,$t)
# $v - R,S
define DLL_AUX_TEMPLATEv
$(empty)
$4: MODVER := $(MODVER)
$4: $t_NO_EXPORTS := $($t_NO_EXPORTS)
$(call EXPORTS_TEMPLATE,$4,$6,$(if $($t_NO_EXPORTS),,1))
endef

# cleanup generated vc*.pdb and .pdb in debug
# define target-specific variables SRC, SDEPS and OBJ_DIR
# $t - EXE,DLL,DRV or KDLL
# $v - R,S
ifdef TOCLEAN
ifdef DEBUG
$(call define_append,EXE_AUX_TEMPLATEv,$$(call TOCLEAN,$$5/vc*.pdb $$(4:$$($$t_SUFFIX)=.pdb)))
$(call define_append,DLL_AUX_TEMPLATEv,$$(call TOCLEAN,$$5/vc*.pdb $$(4:$$($$t_SUFFIX)=.pdb)))
endif
else ifndef SEQ_BUILD
$(call define_append,EXE_AUX_TEMPLATEv,$(value MULTISOURCE_AUX))
$(call define_append,DLL_AUX_TEMPLATEv,$(value MULTISOURCE_AUX))
endif

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $3 - $(TRG_ALL_SDEPS)
# $4 - $(call fixpath,$(DEF))
# $t - EXE,DLL,DRV or KDLL
EXP_AUX_TEMPLATEt = $(foreach n,$(call GET_TARGET_NAME,$t),$(foreach v,$(call GET_VARIANTS,$t),$(call \
  $t_AUX_TEMPLATEv,$1,$2,$3,$(call FORM_TRG,$t,$v),$(call FORM_OBJ_DIR,$t,$v),$4)))

# auxiliary defines for EXE, DLL, DRV or KDLL:
# - standard resource
# - precompiled header
# - target-specific SRC, SDEPS and OBJ_DIR (for CMN_MCL) and IMP (for _LD_TEMPLATE)
# $t - EXE,DLL,DRV or KDLL
define EXP_AUX_TEMPLATE
$(empty)
$(call STD_RES_TEMPLATE,$t)
$(PCH_TEMPLATE)
$(call EXP_AUX_TEMPLATEt,$(TRG_SRC),$(TRG_SDEPS),$(TRG_ALL_SDEPS),$(call fixpath,$(DEF)))
endef

# called by OS_DEFINE_TARGETS
# $t - EXE or DLL
EXE_AUX_TEMPLATE = $(EXP_AUX_TEMPLATE)
DLL_AUX_TEMPLATE = $(EXP_AUX_TEMPLATE)

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $3 - $(TRG_ALL_SDEPS)
# $4 - $(call FORM_TRG,$t,$v)
# $5 - $(call FORM_OBJ_DIR,$t,$v)
# $t - LIB or KLIB
# $v - R,S
# cleanup generated vc*.pdb in debug
ARC_AUX_TEMPLATEv:=
ifdef TOCLEAN
ifdef DEBUG
ARC_AUX_TEMPLATEv = $(call TOCLEAN,$5/vc*.pdb)
endif
else ifndef SEQ_BUILD
ARC_AUX_TEMPLATEv = $(MULTISOURCE_AUX)
endif

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $3 - $(TRG_ALL_SDEPS)
# $t - LIB or KLIB
ARC_AUX_TEMPLATEt= $(foreach v,$(call GET_VARIANTS,$t),$(call \
  ARC_AUX_TEMPLATEv,$1,$2,$3,$(call FORM_TRG,$t,$v),$(call FORM_OBJ_DIR,$t,$v)))

# auxiliary defines for LIB or KLIB:
# - precompiled header
# - target-specific SRC, SDEPS and OBJ_DIR (for CMN_MCL)
# $t - LIB or KLIB
define ARC_AUX_TEMPLATE
$(if $(RES),$(error do not link resource(s) $(RES) into static library $($t): linker will ignore resources in static library))
$(PCH_TEMPLATE)
endef

# $t - LIB or KLIB
ifdef ARC_AUX_TEMPLATEv
$(call define_append,ARC_AUX_TEMPLATE,$(newline)$$(call ARC_AUX_TEMPLATEt,$$(TRG_SRC),$$(TRG_SDEPS),$$(TRG_ALL_SDEPS)))
endif

# called by OS_DEFINE_TARGETS
LIB_AUX_TEMPLATE = $(ARC_AUX_TEMPLATE)
KLIB_AUX_TEMPLATE = $(ARC_AUX_TEMPLATE)

# $1 - $(GEN_DIR)/$(call GET_TARGET_NAME,$t)_$t_MC (for $t - EXE,DLL,...)
# $2 - $(basename $(notdir $3))
# $3 - NTServiceEventLogMsg.mc (either absolute or makefile-related)
# note: clean generated MSG00000.bin included by generated .rc
define ADD_MC_RULE1
MC_H  := $1/$2.h
MC_RC := $1/$2.rc
$$(call MULTI_TARGET,$$(MC_H) $$(MC_RC),$3,$$$$(call MC,$$(MC_H) $$(MC_RC),-h $(ospath) -r $(ospath) $$$$(call ospath,$$$$<)))
$$(call TOCLEAN,$1/*.bin)
endef

# add rule to make auxiliary resource for the target and generate header from .mc-file
# note: defines MC_H and MC_RC variables - absolute pathnames to generated .h and .rc files
# note: in target makefile may $(call ADD_RES_RULE,TRG,$(MC_RC)) to add .res-file compiled from $(MC_RC) to a target
# $1 - EXE,DLL,...
# $2 - NTServiceEventLogMsg.mc (either absolute or makefile-related)
ADD_MC_RULE = $(eval $(call ADD_MC_RULE1,$(GEN_DIR)/$(call GET_TARGET_NAME,$1)_$1_MC,$(basename $(notdir $2)),$2))

# rules to build auxiliary resources
CB_WINXX_RES_RULES:=

# add rule to make auxiliary res for the target
# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional deps for .res
# $5 - $(call FORM_OBJ_DIR,$1)
# $6 - $5/$(basename $(notdir $2)).res
# NOTE: EXE,DLL,...-target dependency on generated resource file is added in $(STD_RES_TEMPLATE) (see ADD_RES_TEMPLATE macro)
# NOTE: generated .res is added to CLEAN list in $(OS_DEFINE_TARGETS) via $(RES)
# NOTE: postpone expansion of ORDER_DEPS - $(FIX_ORDER_DEPS) changes $(ORDER_DEPS) value
define ADD_RES_RULE2
$(FIX_ORDER_DEPS)
NEEDED_DIRS += $5
$6: $(call fixpath,$2 $4) | $5 $$(ORDER_DEPS)
	$$(call RC,$$@,$$<,$3)
RES += $6
endef

# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional deps for .res
# $5 - $(call FORM_OBJ_DIR,$1)
ADD_RES_RULE1 = $(call ADD_RES_RULE2,$1,$2,$3,$4,$5,$5/$(basename $(notdir $2)).res)

# add rule to make auxiliary res for the target
# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional deps for .res
ADD_RES_RULE = $(eval define CB_WINXX_RES_RULES$(newline)$(if $(value CB_WINXX_RES_RULES),,CB_WINXX_RES_RULES:=$(newline))$(value \
  CB_WINXX_RES_RULES)$(newline)$(call ADD_RES_RULE1,$1,$2,$3,$4,$(call FORM_OBJ_DIR,$1))$(newline)endef)

# used to specify path to some resource for rc.exe via /DMY_BMP=$(call RC_DEFINE_PATH,$(TOP)/xx/yy/tt.bmp)
RC_DEFINE_PATH = "\"$(subst \,\\,$(ospath))\""

# initial reset
NO_STD_RES:=
DLL_NO_EXPORTS:=
EXE_EXPORTS:=
DRV_EXPORTS:=
KDLL_NO_EXPORTS:=

# this code is evaluated from $(DEFINE_TARGETS)
# NOTE: $(STD_RES_TEMPLATE) adds standard resource to RES, so postpone evaluation of $(RES) when adding it to CLEAN
# NOTE: reset NO_STD_RES      - it may be temporary set to disable adding standard resource to the target
# NOTE: reset DLL_NO_EXPORTS  - it may be defined to pass check that DLL must export symbols
# NOTE: reset EXE_EXPORTS     - it may be defined to strip-off diagnostic linker message about exe-exported symbols
# NOTE: reset DRV_EXPORTS     - it may be defined to strip-off diagnostic linker message about drv-exported symbols
# NOTE: reset KDLL_NO_EXPORTS - it may be defined to pass check that KDLL must export symbols
define OS_DEFINE_TARGETS
$(value CB_WINXX_RES_RULES)
$(foreach t,$(BLD_TARGETS),$(if $($t),$($t_AUX_TEMPLATE)))
NO_STD_RES:=
DLL_NO_EXPORTS:=
EXE_EXPORTS:=
DRV_EXPORTS:=
KDLL_NO_EXPORTS:=
endef

# cleanup $(RES)
ifdef TOCLEAN
$(call define_append,OS_DEFINE_TARGETS,$(newline)$$$$(call TOCLEAN,$$$$(RES)))
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,MCL_MAX_COUNT SEQ_BUILD YASMC FLEXC BISONC YASM_FLAGS NO_WRAP \
  MC_STRIP_STRINGS WRAP_MC MC MC_COLOR TMC_COLOR \
  RC_LOGO_STRINGS WRAP_RC RC RC_COLOR TRC_COLOR \
  KIMP_PREFIX KIMP_SUFFIX CHECK_LIB_UNI_NAME1=v CHECK_LIB_UNI_NAME=v DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE \
  EMBED_MANIFEST_OPTION EMBED_EXE_MANIFEST=TMD EMBED_DLL_MANIFEST OS_PREDEFINES MK_MAJ_MIN_VER DEF_LIB_LDFLAGS LIB_LD_TEMPLATE=v \
  CMN_LIBS_LDFLAGS CMN_LIBS=v DEF_SUBSYSTEM \
  LINKER_STRIP_STRINGS_en LINKER_STRIP_STRINGS_ru_cp1251 LINKER_STRIP_STRINGS_ru_cp1251_as_cp866_to_cp1251 \
  LINKER_STRIP_STRINGS WRAP_LINKER DEL_DEF_MANIFEST_ON_FAIL \
  WRAP_EXE_EXPORTS_LINKER WRAP_EXE_LINKER EXE_LD_TEMPLATE=v WRAP_DLL_EXPORTS_LINKER WRAP_DLL_LINKER DLL_LD_TEMPLATE=v \
  $(foreach v,R $(VARIANTS_FILTER),LIB_$v_LD1 EXE_$v_LD1 DLL_$v_LD1) \
  OS_APP_FLAGS APP_FLAGS OS_APP_DEFINES APP_DEFINES CMN_CL1 CMN_RCL CMN_SCL CMN_RUCL CMN_SUCL WRAP_CC_COMPILER \
  INCLUDING_FILE_PATTERN_en INCLUDING_FILE_PATTERN_ru_utf8 INCLUDING_FILE_PATTERN_ru_utf8_bytes \
  INCLUDING_FILE_PATTERN_ru_cp1251 INCLUDING_FILE_PATTERN_ru_cp1251_bytes \
  INCLUDING_FILE_PATTERN_ru_cp866 INCLUDING_FILE_PATTERN_ru_cp866_bytes \
  INCLUDING_FILE_PATTERN UDEPS_INCLUDE_FILTER SED_DEPS_SCRIPT \
  WRAP_CC_COMPILER_DEPS CMN_CC CMN_CXX SEQ_COMPILERS_TEMPLATE \
  $(foreach v,R $(VARIANTS_FILTER),LIB_$v_CC LIB_$v_CXX EXE_$v_CC EXE_$v_CXX DLL_$v_CC DLL_$v_CXX LIB_$v_LD EXE_$v_LD DLL_$v_LD) \
  CALL_MCC CALL_MCXX CALL_MPCC CALL_MPCXX CMN_MCL2 CMN_MCL1 CMN_RMCL CMN_SMCL CMN_RUMCL CMN_SUMCL \
  FILTER_SDEPS1 FILTER_SDEPS CMN_MCL MULTI_COMPILERS_TEMPLATE \
  $(foreach v,R $(VARIANTS_FILTER),PCH_$v_CC PCH_$v_CXX) \
  MCC_COLOR MCXX_COLOR MPCC_COLOR MPCXX_COLOR PCHCC_COLOR PCHCXX_COLOR \
  TMCC_COLOR TMCXX_COLOR TMPCC_COLOR TMPCXX_COLOR TPCHCC_COLOR TPCHCXX_COLOR \
  LINK_COLOR XLINK_COLOR LIB_COLOR TLINK_COLOR TXLINK_COLOR TLIB_COLOR \
  SUBSYSTEM_KVER DEF_KLIB_LDFLAGS KLIB_R_LD1 DEF_DRV_LDFLAGS CMN_KLIBS DRV_R_LD1 KDLL_R_LD1 \
  OS_KRN_FLAGS FORCE_SYNC_PDB_KERN KRN_FLAGS OS_KRN_DEFINES KRN_DEFINES CMN_KCL KDEPS_INCLUDE_FILTER CMN_KCC CMN_KCXX \
  KLIB_R_CC DRV_R_CC KDLL_R_CC KLIB_R_CXX DRV_R_CXX KDLL_R_CXX KLIB_R_LD DRV_R_LD KDLL_R_LD \
  CALL_MKCC CALL_MKCXX CALL_MPKCC CALL_MPKCXX CMN_MKCL3 CMN_MKCL2 CMN_MKCL1 CMN_MKCL PCH_R_KCC PCH_R_KCXX \
  MKCC_COLOR MKCXX_COLOR MKPCC_COLOR MKPCXX_COLOR \
  KLIB_R_ASM DRV_R_ASM KDLL_R_ASM KLINK_COLOR KLIB_COLOR BISON FLEX BISON_COLOR FLEX_COLOR \
  PCH_TEMPLATEt=t PCH_TEMPLATEv=t;v PCH_TEMPLATE3=t PCH_TEMPLATE=t ADD_WITH_PCH \
  TRG_ALL_SDEPS MAKE_IMP_PATH EXPORTS_TEMPLATEn=t;n;v NO_EXPORTS_TEMPLATE=t;n;v EXPORTS_TEMPLATE=t;n;v MULTISOURCE_AUX=t;v \
  EXE_AUX_TEMPLATEv=t;n;v DLL_AUX_TEMPLATEv=t;n;v EXP_AUX_TEMPLATEt=t EXP_AUX_TEMPLATE=t EXE_AUX_TEMPLATE=t DLL_AUX_TEMPLATE=t \
  ARC_AUX_TEMPLATEv=t;v ARC_AUX_TEMPLATEt=t ARC_AUX_TEMPLATE=t LIB_AUX_TEMPLATE KLIB_AUX_TEMPLATE \
  ADD_MC_RULE1 ADD_MC_RULE ADD_RES_RULE2 ADD_RES_RULE1 ADD_RES_RULE RC_DEFINE_PATH \
  DRV_TEMPLATE=t;DRV;LIB_DIR;KLIBS;KDLLS;SYSLIBS;SYSLIBPATH KDLL_TEMPLATE DRV_AUX_TEMPLATE2 KDLL_AUX_TEMPLATE2 \
  DRV_AUX_TEMPLATEv KDLL_AUX_TEMPLATEv DRV_AUX_TEMPLATE KDLL_AUX_TEMPLATE)
