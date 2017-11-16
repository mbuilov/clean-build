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

# note: temporary variable _ - variables name prefix - must be defined, either as empty or as T
VC_VER_tmp := $($_VC_VER)

# default values of user-defined C compiler flags
# note: {,T}CFLAGS value may be taken from the environment in project configuration makefile
# note: used by EXE_CFLAGS, LIB_CFLAGS, DLL_CFLAGS (from $(CLEAN_BUILD_DIR)/impl/_c.mk)
# /W3 - warning level 3
$_CFLAGS := /W3

# determine if may build multiple sources at once
# note: SEQ_BUILD - defined in $(CLEAN_BUILD_DIR)/compilers/msvc/cmn.mk, takes value of command-line variable S
$_MP_BUILD:=
ifndef SEQ_BUILD
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2008)))
# >= Visual Studio 2008
# /MP - compile all sources of a module (EXE, DLL or a LIB) at once
$_MP_BUILD := /MP
endif
endif

# When using the /Zi option, the debug info of all compiled sources is stored in a single .pdb,
#  but this can lead to contentions accessing that .pdb during parallel compilation.
# To cope this problem, the /FS option was introduced in Visual Studio 2013.
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2013)))
# >= Visual Studio 2013
$_FORCE_SYNC_PDB := /FS
else
$_FORCE_SYNC_PDB:=
endif

ifdef DEBUG

# set debug info format
ifdef $_MP_BUILD
# compiling sources of a module with /MP option:
#  - groups of sources of a module are compiled sequentially, one group after each other
#  - sources in a group are compiled in parallel by compiler threads, via single compiler invocation.
# note: /MP option implies /FS option, if it's supported by the cl.exe
# /Zi option - store debug info (in new format) in single .pdb, assume compiler internally will serialize access to the .pdb
$_CFLAGS += /Zi
else ifndef $_FORCE_SYNC_PDB
# /Z7 option - store debug info (in old format) in each .obj to avoid contention accessing .pdb during parallel compilation
$_CFLAGS += /Z7
else
# /Zi option - store debug info (in new format) in single .pdb, compiler will serialize access to the .pdb via mspdbsrv.exe
$_CFLAGS += $($_FORCE_SYNC_PDB) /Zi
endif

# /Od - disable optimizations
$_CFLAGS += /Od

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2002)))
# >= Visual Studio 2002
# /RTCs - enables stack frame run-time error checking
# /RTCu - reports when a variable is used without having been initialized
# /GS   - buffer security check
$_CFLAGS += /RTCsu /GS
else
# Visual Studio 6.0
# /GZ - catch release-build errors in debug build
$_CFLAGS += /GZ
endif

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2012)))
# >= Visual Studio 2012
# /sdl - additional security checks
$_CFLAGS += /sdl
endif

else # !DEBUG

# /Ox - maximum optimization
# /GF - pool strings and place them in read-only memory
# /Gy - enable function level linking
$_CFLAGS += /Ox /GF /Gy

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2002)))
# >= Visual Studio 2002
# /GS - buffer security check
# /GL - whole program optimization, link.exe or lib.exe must be invoked with /LTCG
$_CFLAGS += /GS- /GL
endif

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2013)))
# >= Visual Studio 2013
# /Zc:inline - remove unreferenced internal functions from objs
# /Gw         - package global data in individual comdat sections
# note: /Zc:inline is ignored if /GL is specified
$_CFLAGS += /Zc:inline /Gw
endif

endif # !DEBUG

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2005)))
# >= Visual Studio 2005
# /errorReport - report internal compiler errors
$_CFLAGS += /errorReport:none
endif

# default values of user-defined C++ compiler flags
# /Gm - enable minimal rebuild
# note: {,T}CXXFLAGS value may be taken from the environment in project configuration makefile
# note: used by EXE_CXXFLAGS, LIB_CXXFLAGS, DLL_CXXFLAGS (from $(CLEAN_BUILD_DIR)/impl/_c.mk)
$_CXXFLAGS := $($_CFLAGS) /Gm-

# /GR - enable run-time type information
$_CFLAGS += /GR-

ifdef DEBUG
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2002)))
# >= Visual Studio 2002
# /RTCc - reports when a value is assigned to a smaller data type and results in a data loss
# note: for C++ code, it may be needed to define /D_ALLOW_RTCc_IN_STL (starting with Visual Studio 2015)
$_CFLAGS += /RTCc
endif
endif

# lib.exe flags for linking a LIB
# /LTCG - link-time code generation
# note: {,T}ARFLAGS value may be taken from the environment in project configuration makefile
# note: used by LIB_LD
$_ARFLAGS := $(if $(DEBUG),,$(if $(filter /GL,$($_CFLAGS)),/LTCG))

# default values of user-defined link.exe flags for linking executables and shared libraries
# note: {,T}LDFLAGS value may be taken from the environment in project configuration makefile
# note: used by EXE_LDFLAGS, LIB_LDFLAGS, DLL_LDFLAGS from $(CLEAN_BUILD_DIR)/impl/_c.mk
# /DEBUG   - generate debug info (in separate .pdb)
# /RELEASE - set the checksum in PE-header
# /LTCG    - link-time code generation
$_LDFLAGS := $(if $(DEBUG),/DEBUG,/RELEASE$(if $(filter /GL,$($_CFLAGS)), /LTCG))

# how to embed manifest into EXE or DLL
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2012)))
# >= Visual Studio 2012, linker may call mt.exe internally
$_MANIFEST_EMBED_OPTION := /MANIFEST:EMBED
else
$_MANIFEST_EMBED_OPTION:=
endif

