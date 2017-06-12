#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# reset additional variables
# RES - resources to link to dll or exe
# DEF - linker definitions file (used mostly to list exported symbols)
$(eval define PREPARE_C_VARS$(newline)$(value PREPARE_C_VARS)$(newline)RES:=$(newline)DEF:=$(newline)endef)

# max number of sources to compile with /MP compiler option
# - with too many sources it's possible to exceed maximum command string length
MCL_MAX_COUNT := 50

include $(CLEAN_BUILD_DIR)/WINXX/cres.mk

# run via $(MAKE) S=1 to compile each source individually (without /MP compiler option)
ifeq (command line,$(origin S))
SEQ_BUILD := $(S:0=)
else
SEQ_BUILD:=
endif

# dependencies generation supported only for non-multisource (sequential) builds
# note: do not try to trace calls to NO_DEPS, pass 0 as second parameter to CLEAN_BUILD_PROTECT_VARS
ifndef SEQ_BUILD
NO_DEPS := 1
$(call CLEAN_BUILD_PROTECT_VARS,NO_DEPS,0)
endif

include $(CLEAN_BUILD_DIR)/WINXX/auto_c.mk

# yasm/flex/bison compilers
YASMC  := yasm.exe
FLEXC  := flex.exe
BISONC := bison.exe

# note: assume yasm used only for drivers
YASM_FLAGS := -f $(if $(KCPU:%64=),win32,win64)$(if $(KCPU:x86%=),, -m $(if $(KCPU:%64=),x86,amd64))

# strings to strip off from mc.exe output
# note: may be overridden either in project configuration makefile or in command line
MC_STRIP_STRINGS := MC:?Compiling

# wrap mc.exe call to strip-off diagnostic mc messages
# $1 - mc command with arguments
# note: send mc output to stderr
ifndef MC_STRIP_STRINGS
WRAP_MC = $1 >&2
else
WRAP_MC = (($1 2>&1 && echo TRG_MC_OK >&2) | findstr /V /B /R $(call \
  qpath,$(MC_STRIP_STRINGS),/C:)) 3>&2 2>&1 1>&3 | findstr /B /L TRG_MC_OK >NUL
endif

# message compiler
# $1 - generated .rc and .h
# $2 - arguments for mc.exe
# target-specific: TMD
MC = $(call SUP,$(TMD)MC,$1)$(call WRAP_MC,$($(TMD)MC1)$(if $(VERBOSE), -v) $2)

# strings to strip off from rc.exe output if rc.exe does not support /nologo option
# note: may be overridden either in project configuration makefile or in command line
RC_LOGO_STRINGS := Microsoft?(R)?Windows?(R)?Resource?Compiler?Version Copyright?(C)?Microsoft?Corporation.??All?rights?reserved. ^$$

# send resource compiler output to stderr
# $1 - rc command with arguments
ifndef RC_LOGO_STRINGS
WRAP_RC = $1 >&2
else ifdef SUPPRESS_RC_LOGO
WRAP_RC = $1 >&2
else
WRAP_RC = (($1 2>&1 && echo RC_COMPILED_OK >&2) | findstr /B /V /R $(call \
  qpath,$(RC_LOGO_STRINGS),/C:)) 3>&2 2>&1 1>&3 | findstr /B /L RC_COMPILED_OK >NUL
endif

# resource compiler
# $1 - target .res
# $2 - source .rc
# $3 - rc compiler options
# target-specific: TMD
RC = $(call SUP,$(TMD)RC,$1)$(call WRAP_RC,$($(TMD)RC1) $(SUPPRESS_RC_LOGO)$(if \
  $(VERBOSE), /v) $3 $(call qpath,$(VS$(TMD)INC) $(UM$(TMD)INC),/I) /fo$(call ospath,$1 $2))

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

# kernel-mode static library prefix/suffix
KLIB_PREFIX:=
KLIB_SUFFIX := .ka

# dynamically loaded kernel shared library prefix/suffix
KDLL_PREFIX:=
KDLL_SUFFIX := .sys

# import library for kernel dll prefix/suffix
KIMP_PREFIX:=
KIMP_SUFFIX := .lib

# kernel module (driver) prefix/suffix
DRV_PREFIX := drv
DRV_SUFFIX := .sys

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

# check that library name built as RU/SU variant is started with UNI_ prefix
# $1 - library name
# $v - variant name: RU,SU
CHECK_LIB_UNI_NAME1 = $(if $(filter-out UNI_%,$1),$(error library '$1' name must start with UNI_ prefix to build it as $v variant))

# check that library name built as RU/SU variant is started with UNI_ prefix
# $1 - IMP or LIB
# $v - variant name: R,S,RU,SU
# note: $$1 - target library name
CHECK_LIB_UNI_NAME = $(if $(filter %U,$v),$$(call CHECK_LIB_UNI_NAME1,$$(patsubst \
  %$(call LIB_VAR_SUFFIX,$v)$($1_SUFFIX),%,$$(notdir $$1))))

# how to mark exported symbols from a DLL
DLL_EXPORTS_DEFINE := "__declspec(dllexport)"

# how to mark imported symbols from a DLL
DLL_IMPORTS_DEFINE := "__declspec(dllimport)"

# helper macro for target makefiles to pass string define value to C-compiler
# result of this macro will be processed by SUBST_DEFINES
# note: override value from $(CLEAN_BUILD_DIR)/c.mk
STRING_DEFINE = "$(subst ","",$(subst $(comment),$$(comment),$(subst $(space),$$(space),$(subst $$,$$$$,$1))))"

# how to embed manifest into executable or dll
# Note: starting from Visual Studio 2012, linker supports /MANIFEST:EMBED option - linker will call mt.exe internally
EMBED_MANIFEST_OPTION:=

ifndef EMBED_MANIFEST_OPTION
# target-specific: TMD
EMBED_EXE_MANIFEST = $(newline)$(QUIET)if exist $(ospath).manifest ($($(TMD)MT1) -nologo -manifest \
  $(ospath).manifest -outputresource:$(ospath);1 && del $(ospath).manifest)$(DEL_ON_FAIL)
EMBED_DLL_MANIFEST = $(newline)$(QUIET)if exist $(ospath).manifest ($($(TMD)MT1) -nologo -manifest \
  $(ospath).manifest -outputresource:$(ospath);2 && del $(ospath).manifest)$(DEL_ON_FAIL)
else
# reset
EMBED_EXE_MANIFEST:=
EMBED_DLL_MANIFEST:=
endif

# standard defines
# for example, WINVER_DEFINES = WINVER=0x0501 _WIN32_WINNT=0x0501
OS_PREDEFINES := $(WINVARIANT) $(WINVER_DEFINES)

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

# default subsystem for EXE or DLL
# $$1 - target EXE or DLL
# $$2 - objects
# $v - variant
# note: do not add /SUBSYSTEM option if $(LDFLAGS) have already specified one
# target-specific: LDFLAGS, TMD
DEF_SUBSYSTEM = $$(if $$(filter /SUBSYSTEM:%,$$(LDFLAGS)),,/SUBSYSTEM:CONSOLE$(if $$(TMD),,,$(SUBSYSTEM_VER)))

