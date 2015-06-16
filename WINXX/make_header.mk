include $(MTOP)/$(OS)/make_stdres.mk

# run via $(MAKE) S=1 to compile sources sequentially
ifeq ("$(origin S)","command line")
SEQ := $S
else
SEQ:=
endif

# run via $(MAKE) A=1 to show autoconf results
ifeq ("$(origin A)","command line")
VAUTO := $A
else
VAUTO:=
endif

include $(MTOP)/WINXX/autoconf.mk

ifndef YASM
YASM := yasm.exe $(if $(filter %64,$(KCPU)),-f win64 -m amd64,-f win32 -m x86)
endif

# environment variable LIB holds path to system libraries,
# but we have our own meaning of variable LIB (static library target)
# so undefine it
LIB :=

MC  = $(call SUPRESS,$(TMD)MC,$1)$($(TMD)MC1) $(if $(VERBOSE:1=),,-v)
RC  = $(call SUPRESS,$(TMD)RC,$1)$($(TMD)RC1) $(if $(VERBOSE:1=),,/v) $(SUPRESS_RC_LOGO) $3 $(call \
  pqpath,/I,$(VS$(TMD)INC) $(UM$(TMD)INC)) /fo$(ospath) $(call ospath,$2)

EXE_SUFFIX := .exe
OBJ_SUFFIX := .obj
LIB_PREFIX :=
LIB_SUFFIX := .a
IMP_PREFIX :=
IMP_SUFFIX := .lib
DLL_PREFIX :=
DLL_SUFFIX := .dll
KLIB_PREFIX :=
KLIB_SUFFIX := .ka
DRV_PREFIX := drv
DRV_SUFFIX := .sys

# dll and import file for dll - different files
DLL_DIR = $(BIN_DIR)
IMP_DIR = $(LIB_DIR)

ifeq ($(OSVARIANT),WIN81)
WINVER_DEFINES ?= WINVER=0x0603 _WIN32_WINNT=0x0603
SUBSYSTEM_VER ?= 6.03
else ifeq ($(OSVARIANT),WIN8)
WINVER_DEFINES ?= WINVER=0x0602 _WIN32_WINNT=0x0602
SUBSYSTEM_VER ?= 6.02
else ifeq ($(OSVARIANT),WIN7)
WINVER_DEFINES ?= WINVER=0x0601 _WIN32_WINNT=0x0601
SUBSYSTEM_VER ?= 6.01
else ifeq ($(OSVARIANT),WINXP)
WINVER_DEFINES ?= WINVER=0x0501 _WIN32_WINNT=0x0501
SUBSYSTEM_VER ?= $(if $(filter %64,$(UCPU)),5.02,5.01)
else
$(error Unknown OSVARIANT, set to either WINXP,WIN7,WIN8 or WIN81)
endif

# evaluate once
SUBSYSTEM_VER := $(SUBSYSTEM_VER)

ifndef OS_PREDEFINES
OS_PREDEFINES := WINXX $(OSVARIANT) $(WINVER_DEFINES)
endif

ifdef MAY_EMBED_MANIFEST
EMBED_EXE_MANIFEST := $(space)/MANIFEST:EMBED
DLL_MANIFEST_OPTION := $(space)/MANIFEST:EMBED
else
EMBED_EXE_MANIFEST = $(call DEL_ON_FAIL,$1.manifest)$(newline)$(if \
  $(VERBOSE:1=),@)if exist $(ospath).manifest ($($(TMD)MT1) -nologo -manifest $(ospath).manifest -outputresource:$(ospath);1 && del $(ospath).manifest)$(DEL_ON_FAIL)
EMBED_DLL_MANIFEST = $(newline)$(if \
  $(VERBOSE:1=),@)if exist $(ospath).manifest ($($(TMD)MT1) -nologo -manifest $(ospath).manifest -outputresource:$(ospath);2 && del $(ospath).manifest)$(DEL_ON_FAIL)
endif

# some external sources want WIN32 to be defined
ifndef OS_APPDEFS
OS_APPDEFS := $(if $(filter %64,$(UCPU)),LLP64,ILP32) WIN32 CRT_SECURE_NO_DEPRECATE _CRT_SECURE_NO_WARNINGS
endif
ifndef OS_KRNDEFS
OS_KRNDEFS := $(if $(filter %64,$(KCPU)),LLP64 _WIN64 _AMD64_,ILP32 _WIN32 _X86_) _KERNEL WIN32_LEAN_AND_MEAN
endif

# supported target variants:
# R  - dynamicaly linked multi-threaded libc (default)
# S  - statically linked multithreaded libc
# RU - same as R, but with unicode support
# SU - same as S, but with unicode support
VARIANTS_FILTER := S RU SU

# use the same variant of static library as target EXE or DLL
# use appropriate R or S variant of non-UNI_ static library for RU or SU variant of target EXE or DLL
VARIANT_LIB_MAP = $(if $(filter UNI_%,$l),$2,$(subst U,,$2))

