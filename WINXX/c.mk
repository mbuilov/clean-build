OSTYPE := WINDOWS

# additional variables that may have target-dependent variant (EXE_RES, DLL_RES and so on)
TRG_VARS += RES

# additional variables without target-dependent variants
BLD_VARS += DEF

# reset additional variables
define RESET_OS_VARS
RES :=
DEF :=
endef

# make RESET_OS_VARS variable non-recursive (simple)
RESET_OS_VARS := $(RESET_OS_VARS)

include $(MTOP)/WINXX/cres.mk

# run via $(MAKE) S=1 to compile each source individually (without /MP CL compiler option)
ifeq ("$(origin S)","command line")
SEQ_BUILD := $S
endif

# 0 -> $(empty)
SEQ_BUILD := $(SEQ_BUILD:0=)

include $(MTOP)/WINXX/auto_c.mk

ifndef YASMC
# note: assume yasm used only for drivers
YASMC := yasm.exe $(if $(KCPU:%64=),-f win32 -m x86,-f win64 -m amd64)
endif

ifndef FLEXC
FLEXC := flex.exe
endif

ifndef BISONC
BISONC := bison.exe
endif

# environment variable LIB holds path to system libraries,
# but we have our own meaning of variable LIB (static library target)
# so undefine it
LIB:=

# message compiler
# $1 - generated .rc and .h
# target-specific: TMD
MC ?= $(call SUP,$(TMD)MC,$1)$($(TMD)MC1)$(if $(VERBOSE), -v)

# SUPPRESS_RC_LOGO may be defined as /nologo -  not all versions of rc.exe support this switch
SUPPRESS_RC_LOGO := $(SUPPRESS_RC_LOGO)

# resource compiler
# $1 - target .res, $2 - source .rc, $3 - rc compiler options
# target-specific: TMD
RC ?= $(call SUP,$(TMD)RC,$1)$($(TMD)RC1)$(if $(VERBOSE), /v) $(SUPPRESS_RC_LOGO) $3 $(call \
  qpath,$(VS$(TMD)INC) $(UM$(TMD)INC),/I) /fo$(call ospath,$1 $2)

# prefixes/suffixes of build targets, may be already defined in $(TOP)/make/project.mk
# note: if OBJ_SUFFIX is defined, then all prefixes/suffixes must be also defined
ifndef OBJ_SUFFIX
EXE_SUFFIX := .exe
OBJ_SUFFIX := .obj
LIB_PREFIX :=
LIB_SUFFIX := .a    # static library (archive)
IMP_PREFIX :=
IMP_SUFFIX := .lib  # implementation library for dll
DLL_PREFIX :=
DLL_SUFFIX := .dll
KLIB_PREFIX :=
KLIB_SUFFIX := .ka  # kernel-mode static library (archive)
DRV_PREFIX := drv
DRV_SUFFIX := .sys
endif

# dll and import file for dll - different files
# place dll to $(BIN_DIR), implementation lib for dll - to $(LIB_DIR)
# NOTE: DLL_DIR and IMP_DIR must be recursive because $(BIN_DIR) and $(LIB_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(BIN_DIR)
IMP_DIR = $(LIB_DIR)

# SUBSYSTEM for kernel mode
SUBSYSTEM_KVER ?= $(SUBSYSTEM_VER)

# standard defines
# for example, WINVER_DEFINES ?= WINVER=0x0501 _WIN32_WINNT=0x0501
OS_PREDEFINES ?= WINXX $(OSVARIANT) $(WINVER_DEFINES)

# how to embed manifest into executable or dll
ifdef MAY_EMBED_MANIFEST # starting from Visual Studio 2012
EMBED_EXE_MANIFEST := $(space)/MANIFEST:EMBED
DLL_MANIFEST_OPTION := $(space)/MANIFEST:EMBED
else
# target-specific: TMD
EMBED_EXE_MANIFEST ?= $(call DEL_ON_FAIL,$1.manifest)$(newline)$(if \
  $(VERBOSE),,@)if exist $(ospath).manifest ($($(TMD)MT1) -nologo -manifest \
  $(ospath).manifest -outputresource:$(ospath);1 && del $(ospath).manifest)$(DEL_ON_FAIL)
EMBED_DLL_MANIFEST ?= $(newline)$(if \
  $(VERBOSE),,@)if exist $(ospath).manifest ($($(TMD)MT1) -nologo -manifest \
  $(ospath).manifest -outputresource:$(ospath);2 && del $(ospath).manifest)$(DEL_ON_FAIL)
endif

# application-level and kernel-level defines
# note: OS_APPDEFS and OS_KRNDEFS are may be defined as empty
# note: some external sources want WIN32 to be defined
ifeq (undefined,$(origin OS_APPDEFS))
OS_APPDEFS := $(if $(UCPU:%64=),ILP32,LLP64) WIN32 CRT_SECURE_NO_DEPRECATE _CRT_SECURE_NO_WARNINGS
endif
ifeq (undefined,$(origin OS_KRNDEFS))
OS_KRNDEFS := $(if $(KCPU:%64=),ILP32 _WIN32 _X86_,LLP64 _WIN64 _AMD64_) _KERNEL WIN32_LEAN_AND_MEAN
endif

# supported target variants:
# R  - dynamicaly linked multi-threaded libc (default)
# S  - statically linked multithreaded libc
# RU - same as R, but with unicode support (exe or dll may be linked with UNI_-prefixed library)
# SU - same as S, but with unicode support (exe or dll may be linked with UNI_-prefixed library)
ifeq (undefined,$(origin VARIANTS_FILTER))
VARIANTS_FILTER := S RU SU
endif

# for $(DEP_LIB_SUFFIX) from $(MTOP)/c.mk:
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $l - dependent static library name
# use the same variant of static library as target EXE or DLL (for example for S-EXE use S-LIB)
# use appropriate R or S variant of required non-UNI_ static library for RU or SU variant of target EXE or DLL
# (if required static library name do not starts with UNI_ - convert RU->R variant for required library)
VARIANT_LIB_MAP ?= $(if $(l:UNI_%=),$(2:U=),$2)

# for $(DEP_IMP_SUFFIX) from $(MTOP)/c.mk:
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $d - dependent dynamic library name
# use the same variant of dynamic library as target EXE or DLL (for example for S-EXE use S-DLL)
# use appropriate R or S variant of required non-UNI_ dynamic library for RU or SU variant of target EXE or DLL
# (if required implementation library name do not starts with UNI_ - convert SU->S variant for required implementation library)
VARIANT_IMP_MAP ?= $(if $(d:UNI_%=),$(2:U=),$2)