# strings to strip off from link.exe output
LINKER_STRIP_STRINGS_en := Generating?code Finished?generating?code
# cp1251 ".Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð° .Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð°?Ð·Ð°Ð²ÐµÑ€ÑˆÐµÐ½Ð¾"
LINKER_STRIP_STRINGS_ru_cp1251 := .îçäàíèå?êîäà .îçäàíèå?êîäà?çàâåðøåíî
# cp1251 ".Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð° .Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð°?Ð·Ð°Ð²ÐµÑ€ÑˆÐµÐ½Ð¾" as cp866 converted to cp1251
LINKER_STRIP_STRINGS_ru_cp1251_as_cp866_to_cp1251 := .þ÷ôðýøõ?úþôð .þ÷ôðýøõ?úþôð?÷ðòõ¨°õýþ
# default value, may be overridden either in project configuration makefile or in command line
LINKER_STRIP_STRINGS := $(LINKER_STRIP_STRINGS_en)

# wrap linker call to strip-off diagnostic linker messages
# $1 - linker command with arguments
# note: if not $(DEBUG), then send linker output to stderr
ifdef DEBUG
WRAP_LINKER = $1
else ifndef LINKER_STRIP_STRINGS
WRAP_LINKER = $1 >&2
else
WRAP_LINKER = (($1 2>&1 && echo TRG_LINKED_OK >&2) | findstr /V /B /R $(call \
  qpath,$(LINKER_STRIP_STRINGS),/C:)) 3>&2 2>&1 1>&3 | findstr /B /L TRG_LINKED_OK >NUL
endif

# Link.exe has a bug/feature:
# - it may not delete target exe/dll if DEF was specified and were errors while building the exe/dll
# - also it will not delete generated manifest file if failed to build target exe/dll
# $1 - target EXE or DLL
# $2 - $(EMBED_EXE_MANIFEST) or $(EMBED_DLL_MANIFEST)
# target-specific: DEF
DEL_DEF_MANIFEST_ON_FAIL = $(if $(DEF)$2,$(call DEL_ON_FAIL,$(if $(DEF),$1) $(if $2,$1.manifest)))$2

# call exe/drv linker and strip-off message about generated .exp-file
# $1 - target EXE or DLL
# $2 - (wrapped) linker with options
# $3 - $(basename $(notdir $(IMP))).exp
# note: send linker output to stderr
WRAP_EXE_EXPORTS_LINKER = (($(if $(DEBUG),$2 2>&1,($2) 3>&2 2>&1 1>&3) && echo EXE_EXP_LINKED_OK >&2) | \
  findstr /V /L $3) 3>&2 2>&1 1>&3 | findstr /B /L EXE_EXP_LINKED_OK >NUL

# wrap exe/drv linker call to strip-off message about generated .exp-file
# $1 - non-<empty> if exe/drv exports symbols, <empty> - otherwise
# $2 - target EXE or DLL
# $3 - (wrapped) linker with options
# target-specific: IMP
# note: send linker output to stderr
WRAP_EXE_LINKER = $(if $1,$(call WRAP_EXE_EXPORTS_LINKER,$2,$3,$(basename $(notdir $(IMP))).exp),$3$(if $(DEBUG), >&2))

# define EXE linker for variant $v
# $$1 - target EXE
# $$2 - objects
# $v - variant
# target-specific: TMD, LDFLAGS, IMP, EXE_EXPORTS
define EXE_LD_TEMPLATE
$(empty)
EXE_$v_LD1 = $$(call SUP,$$(TMD)XLINK,$$1)$$(call WRAP_EXE_LINKER,$$(EXE_EXPORTS),$$1,$$(call \
  WRAP_LINKER,$$(VS$$(TMD)LD) /nologo $(CMN_LIBS) $$(if $$(EXE_EXPORTS),/IMPLIB:$$(call \
  ospath,$$(IMP))) $(DEF_SUBSYSTEM) $(EMBED_MANIFEST_OPTION) $$(LDFLAGS)))$$(call \
  DEL_DEF_MANIFEST_ON_FAIL,$$1,$$(EMBED_EXE_MANIFEST))
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(EXE_LD_TEMPLATE)))

# call dll linker and check that dll exports symbols, then strip-off message about generated .exp-file
# $1 - target DLL or KDLL
# $2 - (wrapped) linker with options
# $3 - $(basename $(notdir $(IMP))).exp
# target-specific: LIB_DIR
# note: send linker output to stderr
WRAP_DLL_EXPORTS_LINKER = (($(if $(DEBUG),$2 2>&1,($2) 3>&2 2>&1 1>&3) && (dir $(call ospath,$(LIB_DIR)/$3) >NUL 2>&1 || \
  ((echo $(notdir $1) does not exports any symbols!) & del $(ospath) & exit /b 1)) && echo DLL_EXP_LINKED_OK >&2) | \
  findstr /V /L $3) 3>&2 2>&1 1>&3 | findstr /B /L DLL_EXP_LINKED_OK >NUL

# wrap dll linker call to check that dll exports symbols, then strip-off message about .exp-file
# $1 - non-<empty> if dll/kdll do not exports symbols, <empty> - otherwise
# $2 - target DLL or KDLL
# $3 - (wrapped) linker with options
# target-specific: IMP
# note: send linker output to stderr
WRAP_DLL_LINKER = $(if $1,$3$(if $(DEBUG), >&2),$(call WRAP_DLL_EXPORTS_LINKER,$2,$3,$(basename $(notdir $(IMP))).exp))

# define DLL linker for variant $v
# $$1 - target DLL
# $$2 - objects
# $v - variant
# target-specific: TMD, LDFLAGS, IMP, DLL_NO_EXPORTS
# note: send linker output to stderr
define DLL_LD_TEMPLATE
$(empty)
DLL_$v_LD1 = $$(call SUP,$$(TMD)LINK,$$1)$$(call WRAP_DLL_LINKER,$$(DLL_NO_EXPORTS),$$1,$$(call \
  WRAP_LINKER,$$(VS$$(TMD)LD) /nologo /DLL $(CMN_LIBS) $$(if $$(DLL_NO_EXPORTS),,/IMPLIB:$$(call \
  ospath,$$(IMP))) $(DEF_SUBSYSTEM) $(EMBED_MANIFEST_OPTION) $$(LDFLAGS)))$$(call \
  DEL_DEF_MANIFEST_ON_FAIL,$$1,$$(EMBED_DLL_MANIFEST))
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(DLL_LD_TEMPLATE)))

# flags for application-level C-compiler
OS_APP_CFLAGS := /X /GF /W3 /EHsc
ifdef DEBUG
OS_APP_CFLAGS += /Od /Zi /RTCc /RTCsu /GS
else
OS_APP_CFLAGS += /Ox /GL /Gy
endif