# use the same variant of dynamic library as target EXE or DLL
# use appropriate R or S variant of non-UNI_ dynamic library for RU or SU variant of target EXE or DLL
VARIANT_IMP_MAP = $(if $(filter UNI_%,$d),$2,$(subst U,,$2))

# check that library name built as RU/SU variant started with UNI_ prefix
# $1 - IMP or LIB
# $v - variant name: R,S,RU,SU
# $$1 - target library name
CHECK_UNI_NAME1 = $(if $(filter UNI_%,$1),,$(error library '$1' name must start with UNI_ prefix to build it as $2 variant))
CHECK_UNI_NAME = $(if $(filter %U,$v),$$(call CHECK_UNI_NAME1,$$(patsubst $(call VARIANT_$1_PREFIX,$v)%$($1_SUFFIX),%,$$(notdir $$1)),$v))

# $1 - target, $2 - objects, $3 - variant
# note: target variable is not used in VARIANT_LIB_MAP and VARIANT_IMP_MAP, so may pass XXX as first parameter of MAKE_DEP_LIBS and MAKE_DEP_IMPS
CMN_LIBS = /OUT:$$(call ospath,$1) /INCREMENTAL:NO $(if $(DEBUG),/DEBUG,/LTCG /OPT:REF) $$(call ospath,$2 $$(RES)) $$(if \
           $$(strip $$(LIBS)$$(DLLS)),/LIBPATH:$$(call ospath,$$(LIB_DIR))) $$(call MAKE_DEP_LIBS,XXX,$3,$$(LIBS)) $$(call \
            MAKE_DEP_IMPS,XXX,$3,$$(DLLS)) $$(call pqpath,/LIBPATH:,$$(VS$$(TMD)LIB) $$(UM$$(TMD)LIB) $$(call \
            ospath,$$(SYSLIBPATH))) $$(SYSLIBS) $$(if $$(filter /SUBSYSTEM:%,$$(LDFLAGS)),,/SUBSYSTEM:CONSOLE,$(SUBSYSTEM_VER)) $$(LDFLAGS)

define EXE_LD_TEMPLATE
$(empty)
EXE_$v_LD1 = $$(call SUPRESS,$(TMD)LINK,$$1)$$(VS$$(TMD)LD) /nologo $(call CMN_LIBS,$$1,$$2,$v)$$(EMBED_EXE_MANIFEST)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(EXE_LD_TEMPLATE)))

# Link.exe has a bug: it may not delete target dll if DEF was specified and were errors while building the dll
DEL_ON_DLL_FAIL = $(if $(DEF)$(EMBED_DLL_MANIFEST),$(call DEL_ON_FAIL,$(if $(DEF),$1) $(if $(EMBED_DLL_MANIFEST),$1.manifest)))

define DLL_LD_TEMPLATE
$(empty)
DLL_$v_LD1 = $$(call SUPRESS,$(TMD)LINK,$$1)$$(VS$$(TMD)LD) /nologo /DLL $$(if $$(DEF),/DEF:$$(call ospath,$$(DEF))) $(call \
              CMN_LIBS,$$1,$$2,$v) /IMPLIB:$$(call ospath,$$(patsubst $$(DLL_DIR)/$(DLL_PREFIX)%$(DLL_SUFFIX),$$(IMP_DIR)/$(IMP_PREFIX)$(call \
              VARIANT_IMP_PREFIX,$v)%$(IMP_SUFFIX),$$1))$(DLL_MANIFEST_OPTION)$$(DEL_ON_DLL_FAIL)$$(EMBED_DLL_MANIFEST)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(DLL_LD_TEMPLATE)))

define LIB_LD_TEMPLATE
$(empty)
LIB_$v_LD1 = $(call CHECK_UNI_NAME,LIB)$$(call SUPRESS,$(TMD)LIB,$$1)$$(VS$$(TMD)LD) /lib /nologo /OUT:$$(call ospath,$$1 $$2) $(if $(DEBUG),,/LTCG) $$(LDFLAGS)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(LIB_LD_TEMPLATE)))

KLIB_LD1 = $(call SUPRESS,KLIB,$1)$(WKLD) /lib /nologo /OUT:$(call ospath,$1 $2) $(if $(DEBUG),,/LTCG) $(LDFLAGS)

ifdef DEBUG
DEF_APP_FLAGS := /X /GF /W3 /EHsc /Od /Zi /RTCc /RTCsu /GS
else
DEF_APP_FLAGS := /X /GF /W3 /EHsc /Ox /GL /Gy
endif
DEF_APP_FLAGS += /wd4251# 'class' needs to have dll-interface to be used by clients of class...
DEF_APP_FLAGS += /wd4275# non dll-interface class 'class' used as base for dll-interface class 'class'
DEF_APP_FLAGS += /wd4996# 'strdup': The POSIX name for this item is deprecated...

