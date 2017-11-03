#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# define default values of next variables based on the value of {,T}VC_VER:
#
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

# note: TMD must be defined, either as empty or as T
VC_VER_tmp := $($(TMD)VC_VER)

# default values of user-defined C compiler flags
# note: {,T}CFLAGS value may be taken from the environment in project configuration makefile
# note: used by EXE_CFLAGS, LIB_CFLAGS, DLL_CFLAGS (from $(CLEAN_BUILD_DIR)/impl/_c.mk)
# /W3 - warning level 3
$(TMD)CFLAGS := /W3

# determine if may build multiple sources at once
# note: SEQ_BUILD - defined in $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk, takes value of command-line variable S
$(TMD)MP_BUILD:=
ifndef SEQ_BUILD
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2008)))
# >= Visual Studio 2008
# /MP - compile all sources of a module (EXE, DLL or a LIB) at once
$(TMD)MP_BUILD := /MP
endif
endif

# When using the /Zi option, the debug info of all compiled sources is stored in a single .pdb,
#  but this can lead to contentions accessing that .pdb during parallel compilation.
# To cope this problem, the /FS option was introduced in Visual Studio 2013.
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2013)))
# >= Visual Studio 2013
$(TMD)FORCE_SYNC_PDB := /FS
else
$(TMD)FORCE_SYNC_PDB:=
endif

ifdef DEBUG

# set debug info format
ifdef $(TMD)MP_BUILD
# compiling sources of a module with /MP option:
#  - groups of sources of a module are compiled sequentially, one group after each other
#  - sources in a group are compiled in parallel by compiler threads, via single compiler invocation.
# note: /MP option implies /FS option, if it's supported by the cl.exe
# /Zi option - store debug info (in new format) in single .pdb, assume compiler internally will serialize access to the .pdb
$(TMD)CFLAGS += /Zi
else ifndef $(TMD)FORCE_SYNC_PDB
# /Z7 option - store debug info (in old format) in each .obj to avoid contention accessing .pdb during parallel compilation
$(TMD)CFLAGS += /Z7
else
# /Zi option - store debug info (in new format) in single .pdb, compiler will serialize access to the .pdb via mspdbsrv.exe
$(TMD)CFLAGS += $($(TMD)FORCE_SYNC_PDB) /Zi
endif

# /Od - disable optimizations
$(TMD)CFLAGS += /Od

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2002)))
# >= Visual Studio 2002
# /RTCs - enables stack frame run-time error checking
# /RTCu - reports when a variable is used without having been initialized
# /GS   - buffer security check
$(TMD)CFLAGS += /RTCsu /GS
else
# Visual Studio 6.0
# /GZ - catch release-build errors in debug build
$(TMD)CFLAGS += /GZ
endif

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2012)))
# >= Visual Studio 2012
# /sdl - additional security checks
$(TMD)CFLAGS += /sdl
endif

else # !DEBUG

# /Ox - maximum optimization
# /GF - pool strings and place them in read-only memory
# /Gy - enable function level linking
$(TMD)CFLAGS += /Ox /GF /Gy

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2002)))
# >= Visual Studio 2002
# /GS - buffer security check
# /GL - whole program optimization, link.exe or lib.exe must be invoked with /LTCG
$(TMD)CFLAGS += /GS- /GL
endif

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2013)))
# >= Visual Studio 2013
# /Zc:inline - remove unreferenced internal functions from objs
# /Gw         - package global data in individual comdat sections
# note: /Zc:inline is ignored if /GL is specified
$(TMD)CFLAGS += /Zc:inline /Gw
endif

endif # !DEBUG

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2005)))
# >= Visual Studio 2005
# /errorReport - report internal compiler errors
$(TMD)CFLAGS += /errorReport:none
endif

# default values of user-defined C++ compiler flags
# /Gm - enable minimal rebuild
# note: {,T}CXXFLAGS value may be taken from the environment in project configuration makefile
# note: used by EXE_CXXFLAGS, LIB_CXXFLAGS, DLL_CXXFLAGS (from $(CLEAN_BUILD_DIR)/impl/_c.mk)
$(TMD)CXXFLAGS := $($(TMD)CFLAGS) /Gm-

# /GR - enable run-time type information
$(TMD)CFLAGS += /GR-

ifdef DEBUG
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2002)))
# >= Visual Studio 2002
# /RTCc - reports when a value is assigned to a smaller data type and results in a data loss
# note: for C++ code, it may be needed to define /D_ALLOW_RTCc_IN_STL (starting with Visual Studio 2015)
$(TMD)CFLAGS += /RTCc
endif
endif

# lib.exe flags for linking a LIB
# /LTCG - link-time code generation
# note: {,T}ARFLAGS value may be taken from the environment in project configuration makefile
# note: used by LIB_LD
$(TMD)ARFLAGS := $(if $(DEBUG),,$(if $(filter /GL,$($(TMD)CFLAGS)),/LTCG))

# default values of user-defined link.exe flags for linking executables and shared libraries
# note: {,T}LDFLAGS value may be taken from the environment in project configuration makefile
# note: used by EXE_LDFLAGS, LIB_LDFLAGS, DLL_LDFLAGS from $(CLEAN_BUILD_DIR)/impl/_c.mk
# /DEBUG   - generate debug info (in separate .pdb)
# /RELEASE - set the checksum in PE-header
# /LTCG    - link-time code generation
$(TMD)LDFLAGS := $(if $(DEBUG),/DEBUG,/RELEASE$(if $(filter /GL,$($(TMD)CFLAGS)), /LTCG))