ifneq (,$(call is_less,10,$(VS_VER)))
# >= Visual Studio 2012
ifdef DEBUG
OS_APP_CFLAGS += /sdl # Enable additional security checks
endif
endif

ifneq (,$(call is_less,11,$(VS_VER)))
# >= Visual Studio 2013
OS_APP_CFLAGS += /Zc:inline # Remove unreferenced COMDAT
OS_APP_CFLAGS += /Zc:strictStrings # Disable string literal type conversion
OS_APP_CFLAGS += /Zc:rvalueCast # Enforce type conversion rules
endif

ifneq (,$(call is_less,13,$(VS_VER)))
# >= Visual Studio 2015
ifdef DEBUG
OS_APP_CFLAGS += /D_ALLOW_RTCc_IN_STL
endif
endif

ifdef SEQ_BUILD

# option for parallel builds, starting from Visual Studio 2013
ifdef FORCE_SYNC_PDB
OS_APP_CFLAGS += $(FORCE_SYNC_PDB) #/FS
endif

endif # SEQ_BUILD

# APP_CFLAGS may be overridden in project makefile
APP_CFLAGS := $(OS_APP_CFLAGS)

# application-level defines
# note: some external sources want WIN32 to be defined
OS_APP_DEFINES := WIN32 CRT_SECURE_NO_DEPRECATE _CRT_SECURE_NO_WARNINGS

ifneq (,$(call is_less,$(VS_VER),14))
OS_APP_DEFINES += inline=__inline
endif

# APP_DEFINES may be overridden in project makefile
APP_DEFINES := $(OS_PREDEFINES) $(OS_APP_DEFINES)

# call C compiler
# $1 - outdir/
# $2 - sources
# $3 - flags
# target-specific: TMD, DEFINES, INCLUDE
CMN_CL1 = $(VS$(TMD)CL) /nologo /c $(APP_CFLAGS) $(call SUBST_DEFINES,$(addprefix /D,$(APP_DEFINES) $(DEFINES))) $(call \
  qpath,$(call ospath,$(INCLUDE)) $(VS$(TMD)INC) $(UM$(TMD)INC),/I) /Fo$(ospath) /Fd$(ospath) $3 $(call ospath,$2)

# C compilers for different variants (R,S,RU,SU)
# $1 - outdir/
# $2 - sources
# $3 - flags
CMN_RCL  = $(CMN_CL1) /MD$(if $(DEBUG),d)
CMN_SCL  = $(CMN_CL1) /MT$(if $(DEBUG),d)
CMN_RUCL = $(CMN_RCL) /DUNICODE /D_UNICODE
CMN_SUCL = $(CMN_SCL) /DUNICODE /D_UNICODE

# $(SED) expression to match C compiler messages about included files
INCLUDING_FILE_PATTERN_en := Note: including file:
# utf8 "ÐŸÑ€Ð¸Ð¼ÐµÑ‡Ð°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ Ñ„Ð°Ð¹Ð»Ð°:"
INCLUDING_FILE_PATTERN_ru_utf8 := ÐŸÑ€Ð¸Ð¼ÐµÑ‡Ð°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ Ñ„Ð°Ð¹Ð»Ð°:
INCLUDING_FILE_PATTERN_ru_utf8_bytes := \xd0\x9f\xd1\x80\xd0\xb8\xd0\xbc\xd0\xb5\xd1\x87\xd0\xb0\xd0\xbd\xd0\xb8\xd0\xb5: \xd0\xb2\xd0\xba\xd0\xbb\xd1\x8e\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5 \xd1\x84\xd0\xb0\xd0\xb9\xd0\xbb\xd0\xb0:
# cp1251 "ÐŸÑ€Ð¸Ð¼ÐµÑ‡Ð°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ Ñ„Ð°Ð¹Ð»Ð°:"
INCLUDING_FILE_PATTERN_ru_cp1251 := Ïðèìå÷àíèå: âêëþ÷åíèå ôàéëà:
INCLUDING_FILE_PATTERN_ru_cp1251_bytes := \xcf\xf0\xe8\xec\xe5\xf7\xe0\xed\xe8\xe5: \xe2\xea\xeb\xfe\xf7\xe5\xed\xe8\xe5 \xf4\xe0\xe9\xeb\xe0:
# cp866 "ÐŸÑ€Ð¸Ð¼ÐµÑ‡Ð°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ Ñ„Ð°Ð¹Ð»Ð°:"
INCLUDING_FILE_PATTERN_ru_cp866 := à¨¬¥ç ­¨¥: ¢ª«îç¥­¨¥ ä ©« :
INCLUDING_FILE_PATTERN_ru_cp866_bytes := \x8f\xe0\xa8\xac\xa5\xe7\xa0\xad\xa8\xa5: \xa2\xaa\xab\xee\xe7\xa5\xad\xa8\xa5 \xe4\xa0\xa9\xab\xa0:
# default value, may be overridden either in project configuration makefile or in command line
INCLUDING_FILE_PATTERN := $(INCLUDING_FILE_PATTERN_en)

# $(SED) expression to filter-out system files while dependencies generation
# note: may be overridden either in project configuration makefile or in command line
# c:\\program?files?(x86)\\microsoft?visual?studio?10.0\\vc\\include\\
UDEPS_INCLUDE_FILTER := $(subst \,\\,$(VSINC) $(UMINC))

# $(SED) script to generate dependencies file from C compiler output
# $2 - target object file
# $3 - source
# $4 - $(basename $2).d
# $5 - prefixes of system includes to filter out

# s/\x0d//;                                - fix line endings - remove CR
# /^$(notdir $3)$$/d;                      - delete compiled file name printed by cl, start new circle
# /^$(INCLUDING_FILE_PATTERN) /!{p;d;}     - print all lines not started with $(INCLUDING_FILE_PATTERN) and space, start new circle
# s/^$(INCLUDING_FILE_PATTERN)  *//;       - strip-off leading $(INCLUDING_FILE_PATTERN) with spaces
# $(subst ?, ,$(foreach x,$5,\@^$x.*@Id;)) - delete lines started with system include paths, start new circle
# s/ /\\ /g;                               - escape spaces in included file path
# s@.*@&:\n$2: &@;w $4                     - make dependencies, then write to generated dep-file

SED_DEPS_SCRIPT = \
-e "s/\x0d//;/^$(notdir $3)$$/d;/^$(INCLUDING_FILE_PATTERN) /!{p;d;}" \
-e "s/^$(INCLUDING_FILE_PATTERN)  *//;$(subst ?, ,$(foreach x,$5,\@^$x.*@Id;))s/ /\\ /g;s@.*@&:\n$2: &@;w $4"

# WRAP_COMPILER - call compiler and auto-generate dependencies
WRAP_COMPILER:=