ifeq (undefined,$(origin APP_FLAGS))
APP_FLAGS := $(DEF_APP_FLAGS)
endif

# $1 - outdir, $2 - sources, $3 - flags
CMN_CL1  = $(VS$(TMD)CL) /nologo /c $(APP_FLAGS) $(call SUBST_DEFINES,$(addprefix /D,$(DEFINES))) $(call \
            pqpath,/I,$(call ospath,$(INCLUDE)) $(VS$(TMD)INC) $(UM$(TMD)INC)) /Fo$(ospath) /Fd$(ospath) $3 $(call ospath,$2)

CMN_RCL  = $(CMN_CL1) /MD$(if $(DEBUG),d)
CMN_SCL  = $(CMN_CL1) /MT$(if $(DEBUG),d)
CMN_RUCL = $(CMN_RCL) /DUNICODE /D_UNICODE
CMN_SUCL = $(CMN_SCL) /DUNICODE /D_UNICODE

ifdef SEQ

INCLUDING_FILE_PATTERN ?= Note: including file:
INCLUDING_FILE_PATTERN1 := $(INCLUDING_FILE_PATTERN)

UDEPS_INCLUDE_FILTER ?= c:\\program?files?(x86)\\microsoft?visual?studio?10.0\\vc\\include\\
UDEPS_INCLUDE_FILTER1 := $(UDEPS_INCLUDE_FILTER)

# $2 - target object file, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes to filter out
SED_DEPS_SCRIPT = 1{x;s@.*@$2: $3 \\@;x;};/^$(notdir $3)$$/d;\
/^COMPILATION_FAILED/{H;s@^COMPILATION_FAILED@$(INCLUDING_FILE_PATTERN1) &@;};\
/^$(INCLUDING_FILE_PATTERN1) /!{p;s@.*@|@;};s@^$(INCLUDING_FILE_PATTERN1) COMPILATION_FAILED@|@;\
/^$(INCLUDING_FILE_PATTERN1) /{s@^$(INCLUDING_FILE_PATTERN1)  *@@;$(subst \
?, ,$(subst $(space),,$(foreach x,$5,s@^$x.*@|@I;)))s@ @\\ @g;};/^|/!{H;s@.*@&:@;x;s@.*@& \\@;x;};$${x;H;s@.*@@;H;x;s@^|@@;};/^|/d;w $4

# $1 - compiler with options, $2 - target object, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes
ifdef NO_DEPS
WRAP_COMPILER = $1
else
WRAP_COMPILER = ($1 /showIncludes 2>&1 || echo COMPILATION_FAILED) | sed.exe -n "$(SED_DEPS_SCRIPT)" && findstr /b COMPILATION_FAILED $(call \
  ospath,$4) > NUL & if errorlevel 1 (cmd /c exit 0) else (del $(call ospath,$4) && cmd /c exit 1)
endif

# $1 - target, $2 - source, $3 - compiler
CMN_CC   = $(call SUPRESS,$(TMD)CC,$2)$(call WRAP_COMPILER,$(call $3,$(dir $1),$2,$(CFLAGS)),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER1))
CMN_CXX  = $(call SUPRESS,$(TMD)CXX,$2)$(call WRAP_COMPILER,$(call $3,$(dir $1),$2,$(CXXFLAGS)),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER1))

# $1 - target, $2 - source
define COMPILTERS_TEMPLATE
$(empty)
LIB_$v_CC  = $$(call CMN_CC,$$1,$$2,CMN_$vCL)
LIB_$v_CXX = $$(call CMN_CXX,$$1,$$2,CMN_$vCL)
EXE_$v_CC  = $$(LIB_$v_CC)
EXE_$v_CXX = $$(LIB_$v_CXX)
DLL_$v_CC  = $$(EXE_$v_CC)
DLL_$v_CXX = $$(EXE_$v_CXX)
EXE_$v_LD  = $$(EXE_$v_LD1)
DLL_$v_LD  = $$(DLL_$v_LD1)
LIB_$v_LD  = $$(LIB_$v_LD1)
$(empty)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(COMPILTERS_TEMPLATE)))

APP_FLAGS += $(FORCE_SYNC_PDB) #/FS

else # !SEQ

# $1 - outdir, $2 - pch, $3 - non-pch C, $4 - non-pch CXX, $5 - pch C, $6 - pch CXX, $7 - compiler, $8 - aux compiler flags
CMN_MCL2 = $(if \
            $3,$(call SUPRESS,$(TMD)MCC,$3)$(call $7,$1,$3,$8/MP $(CFLAGS))$(newline))$(if \
            $4,$(call SUPRESS,$(TMD)MCXX,$4)$(call $7,$1,$4,$8/MP $(CXXFLAGS))$(newline))$(if \
            $5,$(call SUPRESS,$(TMD)MPCC,$5)$(call $7,$1,$5,$8/MP /Yu$2 /Fp$1$(basename $2)_c.pch /FI$2 $(CFLAGS))$(newline))$(if \
            $6,$(call SUPRESS,$(TMD)MPCXX,$6)$(call $7,$1,$6,$8/MP /Yu$2 /Fp$1$(basename $2)_cpp.pch /FI$2 $(CXXFLAGS))$(newline))