# check that library name built as RU/SU variant is started with UNI_ prefix
# $1 - library name, $2 - variant name: RU,SU
CHECK_LIB_UNI_NAME1 = $(if $(filter-out UNI_%,$1),$(error library '$1' name must be started with UNI_ prefix to build it as $2 variant))

# check that library name built as RU/SU variant is started with UNI_ prefix
# $1 - IMP or LIB, $v - variant name: R,S,RU,SU
# note: $$1 - target library name
CHECK_LIB_UNI_NAME ?= $(if $(filter %U,$v),$$(call CHECK_LIB_UNI_NAME1,$$(patsubst \
  %$(call VARIANT_$1_SUFFIX,$v)$($1_SUFFIX),%,$$(notdir $$1)),$v))

# common linker flags for EXE or DLL
# $$1 - target file, $$2 - objects, $v - variant
ifeq (undefined,$(origin CMN_LIBS_LDFLAGS))
CMN_LIBS_LDFLAGS := /INCREMENTAL:NO $(if $(DEBUG),/DEBUG,/LTCG /OPT:REF)
endif

# common parts of linker options for built EXE or DLL
# $$1 - target exe or dll, $$2 - objects, $v - variant
# note: because target variable (EXE or DLL) is not used in VARIANT_LIB_MAP and VARIANT_IMP_MAP,
#  may pass any value as first parameter to MAKE_DEP_LIBS and MAKE_DEP_IMPS (macros from $(MTOP)/c.mk)
# target-specific: TMD, RES, LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS
CMN_LIBS ?= /OUT:$$(ospath) $(CMN_LIBS_LDFLAGS) $$(call ospath,$$2 $$(RES)) $$(if $$(strip \
  $$(LIBS)$$(DLLS)),/LIBPATH:$$(call ospath,$$(LIB_DIR))) $$(call MAKE_DEP_LIBS,XXX,$v,$$(LIBS)) $$(call \
  MAKE_DEP_IMPS,XXX,$v,$$(DLLS)) $$(call qpath,$$(VS$$(TMD)LIB) $$(UM$$(TMD)LIB) $$(call \
  ospath,$$(SYSLIBPATH)),/LIBPATH:) $$(SYSLIBS)

# default subsystem for EXE
# $$1 - target exe, $$2 - objects, $v - variant
# note: do not add /SUBSYSTEM option if $(LDFLAGS) have already specified one
# target-specific: LDFLAGS
DEF_EXE_SUBSYSTEM ?= $$(if $$(filter /SUBSYSTEM:%,$$(LDFLAGS)),,/SUBSYSTEM:CONSOLE,$(SUBSYSTEM_VER))

# define EXE linker for variant $v
# $$1 - target exe, $$2 - objects, $v - variant
# target-specific: TMD, LDFLAGS
define EXE_LD_TEMPLATE
$(empty)
EXE_$v_LD1 = $$(call SUP,$(TMD)LINK,$$1)$$(VS$$(TMD)LD) /nologo $(CMN_LIBS) $(DEF_EXE_SUBSYSTEM) $$(LDFLAGS)$$(EMBED_EXE_MANIFEST)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(EXE_LD_TEMPLATE)))

# Link.exe has a bug/feature: it may not delete target dll if DEF was specified and were errors while building the dll
# target-specific: DEF
DEL_ON_DLL_FAIL ?= $(if $(DEF)$(EMBED_DLL_MANIFEST),$(call DEL_ON_FAIL,$(if $(DEF),$1) $(if $(EMBED_DLL_MANIFEST),$1.manifest)))

# define DLL linker for variant $v
# $$1 - target dll, $$2 - objects, $v - variant
# target-specific: TMD, DEF, LDFLAGS, IMP
define DLL_LD_TEMPLATE
$(empty)
DLL_$v_LD1 = $$(call SUP,$(TMD)LINK,$$1)$$(VS$$(TMD)LD) /nologo /DLL $$(if $$(DEF),/DEF:$$(call \
  ospath,$$(DEF))) $(CMN_LIBS) $$(LDFLAGS) /IMPLIB:$$(call \
  ospath,$$(IMP))$(DLL_MANIFEST_OPTION)$$(DEL_ON_DLL_FAIL)$$(EMBED_DLL_MANIFEST)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(DLL_LD_TEMPLATE)))

# default linker flags for LIB
# $$1 - target lib, $$2 - objects, $v - variant
ifeq (undefined,$(origin DEF_LIB_LDFLAGS))
DEF_LIB_LDFLAGS := $(if $(DEBUG),,/LTCG)
endif

# define LIB linker for variant $v
# $$1 - target lib, $$2 - objects, $v - variant
# target-specific: TMD, LDFLAGS
define LIB_LD_TEMPLATE
$(empty)
LIB_$v_LD1 = $(call CHECK_LIB_UNI_NAME,LIB)$$(call SUP,$(TMD)LIB,$$1)$$(VS$$(TMD)LD) \
  /lib /nologo /OUT:$$(call ospath,$$1 $$2) $(DEF_LIB_LDFLAGS) $$(LDFLAGS)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(LIB_LD_TEMPLATE)))

# default linker flags for KLIB
# $1 - target klib, $2 - objects
ifeq (undefined,$(origin DEF_KLIB_LDFLAGS))
DEF_KLIB_LDFLAGS := $(if $(DEBUG),,/LTCG)
endif

# define KLIB linker
# $1 - target klib, $2 - objects
# target-specific: LDFLAGS
KLIB_LD1 = $(call SUP,KLIB,$1)$(WKLD) /lib /nologo /OUT:$(call ospath,$1 $2) $(DEF_KLIB_LDFLAGS) $(LDFLAGS)

# flags for application level C-compiler
ifeq (undefined,$(origin APP_FLAGS))
APP_FLAGS := /X /GF /W3 /EHsc
ifdef DEBUG
APP_FLAGS += /Od /Zi /RTCc /RTCsu /GS
else
APP_FLAGS += /Ox /GL /Gy
endif
APP_FLAGS += /wd4251 # 'class' needs to have dll-interface to be used by clients of class...
APP_FLAGS += /wd4275 # non dll-interface class 'class' used as base for dll-interface class 'class'
APP_FLAGS += /wd4996 # 'strdup': The POSIX name for this item is deprecated...
APP_FLAGS += /wd4001 # nonstandard extension 'single line comment' was used
endif

# call C compiler
# $1 - outdir, $2 - sources, $3 - flags
# target-specific: TMD, DEFINES, INCLUDE
CMN_CL1 = $(VS$(TMD)CL) /nologo /c $(APP_FLAGS) $(call SUBST_DEFINES,$(addprefix /D,$(DEFINES))) $(call \
  qpath,$(call ospath,$(INCLUDE)) $(VS$(TMD)INC) $(UM$(TMD)INC),/I) /Fo$(ospath) /Fd$(ospath) $3 $(call ospath,$2)