# $1 - compiler with options
# $2 - target object file
# $3 - source
# $4 - $(basename $2).d
# $5 - prefixes of system includes
# note: send compiler output to stderr
ifndef NO_DEPS
ifdef SEQ_BUILD
WRAP_COMPILER = (($1 /showIncludes 2>&1 && set /p ="COMPILATION_OK" >&2 <NUL) | \
  ($(SED) -n $(SED_DEPS_SCRIPT) 2>&1 && set /p ="_SED_OK" >&2 <NUL)) 3>&2 2>&1 1>&3 | findstr /B /L COMPILATION_OK_SED_OK >NUL
endif
endif

ifndef WRAP_COMPILER
# if not generating auto-dependencies, just stip-off names of compiled sources
# $1 - compiler with options
# $3 - sources
# note: send compiler output to stderr
WRAP_COMPILER = (($1 2>&1 && echo COMPILATION_OK >&2) | findstr /V /X /L "$(notdir \
  $3)") 3>&2 2>&1 1>&3 | findstr /B /L COMPILATION_OK >NUL
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
# note: auto-dependencies generation available only in sequential mode - /MP conflicts with /showIncludes
# note: precompiled headers are not supported in this mode (but support may be added later)

# common C/C++ compiler
# $1 - target object file
# $2 - source
# $3 - compiler
# target-specific: TMD, CFLAGS, CXXFLAGS
CMN_CC = $(call SUP,$(TMD)CC,$2)$(call WRAP_COMPILER,$(call $3,$(dir $1),$2,$(CFLAGS)),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))
CMN_CXX = $(call SUP,$(TMD)CXX,$2)$(call WRAP_COMPILER,$(call $3,$(dir $1),$2,$(CXXFLAGS)),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

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
# note: there is support for precompiled headers in this mode

# $1 - sources
# $2 - outdir/
# $3 - compiler (CMN_RCL or CMN_SCL)
# $4 - aux compiler flags
# $5 - pch header
# target-specific: TMD, CFLAGS, CXXFLAGS
CALL_MCC   = $(call SUP,$(TMD)MCC,$1)$(call WRAP_COMPILER,$(call $3,$2,$1,$4/MP $(CFLAGS)),,$1)
CALL_MCXX  = $(call SUP,$(TMD)MCXX,$1)$(call WRAP_COMPILER,$(call $3,$2,$1,$4/MP $(CXXFLAGS)),,$1)
CALL_MPCC  = $(call SUP,$(TMD)MPCC,$1)$(call WRAP_COMPILER,$(call $3,$2,$1,$4/MP /Yu$5 /Fp$2$(basename \
  $(notdir $5))_c.pch /FI$5 $(CFLAGS)),,$1)
CALL_MPCXX = $(call SUP,$(TMD)MPCXX,$1)$(call WRAP_COMPILER,$(call $3,$2,$1,$4/MP /Yu$5 /Fp$2$(basename \
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
# $$1 - target EXE, DLL or LIB, target-specific: SRC, OBJ_DIR
LIB_$v_LD = $$(call CMN_MCL,$$1,CMN_$vMCL)$$(call \
  LIB_$v_LD1,$$1,$$(addprefix $$(OBJ_DIR)/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(SRC))))))
EXE_$v_LD = $$(call CMN_MCL,$$1,CMN_$vMCL)$$(call \
  EXE_$v_LD1,$$1,$$(addprefix $$(OBJ_DIR)/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(SRC))))))
DLL_$v_LD = $$(call CMN_MCL,$$1,CMN_$vMCL)$$(call \
  DLL_$v_LD1,$$1,$$(addprefix $$(OBJ_DIR)/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(SRC))))))
# $$1 - target pch object, $$2 - pch-source, $$3 - pch header name
# target-specific: TMD, CFLAGS, CXXFLAGS
PCH_$v_CC  = $$(call SUP,$$(TMD)PCHCC,$$2)$$(call WRAP_COMPILER,$$(call CMN_$vCL,$$(dir $$1),$$2,/Yc$$3 /Yl$$(basename \
  $$(notdir $$2)) /Fp$$(dir $$1)$$(basename $$(notdir $$3))_c.pch $$(CFLAGS)),$$1,$$2,$$(basename $$1).d,$(UDEPS_INCLUDE_FILTER))
PCH_$v_CXX = $$(call SUP,$$(TMD)PCHCXX,$$2)$$(call WRAP_COMPILER,$$(call CMN_$vCL,$$(dir $$1),$$2,/Yc$$3 /Yl$$(basename \
  $$(notdir $$2)) /Fp$$(dir $$1)$$(basename $$(notdir $$3))_cpp.pch $$(CXXFLAGS)),$$1,$$2,$$(basename $$1).d,$(UDEPS_INCLUDE_FILTER))
$(empty)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(MULTI_COMPILERS_TEMPLATE)))

endif # !SEQ_BUILD

ifdef DRIVERS_SUPPORT

# SUBSYSTEM for kernel mode
SUBSYSTEM_KVER := $(SUBSYSTEM_VER)

# default linker flags for KLIB
# $1 - target KLIB
# $2 - objects
DEF_KLIB_LDFLAGS := $(if $(DEBUG),,/LTCG)

# define KLIB linker
# $1 - target KLIB
# $2 - objects
# target-specific: LDFLAGS
# note: send linker stdout to stderr
KLIB_R_LD1 = $(call SUP,KLIB,$1)$(WKLD) /lib /nologo /OUT:$(call ospath,$1 $2) $(DEF_KLIB_LDFLAGS) $(LDFLAGS) >&2

DEF_DRV_LDFLAGS = \
  /kernel /INCREMENTAL:NO $(if $(DEBUG),/DEBUG,/RELEASE /LTCG /OPT:REF) /DRIVER /FULLBUILD \
  /NODEFAULTLIB /SAFESEH:NO /MANIFEST:NO /MERGE:_PAGE=PAGE /MERGE:_TEXT=.text /MERGE:.rdata=.text \
  /SECTION:INIT,d /ENTRY:DriverEntry$(if $(KCPU:%64=),@8) /ALIGN:0x40 /BASE:0x10000 /STACK:0x40000,0x1000 \
  /MACHINE:$(if $(KCPU:%64=),x86,x64) /SUBSYSTEM:NATIVE,$(SUBSYSTEM_KVER)

# common parts of linker options for built DRV or KDLL
# $1 - target EXE or DLL
# $2 - objects
# $v - variant: R
# target-specific: MODVER, DEF, RES, LIBS, KDLLS, LIB_DIR, SYSLIBPATH, SYSLIBS
CMN_KLIBS = /OUT:$(ospath) /VERSION:$(call MK_MAJ_MIN_VER,$(MODVER)) $(addprefix \
  /DEF:,$(call ospath,$(DEF))) $(DEF_DRV_LDFLAGS) $(call ospath,$2 $(RES)) $(if \
  $(firstword $(KLIBS)$(KDLLS)),/LIBPATH:$(call ospath,$(LIB_DIR))) $(addprefix \
  $(KLIB_PREFIX),$(KLIBS:=$(KLIB_SUFFIX))) $(addprefix $(KIMP_PREFIX),$(KDLLS:=$(KIMP_SUFFIX))) $(call \
  qpath,$(call ospath,$(SYSLIBPATH)),/LIBPATH:) $(SYSLIBS)