# manifest embedding
# $1 - path to target EXE or DLL
# note: in Visual Studio 2012 and above, linker may call mt.exe internally
# note: there is no mt.exe tool in DDK, so MT may be defined with empty value
$_EMBED_EXE_MANIFEST:=
$_EMBED_DLL_MANIFEST:=
ifndef $_MANIFEST_EMBED_OPTION
ifdef MT
ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2005)))
# >= Visual Studio 2005
$_EMBED_EXE_MANIFEST = $(newline)$(QUIET)if exist $(ospath).manifest $(MT) -nologo \
  -manifest $(ospath).manifest -outputresource:$(ospath);1 && del $(ospath).manifest
$_EMBED_DLL_MANIFEST = $(newline)$(QUIET)if exist $(ospath).manifest $(MT) -nologo \
  -manifest $(ospath).manifest -outputresource:$(ospath);2 && del $(ospath).manifest
endif
endif
endif

# common flags for application-level C/C++ compilers
# /EHsc - synchronous exception handling model, extern C functions never throw an exception
# /X    - do not search include files in directories specified in the PATH and INCLUDE environment variables
$_CMN_CFLAGS := /EHsc /X

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2002)))
# >= Visual Studio 2002
# /Zc:wchar_t - wchar_t is native type
$_CMN_CFLAGS += /Zc:wchar_t
endif

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2013)))
# >= Visual Studio 2013
# /Zc:rvalueCast    - enforce type conversion rules
# /Zc:strictStrings - disable string literal type conversion 
$_CMN_CFLAGS += /Zc:rvalueCast /Zc:strictStrings
endif

ifeq (,$(call is_less_float,$(VC_VER_tmp),$(VS2005)))
# >= Visual Studio 2005
# /D_CRT_SECURE_NO_DEPRECATE - disable warnings about use of 'non-secure' functions like strcpy()
# note: may add /D_CRT_NONSTDC_NO_DEPRECATE - to disable warnings about use of POSIX functions like access()
$_CMN_CFLAGS += /D_CRT_SECURE_NO_DEPRECATE
endif

# paths to application-level system headers and libraries
$_APPINCLUDE := $($_VCINCLUDE) $($_UMINCLUDE)
$_APPLIBPATH := $($_VCLIBPATH) $($_UMLIBPATH)

# add standard include paths
$_CMN_CFLAGS += $(call qpath,$($_APPINCLUDE),/I)

ifndef _
# specify windows api version
# note: not for tool mode
# note: WINVER_DEFINES may be empty
CMN_CFLAGS += $(addprefix /D,$(WINVER_DEFINES))
endif

# default flags for application-level C++ compiler
$_DEF_CXXFLAGS := $($_CMN_CFLAGS)

# default flags for application-level C compiler
$_DEF_CFLAGS := $($_CMN_CFLAGS)

ifneq (,$(call is_less_float,$(VC_VER_tmp),$(VS2015)))
# < Visual Studio 2015
# allow 'inline' keyword in C code
$_DEF_CFLAGS += /Dinline=__inline
endif

# regular expression for findstr.exe to match and strip-off diagnostic linker message
# default value, may be overridden either in project configuration makefile or in command line
ifndef _
LINKER_STRIP_STRINGS := $(LINKER_STRIP_STRINGS_en)
else
$_LINKER_STRIP_STRINGS := $(LINKER_STRIP_STRINGS)
endif

# define {,T}WRAP_LINKER - link.exe wrapper
$(call MSVC_DEFINE_LINKER_WRAPPER,$_WRAP_LINKER,$($_LINKER_STRIP_STRINGS))

# $(SED) regular expression used to match paths to included headers in output of cl.exe running with /showIncludes option
# default value, may be overridden either in project configuration makefile or in command line
ifndef _
INCLUDING_FILE_PATTERN := $(INCLUDING_FILE_PATTERN_en)
else
$_INCLUDING_FILE_PATTERN := $(INCLUDING_FILE_PATTERN)
endif

# prefixes of system include paths to filter-out by $(SED) while dependencies generation
# note: may be overridden either in project configuration makefile or in command line
# c:\\program?files?(x86)\\microsoft?visual?studio?10.0\\vc\\include\\
# note: likely with trailing double-slash
$_UDEPS_INCLUDE_FILTER := $(subst \,\\,$(patsubst %\\,%\,$(addsuffix \,$($_APPINCLUDE))))

# define {,T}WRAP_CCN and {,T}WRAP_CCD - cl.exe wrappers
$(call MSVC_DEFINE_COMPILER_WRAPPERS,$_WRAP_CCN,$_WRAP_CCD,$($_INCLUDING_FILE_PATTERN),$($_UDEPS_INCLUDE_FILTER))

ifneq (,$(call is_less_float,$(VC_VER_tmp),$(VS2002)))
# < Visual Studio .NET
# cl.exe supports /showIncludes option only starting with Visual Studio .NET
$(eval $_WRAP_CCD = $(value $_WRAP_CCN))
endif

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,$(addprefix $_,CFLAGS CXXFLAGS ARFLAGS LDFLAGS MP_BUILD FORCE_SYNC_PDB MANIFEST_EMBED_OPTION \
  EMBED_EXE_MANIFEST EMBED_DLL_MANIFEST CMN_CFLAGS APPINCLUDE APPLIBPATH DEF_CFLAGS DEF_CXXFLAGS LINKER_STRIP_STRINGS WRAP_LINKER \
  INCLUDING_FILE_PATTERN UDEPS_INCLUDE_FILTER WRAP_CCN WRAP_CCD))