# $1 - outdir, $2 - C-sources, $3 - CXX-sources, $4 - compiler, $5 - aux compiler flags
CMN_MCL1 = $(call CMN_MCL2,$1,$(PCH),$(filter-out $(WITH_PCH),$2),$(filter-out \
            $(WITH_PCH),$3),$(filter $(WITH_PCH),$2),$(filter $(WITH_PCH),$3),$4,$5)

# $1 - outdir, $2 - sources, $3 - aux compiler flags
CMN_RMCL = $(call CMN_MCL1,$1,$(filter %.c,$2),$(filter %.cpp,$2),CMN_RCL,$3)
CMN_SMCL = $(call CMN_MCL1,$1,$(filter %.c,$2),$(filter %.cpp,$2),CMN_SCL,$3)
CMN_RUMCL = $(call CMN_RMCL,$1,$2,/DUNICODE /D_UNICODE )
CMN_SUMCL = $(call CMN_SMCL,$1,$2,/DUNICODE /D_UNICODE )

# also recompile sources that are depend on changed sources
# $1 - $(SDEPS) - list of pairs: <source file> <dependency1>|<dependency2>|...
FILTER_SDEPS = $(if $1,$(if $(filter $(subst |, ,$(word 2,$1)),$?),$(firstword $1) )$(call FILTER_SDEPS,$(wordlist 3,999999,$1)))

# $1 - target, $2 - objects, $3 - CMN_RMCL, CMN_SMCL, CMN_RUMCL, CMN_SUMCL
CMN_MCL = $(call $3,$(dir $(firstword $(filter %$(OBJ_SUFFIX),$2))),$(sort $(filter $(SRC),$? $(call FILTER_SDEPS,$(SDEPS)))))

define COMPILTERS_TEMPLATE
# $$1 - target, $$2 - objects
EXE_$v_LD  = $$(call CMN_MCL,$$1,$$2,CMN_$vMCL)$$(EXE_$v_LD1)
DLL_$v_LD  = $$(call CMN_MCL,$$1,$$2,CMN_$vMCL)$$(DLL_$v_LD1)
LIB_$v_LD  = $$(call CMN_MCL,$$1,$$2,CMN_$vMCL)$$(LIB_$v_LD1)
# $$1 - target, $$2 - pch-source, $$3 - pch
PCH_$v_CC  = $$(call SUPRESS,$(TMD)PCHCC,$$2)$$(call CMN_$vCL,$$(dir $$1),$$2,/Yc$$3 /Yl$$(basename $$(notdir $$2)) /Fp$$(dir $$1)$$(basename $$3)_c.pch $$(CFLAGS))
PCH_$v_CXX = $$(call SUPRESS,$(TMD)PCHCXX,$$2)$$(call CMN_$vCL,$$(dir $$1),$$2,/Yc$$3 /Yl$$(basename $$(notdir $$2)) /Fp$$(dir $$1)$$(basename $$3)_cpp.pch $$(CXXFLAGS))
$(empty)
endef
$(eval $(foreach v,R $(VARIANTS_FILTER),$(COMPILTERS_TEMPLATE)))

endif # !SEQ

DRV_LNK := $(WKLD) /nologo /INCREMENTAL:NO $(if $(DEBUG),/DEBUG,/LTCG /OPT:REF) /DRIVER /FULLBUILD \
             /NODEFAULTLIB /SAFESEH:NO /MANIFEST:NO /MERGE:_PAGE=PAGE /MERGE:_TEXT=.text /MERGE:.rdata=.text \
             /SECTION:INIT,d /ENTRY:DriverEntry /ALIGN:0x40 /BASE:0x10000 /STACK:0x40000,0x1000 \
             /MACHINE:$(if $(filter %64,$(KCPU)),x64,x86) \
             /SUBSYSTEM:NATIVE,$(if \
              $(filter WIN81,$(OSVARIANT)),6.03,$(if \
              $(filter WIN8,$(OSVARIANT)),6.02,$(if \
              $(filter WIN7,$(OSVARIANT)),6.01,$(if $(filter %64,$(KCPU)),5.02,5.01))))

# $1 - target, $2 - objects
DRV_LD1  = $(call SUPRESS,KLINK,$1)$(DRV_LNK) /OUT:$(call ospath,$1 $2 $(RES)) $(if \
           $(KLIBS),/LIBPATH:$(call ospath,$(LIB_DIR))) $(addsuffix $(KLIB_SUFFIX),$(addprefix \
           $(KLIB_PREFIX),$(KLIBS))) $(call pqpath,/LIBPATH:,$(call ospath,$(SYSLIBPATH))) $(SYSLIBS) $(LDFLAGS)