# define DRV linker
# $1 - target DRV
# $2 - objects
# $v - variant: R
# target-specific: MODVER, RES, KLIBS, SYSLIBPATH, SYSLIBS, LDFLAGS, DEF, IMP, DRV_EXPORTS
# note: send linker output to stderr
DRV_R_LD1 = $(call SUP,KLINK,$1)$(call WRAP_EXE_LINKER,$(DRV_EXPORTS),$1,$(call \
  WRAP_LINKER,$(WKLD) /nologo $(CMN_KLIBS) $(if $(DRV_EXPORTS),/IMPLIB:$(call ospath,$(IMP))) $(LDFLAGS)))

# define KDLL linker
# $1 - target KDLL
# $2 - objects
# $v - variant: R
# target-specific: DEF, LDFLAGS, IMP, KDLL_NO_EXPORTS
# note: send linker output to stderr
KDLL_R_LD1 = $(call SUP,KLINK,$1)$(call WRAP_DLL_LINKER,$(KDLL_NO_EXPORTS),$1,$(call \
  WRAP_LINKER,$(WKLD) /nologo /DLL $(CMN_KLIBS) $(if $(KDLL_NO_EXPORTS),,/IMPLIB:$(call ospath,$(IMP))) $(LDFLAGS)))

# flags for kernel-level C-compiler
OS_KRN_CFLAGS := /kernel -cbstring /X /GF /W3 /GR- /Gz /Zl /Oi /Zi /Gm- /Zp8 /Gy /Zc:wchar_t-
ifdef DEBUG
OS_KRN_CFLAGS += /GS /Oy- /Od $(if $(KCPU:%64=),,-d2epilogunwind) /d1import_no_registry /d2Zi+
else
OS_KRN_CFLAGS += /GS- /Oy /d1nodatetime
endif

ifneq (,$(call is_less,10,$(VS_VER)))
# >= Visual Studio 2012
ifdef DEBUG
OS_KRN_CFLAGS += /sdl # Enable additional security checks
endif
endif

ifneq (,$(call is_less,11,$(VS_VER)))
# >= Visual Studio 2013
OS_KRN_CFLAGS += /Zc:inline # Remove unreferenced COMDAT
OS_KRN_CFLAGS += /Zc:rvalueCast # Enforce type conversion rules
OS_KRN_CFLAGS += /Zc:strictStrings # Disable string literal type conversion
endif

ifdef SEQ_BUILD

# option for parallel builds, starting from Visual Studio 2013
FORCE_SYNC_PDB_KERN := $(FORCE_SYNC_PDB)

ifdef FORCE_SYNC_PDB_KERN
OS_KRN_CFLAGS += $(FORCE_SYNC_PDB_KERN) #/FS
endif

endif # SEQ_BUILD

# KRN_CFLAGS may be overridden in project makefile
KRN_CFLAGS := $(OS_KRN_CFLAGS)

# kernel-level defines
OS_KRN_DEFINES := WINNT=1 $(if $(DEBUG),DBG=1 MSC_NOOPT DEPRECATE_DDK_FUNCTIONS=1) $(if \
  $(KCPU:%64=),_WIN32 _X86_=1 i386=1 STD_CALL,_WIN64 _AMD64_ AMD64) WIN32_LEAN_AND_MEAN

# KRN_DEFINES may be overridden in project makefile
KRN_DEFINES := $(OS_PREDEFINES) $(OS_KRN_DEFINES)

# call C compiler
# $1 - outdir/
# $2 - sources
# $3 - flags
# target-specific: DEFINES, INCLUDE
CMN_KCL = $(WKCL) /nologo /c $(KRN_CFLAGS) $(call SUBST_DEFINES,$(addprefix /D,$(KRN_DEFINES) $(DEFINES))) $(call \
  qpath,$(call ospath,$(INCLUDE)) $(KMINC),/I) /Fo$(ospath) /Fd$(ospath) $3 $(call ospath,$2)

ifdef SEQ_BUILD

# sequential build: don't add /MP option to Visual Studio C compiler
# note: auto-dependencies generation available only in sequential mode - /MP conflicts with /showIncludes
# note: precompiled headers are not supported in this mode (but support may be added later)

# $(SED) expression to filter-out system files while dependencies generation
# note: may be overridden either in project configuration makefile or in command line
# c:\\winddk\\
KDEPS_INCLUDE_FILTER := $(subst \,\\,$(KMINC))

# common kernel C/C++ compiler
# $1 - target object file
# $2 - source
# target-specific: CFLAGS, CXXFLAGS
CMN_KCC = $(call SUP,KCC,$2)$(call WRAP_COMPILER,$(call CMN_KCL,$(dir $1),$2,$(CFLAGS)),$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))
CMN_KCXX = $(call SUP,KCXX,$2)$(call WRAP_COMPILER,$(call CMN_KCL,$(dir $1),$2,$(CXXFLAGS)),$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))

# $1 - target object file
# $2 - source
KLIB_R_CC  = $(CMN_KCC)
DRV_R_CC   = $(CMN_KCC)
KDLL_R_CC  = $(CMN_KCC)
KLIB_R_CXX = $(CMN_KCXX)
DRV_R_CXX  = $(CMN_KCXX)
KDLL_R_CXX = $(CMN_KCXX)
KLIB_R_LD  = $(KLIB_R_LD1)
DRV_R_LD   = $(DRV_R_LD1)
KDLL_R_LD  = $(KDLL_R_LD1)

else # !SEQ_BUILD

# multi-source build: build multiple sources at one CL call - using /MP option
# note: auto-dependencies generation is not supported in this mode - /MP conflicts with /showIncludes
# note: there is support for precompiled headers in this mode

# $1 - sources
# $2 - outdir/
# $3 - pch header
# target-specific: CFLAGS, CXXFLAGS
CALL_MKCC   = $(call SUP,MKCC,$1)$(call WRAP_COMPILER,$(call CMN_KCL,$2,$1,/MP $(CFLAGS)),,$1)
CALL_MKCXX  = $(call SUP,MKCXX,$1)$(call WRAP_COMPILER,$(call CMN_KCL,$2,$1,/MP $(CXXFLAGS)),,$1)
CALL_MPKCC  = $(call SUP,MPKCC,$1)$(call WRAP_COMPILER,$(call CMN_KCL,$2,$1,/MP /Yu$3 /Fp$2$(basename \
  $(notdir $3))_c.pch /FI$3 $(CFLAGS)),,$1)
CALL_MPKCXX = $(call SUP,MPKCXX,$1)$(call WRAP_COMPILER,$(call CMN_KCL,$2,$1,/MP /Yu$3 /Fp$2$(basename \
  $(notdir $3))_cpp.pch /FI$3 $(CXXFLAGS)),,$1)

