#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# common msvc compiler definitions, included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# Microsoft Visual C++ (MSVC++) versions
#---------------------------------------------------------------------------------
# MSVC++ _MSC_VER    product name      C++ compiler default installation path
#---------------------------------------------------------------------------------
#  6.0     1200   Visual Studio 6.0    Microsoft Visual Studio\VC98\Bin\cl.exe
#  7.0     1300   Visual Studio 2002   Microsoft Visual Studio .NET\VC7\bin\cl.exe
#  7.1     1310   Visual Studio 2003   Microsoft Visual Studio .NET 2003\VC7\bin\cl.exe
#  8.0     1400   Visual Studio 2005   Microsoft Visual Studio 8\VC\bin\cl.exe
#  9.0     1500   Visual Studio 2008   Microsoft Visual Studio 9.0\VC\bin\cl.exe
#  10.0    1600   Visual Studio 2010   Microsoft Visual Studio 10.0\VC\bin\cl.exe
#  11.0    1700   Visual Studio 2012   Microsoft Visual Studio 11.0\VC\bin\cl.exe
#  12.0    1800   Visual Studio 2013   Microsoft Visual Studio 12.0\VC\bin\cl.exe
#  14.0    1900   Visual Studio 2015   Microsoft Visual Studio 14.0\VC\bin\cl.exe
#  14.10   1910   Visual Studio 2017   Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017\bin\HostX86\x86\cl.exe
#  14.11   1911   Visual Studio 2017   Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe

# map Visual Studio version -> MSVC++ version
VS2002 := 7
VS2003 := 7.1
VS2005 := 8
VS2008 := 9
VS2010 := 10
VS2012 := 11
VS2013 := 12
VS2015 := 14
VS2017 := 14.1

# map _MSC_VER major -> MSVC++ version major
MSC_VER_12 := 6
MSC_VER_13 := 7
MSC_VER_14 := 8
MSC_VER_15 := 9
MSC_VER_16 := 10
MSC_VER_17 := 11
MSC_VER_18 := 12
MSC_VER_19 := 14

# Windows tools, such as rc.exe, mc.exe, cl.exe, link.exe, produce excessive output in stdout,
#  by default, try to filter this output out by wrapping calls to the tools.
# If not empty, then do not wrap tools
NO_WRAP:=

# Creating a process on Windows costs more time than on Unix,
# so when compiling in parallel, it takes more total time to
# call compiler for each source individually over than
# compiling multiple sources at once, so that compiler itself
# internally may parallel the compilation cloning itself and
# working in service mode.

# By default, compile all sources of a module at once (however, different modules may be compiled in parallel)
# Run via $(MAKE) S=1 to compile each source individually (without /MP compiler option)
ifeq (command line,$(origin S))
SEQ_BUILD := $(S:0=)
else
SEQ_BUILD:=
endif

# strings to strip off from link.exe output (spaces are replaced with ?)
LINKER_STRIP_STRINGS_en := Generating?code Finished?generating?code
# cp1251 ".Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð° .Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð°?Ð·Ð°Ð²ÐµÑÑÐµÐ½Ð¾"
LINKER_STRIP_STRINGS_ru_cp1251 := .îçäàíèå?êîäà .îçäàíèå?êîäà?çàâåðøåíî
# cp1251 ".Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð° .Ð¾Ð·Ð´Ð°Ð½Ð¸Ðµ?ÐºÐ¾Ð´Ð°?Ð·Ð°Ð²ÐµÑÑÐµÐ½Ð¾" as cp866 converted to cp1251
LINKER_STRIP_STRINGS_ru_cp1251_as_cp866_to_cp1251 := .þ÷ôðýøõ?úþôð .þ÷ôðýøõ?úþôð?÷ðòõ¨°õýþ

# code to define linker wrapper macro
define MSVC_WRAP_LINKER_TEMPL

# call linker and strip-off diagnostic message and message about generated .exp-file
# $1 - linker with options
# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifdef VERBOSE
<WRAP_LINKER> = $1 >&2
else
<WRAP_LINKER> = $1
endif

# $1 - linker with options
# note: FILTER_OUTPUT sends command output to stderr
# note: no diagnostic message is printed in DEBUG
# target-specific: IMP (may be empty)
ifndef NO_WRAP
$(eval <WRAP_LINKER> = $$(if $$(IMP),$$(call \
  FILTER_OUTPUT,$$1,|$(FINDSTR) /VC:$$(basename $$(notdir $$(IMP))).exp),$(value <WRAP_LINKER>)))