# C compilers for different variants (R,S,RU,SU)
# $1 - outdir, $2 - sources, $3 - flags
CMN_RCL  ?= $(CMN_CL1) /MD$(if $(DEBUG),d)
CMN_SCL  ?= $(CMN_CL1) /MT$(if $(DEBUG),d)
CMN_RUCL ?= $(CMN_RCL) /DUNICODE /D_UNICODE
CMN_SUCL ?= $(CMN_SCL) /DUNICODE /D_UNICODE

# $(SED) expression to match C compiler messages about included files
#INCLUDING_FILE_PATTERN ?= \xd0\x9f\xd1\x80\xd0\xb8\xd0\xbc\xd0\xb5\xd1\x87\xd0\xb0\xd0\xbd\xd0\xb8\xd0\xb5\x3a\x20\xd0\xb2\xd0\xba\xd0\xbb\xd1\x8e\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5\x20\xd1\x84\xd0\xb0\xd0\xb9\xd0\xbb\xd0\xb0:
ifeq (undefined,$(origin INCLUDING_FILE_PATTERN))
INCLUDING_FILE_PATTERN := Note: including file:
endif

# $(SED) expression to filter-out system files while dependencies generation
ifeq (undefined,$(origin UDEPS_INCLUDE_FILTER))
UDEPS_INCLUDE_FILTER := c:\\program?files?(x86)\\microsoft?visual?studio?10.0\\vc\\include\\
endif

# $(SED) script to generate dependencies file from C compiler output
# $2 - target object file, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes to filter out

# s/\x0d//;                                - fix line endings - remove CR
# /^$(notdir $3)$$/d;                      - delete compiled file name printed by cl
# /^COMPILATION_FAILED.*/w $4              - write COMPILATION_FAILED string to generated dep-file
# /^COMPILATION_FAILED.*/d                 - don't print COMPILATION_FAILED, start new circle
# /^$(INCLUDING_FILE_PATTERN) /!{p;d;}     - print all lines not started with $(INCLUDING_FILE_PATTERN) and space, start new circle
# s/^$(INCLUDING_FILE_PATTERN)  *//;       - strip-off leading $(INCLUDING_FILE_PATTERN) with spaces
# $(subst ?, ,$(foreach x,$5,\@^$x.*@Id;)) - delete lines started with system include paths, start new circle
# s/ /\\ /g;                               - escape spaces in included file path
# s@.*@&:\n$2: &@;w $4                     - make dependencies, then write to generated dep-file

SED_DEPS_SCRIPT ?= \
-e "s/\x0d//;/^$(notdir $3)$$/d;/^COMPILATION_FAILED.*/w $4" \
-e "/^COMPILATION_FAILED.*/d;/^$(INCLUDING_FILE_PATTERN) /!{p;d;}" \
-e "s/^$(INCLUDING_FILE_PATTERN)  *//;$(subst ?, ,$(foreach x,$5,\@^$x.*@Id;))s/ /\\ /g;s@.*@&:\n$2: &@;w $4"

# WRAP_COMPILER - either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options, $2 - target object, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes
ifdef NO_DEPS
WRAP_COMPILER = $1
else
# compiler will run in a sub-batch, where double-quotes are escaped by two double-quotes
WRAP_COMPILER ?= ($(subst \","",$1) /showIncludes 2>&1 || echo COMPILATION_FAILED) | \
  $(SED) -n $(SED_DEPS_SCRIPT) && findstr /b COMPILATION_FAILED $(call \
  ospath,$4) > NUL & if errorlevel 1 (cmd /c exit 0) else (del $(call ospath,$4) && cmd /c exit 1)
endif

ifdef SEQ_BUILD

# sequential build: don't add /MP option to Visual Studio C compiler
# note: auto-dependencies generation available only in sequential mode - /MP conflicts with /showIncludes
# note: precompiled headers are not supported in this mode

# common C/C++ compiler
# $1 - target object, $2 - source, $3 - compiler
# target-specific: TMD, CFLAGS, CXXFLAGS
CMN_CC = $(call SUP,$(TMD)CC,$2)$(call WRAP_COMPILER,$(call $3,$(dir $1),$2,$(CFLAGS)),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))
CMN_CXX = $(call SUP,$(TMD)CXX,$2)$(call WRAP_COMPILER,$(call $3,$(dir $1),$2,$(CXXFLAGS)),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

# define compilers for different target variants
define SEQ_COMPILERS_TEMPLATE
$(empty)
# $1 - target object, $2 - source
LIB_$v_CC  = $$(call CMN_CC,$$1,$$2,CMN_$vCL)
LIB_$v_CXX = $$(call CMN_CXX,$$1,$$2,CMN_$vCL)
EXE_$v_CC  = $$(LIB_$v_CC)
EXE_$v_CXX = $$(LIB_$v_CXX)
DLL_$v_CC  = $$(EXE_$v_CC)
DLL_$v_CXX = $$(EXE_$v_CXX)
# $1 - target exe/dll/lib, $2 - objects
EXE_$v_LD = $$(EXE_$v_LD1)
DLL_$v_LD = $$(DLL_$v_LD1)
LIB_$v_LD = $$(LIB_$v_LD1)
$(empty)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(SEQ_COMPILERS_TEMPLATE)))

# option for parallel builds, starting from Visual Studio 2013
APP_FLAGS += $(FORCE_SYNC_PDB) #/FS

else # !SEQ_BUILD

# multi-source build: build multiple sources at one CL call - using /MP option
# note: auto-dependencies generation is not supported in this mode - /MP conflicts with /showIncludes
# note: there is support for precompiled headers in this mode

# $1 - outdir, $2 - pch, $3 - non-pch C, $4 - non-pch CXX, $5 - pch C, $6 - pch CXX, $7 - compiler, $8 - aux compiler flags
# target-specific: TMD, CFLAGS, CXXFLAGS
CMN_MCL2 = $(if \
  $3,$(call SUP,$(TMD)MCC,$3)$(call $7,$1,$3,$8/MP $(CFLAGS))$(newline))$(if \
  $4,$(call SUP,$(TMD)MCXX,$4)$(call $7,$1,$4,$8/MP $(CXXFLAGS))$(newline))$(if \
  $5,$(call SUP,$(TMD)MPCC,$5)$(call $7,$1,$5,$8/MP /Yu$2 /Fp$1$(basename $(notdir $2))_c.pch /FI$2 $(CFLAGS))$(newline))$(if \
  $6,$(call SUP,$(TMD)MPCXX,$6)$(call $7,$1,$6,$8/MP /Yu$2 /Fp$1$(basename $(notdir $2))_cpp.pch /FI$2 $(CXXFLAGS))$(newline))