# $1 - outdir/
# $2 - pch header
# $3 - non-pch C
# $4 - non-pch CXX
# $5 - pch C
# $6 - pch CXX
CMN_MKCL3 = $(if \
  $3,$(call xcmd,CALL_MKCC,$3,$(MCL_MAX_COUNT),$1,$2)$(newline))$(if \
  $4,$(call xcmd,CALL_MKCXX,$4,$(MCL_MAX_COUNT),$1,$2)$(newline))$(if \
  $5,$(call xcmd,CALL_MPKCC,$5,$(MCL_MAX_COUNT),$1,$2)$(newline))$(if \
  $6,$(call xcmd,CALL_MPKCXX,$6,$(MCL_MAX_COUNT),$1,$2)$(newline))

# $1 - outdir/
# $2 - C-sources
# $3 - CXX-sources
# target-specific: PCH, WITH_PCH
CMN_MKCL2 = $(call CMN_MKCL3,$1,$(PCH),$(filter-out $(WITH_PCH),$2),$(filter-out \
  $(WITH_PCH),$3),$(filter $(WITH_PCH),$2),$(filter $(WITH_PCH),$3))

# $1 - outdir/
# $2 - sources
CMN_MKCL1 = $(call CMN_MKCL2,$1,$(filter %.c,$2),$(filter %.cpp,$2))

# $1 - target KLIB, DRV or KDLL
# $2 - objects
# target-specific: SRC, SDEPS
CMN_MKCL = $(call CMN_MKCL1,$(dir $(firstword $2)),$(sort $(filter $(SRC),$? $(call FILTER_SDEPS,$(SDEPS)))))

# $1 - target KLIB, DRV or KDLL
# $2 - objects
KLIB_R_LD = $(CMN_MKCL)$(KLIB_R_LD1)
DRV_R_LD  = $(CMN_MKCL)$(DRV_R_LD1)
KDLL_R_LD = $(CMN_MKCL)$(KDLL_R_LD1)

# $1 - target pch object
# $2 - pch-source
# $3 - pch header name
# target-specific: CFLAGS, CXXFLAGS
PCH_R_KCC  = $(call SUP,PCHKCC,$2)$(call WRAP_COMPILER,$(call CMN_KCL,$(dir $1),$2,/Yc$3 /Yl$(basename \
  $(notdir $2)) /Fp$(dir $1)$(basename $(notdir $3))_c.pch $(CFLAGS)),$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))
PCH_R_KCXX = $(call SUP,PCHKCXX,$2)$(call WRAP_COMPILER,$(call CMN_KCL,$(dir $1),$2,/Yc$3 /Yl$(basename \
  $(notdir $2)) /Fp$(dir $1)$(basename $(notdir $3))_cpp.pch $(CXXFLAGS)),$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))

endif # !SEQ_BUILD

# kernel-level assembler
# $1 - target object file
# $2 - asm-source
# target-specific: ASMFLAGS
KLIB_R_ASM = $(call SUP,ASM,$2)$(YASMC) $(YASM_FLAGS) $(ASMFLAGS) -o $(call ospath,$1 $2)
DRV_R_ASM  = $(KLIB_R_ASM)
KDLL_R_ASM = $(KLIB_R_ASM)

endif # DRIVERS_SUPPORT

# $1 - target
# $2 - source
BISON = $(call SUP,BISON,$2)$(BISONC) -o $(ospath) -d --fixed-output-files $(call ospath,$(call abspath,$2))
FLEX  = $(call SUP,FLEX,$2)$(FLEXC) -o$(call ospath,$1 $2)

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
define PCH_TEMPLATE1
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
# $3 - $(call FORM_OBJ_DIR,$t,$v)
# $4 - $(call FORM_TRG,$t,$v)
# $5 - K or <empty>
# $t - EXE,LIB,DLL,DRV,KLIB,KDLL
# $v - R,S,RU,SU
# note: $$(PCH_OBJS) will be built before link phase - before sources are compiled with MCL
define PCH_TEMPLATE2
$(empty)
$4: PCH := $$(TRG_PCH)
$4: WITH_PCH := $$(TRG_WITH_PCH)
PCH_C_OBJ := $3/$1_$t_$2_c$(OBJ_SUFFIX)
PCH_CXX_OBJ := $3/$1_$t_$2_cpp$(OBJ_SUFFIX)
$$(PCH_C_OBJ): $$(PCH_C_SRC) $$(TRG_PCH) | $3 $$(ORDER_DEPS)
	$$(call PCH_$v_$5CC,$$@,$$<,$$(PCH))
$$(PCH_CXX_OBJ): $$(PCH_CXX_SRC) $$(TRG_PCH) | $3 $$(ORDER_DEPS)
	$$(call PCH_$v_$5CXX,$$@,$$<,$$(PCH))
PCH_OBJS := $$(if $$(filter %.c,$$(TRG_WITH_PCH)),$$(PCH_C_OBJ)) $$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(PCH_CXX_OBJ))
$4: $$(PCH_OBJS)
ifndef NO_DEPS
-include $$(addprefix $3/,$$(if \
  $$(filter %.c,$$(TRG_WITH_PCH)),$$(basename $$(notdir $$(PCH_C_SRC))).d) $$(if \
  $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(basename $$(notdir $$(PCH_CXX_SRC))).d))
endif
$$(call TOCLEAN,$$(PCH_OBJS))
$$(call TOCLEAN,$$(if $$(filter %.c,$$(TRG_WITH_PCH)),$3/$2_c.pch $3/$$(basename $$(notdir $$(PCH_C_SRC))).d))
$$(call TOCLEAN,$$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$3/$2_cpp.pch $3/$$(basename $$(notdir $$(PCH_CXX_SRC))).d))
endef

# $1 - $(call GET_TARGET_NAME,$t)
# $2 - $$(basename $$(notdir $$(TRG_PCH)))
# $3 - K or <empty>
# $t - EXE,LIB,DLL,DRV,KLIB,KDLL
PCH_TEMPLATE3 = $(PCH_TEMPLATE1)$(foreach v,$(call GET_VARIANTS,$t),$(call \
  PCH_TEMPLATE2,$1,$2,$(call FORM_OBJ_DIR,$t,$v),$(call FORM_TRG,$t,$v),$3))

# $t - EXE,LIB,DLL,DRV,KLIB,KDLL
# note: must reset target-specific WITH_PCH if not using precompiled header, otherwise:
# - DLL or LIB target may inherit WITH_PCH value from EXE,
# - LIB target may inherit WITH_PCH value from DLL
PCH_TEMPLATE = $(if $(word 2,$(PCH) $(WITH_PCH)),$(call \
  PCH_TEMPLATE3,$(call GET_TARGET_NAME,$t),$$(basename $$(notdir $$(TRG_PCH))),$(if $(filter DRV KLIB KDLL,$t),K)),$(foreach \
  v,$(call GET_VARIANTS,$t),$(call FORM_TRG,$t,$v): WITH_PCH:=$(newline)))

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
# $t - EXE, DLL, DRV or KDLL
# $n - $(call GET_TARGET_NAME,$t)
ifndef TOCLEAN
define EXPORTS_TEMPLATE1
$1: IMP := $3
$1: DEF := $2
$1: $2 | $(LIB_DIR)
NEEDED_DIRS += $(LIB_DIR)
$3: $1
endef
else ifdef DEBUG
# cleanup generated .exp file in debug
EXPORTS_TEMPLATE1 = $(call TOCLEAN,$3 $(3:$(IMP_SUFFIX)=.exp))
else
EXPORTS_TEMPLATE1:=
endif