ifndef DEBUG
ifneq (,<STRIP_EXPR>)
<WRAP_LINKER> = $(call FILTER_OUTPUT,$1,<STRIP_EXPR>$(patsubst %, |$(FINDSTR) /VC:%.exp,$(basename $(notdir $(IMP)))))
endif
endif
endif

endef

# define the linker wrapper
# $1 - linker wrapper name, e.g. WRAP_LINKER
# $2 - strings to strip-off from link.exe output, e.g. $(LINKER_STRIP_STRINGS_en)
MSVC_DEFINE_LINKER_WRAPPER = $(eval $(subst <WRAP_LINKER>,$1,$(subst \
  <STRIP_EXPR>,$(call qpath,$2,|$(FINDSTR) /VBRC:),$(value MSVC_WRAP_LINKER_TEMPL))))

# $(SED) expression to match C compiler messages about included files (used for dependencies auto-generation)
# NOTE: /showIncludes compiler option is available only for Visual Studio .NET and later!
# how to get pattern:
#  V := C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\include\varargs.h
#  X := $(wordlist 2,999999,$(shell cl.exe /nologo /showIncludes /FI "$V" /TC /c "$V" /E 2>&1 >NUL))
#  P := $(subst ?, ,$(firstword $(subst $(subst $(space),?,$V), ,$(subst $(space),?,$X))))
INCLUDING_FILE_PATTERN_en := Note: including file:
# utf8 "ÐÑÐ¸Ð¼ÐµÑÐ°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑÑÐµÐ½Ð¸Ðµ ÑÐ°Ð¹Ð»Ð°:"
INCLUDING_FILE_PATTERN_ru_utf8 := ÐÑÐ¸Ð¼ÐµÑÐ°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑÑÐµÐ½Ð¸Ðµ ÑÐ°Ð¹Ð»Ð°:
INCLUDING_FILE_PATTERN_ru_utf8_bytes := \xd0\x9f\xd1\x80\xd0\xb8\xd0\xbc\xd0\xb5\xd1\x87\xd0\xb0\xd0\xbd\xd0\xb8\xd0\xb5: \xd0\xb2\xd0\xba\xd0\xbb\xd1\x8e\xd1\x87\xd0\xb5\xd0\xbd\xd0\xb8\xd0\xb5 \xd1\x84\xd0\xb0\xd0\xb9\xd0\xbb\xd0\xb0:
# cp1251 "ÐÑÐ¸Ð¼ÐµÑÐ°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑÑÐµÐ½Ð¸Ðµ ÑÐ°Ð¹Ð»Ð°:"
INCLUDING_FILE_PATTERN_ru_cp1251 := Ïðèìå÷àíèå: âêëþ÷åíèå ôàéëà:
INCLUDING_FILE_PATTERN_ru_cp1251_bytes := \xcf\xf0\xe8\xec\xe5\xf7\xe0\xed\xe8\xe5: \xe2\xea\xeb\xfe\xf7\xe5\xed\xe8\xe5 \xf4\xe0\xe9\xeb\xe0:
# cp866 "ÐÑÐ¸Ð¼ÐµÑÐ°Ð½Ð¸Ðµ: Ð²ÐºÐ»ÑÑÐµÐ½Ð¸Ðµ ÑÐ°Ð¹Ð»Ð°:"
INCLUDING_FILE_PATTERN_ru_cp866 := à¨¬¥ç ­¨¥: ¢ª«îç¥­¨¥ ä ©« :
INCLUDING_FILE_PATTERN_ru_cp866_bytes := \x8f\xe0\xa8\xac\xa5\xe7\xa0\xad\xa8\xa5: \xa2\xaa\xab\xee\xe7\xa5\xad\xa8\xa5 \xe4\xa0\xa9\xab\xa0:

# $(SED) script to generate dependencies file from msvc compiler output
# $1 - compiler with options (unused)
# $2 - path to the source, e.g. C:\project\src\src1.c
# $3 - target object file, e.g. C:\build\obj\src.obj
# $4 - included header file search pattern - one of $(INCLUDING_FILE_PATTERN_...)
# $5 - prefixes of system includes to filter out, e.g. $(UDEPS_INCLUDE_FILTER)/$(KDEPS_INCLUDE_FILTER)