# $1 - outdir, $2 - C-sources, $3 - CXX-sources, $4 - compiler, $5 - aux compiler flags (either empty or '/DUNICODE /D_UNICODE ')
# target-specific: PCH, WITH_PCH
CMN_MCL1 = $(call CMN_MCL2,$1,$(PCH),$(filter-out $(WITH_PCH),$2),$(filter-out \
  $(WITH_PCH),$3),$(filter $(WITH_PCH),$2),$(filter $(WITH_PCH),$3),$4,$5)

# $1 - outdir, $2 - sources, $3 - aux compiler flags (either empty or '/DUNICODE /D_UNICODE ')
CMN_RMCL  = $(call CMN_MCL1,$1,$(filter %.c,$2),$(filter %.cpp,$2),CMN_RCL,$3)
CMN_SMCL  = $(call CMN_MCL1,$1,$(filter %.c,$2),$(filter %.cpp,$2),CMN_SCL,$3)
CMN_RUMCL = $(call CMN_RMCL,$1,$2,/DUNICODE /D_UNICODE )
CMN_SUMCL = $(call CMN_SMCL,$1,$2,/DUNICODE /D_UNICODE )

# also recompile sources that are depend on changed sources
# $1 - $(SDEPS) - list of pairs: <source file> <dependency1>|<dependency2>|...
FILTER_SDEPS = $(if $1,$(if $(filter $(subst |, ,$(word 2,$1)),$?),$(firstword $1) )$(call FILTER_SDEPS,$(wordlist 3,999999,$1)))

# $1 - target, $2 - objects, $3 - CMN_RMCL, CMN_SMCL, CMN_RUMCL, CMN_SUMCL
# target-specific: SRC, SDEPS
CMN_MCL = $(call $3,$(dir $(firstword $2)),$(sort $(filter $(SRC),$? $(call FILTER_SDEPS,$(SDEPS)))))

define MULTI_COMPILERS_TEMPLATE
# $$1 - target EXE,LIB,DLL,... $$2 - objects
EXE_$v_LD  = $$(call CMN_MCL,$$1,$$2,CMN_$vMCL)$$(EXE_$v_LD1)
DLL_$v_LD  = $$(call CMN_MCL,$$1,$$2,CMN_$vMCL)$$(DLL_$v_LD1)
LIB_$v_LD  = $$(call CMN_MCL,$$1,$$2,CMN_$vMCL)$$(LIB_$v_LD1)
# $$1 - target pch object, $$2 - pch-source, $$3 - pch header
# target-specific: TMD, CFLAGS, CXXFLAGS
PCH_$v_CC  = $$(call SUP,$(TMD)PCHCC,$$2)$$(call WRAP_COMPILER,$$(call CMN_$vCL,$$(dir $$1),$$2,/Yc$$3 /Yl$$(basename \
  $$(notdir $$2)) /Fp$$(dir $$1)$$(basename $$(notdir $$3))_c.pch $$(CFLAGS)),$$1,$$2,$$(basename $$1).d,$(UDEPS_INCLUDE_FILTER))
PCH_$v_CXX = $$(call SUP,$(TMD)PCHCXX,$$2)$$(call WRAP_COMPILER,$$(call CMN_$vCL,$$(dir $$1),$$2,/Yc$$3 /Yl$$(basename \
  $$(notdir $$2)) /Fp$$(dir $$1)$$(basename $$(notdir $$3))_cpp.pch $$(CXXFLAGS)),$$1,$$2,$$(basename $$1).d,$(UDEPS_INCLUDE_FILTER))
$(empty)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(MULTI_COMPILERS_TEMPLATE)))

endif # !SEQ_BUILD

DEF_DRV_LDFLAGS ?= /INCREMENTAL:NO $(if $(DEBUG),/DEBUG,/LTCG /OPT:REF) /DRIVER /FULLBUILD \
  /NODEFAULTLIB /SAFESEH:NO /MANIFEST:NO /MERGE:_PAGE=PAGE /MERGE:_TEXT=.text /MERGE:.rdata=.text \
  /SECTION:INIT,d /ENTRY:DriverEntry /ALIGN:0x40 /BASE:0x10000 /STACK:0x40000,0x1000 \
  /MACHINE:$(if $(KCPU:%64=),x86,x64) /SUBSYSTEM:NATIVE,$(SUBSYSTEM_KVER)

# $1 - target, $2 - objects
# target-specific: RES, KLIBS, SYSLIBPATH, SYSLIBS, LDFLAGS
DRV_LD1 = $(call SUP,KLINK,$1)$(WKLD) /nologo $(DEF_DRV_LDFLAGS) /OUT:$(call ospath,$1 $2 $(RES)) $(if \
  $(KLIBS),/LIBPATH:$(call ospath,$(LIB_DIR))) $(addsuffix $(KLIB_SUFFIX),$(addprefix \
  $(KLIB_PREFIX),$(KLIBS))) $(call qpath,$(call ospath,$(SYSLIBPATH)),/LIBPATH:) $(SYSLIBS) $(LDFLAGS)

# flags for kernel-level C-compiler
ifeq (undefined,$(origin KRN_FLAGS))
KRN_FLAGS := /X /GF /W3 /GR- /Gz /Zl /GS- /Oi /Z7
ifdef DEBUG
KRN_FLAGS := /Od
else
KRN_FLAGS := /Gy
endif
endif

# $1 - outdir, $2 - sources, $3 - flags
# target-specific: DEFINES, INCLUDE
CMN_KCL = $(WKCL) /nologo /c $(KRN_FLAGS) $(call SUBST_DEFINES,$(addprefix /D,$(DEFINES))) $(call \
  qpath,$(call ospath,$(INCLUDE)) $(KMINC),/I) /Fo$(ospath) /Fd$(ospath) $3 $(call ospath,$2)

ifdef SEQ_BUILD

# sequential build: don't add /MP option to Visual Studio C compiler
# note: auto-dependencies generation available only in sequential mode - /MP conflicts with /showIncludes
# note: precompiled headers are not supported in this mode

KDEPS_INCLUDE_FILTER ?= c:\\winddk\\

# $1 - target, $2 - source
# target-specific: CFLAGS
CMN_KCC   = $(call SUP,KCC,$2)$(call WRAP_COMPILER,$(call CMN_KCL,$(dir $1),$2,$(CFLAGS)),$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))
KLIB_R_CC = $(CMN_KCC)
DRV_R_CC  = $(CMN_KCC)
KLIB_LD   = $(KLIB_LD1)
DRV_LD    = $(DRV_LD1)