# for DLL or EXE that do not exports symbols
# $1 - $(call FORM_TRG,$t,$v)
# $t - EXE, DLL, DRV or KDLL
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
# $t - EXE, DLL, DRV or KDLL
# $n - $(call GET_TARGET_NAME,$t)
# $v - R,S
EXPORTS_TEMPLATE = $(if $3,$(call EXPORTS_TEMPLATE1,$1,$2,$(call MAKE_IMP_PATH,$n,$v)),$(NO_EXPORTS_TEMPLATE))

# add dependency on sources for the target,
# define target-specific variables: SRC, SDEPS, OBJ_DIR
# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $3 - $(TRG_ALL_SDEPS)
# $4 - $(call FORM_TRG,$t,$v)
# $5 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE, DLL, DRV or KDLL
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
# $t - EXE, DRV
# $n - $(call GET_TARGET_NAME,$t)
# $v - R,S
define EXE_AUX_TEMPLATE2
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
# $t - DLL, KDLL
# $n - $(call GET_TARGET_NAME,$t)
# $v - R,S
define DLL_AUX_TEMPLATE2
$(empty)
$4: MODVER := $(MODVER)
$4: $t_NO_EXPORTS := $($t_NO_EXPORTS)
$(call EXPORTS_TEMPLATE,$4,$6,$(if $($t_NO_EXPORTS),,1))
endef

# cleanup generated vc*.pdb and .pdb in debug
# define target-specific variables SRC, SDEPS and OBJ_DIR
# $t - EXE, DLL, DRV or KDLL
ifdef TOCLEAN
ifdef DEBUG
$(eval define EXE_AUX_TEMPLATE2$(newline)$(value EXE_AUX_TEMPLATE2)$$(call TOCLEAN,$$5/vc*.pdb $$(4:$$($$t_SUFFIX)=.pdb))$(newline)endef)
$(eval define DLL_AUX_TEMPLATE2$(newline)$(value DLL_AUX_TEMPLATE2)$$(call TOCLEAN,$$5/vc*.pdb $$(4:$$($$t_SUFFIX)=.pdb))$(newline)endef)
endif
else ifndef SEQ_BUILD
$(eval define EXE_AUX_TEMPLATE2$(newline)$(value EXE_AUX_TEMPLATE2)$(value MULTISOURCE_AUX)$(newline)endef)
$(eval define DLL_AUX_TEMPLATE2$(newline)$(value DLL_AUX_TEMPLATE2)$(value MULTISOURCE_AUX)$(newline)endef)
endif

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $3 - $(TRG_ALL_SDEPS)
# $4 - $(call fixpath,$(DEF))
# $t - EXE, DLL, DRV or KDLL
EXP_AUX_TEMPLATE1 = $(foreach n,$(call GET_TARGET_NAME,$t),$(foreach v,$(call GET_VARIANTS,$t),$(call \
  $t_AUX_TEMPLATE2,$1,$2,$3,$(call FORM_TRG,$t,$v),$(call FORM_OBJ_DIR,$t,$v),$4)))

# auxiliary defines for EXE or DLL:
# - standard resource
# - precompiled header
# - target-specific SRC, SDEPS and OBJ_DIR (for CMN_MCL) and IMP (for EXE_LD_TEMPLATE/DLL_LD_TEMPLATE)
# $t - EXE or DLL
define EXP_AUX_TEMPLATE
$(empty)
$(call STD_RES_TEMPLATE,$t)
$(PCH_TEMPLATE)
$(call EXP_AUX_TEMPLATE1,$(TRG_SRC),$(TRG_SDEPS),$(TRG_ALL_SDEPS),$(call fixpath,$(DEF)))
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
ARC_AUX_TEMPLATE2:=
ifdef TOCLEAN
ifdef DEBUG
ARC_AUX_TEMPLATE2 = $(call TOCLEAN,$5/vc*.pdb)
endif
else ifndef SEQ_BUILD
ARC_AUX_TEMPLATE2 = $(MULTISOURCE_AUX)
endif

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $3 - $(TRG_ALL_SDEPS)
# $t - LIB or KLIB
ARC_AUX_TEMPLATE1 = $(foreach v,$(call GET_VARIANTS,$t),$(call \
  ARC_AUX_TEMPLATE2,$1,$2,$3,$(call FORM_TRG,$t,$v),$(call FORM_OBJ_DIR,$t,$v)))

# auxiliary defines for LIB or KLIB:
# - precompiled header
# - target-specific SRC, SDEPS and OBJ_DIR (for CMN_MCL)
# $t - LIB or KLIB
define ARC_AUX_TEMPLATE
$(if $(RES),$(error do not link resource(s) $(RES) into static library $($t): linker will ignore resources in static library))
$(PCH_TEMPLATE)
endef

# $t - LIB or KLIB
ifdef ARC_AUX_TEMPLATE2
$(eval define ARC_AUX_TEMPLATE$(newline)$(value ARC_AUX_TEMPLATE)$(newline)$$(call \
  ARC_AUX_TEMPLATE1,$$(TRG_SRC),$$(TRG_SDEPS),$$(TRG_ALL_SDEPS))$(newline)endef)
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

ifdef DRIVERS_SUPPORT