ifdef DEBUG
DEF_KERN_FLAGS := /X /GF /W3 /GR- /Gz /Zl /GS- /Oi /Z7 /Od
else
DEF_KERN_FLAGS := /X /GF /W3 /GR- /Gz /Zl /GS- /Ox /GL /Gy
endif

ifeq (undefined,$(origin KERN_FLAGS))
KERN_FLAGS := $(DEF_KERN_FLAGS)
endif

# $1 - outdir, $2 - sources, $3 - flags
CMN_KCL  = $(WKCL) /nologo /c $(KERN_FLAGS) $(call SUBST_DEFINES,$(addprefix /D,$(DEFINES))) $(call \
            pqpath,/I,$(call ospath,$(INCLUDE)) $(KMINC)) /Fo$(ospath) /Fd$(ospath) $3 $(call ospath,$2)

ifdef SEQ

KDEPS_INCLUDE_FILTER ?= c:\\winddk\\
KDEPS_INCLUDE_FILTER1 := $(KDEPS_INCLUDE_FILTER)

# $1 - target, $2 - source
CMN_KCC   = $(call SUPRESS,KCC,$2)$(call WRAP_COMPILER,$(call CMN_KCL,$(dir $1),$2,$(CFLAGS)),$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER1))
KLIB_R_CC = $(CMN_KCC)
DRV_R_CC  = $(CMN_KCC)
KLIB_LD   = $(KLIB_LD1)
DRV_LD    = $(DRV_LD1)

ifndef FORCE_SYNC_PDB_KERN
FORCE_SYNC_PDB_KERN := $(FORCE_SYNC_PDB)
endif

KERN_FLAGS += $(FORCE_SYNC_PDB_KERN) #/FS

else # !SEQ

# $1 - outdir, $2 - pch, $3 - non-pch sources, $4 - pch sources
CMN_MKCL1 = $(if \
            $3,$(call SUPRESS,MKCC,$3)$(call CMN_KCL,$1,$3,/MP $(CFLAGS))$(newline))$(if \
            $4,$(call SUPRESS,MPKCC,$4)$(call CMN_KCL,$1,$4,/MP /Yu$2 /Fp$1$(basename $2)_c.pch /FI$2 $(CFLAGS))$(newline))

# $1 - outdir, $2 - C-sources
CMN_MKCL = $(call CMN_MKCL1,$1,$(PCH),$(filter-out $(WITH_PCH),$2),$(filter $(WITH_PCH),$2))

# $1 - target, $2 - objects
KLIB_LD  = $(call CMN_MKCL,$(dir $(firstword $(filter %$(OBJ_SUFFIX),$2))),$(sort $(filter $(filter %.c,$(SRC)),$? $(call FILTER_SDEPS,$(SDEPS)))))$(KLIB_LD1)
DRV_LD   = $(call CMN_MKCL,$(dir $(firstword $(filter %$(OBJ_SUFFIX),$2))),$(sort $(filter $(filter %.c,$(SRC)),$? $(call FILTER_SDEPS,$(SDEPS)))))$(DRV_LD1)

# $1 - target, $2 - pch-source, $3 - pch
PCH_KCC  = $(call SUPRESS,PCHKCC,$2)$(call CMN_KCL,$(dir $1),$2,/Yc$3 /Yl$(basename $(notdir $2)) /Fp$(dir $1)$(basename $3)_c.pch $(CFLAGS))

endif # !SEQ

KLIB_R_ASM ?= $(call SUPRESS,ASM,$2)$(YASM) -o $(call ospath,$1 $2) $(ASMFLAGS)

BISON = $(call SUPRESS,BISON,$2)$(CD) && bison.exe -d --fixed-output-files $(call ospath,$(call abspath,$2))
FLEX  = $(call SUPRESS,FLEX,$2)flex.exe -o$(call ospath,$1 $2)

ifndef SEQ
# $1 - EXE,LIB,DLL, $2 - $(call GET_TARGET_NAME,$1), $3 - $$(basename $$(notdir $$(TRG_PCH))),
# $4 - $(call FORM_OBJ_DIR,$1,$v), $5 - $(call FORM_TRG,$1,$v), $v - R,S
define PCH_TEMPLATE1
TRG_PCH := $(if $($1_PCH),$($1_PCH),$(PCH))
TRG_WITH_PCH := $(call FIXPATH,$(WITH_PCH) $($1_WITH_PCH))
PCH_C_SRC := $(BLDSRC_DIR)/$1_$2_$3_c.c
PCH_CXX_SRC := $(BLDSRC_DIR)/$1_$2_$3_cpp.cpp
CLEAN += $$(if $$(filter %.c,$$(TRG_WITH_PCH)),$$(PCH_C_SRC)) $$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(PCH_CXX_SRC))
endef
define PCH_TEMPLATE2
$(empty)
$5: PCH := $$(notdir $$(TRG_PCH))
$5: WITH_PCH := $$(TRG_WITH_PCH)
$$(PCH_C_SRC) $$(PCH_CXX_SRC): | $(BLDSRC_DIR)
	$(if $(VERBOSE:1=),@)echo #include "$$(PCH)" > $$@