# s/\x0d//;                                - fix line endings - remove carriage-return (CR)
# /^$(notdir $2)$$/d;                      - delete compiled source file name printed by cl.exe, start new circle
# /^$4 /!{p;d;}                            - print all lines not started with $4 pattern and space, start new circle
# s/^$4 *//;                               - strip-off leading $4 pattern with spaces
# $(subst ?, ,$(foreach x,$5,\@^$x.*@Id;)) - delete lines started with system include paths, start new circle
# s/ /\\ /g;                               - escape spaces in included file path
# s@.*@&:\n$3: &@;w $3.d                   - make dependencies, then write to generated dep-file (e.g. C:\build\obj\src.obj.d)

MSVC_DEPS_SCRIPT = \
-e "s/\x0d//;/^$(notdir $2)$$/d;/^$4 /!{p;d;}" \
-e "s/^$4 *//;$(subst ?, ,$(foreach x,$5,\@^$x.*@Id;))s/ /\\ /g;s@.*@&:\n$3: &@;w $(basename $3).d"

# code to define compiler wrapper macros
define MSVC_WRAP_COMPLIER_TEMPL

# just strip-off names of compiled sources
# $1 - compiler with options
# $2 - path(s) to the source(s) (non-empty)
# note: FILTER_OUTPUT sends command output to stderr
# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifndef NO_WRAP
<WRAP_CC_NODEP> = $(call FILTER_OUTPUT,$1,$(addprefix |$(FINDSTR) /VXC:,$(notdir $2)))
else ifdef VERBOSE
<WRAP_CC_NODEP> = $1 >&2
else
<WRAP_CC_NODEP> = $1
endif

# if NO_DEPS is set, do not auto-generate dependencies
$(eval <WRAP_CC_DEP> = $(value <WRAP_CC_NODEP>))

# call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - path to the source
# $3 - target object file
# note: send output to stderr in VERBOSE mode, this is needed for build script generation
# note: may auto-generate dependencies only if building sources sequentially, because /showIncludes option conflicts with /MP
ifndef NO_WRAP
ifndef NO_DEPS
<WRAP_CC_DEP> = (($1 /showIncludes 2>&1 && set/p="C">&2<NUL)|$(SED) -n $(call \
  MSVC_DEPS_SCRIPT,$1,$2,$3,<INCLUDING_FILE_PATTERN>,<DEPS_INCLUDE_FILTER>) 2>&1 && set/p="S">&2<NUL)3>&2 2>&1 1>&3|$(FINDSTR) /BC:CS>NUL
endif
endif

endef

# define compiler wrappers
# $1 - no-dep compiler wrapper name, e.g. WRAP_CCN
# $2 - dep compiler no-dep wrapper name, e.g. WRAP_CCD
# $3 - regular expression used to match paths to included headers, e.g. $(INCLUDING_FILE_PATTERN_en)
# $4 - prefixes of system include paths to filter-out, e.g. $(subst \,\\,$(VCINCLUDE) $(UMINCLUDE))
MSVC_DEFINE_COMPILER_WRAPPERS = $(eval $(subst <WRAP_CC_NODEP>,$1,$(subst <WRAP_CC_DEP>,$2,$(subst \
  <INCLUDING_FILE_PATTERN>,$3,$(subst <DEPS_INCLUDE_FILTER>,$4,$(value MSVC_WRAP_COMPLIER_TEMPL))))))

# make version string: major.minor.patch -> major.minor
# target-specific: MODVER
MODVER_MAJOR_MINOR = $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(MODVER)) 0 0))

# version of EXE,DLL,DRV,KDLL
MK_VERSION_OPTION = /VERSION:$(MODVER_MAJOR_MINOR)

# make compiler options string to specify included headers search path
# note: assume there are no spaces in include paths
# note: override default implementation from $(CLEAN_BUILD_DIR)/types/c/c_base.mk
MK_INCLUDE_OPTION = $(addprefix /I,$(ospath))

# make compiler options string to specify defines
# note: override default implementation from $(CLEAN_BUILD_DIR)/types/c/c_base.mk
MK_DEFINES_OPTION1 = $(addprefix /D,$1)

# add source-file dependencies for the target,
#  define target-specific variables: SRC, SDEPS, OBJ_DIR
# parameters (same as for C_BASE_TEMPLATE):
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,LIB...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
define MP_TARGET_SRC_DEPS
$1: SRC := $2
$1: SDEPS := $3
$1: OBJ_DIR := $4
$1: $2 $(sort $(call ALL_SDEPS,$3)) | $4
endef