FORCE_SYNC_PDB_KERN ?= $(FORCE_SYNC_PDB)

# option for parallel builds, starting from Visual Studio 2013
KRN_FLAGS += $(FORCE_SYNC_PDB_KERN) #/FS

else # !SEQ_BUILD

# multi-source build: build multiple sources at one CL call - using /MP option
# note: auto-dependencies generation is not supported in this mode - /MP conflicts with /showIncludes
# note: there is support for precompiled headers in this mode

# $1 - outdir, $2 - pch, $3 - non-pch sources, $4 - pch sources
# target-specific: CFLAGS
CMN_MKCL1 = $(if \
  $3,$(call SUP,MKCC,$3)$(call CMN_KCL,$1,$3,/MP $(CFLAGS))$(newline))$(if \
  $4,$(call SUP,MPKCC,$4)$(call CMN_KCL,$1,$4,/MP /Yu$2 /Fp$1$(basename $(notdir $2))_c.pch /FI$2 $(CFLAGS))$(newline))

# $1 - outdir, $2 - C-sources
# target-specific: PCH, WITH_PCH
CMN_MKCL = $(call CMN_MKCL1,$1,$(PCH),$(filter-out $(WITH_PCH),$2),$(filter $(WITH_PCH),$2))

# $1 - target, $2 - objects
# target-specific: SRC, SDEPS
KLIB_LD = $(call CMN_MKCL,$(dir $(firstword $2)),$(sort $(filter $(SRC),$? $(call FILTER_SDEPS,$(SDEPS)))))$(KLIB_LD1)
DRV_LD  = $(call CMN_MKCL,$(dir $(firstword $2)),$(sort $(filter $(SRC),$? $(call FILTER_SDEPS,$(SDEPS)))))$(DRV_LD1)

# $1 - target, $2 - pch-source, $3 - pch
# target-specific: CFLAGS
PCH_KCC = $(call SUP,PCHKCC,$2)$(call WRAP_COMPILER,$(call CMN_KCL,$(dir $1),$2,/Yc$3 /Yl$(basename \
  $(notdir $2)) /Fp$(dir $1)$(basename $(notdir $3))_c.pch $(CFLAGS)),$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))

endif # !SEQ_BUILD

# kernel-level assembler
# $1 - target, $2 - asm-source
# target-specific: ASMFLAGS
KLIB_R_ASM ?= $(call SUP,ASM,$2)$(YASMC) -o $(call ospath,$1 $2) $(ASMFLAGS)
DRV_R_ASM  ?= $(KLIB_R_ASM)

# $1 - target, $2 - source
BISON ?= $(call SUP,BISON,$2)$(CD) && $(BISONC) -d --fixed-output-files $(call ospath,$(call abspath,$2))
FLEX  ?= $(call SUP,FLEX,$2)$(FLEXC) -o$(call ospath,$1 $2)

ifndef SEQ_BUILD

# templates to create precompiled header
# note: for now implemented only for multi-source build
# NOTE: $(PCH) - makefile-related path to header to precompile

# $1 - EXE,LIB,DLL
# $2 - $(call GET_TARGET_NAME,$1)
# $3 - $$(basename $$(notdir $$(TRG_PCH)))
# target-specific: $$(PCH)
define PCH_TEMPLATE1
TRG_PCH := $(call FIXPATH,$(firstword $($1_PCH) $(PCH)))
TRG_WITH_PCH := $(call FIXPATH,$(WITH_PCH) $($1_WITH_PCH))
PCH_C_SRC := $(GEN_DIR)/pch/$2_$1_$3_c.c
PCH_CXX_SRC := $(GEN_DIR)/pch/$2_$1_$3_cpp.cpp
NEEDED_DIRS += $(GEN_DIR)/pch
$$(PCH_C_SRC) $$(PCH_CXX_SRC): | $(GEN_DIR)/pch
	$(if $(VERBOSE),,@)echo #include "$$(PCH)" > $$@
CLEAN += $$(if $$(filter %.c,$$(TRG_WITH_PCH)),$$(PCH_C_SRC)) $$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(PCH_CXX_SRC))
endef

# $1 - EXE,LIB,DLL
# $2 - $(call GET_TARGET_NAME,$1)
# $3 - $$(basename $$(notdir $$(TRG_PCH)))
# $4 - $(call FORM_OBJ_DIR,$1,$v)
# $5 - $(call FORM_TRG,$1,$v)
# $v - R,S,RU,SU
# note: $(NO_DEPS) - may be recursive and so have different values, for example depending on value of $(CURRENT_MAKEFILE)
# note: $$(PCH_OBJS) will be built before link phase - before sources are compiled with MCL
define PCH_TEMPLATE2
$(empty)
$5: PCH := $$(TRG_PCH)
$5: WITH_PCH := $$(TRG_WITH_PCH)
PCH_C_OBJ := $4/$2_$1_$3_c$(OBJ_SUFFIX)
PCH_CXX_OBJ := $4/$2_$1_$3_cpp$(OBJ_SUFFIX)
$$(PCH_C_OBJ): $$(PCH_C_SRC) $$(TRG_PCH) | $4 $$(ORDER_DEPS)
	$$(call PCH_$v_CC,$$@,$$<,$$(PCH))
$$(PCH_CXX_OBJ): $$(PCH_CXX_SRC) $$(TRG_PCH) | $4 $$(ORDER_DEPS)
	$$(call PCH_$v_CXX,$$@,$$<,$$(PCH))
PCH_OBJS := $$(if $$(filter %.c,$$(TRG_WITH_PCH)),$$(PCH_C_OBJ)) $$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(PCH_CXX_OBJ))
$5: $$(PCH_OBJS)
ifeq ($(NO_DEPS),)
-include $$(addprefix $4/,$$(if \
  $$(filter %.c,$$(TRG_WITH_PCH)),$$(basename $$(notdir $$(PCH_C_SRC))).d) $$(if \
  $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(basename $$(notdir $$(PCH_CXX_SRC))).d))
endif
CLEAN += $$(PCH_OBJS)
CLEAN += $$(if $$(filter %.c,$$(TRG_WITH_PCH)),$4/$3_c.pch $4/$$(basename $$(notdir $$(PCH_C_SRC))).d)
CLEAN += $$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$4/$3_cpp.pch $4/$$(basename $$(notdir $$(PCH_CXX_SRC))).d)
endef