PCH_C_OBJ := $4/$1_$2_$3_c$(OBJ_SUFFIX)
PCH_CXX_OBJ := $4/$1_$2_$3_cpp$(OBJ_SUFFIX)
$$(PCH_C_OBJ): $$(PCH_C_SRC) $(CURRENT_DEPS) | $4
	$$(call PCH_$v_CC,$$@,$$<,$$(PCH))
$$(PCH_CXX_OBJ): $$(PCH_CXX_SRC) $(CURRENT_DEPS) | $4
	$$(call PCH_$v_CXX,$$@,$$<,$$(PCH))
PCH_OBJS := $$(if $$(filter %.c,$$(TRG_WITH_PCH)),$$(PCH_C_OBJ)) $$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$$(PCH_CXX_OBJ))
$5: $$(PCH_OBJS)
CLEAN += $$(PCH_OBJS)
CLEAN += $$(if $$(filter %.c,$$(TRG_WITH_PCH)),$4/$3_c.pch)
CLEAN += $$(if $$(filter %.cpp,$$(TRG_WITH_PCH)),$4/$3_cpp.pch)
endef
PCH_TEMPLATE3 = $(PCH_TEMPLATE1)$(foreach v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call \
  PCH_TEMPLATE2,$1,$2,$3,$(call FORM_OBJ_DIR,$1,$v),$(call FORM_TRG,$1,$v)))
PCH_TEMPLATE = $(if $(word 2,$(firstword $($1_PCH)$(PCH)) $(firstword $(WITH_PCH)$($1_WITH_PCH))),$(call \
  PCH_TEMPLATE3,$1,$(call GET_TARGET_NAME,$1),$$(basename $$(notdir $$(TRG_PCH)))),$(foreach \
  v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call FORM_TRG,$1,$v): WITH_PCH:=$(newline)))
endif # !SEQ

ifndef SEQ
# $1 - KLIB,DRV, $2 - $($1), $3 - $$(basename $$(notdir $$(TRG_PCH))),
# $4 - $(call FORM_OBJ_DIR,$1), $5 - $(call FORM_TRG,$1)
define KPCH_TEMPLATE1
TRG_PCH := $(if $($1_PCH),$($1_PCH),$(PCH))
$5: PCH := $$(notdir $$(TRG_PCH))
$5: WITH_PCH := $(call FIXPATH,$(WITH_PCH) $($1_WITH_PCH))
PCH_C_SRC := $(BLDSRC_DIR)/$1_$2_$3_c.c
$$(PCH_C_SRC): | $(BLDSRC_DIR)
	$(if $(VERBOSE:1=),@)echo #include "$$(PCH)" > $$@
PCH_C_OBJ := $4/$1_$2_$3_c$(OBJ_SUFFIX)
$$(PCH_C_OBJ): $$(PCH_C_SRC) $(CURRENT_DEPS) | $4
	$$(call PCH_KCC,$$@,$$<,$$(PCH))
$5: $$(PCH_C_OBJ)
CLEAN += $$(PCH_C_OBJ) $$(PCH_C_SRC) $4/$3_c.pch
endef
KPCH_TEMPLATE = $(if $(word 2,$(firstword $($1_PCH)$(PCH)) $(firstword $(WITH_PCH)$($1_WITH_PCH))),$(call \
  KPCH_TEMPLATE1,$1,$($1),$$(basename $$(notdir $$(TRG_PCH))),$(call FORM_OBJ_DIR,$1),$(call FORM_TRG,$1)),$(call FORM_TRG,$1): WITH_PCH:=)
endif # !SEQ

# function to add (generated?) sources to $({EXE,LIB,DLL,...}_WITH_PCH) list - to compile sources with pch header
# $1 - EXE,LIB,DLL,... $2 - sources
ADD_WITH_PCH = $(eval $1_WITH_PCH += $2)

# auxiliary dependencies

# $1 - EXE,LIB,DLL,...
TRG_ALL_DEPS1 = $(if $1,$(word 2,$1) $(call TRG_ALL_DEPS1,$(wordlist 3,999999,$1)))
TRG_ALL_DEPS = $(call FIXPATH,$(subst |, ,$(call TRG_ALL_DEPS1,$(SDEPS) $($1_SDEPS))))