# how to embed manifest into EXE or DLL
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2012)))
# >= Visual Studio 2012, linker may call mt.exe internally
$(TMD)MANIFEST_EMBED_OPTION := /MANIFEST:EMBED
else
$(TMD)MANIFEST_EMBED_OPTION:=
endif

# manifest embedding
# $1 - path to target EXE or DLL
# note: in Visual Studio 2012 and above, linker may call mt.exe internally
$(TMD)EMBED_EXE_MANIFEST:=
$(TMD)EMBED_DLL_MANIFEST:=
ifndef $(TMD)MANIFEST_EMBED_OPTION
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2005)))
# >= Visual Studio 2005
$(TMD)EMBED_EXE_MANIFEST = $(newline)$(QUIET)if exist $(ospath).manifest $(MT) -nologo \
  -manifest $(ospath).manifest -outputresource:$(ospath);1 && del $(ospath).manifest
$(TMD)EMBED_DLL_MANIFEST = $(newline)$(QUIET)if exist $(ospath).manifest $(MT) -nologo \
  -manifest $(ospath).manifest -outputresource:$(ospath);2 && del $(ospath).manifest
endif
endif

# common flags for application-level C/C++ compilers
# /EHsc - synchronous exception handling model, extern C functions never throw an exception
# /X    - do not search include files in directories specified in the PATH and INCLUDE environment variables
$(TMD)CMN_CFLAGS := /EHsc /X

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2002)))
# >= Visual Studio 2002
# /Zc:wchar_t - wchar_t is native type
$(TMD)CMN_CFLAGS += /Zc:wchar_t
endif

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2013)))
# >= Visual Studio 2013
# /Zc:rvalueCast    - enforce type conversion rules
# /Zc:strictStrings - disable string literal type conversion 
$(TMD)CMN_CFLAGS += /Zc:rvalueCast /Zc:strictStrings
endif

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2005)))
# >= Visual Studio 2005
# /D_CRT_SECURE_NO_DEPRECATE - disable warnings about use of 'non-secure' functions like strcpy()
# note: may add /D_CRT_NONSTDC_NO_DEPRECATE - to disable warnings about use of POSIX functions like access()
$(TMD)CMN_CFLAGS += /D_CRT_SECURE_NO_DEPRECATE
endif

# paths to application-level system headers and libraries
$(TMD)APPINCLUDE := $($(TMD)VCINCLUDE) $($(TMD)UMINCLUDE)
$(TMD)APPLIBPATH := $($(TMD)VCLIBPATH) $($(TMD)UMLIBPATH)

# add standard include paths
$(TMD)CMN_CFLAGS += $(call qpath,$($(TMD)APPINCLUDE),/I)

ifndef TMD
# specify windows api version
# note: not for tool mode
# note: WINVER_DEFINES may be empty
CMN_CFLAGS += $(addprefix /D,$(WINVER_DEFINES))
endif

# default flags for application-level C++ compiler
$(TMD)DEF_CXXFLAGS := $($(TMD)CMN_CFLAGS)

# default flags for application-level C compiler
$(TMD)DEF_CFLAGS := $($(TMD)CMN_CFLAGS)

ifneq (,$(call is_less_float,$(VC_VER_tmp),$(VS2015)))
# < Visual Studio 2015
# allow 'inline' keyword in C code
$(TMD)DEF_CFLAGS += /Dinline=__inline
endif

# regular expression for findstr.exe to match and strip-off diagnostic linker message
# default value, may be overridden either in project configuration makefile or in command line
ifndef TMD
LINKER_STRIP_STRINGS := $(LINKER_STRIP_STRINGS_en)
else
$(TMD)LINKER_STRIP_STRINGS := $(LINKER_STRIP_STRINGS)
endif

# define {,T}WRAP_LINKER - link.exe wrapper
$(call MSVC_DEFINE_LINKER_WRAPPER,$(TMD)WRAP_LINKER,$($(TMD)LINKER_STRIP_STRINGS))

# $(SED) regular expression used to match paths to included headers in output of cl.exe running with /showIncludes option
# default value, may be overridden either in project configuration makefile or in command line
ifndef TMD
INCLUDING_FILE_PATTERN := $(INCLUDING_FILE_PATTERN_en)
else
$(TMD)INCLUDING_FILE_PATTERN := $(INCLUDING_FILE_PATTERN)
endif

# prefixes of system include paths to filter-out by $(SED) while dependencies generation
# note: may be overridden either in project configuration makefile or in command line
# c:\\program?files?(x86)\\microsoft?visual?studio?10.0\\vc\\include\\
# note: likely with trailing double-slash
$(TMD)UDEPS_INCLUDE_FILTER := $(subst \,\\,$(patsubst %\\,%\,$(addsuffix \,$($(TMD)APPINCLUDE))))

# define {,T}WRAP_CCN and {,T}WRAP_CCD - cl.exe wrappers
$(call MSVC_DEFINE_COMPILER_WRAPPERS,$(TMD)WRAP_CCN,$(TMD)WRAP_CCD,$($(TMD)INCLUDING_FILE_PATTERN),$($(TMD)UDEPS_INCLUDE_FILTER))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,$(addprefix $(TMD),CFLAGS CXXFLAGS ARFLAGS LDFLAGS MP_BUILD FORCE_SYNC_PDB MANIFEST_EMBED_OPTION \
  EMBED_EXE_MANIFEST EMBED_DLL_MANIFEST CMN_CFLAGS APPINCLUDE APPLIBPATH DEF_CFLAGS DEF_CXXFLAGS LINKER_STRIP_STRINGS WRAP_LINKER \
  INCLUDING_FILE_PATTERN UDEPS_INCLUDE_FILTER WRAP_CCN WRAP_CCD))