# $1 - EXE,LIB,DLL
# $2 - $(call GET_TARGET_NAME,$1)
# $3 - $$(basename $$(notdir $$(TRG_PCH)))
PCH_TEMPLATE3 = $(PCH_TEMPLATE1)$(foreach v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call \
  PCH_TEMPLATE2,$1,$2,$3,$(call FORM_OBJ_DIR,$1,$v),$(call FORM_TRG,$1,$v)))

# $1 - EXE,LIB,DLL
# note: must reset target-specific WITH_PCH if not using precompiled header,
# otherwise DLL or LIB target may inherit WITH_PCH value from EXE, LIB target may inherit WITH_PCH value from DLL
PCH_TEMPLATE = $(if $(word 2,$(firstword $($1_PCH)$(PCH)) $(firstword $(WITH_PCH)$($1_WITH_PCH))),$(call \
  PCH_TEMPLATE3,$1,$(call GET_TARGET_NAME,$1),$$(basename $$(notdir $$(TRG_PCH)))),$(foreach \
  v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call FORM_TRG,$1,$v): WITH_PCH:=$(newline)))

# $1 - KLIB,DRV
# $2 - $($1)
# $3 - $$(basename $$(notdir $$(TRG_PCH)))
# $4 - $(call FORM_OBJ_DIR,$1)
# $5 - $(call FORM_TRG,$1)
# note: $(NO_DEPS) - may be recursive and so have different values, for example depending on value of $(CURRENT_MAKEFILE)
# note: $$(PCH_C_OBJ) will be built before link phase - before sources are compiled with MKCL
define KPCH_TEMPLATE1
TRG_PCH := $(call FIXPATH,$(firstword $($1_PCH) $(PCH)))
$5: PCH := $$(TRG_PCH)
$5: WITH_PCH := $(call FIXPATH,$(WITH_PCH) $($1_WITH_PCH))
PCH_C_SRC := $(GEN_DIR)/pch/$2_$1_$3_c.c
NEEDED_DIRS += $(GEN_DIR)/pch
$$(PCH_C_SRC): | $(GEN_DIR)/pch
	$(if $(VERBOSE),,@)echo #include "$$(PCH)" > $$@
PCH_C_OBJ := $4/$2_$1_$3_c$(OBJ_SUFFIX)
$$(PCH_C_OBJ): $$(PCH_C_SRC) $$(TRG_PCH) | $4 $$(ORDER_DEPS)
	$$(call PCH_KCC,$$@,$$<,$$(PCH))
$5: $$(PCH_C_OBJ)
ifeq ($(NO_DEPS),)
-include $4/$$(basename $$(notdir $$(PCH_C_SRC))).d
endif
CLEAN += $$(PCH_C_OBJ) $$(PCH_C_SRC) $4/$3_c.pch $4/$$(basename $$(notdir $$(PCH_C_SRC))).d
endef

# $1 - KLIB,DRV
# note: must reset target-specific WITH_PCH if not using precompiled header,
# otherwise KLIB target may inherit WITH_PCH value from DRV
KPCH_TEMPLATE = $(if $(word 2,$(firstword $($1_PCH)$(PCH)) $(firstword $(WITH_PCH)$($1_WITH_PCH))),$(call \
  KPCH_TEMPLATE1,$1,$($1),$$(basename $$(notdir $$(TRG_PCH))),$(call FORM_OBJ_DIR,$1),$(call FORM_TRG,$1)),$(call FORM_TRG,$1): WITH_PCH:=)

endif # !SEQ_BUILD

# function to add (generated?) sources to $({EXE,LIB,DLL,...}_WITH_PCH) list - to compile sources with pch header
# $1 - EXE,LIB,DLL,... $2 - sources
ADD_WITH_PCH = $(eval $1_WITH_PCH += $2)

# auxiliary dependencies

# $1 - EXE,LIB,DLL,...
TRG_ALL_DEPS1 = $(if $1,$(word 2,$1) $(call TRG_ALL_DEPS1,$(wordlist 3,999999,$1)))
TRG_ALL_DEPS = $(call FIXPATH,$(subst |, ,$(call TRG_ALL_DEPS1,$(SDEPS) $($1_SDEPS))))

# $1 - $(call TRG_SRC,EXE)
# $2 - $(call TRG_DEPS,EXE)
# $3 - $(call TRG_ALL_DEPS,EXE)
# $4 - $(call FORM_TRG,EXE,$v)
# $5 - $(call FORM_OBJ_DIR,EXE,$v)
define EXE_AUX_TEMPLATE2
$(empty)
$4: SRC := $1
$4: SDEPS := $2
$4: $1 $3
ifdef DEBUG
CLEAN += $5/vc*.pdb $(4:$(EXE_SUFFIX)=.pdb)
endif
endef

# $1 - $(call TRG_SRC,EXE)
# $2 - $(call TRG_DEPS,EXE)
# $3 - $(call TRG_ALL_DEPS,EXE)
EXE_AUX_TEMPLATE1 = $(foreach v,$(call GET_VARIANTS,EXE,VARIANTS_FILTER),$(call \
  EXE_AUX_TEMPLATE2,$1,$2,$3,$(call FORM_TRG,EXE,$v),$(call FORM_OBJ_DIR,EXE,$v)))

# auxiliary defines for EXE:
# - standard resource
# - precompiled header
# - target-specific SRC and SDEPS (for CMN_MCL)
define EXE_AUX_TEMPLATE
$(call STD_RES_TEMPLATE,EXE)
$(call PCH_TEMPLATE,EXE)
$(call EXE_AUX_TEMPLATE1,$(call TRG_SRC,EXE),$(call TRG_DEPS,EXE),$(call TRG_ALL_DEPS,EXE))
endef

# $1 - $(call TRG_SRC,LIB)
# $2 - $(call TRG_DEPS,LIB)
# $3 - $(call TRG_ALL_DEPS,LIB)
# $4 - $(call FORM_TRG,LIB,$v)
# $5 - $(call FORM_OBJ_DIR,LIB,$v)
define LIB_AUX_TEMPLATE2
$(empty)
$4: SRC := $1
$4: SDEPS := $2
$4: $1 $3
ifdef DEBUG
CLEAN += $5/vc*.pdb
endif
endef

# $1 - $(call TRG_SRC,LIB)
# $2 - $(call TRG_DEPS,LIB)
# $3 - $(call TRG_ALL_DEPS,LIB)
LIB_AUX_TEMPLATE1 = $(foreach v,$(call GET_VARIANTS,LIB,VARIANTS_FILTER),$(call \
  LIB_AUX_TEMPLATE2,$1,$2,$3,$(call FORM_TRG,LIB,$v),$(call FORM_OBJ_DIR,LIB,$v)))