# how to build driver, used by $(C_RULES)
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - DRV or KDLL
# $v - non-empty variant: R
define DRV_TEMPLATE
$(call STD_RES_TEMPLATE,$t)
$(PCH_TEMPLATE)
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$1: $(call OBJ_RULES,CC,$(filter %.c,$2),$3,$4)
$1: $(call OBJ_RULES,CXX,$(filter %.cpp,$2),$3,$4)
$1: $(call OBJ_RULES,ASM,$(filter %.asm,$2),$3,$4)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: LIB_DIR    := $(LIB_DIR)
$1: KLIBS      := $(KLIBS)
$1: KDLLS      := $(KDLLS)
$1: INCLUDE    := $(TRG_INCLUDE)
$1: DEFINES    := $(TRG_DEFINES)
$1: CFLAGS     := $(TRG_CFLAGS)
$1: CXXFLAGS   := $(TRG_CXXFLAGS)
$1: ASMFLAGS   := $(TRG_ASMFLAGS)
$1: LDFLAGS    := $(TRG_LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH)
$1: $(addprefix $(LIB_DIR)/,$(addprefix \
  $(KLIB_PREFIX),$(KLIBS:=$(KLIB_SUFFIX))) $(addprefix \
  $(KIMP_PREFIX),$(KDLLS:=$(KIMP_SUFFIX))))
	$$(call $t_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
endef

# how to build kernel shared library, used by $(C_RULES)
KDLL_TEMPLATE = $(DRV_TEMPLATE)

# for EXP_AUX_TEMPLATE1
DRV_AUX_TEMPLATE2 = $(EXE_AUX_TEMPLATE2)
KDLL_AUX_TEMPLATE2 = $(DLL_AUX_TEMPLATE2)

# auxiliary defines for DRV or KDLL:
# - standard resource
# - precompiled header
# - target-specific SRC, SDEPS and OBJ_DIR (for CMN_MKCL) and IMP (for DRV_LD_TEMPLATE/KDLL_LD_TEMPLATE)
# $t - DRV or KDLL
define KEXP_AUX_TEMPLATE
$(empty)
$(call EXP_AUX_TEMPLATE1,$(TRG_SRC),$(TRG_SDEPS),$(TRG_ALL_SDEPS),$(call fixpath,$(DEF)))
endef

# called by OS_DEFINE_TARGETS
# $t - DRV or KDLL
DRV_AUX_TEMPLATE = $(KEXP_AUX_TEMPLATE)
KDLL_AUX_TEMPLATE = $(KEXP_AUX_TEMPLATE)

endif # DRIVERS_SUPPORT

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
$(eval define OS_DEFINE_TARGETS$(newline)$(value OS_DEFINE_TARGETS)$(newline)$$$$(call TOCLEAN,$$$$(RES))$(newline)endef)
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,MCL_MAX_COUNT SEQ_BUILD YASMC FLEXC BISONC YASM_FLAGS MC_STRIP_STRINGS WRAP_MC MC RC_LOGO_STRINGS \
  WRAP_RC RC KIMP_PREFIX KIMP_SUFFIX CHECK_LIB_UNI_NAME1=v CHECK_LIB_UNI_NAME=v DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE \
  EMBED_MANIFEST_OPTION EMBED_EXE_MANIFEST=TMD EMBED_DLL_MANIFEST OS_PREDEFINES MK_MAJ_MIN_VER DEF_LIB_LDFLAGS LIB_LD_TEMPLATE=v \
  CMN_LIBS_LDFLAGS CMN_LIBS=v DEF_SUBSYSTEM \
  LINKER_STRIP_STRINGS_en LINKER_STRIP_STRINGS_ru_cp1251 LINKER_STRIP_STRINGS_ru_cp1251_as_cp866_to_cp1251 \
  LINKER_STRIP_STRINGS WRAP_LINKER DEL_DEF_MANIFEST_ON_FAIL \
  WRAP_EXE_EXPORTS_LINKER WRAP_EXE_LINKER EXE_LD_TEMPLATE=v WRAP_DLL_EXPORTS_LINKER WRAP_DLL_LINKER DLL_LD_TEMPLATE=v \
  $(foreach v,R $(VARIANTS_FILTER),LIB_$v_LD1 EXE_$v_LD1 DLL_$v_LD1) \
  OS_APP_CFLAGS APP_CFLAGS OS_APP_DEFINES APP_DEFINES CMN_CL1 CMN_RCL CMN_SCL CMN_RUCL CMN_SUCL \
  INCLUDING_FILE_PATTERN_en INCLUDING_FILE_PATTERN_ru_utf8 INCLUDING_FILE_PATTERN_ru_utf8_bytes \
  INCLUDING_FILE_PATTERN_ru_cp1251 INCLUDING_FILE_PATTERN_ru_cp1251_bytes \
  INCLUDING_FILE_PATTERN_ru_cp866 INCLUDING_FILE_PATTERN_ru_cp866_bytes \
  INCLUDING_FILE_PATTERN UDEPS_INCLUDE_FILTER SED_DEPS_SCRIPT \
  WRAP_COMPILER CMN_CC CMN_CXX SEQ_COMPILERS_TEMPLATE \
  $(foreach v,R $(VARIANTS_FILTER),LIB_$v_CC LIB_$v_CXX EXE_$v_CC EXE_$v_CXX DLL_$v_CC DLL_$v_CXX LIB_$v_LD EXE_$v_LD DLL_$v_LD) \
  CALL_MCC CALL_MCXX CALL_MPCC CALL_MPCXX CMN_MCL2 CMN_MCL1 CMN_RMCL CMN_SMCL CMN_RUMCL CMN_SUMCL \
  FILTER_SDEPS1 FILTER_SDEPS CMN_MCL MULTI_COMPILERS_TEMPLATE \
  $(foreach v,R $(VARIANTS_FILTER),PCH_$v_CC PCH_$v_CXX) \
  SUBSYSTEM_KVER DEF_KLIB_LDFLAGS KLIB_R_LD1 DEF_DRV_LDFLAGS CMN_KLIBS DRV_R_LD1 KDLL_R_LD1 \
  OS_KRN_CFLAGS FORCE_SYNC_PDB_KERN KRN_CFLAGS OS_KRN_DEFINES KRN_DEFINES CMN_KCL KDEPS_INCLUDE_FILTER CMN_KCC CMN_KCXX \
  KLIB_R_CC DRV_R_CC KDLL_R_CC KLIB_R_CXX DRV_R_CXX KDLL_R_CXX KLIB_R_LD DRV_R_LD KDLL_R_LD \
  CALL_MKCC CALL_MKCXX CALL_MPKCC CALL_MPKCXX CMN_MKCL3 CMN_MKCL2 CMN_MKCL1 CMN_MKCL PCH_R_KCC PCH_R_KCXX \
  KLIB_R_ASM DRV_R_ASM KDLL_R_ASM BISON FLEX \
  PCH_TEMPLATE1 PCH_TEMPLATE2=v;t PCH_TEMPLATE3=t PCH_TEMPLATE=t ADD_WITH_PCH \
  TRG_ALL_SDEPS MAKE_IMP_PATH EXPORTS_TEMPLATE1=t;n;v NO_EXPORTS_TEMPLATE=t;n;v EXPORTS_TEMPLATE=t;n;v MULTISOURCE_AUX=t;v \
  EXE_AUX_TEMPLATE2=t;n;v DLL_AUX_TEMPLATE2=t;n;v EXP_AUX_TEMPLATE1=t EXP_AUX_TEMPLATE=t EXE_AUX_TEMPLATE=t DLL_AUX_TEMPLATE=t \
  ARC_AUX_TEMPLATE2=t;v ARC_AUX_TEMPLATE1=t ARC_AUX_TEMPLATE=t LIB_AUX_TEMPLATE KLIB_AUX_TEMPLATE \
  ADD_MC_RULE1 ADD_MC_RULE ADD_RES_RULE2 ADD_RES_RULE1 ADD_RES_RULE RC_DEFINE_PATH \
  DRV_TEMPLATE=t KDLL_TEMPLATE DRV_AUX_TEMPLATE2 KDLL_AUX_TEMPLATE2 KEXP_AUX_TEMPLATE=t DRV_AUX_TEMPLATE KDLL_AUX_TEMPLATE)