# C_BASE_TEMPLATE_MP will have the same value as C_BASE_TEMPLATE,
#  but without calls to OBJ_RULES for C/C++ sources and
#  with $(MP_TARGET_SRC_DEPS) at last line
$(eval define C_BASE_TEMPLATE_MP$(newline)$(subst $(newline)$$1:$$(call \
  OBJ_RULES,CC,$$(filter $$(CC_MASK),$$2),$$3,$$4)$(newline)$$1:$$(call \
  OBJ_RULES,CXX,$$(filter $$(CXX_MASK),$$2),$$3,$$4),,$(value \
  C_BASE_TEMPLATE))$(newline)$$(MP_TARGET_SRC_DEPS)$(newline)endef)

# get list of sources newer than the target (EXE,DLL,LIB,...)
# target-specific: SRC, SDEPS
# note: assume called in context of the rule creating target EXE,DLL,LIB,... (by the linker command, such as EXE_LD,DLL_LD,LIB_LD,...)
# note: assume C_BASE_TEMPLATE_MP was used for the target EXE,DLL,LIB,.., so target-specific variables SRC and SDEPS are defined
NEWER_SOURCES = $(sort $(filter $(SRC),$? $(call R_FILTER_SDEPS,$?,$(SDEPS))))

# It is possible to exceed maximum command string length if compiling too many sources at once,
#  to prevent this, split all sources of a module to groups, then compile groups one after each other.
# Maximum number of sources in a group compiled at once.
MCL_MAX_COUNT := 50

# compile multiple sources at once
# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU,...
# $3 - C compiler macro, e.g. OBJ_MCC
# $4 - C++ compiler macro, e.g. OBJ_MCXX
# note: compiler macros called with parameters:
#  $1 - sources
#  $2 - target type: EXE,DLL,LIB,...
#  $3 - non-empty variant: R,S,RU,SU,...
CMN_MCL = $(call CMN_MCL1,$1,$2,$3,$4,$(NEWER_SOURCES))

# compile multiple sources at once
# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU,...
# $3 - C compiler macro, e.g. OBJ_MCC
# $4 - C++ compiler macro, e.g. OBJ_MCXX
# $5 - sources (result of $(NEWER_SOURCES))
CMN_MCL1 = $(call CMN_MCL2,$1,$2,$3,$4,$(filter $(CC_MASK),$5),$(filter $(CXX_MASK),$5))

# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU
# $3 - C compiler macro, e.g. OBJ_MCC or OBJ_PMCC
# $4 - C++ compiler macro, e.g. OBJ_MCXX or OBJ_PMCXX
# $5 - C sources
# $6 - C++ sources
CMN_MCL2 = $(if \
  $5,$(call xcmd,$3,$5,$(MCL_MAX_COUNT),$1,$2)$(newline))$(if \
  $6,$(call xcmd,$4,$6,$(MCL_MAX_COUNT),$1,$2)$(newline))

# protect variables from modifications in target makefiles
# note: do not trace calls to these variables because they are used in ifdefs
$(call SET_GLOBAL,NO_WRAP SEQ_BUILD,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,VS2002 VS2003 VS2005 VS2008 VS2010 VS2012 VS2013 VS2015 VS2017 \
  LINKER_STRIP_STRINGS_en LINKER_STRIP_STRINGS_ru_cp1251 LINKER_STRIP_STRINGS_ru_cp1251_as_cp866_to_cp1251 \
  MSVC_WRAP_LINKER_TEMPL MSVC_DEFINE_LINKER_WRAPPER \
  INCLUDING_FILE_PATTERN_en INCLUDING_FILE_PATTERN_ru_utf8 INCLUDING_FILE_PATTERN_ru_utf8_bytes \
  INCLUDING_FILE_PATTERN_ru_cp1251 INCLUDING_FILE_PATTERN_ru_cp1251_bytes \
  INCLUDING_FILE_PATTERN_ru_cp866 INCLUDING_FILE_PATTERN_ru_cp866_bytes MSVC_DEPS_SCRIPT \
  MSVC_WRAP_COMPLIER_TEMPL MSVC_DEFINE_COMPILER_WRAPPERS \
  MODVER_MAJOR_MINOR MK_VERSION_OPTION MK_INCLUDE_OPTION MK_DEFINES_OPTION1 \
  MP_TARGET_SRC_DEPS C_BASE_TEMPLATE_MP NEWER_SOURCES MCL_MAX_COUNT CMN_MCL CMN_MCL1 CMN_MCL2)