# auxiliary defines for LIB:
# - precompiled header
# - target-specific SRC and SDEPS (for CMN_MCL)
define LIB_AUX_TEMPLATE
ifneq ($(RES)$(LIB_RES),)
$$(error don't link resource(s) $(strip $(RES) $(LIB_RES)) into static library: linker will ignore resources in static library)
endif
$(call PCH_TEMPLATE,LIB)
$(call LIB_AUX_TEMPLATE1,$(call TRG_SRC,LIB),$(call TRG_DEPS,LIB),$(call TRG_ALL_DEPS,LIB))
endef

# $1 - $(call TRG_SRC,DLL)
# $2 - $(call TRG_DEPS,DLL)
# $3 - $(call TRG_ALL_DEPS,DLL)
# $4 - $(call FORM_TRG,DLL,$v)
# $5 - $(call FORM_OBJ_DIR,DLL,$v)
# $6 - $(IMP_DIR)/$(IMP_PREFIX)$(call GET_TARGET_NAME,DLL)$(call VARIANT_IMP_SUFFIX,$v)
# $7 - $(call FIXPATH,$(firstword $(DLL_DEF) $(DEF)))
define DLL_AUX_TEMPLATE2
$(empty)
$4: SRC := $1
$4: SDEPS := $2
$4: IMP := $6$(IMP_SUFFIX)
$4: DEF := $7
$4: $1 $3 $7 | $(IMP_DIR)
NEEDED_DIRS += $(IMP_DIR)
$6$(IMP_SUFFIX): $4
ifdef DEBUG
CLEAN += $5/vc*.pdb $(4:$(DLL_SUFFIX)=.pdb) $6$(IMP_SUFFIX) $6.exp
endif
endef

# $1 - $(call TRG_SRC,DLL)
# $2 - $(call TRG_DEPS,DLL)
# $3 - $(call TRG_ALL_DEPS,DLL)
# $4 - $(call GET_TARGET_NAME,DLL)
# $5 - $(call FIXPATH,$(firstword $(DLL_DEF) $(DEF)))
DLL_AUX_TEMPLATE1 = $(foreach v,$(call GET_VARIANTS,DLL,VARIANTS_FILTER),$(call \
  DLL_AUX_TEMPLATE2,$1,$2,$3,$(call FORM_TRG,DLL,$v),$(call \
  FORM_OBJ_DIR,DLL,$v),$(IMP_DIR)/$(IMP_PREFIX)$4$(call VARIANT_IMP_SUFFIX,$v),$5))

# auxiliary defines for DLL:
# - standard resource
# - precompiled header
# - target-specific SRC and SDEPS (for CMN_MCL) and IMP (for DLL_LD_TEMPLATE)
define DLL_AUX_TEMPLATE
$(call STD_RES_TEMPLATE,DLL)
$(call PCH_TEMPLATE,DLL)
$(call DLL_AUX_TEMPLATE1,$(call TRG_SRC,DLL),$(call TRG_DEPS,DLL),$(call TRG_ALL_DEPS,DLL),$(call \
  GET_TARGET_NAME,DLL),$(call FIXPATH,$(firstword $(DLL_DEF) $(DEF))))
endef

# $1 - $(call FORM_TRG,KLIB)
# $2 - $(call TRG_SRC,KLIB)
define KLIB_AUX_TEMPLATE1
$1: SRC := $2
$1: SDEPS := $(call TRG_DEPS,KLIB)
$1: $2 $(call TRG_ALL_DEPS,KLIB)
ifdef DEBUG
CLEAN += $(call FORM_OBJ_DIR,KLIB)/vc*.pdb
endif
endef

# auxiliary defines for KLIB:
# - precompiled header
# - target-specific SRC and SDEPS (for CMN_MKCL)
define KLIB_AUX_TEMPLATE
ifneq ($(RES)$(KLIB_RES),)
$$(error don't link resource(s) $(strip $(RES) $(KLIB_RES)) into static library: linker will ignore resources in static library)
endif
$(call KPCH_TEMPLATE,KLIB)
$(call KLIB_AUX_TEMPLATE1,$(call FORM_TRG,KLIB),$(call TRG_SRC,KLIB))
endef

# add rule to make auxiliary res for the target and generate header from .mc-file
# note: defines MC_H and MC_RC variables - absolute pathnames to generated .h and .rc files
# note: in target makefile may $(call ADD_RES_RULE,TRG,$(MC_RC)) to add .res-file to a target
# $1 - EXE,DLL,...
# $2 - NTServiceEventLogMsg.mc (either absolute or makefile-related)
define ADD_MC_RULE1
MC_DIR := $(GEN_DIR)/$(call GET_TARGET_NAME,$1)_$1_MC
MC_H   := $$(MC_DIR)/$(basename $(notdir $2)).h
MC_RC  := $$(MC_DIR)/$(basename $(notdir $2)).rc
CLEAN += $$(MC_DIR)
$$(call MULTI_TARGET,$$(MC_H) $$(MC_RC),$2,$$$$(call MC,$$(MC_H) $$(MC_RC)) -h $$(call \
  ospath,$$(MC_DIR)) -r $$(call ospath,$$(MC_DIR)) $$$$(call ospath,$$$$<))
endef
ADD_MC_RULE = $(eval $(ADD_MC_RULE1))

# rules to build auxiliary resources
# note: must be recursive macro - to delay expansion of RC options,
# for example to expand options after including USEs
CB_WINXX_RES_RULES=

# add rule to make auxiliary res for the target
# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional deps for .res
# $5 - $(call FORM_OBJ_DIR,$1)
# NOTE: EXE,DLL,...-target dependency on $(AUX_RES) is added in $(STD_RES_TEMPLATE)
# NOTE: generated .res is added to CLEAN list in $(OS_DEFINE_TARGETS) via $1_RES
define ADD_RES_RULE1
$(FIX_ORDER_DEPS)
AUX_RES := $5/$(basename $(notdir $2)).res
NEEDED_DIRS += $5
$$(AUX_RES): RES_OPTS := $3
$$(AUX_RES): $(call FIXPATH,$2 $4) | $5 $$(ORDER_DEPS)
	$$(call RC,$$@,$$<,$$(RES_OPTS))
$1_RES += $$(AUX_RES)
endef

# add rule to make auxiliary res for the target
# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional deps for .res
# NOTE: $3 - options for RC are expanded in $(OS_DEFINE_TARGETS), after including USEs
ADD_RES_RULE = $(eval CB_WINXX_RES_RULES += $(subst $(newline),$$(newline),$(call ADD_RES_RULE1,$1,$2,$3,$4,$(call FORM_OBJ_DIR,$1))))

# used to specify path to some resource for rc.exe via /DMY_BMP=$(call RC_DEFINE_PATH,$(TOP)/xx/yy/tt.bmp)
RC_DEFINE_PATH = "\"$(subst \,\\,$(ospath))\""

# $1 - target file: $(call FORM_TRG,DRV)
# $2 - sources:     $(call TRG_SRC,DRV)
# $3 - deps:        $(call TRG_DEPS,DRV)
# $4 - objdir:      $(call FORM_OBJ_DIR,DRV)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
define DRV_TEMPLATE
$(call STD_RES_TEMPLATE,DRV)
$(call KPCH_TEMPLATE,DRV)
NEEDED_DIRS += $4
$(call OBJ_RULES,DRV,CC,$(filter %.c,$2),$3,$4)
$(call OBJ_RULES,DRV,ASM,$(filter %.asm,$2),$3,$4)
$(STD_TARGET_VARS)
$1: SRC        := $2
$1: SDEPS      := $3
$1: LIB_DIR    := $(LIB_DIR)
$1: KLIBS      := $(KLIBS)
$1: INCLUDE    := $(call TRG_INCLUDE,DRV)
$1: DEFINES    := $(KRNDEFS) $(DEFINES) $(DRV_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(DRV_CFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(DRV_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(DRV_LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS) $(DRV_SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH) $(DRV_SYSLIBPATH)
$1: $(addsuffix $(KLIB_SUFFIX),$(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(KLIBS))) $5 $2 $(call TRG_ALL_DEPS,DRV)
	$$(call DRV_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
CLEAN += $5
ifdef DEBUG
CLEAN += $4/vc*.pdb $(1:$(DRV_SUFFIX)=.pdb)
endif
endef

# how to build driver
DRV_RULES1 = $(call DRV_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
DRV_RULES = $(if $(DRV),$(call DRV_RULES1,$(call FORM_TRG,DRV),$(call TRG_SRC,DRV),$(call TRG_DEPS,DRV),$(call FORM_OBJ_DIR,DRV)))

# this code is evaluated from $(DEFINE_TARGETS)
# NOTE: $(STD_RES_TEMPLATE) adds standard resource to $1_RES, so postpone evaluation of $($x_RES) when adding it to CLEAN
# NOTE: reset NO_STD_RES variable - it may be temporary set to disable adding standard resource to the target
define OS_DEFINE_TARGETS
$(subst $$(newline),$(newline),$(value CB_WINXX_RES_RULES))
$(if $(EXE),$(EXE_AUX_TEMPLATE))
$(if $(LIB),$(LIB_AUX_TEMPLATE))
$(if $(DLL),$(DLL_AUX_TEMPLATE))
$(if $(KLIB),$(KLIB_AUX_TEMPLATE))
$(DRV_RULES)
CLEAN += $(RES) $(foreach x,$(BLD_TARGETS),$$($x_RES))
CB_WINXX_RES_RULES=
NO_STD_RES:=
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,SEQ_BUILD YASMC FLEXC BISONC MC SUPPRESS_RC_LOGO RC \
  EXE_SUFFIX OBJ_SUFFIX LIB_PREFIX LIB_SUFFIX IMP_PREFIX IMP_SUFFIX DLL_PREFIX DLL_SUFFIX KLIB_PREFIX KLIB_SUFFIX DRV_PREFIX DRV_SUFFIX \
  DLL_DIR IMP_DIR SUBSYSTEM_KVER OS_PREDEFINES MAY_EMBED_MANIFEST \
  EMBED_EXE_MANIFEST DLL_MANIFEST_OPTION EMBED_DLL_MANIFEST \
  OS_APPDEFS OS_KRNDEFS VARIANTS_FILTER VARIANT_LIB_MAP VARIANT_IMP_MAP \
  CHECK_LIB_UNI_NAME1 CHECK_LIB_UNI_NAME CMN_LIBS_LDFLAGS CMN_LIBS \
  DEF_EXE_SUBSYSTEM EXE_LD_TEMPLATE DEL_ON_DLL_FAIL DLL_LD_TEMPLATE DEF_LIB_LDFLAGS LIB_LD_TEMPLATE DEF_KLIB_LDFLAGS \
  $(foreach v,R $(VARIANTS_FILTER),EXE_$v_LD1 DLL_$v_LD1 LIB_$v_LD1) KLIB_LD1 \
  APP_FLAGS CMN_CL1 CMN_RCL CMN_SCL CMN_RUCL CMN_SUCL \
  INCLUDING_FILE_PATTERN UDEPS_INCLUDE_FILTER SED_DEPS_SCRIPT \
  WRAP_COMPILER CMN_CC CMN_CXX SEQ_COMPILERS_TEMPLATE \
  $(foreach v,R $(VARIANTS_FILTER),LIB_$v_CC LIB_$v_CXX EXE_$v_CC EXE_$v_CXX DLL_$v_CC DLL_$v_CXX EXE_$v_LD DLL_$v_LD LIB_$v_LD) \
  CMN_MCL2 CMN_MCL1 CMN_RMCL CMN_SMCL CMN_RUMCL CMN_SUMCL FILTER_SDEPS CMN_MCL MULTI_COMPILERS_TEMPLATE \
  $(foreach v,R $(VARIANTS_FILTER),PCH_$v_CC PCH_$v_CXX) \
  DEF_DRV_LDFLAGS DRV_LD1 KRN_FLAGS CMN_KCL KDEPS_INCLUDE_FILTER CMN_KCC KLIB_R_CC DRV_R_CC KLIB_LD DRV_LD FORCE_SYNC_PDB_KERN \
  CMN_MKCL1 CMN_MKCL PCH_KCC KLIB_R_ASM BISON FLEX \
  PCH_TEMPLATE1 PCH_TEMPLATE2 PCH_TEMPLATE3 PCH_TEMPLATE KPCH_TEMPLATE1 KPCH_TEMPLATE ADD_WITH_PCH \
  TRG_ALL_DEPS1 TRG_ALL_DEPS \
  EXE_AUX_TEMPLATE2 EXE_AUX_TEMPLATE1 EXE_AUX_TEMPLATE \
  LIB_AUX_TEMPLATE2 LIB_AUX_TEMPLATE1 LIB_AUX_TEMPLATE \
  DLL_AUX_TEMPLATE2 DLL_AUX_TEMPLATE1 DLL_AUX_TEMPLATE \
  KLIB_AUX_TEMPLATE1 KLIB_AUX_TEMPLATE \
  ADD_MC_RULE1 ADD_MC_RULE ADD_RES_RULE1 ADD_RES_RULE RC_DEFINE_PATH \
  DRV_TEMPLATE DRV_RULES1 DRV_RULES)