# $1 - $(call TRG_SRC,EXE), $2 - $(call TRG_DEPS,EXE), $3 - $(call TRG_ALL_DEPS,EXE), $4 - $(call FORM_TRG,EXE,$v), $5 - $(call FORM_OBJ_DIR,EXE,$v), $v - R,S
define EXE_AUX_TEMPLATE2
$(empty)
$4: SRC := $1
$4: SDEPS := $2
$4: $1 $3
ifdef DEBUG
CLEAN += $5/vc*.pdb $(patsubst %$(EXE_SUFFIX),%.pdb,$4)
endif
endef
EXE_AUX_TEMPLATE1 = $(foreach v,$(call GET_VARIANTS,EXE,VARIANTS_FILTER),$(call EXE_AUX_TEMPLATE2,$1,$2,$3,$(call FORM_TRG,EXE,$v),$(call FORM_OBJ_DIR,EXE,$v)))
define EXE_AUX_TEMPLATE
$(call STD_RES_TEMPLATE,EXE)
$(call PCH_TEMPLATE,EXE)
$(call EXE_AUX_TEMPLATE1,$(call TRG_SRC,EXE),$(call TRG_DEPS,EXE),$(call TRG_ALL_DEPS,EXE))
endef

# $1 - $(call TRG_SRC,LIB), $2 - $(call TRG_DEPS,LIB), $3 - $(call TRG_ALL_DEPS,LIB), $4 - $(call FORM_TRG,LIB,$v), $5 - $(call FORM_OBJ_DIR,LIB,$v), $v - R,S
define LIB_AUX_TEMPLATE2
$(empty)
$4: SRC := $1
$4: SDEPS := $2
$4: $1 $3
ifdef DEBUG
CLEAN += $5/vc*.pdb
endif
endef
LIB_AUX_TEMPLATE1 = $(foreach v,$(call GET_VARIANTS,LIB,VARIANTS_FILTER),$(call LIB_AUX_TEMPLATE2,$1,$2,$3,$(call FORM_TRG,LIB,$v),$(call FORM_OBJ_DIR,LIB,$v)))
define LIB_AUX_TEMPLATE
ifneq ($(RES)$(LIB_RES),)
$$(warning "don't link resource(s) $(strip $(RES) $(LIB_RES)) into static library: linker will ignore resources in static library")
endif
$(call PCH_TEMPLATE,LIB)
$(call LIB_AUX_TEMPLATE1,$(call TRG_SRC,LIB),$(call TRG_DEPS,LIB),$(call TRG_ALL_DEPS,LIB))
endef

# $1 - $(call TRG_SRC,DLL), $2 - $(call TRG_DEPS,DLL), $3 - $(call TRG_ALL_DEPS,DLL), $4 - $(call FORM_TRG,DLL,$v), $5 - $(call FORM_OBJ_DIR,DLL,$v)
# $6 - $(IMP_DIR)/$(IMP_PREFIX)$(call VARIANT_IMP_PREFIX,$v)$(call GET_TARGET_NAME,DLL), $7 - $(call TRG_DEF,DLL), $v - R,S
define DLL_AUX_TEMPLATE2
$(empty)
$4: SRC := $1
$4: SDEPS := $2
$4: DLL_DIR := $(DLL_DIR)
$4: $1 $3 $7
# note: ; - empty rule: imp is always updated if dll was updated
$6$(IMP_SUFFIX): $4;
ifdef DEBUG
CLEAN += $5/vc*.pdb $(patsubst %$(DLL_SUFFIX),%.pdb,$4) $(addprefix $6,$(IMP_SUFFIX) .exp)
endif
endef
DLL_AUX_TEMPLATE1 = $(foreach v,$(call GET_VARIANTS,DLL,VARIANTS_FILTER),$(call \
  DLL_AUX_TEMPLATE2,$1,$2,$3,$(call FORM_TRG,DLL,$v),$(call FORM_OBJ_DIR,DLL,$v),$(IMP_DIR)/$(IMP_PREFIX)$(call VARIANT_IMP_PREFIX,$v)$4,$5))
define DLL_AUX_TEMPLATE
$(call STD_RES_TEMPLATE,DLL)
$(call PCH_TEMPLATE,DLL)
$(call DLL_AUX_TEMPLATE1,$(call TRG_SRC,DLL),$(call TRG_DEPS,DLL),$(call TRG_ALL_DEPS,DLL),$(call GET_TARGET_NAME,DLL),$(call TRG_DEF,DLL))
endef

# $1 - $(call FORM_TRG,KLIB), $2 - $(call TRG_SRC,KLIB)
define KLIB_AUX_TEMPLATE1
$1: SRC := $2
$1: SDEPS := $(call TRG_DEPS,KLIB)
$1: $2 $(call TRG_ALL_DEPS,KLIB)
$(call KPCH_TEMPLATE,KLIB)
ifdef DEBUG
CLEAN += $(call FORM_OBJ_DIR,KLIB)/vc*.pdb
endif
endef
define KLIB_AUX_TEMPLATE
ifneq ($(RES)$(KLIB_RES),)
$$(warning "don't link resource(s) $(strip $(RES) $(KLIB_RES)) into static library: linker will ignore resources in static library")
endif
$(call KLIB_AUX_TEMPLATE1,$(call FORM_TRG,KLIB),$(call TRG_SRC,KLIB))
endef

# add rule to make auxiliary res for the target and generate header from .mc-file
# note: defines MC_H and MC_RC variables - absolute pathnames of generated .h and .rc files
# note: later may $(call ADD_RES_RULE,TRG,$(MC_RC)) to add .res-file to a target
# $1 - EXE,DLL,... $2 - NTServiceEventLogMsg.mc
define ADD_MC_RULE1
MC_H_DIR   := $(BLDINC_DIR)/$1_$(call GET_TARGET_NAME,$1)_MC
MC_SRC_DIR := $(BLDSRC_DIR)/$1_$(call GET_TARGET_NAME,$1)_MC
MC_H       := $$(MC_H_DIR)/$(basename $(notdir $2)).h
MC_RC      := $$(MC_SRC_DIR)/$(basename $(notdir $2)).rc
$$(MC_H) $$(MC_RC): | $$(MC_H_DIR) $$(MC_SRC_DIR)
CLEAN += $$(MC_H) $$(MC_SRC_DIR)
NEEDED_DIRS += $$(MC_H_DIR) $$(MC_SRC_DIR)
$$(call MULTI_TARGET,$$(MC_H) $$(MC_RC),$(call FIXPATH,$2),$$$$(call MC,$$(MC_H) $$(MC_RC)) -h $$(call \
  ospath,$$(MC_H_DIR)) -r $$(call ospath,$$(MC_SRC_DIR)) $$$$(call ospath,$$$$<))
endef
ADD_MC_RULE = $(eval $(ADD_MC_RULE1))

# add rule to make auxiliary res for the target
# note: defines AUX_RES variable - pathname of to be built .res file
# $1 - EXE,DLL,... $2 - rc name, $3 - options for RC, $4 - optional deps for .res, $5 - $(call FORM_OBJ_DIR,$1)
# NOTE: EXE,DLL,...-target dependency on $(AUX_RES) is added in ADD_STD_RES_TEMPLATE1 or in LIB_AUX_TEMPLATE2
# NOTE: generated .res added to CLEAN list in $(OS_DEFINE_TARGETS)
define ADD_RES_RULE1
AUX_RES := $5/$(basename $(notdir $2)).res
NEEDED_DIRS += $5
$$(AUX_RES): $(call FIXPATH,$2 $4) $(CURRENT_DEPS) | $5
	$$(call RC,$$@,$$<,$3)
$1_RES_WINXX += $$(AUX_RES)
endef
ADD_RES_RULE = $(eval $(call ADD_RES_RULE1,$1,$2,$3,$4,$(call FORM_OBJ_DIR,$1)))

# $1 - target file: $(call FORM_TRG,DRV)
# $2 - sources:     $(call TRG_SRC,DRV)
# $3 - deps:        $(call TRG_DEPS,DRV)
# $4 - objdir:      $(call FORM_OBJ_DIR,DRV)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
define DRV_TEMPLATE
$(call STD_RES_TEMPLATE,DRV)
$(call KPCH_TEMPLATE,DRV)
NEEDED_DIRS += $4
$(call OBJ_RULES,DRV,CC,$(filter %.c,$2),$3)
$(call STD_TARGET_VARS,$1)
$1: SRC        := $2
$1: SDEPS      := $3
$1: LIB_DIR    := $(LIB_DIR)
$1: KLIBS      := $(KLIBS)
$1: INCLUDE    := $(call TRG_INCLUDE,DRV)
$1: DEFINES    := $(KRNDEFS) $(DEFINES) $(DRV_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(DRV_CFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(DRV_LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS) $(DRV_SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH) $(DRV_SYSLIBPATH)
$1: $(addsuffix $(KLIB_SUFFIX),$(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(KLIBS))) $5 $2 $(call TRG_ALL_DEPS,DRV) $(CURRENT_DEPS) | $(BIN_DIR)
	$$(call DRV_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $1 $5
ifdef DEBUG
CLEAN += $4/vc*.pdb $(BIN_DIR)/$(DRV_PREFIX)$(DRV).pdb
endif
endef

# how to build driver
DRV_RULES1 = $(call DRV_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
DRV_RULES = $(if $(DRV),$(call DRV_RULES1,$(call FORM_TRG,DRV),$(call TRG_SRC,DRV),$(call TRG_DEPS,DRV),$(call FORM_OBJ_DIR,DRV)))

# this code is normally evaluated at end of target Makefile
define OS_DEFINE_TARGETS
$(if $(EXE),$(EXE_AUX_TEMPLATE))
$(if $(LIB),$(LIB_AUX_TEMPLATE))
$(if $(DLL),$(DLL_AUX_TEMPLATE))
$(if $(KLIB),$(KLIB_AUX_TEMPLATE))
$(DRV_RULES)
# note: EXE_AUX_TEMPLATE adds value to EXE_RES, so must use $$($x_RES)
CLEAN += $(RES) $(foreach x,$(BLD_TARGETS),$$($x_RES))
NO_TARGET_RES:=
endef
