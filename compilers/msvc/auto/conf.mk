#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# MSVC C/C++ compiler auto-configuration (app-level), included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

#################################################################################################################
# input for autoconfiguration:
#
# 1) VS - Visual Studio installation path
#   may be specified if autoconfiguration based on values of environment variables and registry keys fails, e.g.:
#     VS=C:\Program Files\Microsoft Visual Studio
#     VS=C:\Program Files\Microsoft Visual Studio .NET 2003
#     VS=C:\Program Files\Microsoft Visual Studio 14.0
#     VS=C:\Program Files\Microsoft Visual Studio\2017
#     VS=C:\Program Files\Microsoft Visual Studio\2017\Enterprise
#
# 2) MSVC - Visual C++ tools path
#   may be specified instead of VS variable (VS is ignored then), e.g.:
#     MSVC=C:\Program Files\Microsoft Visual Studio\VC98
#     MSVC=C:\Program Files\Microsoft Visual C++ Toolkit 2003
#     MSVC=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7
#     MSVC=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC
#     MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC
#     MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC
#     MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503
#
# 3) VCCL - path to Visual C++ compiler (cl.exe)
#   may be specified instead of VS or MSVC variables (they are ignored then), e.g.:
#     VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\cl.exe
#     VCCL=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe
#     VCCL=C:\WINDDK\3790\bin\x86\cl.exe
#     VCCL=C:\WinDDK\7600.16385.1\bin\x86\amd64\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe
#
# 4) SDK - path to Windows Software Development Kit,
#   may be specified explicitly if failed to determine it automatically or to override automatically defined value, e.g.:
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v6.0
#     SDK=C:\Program Files (x86)\Windows Kits\8.0
#     SDK=C:\Program Files (x86)\Windows Kits\10.0
#
# 5) DDK - path to Windows Driver Development Kit,
#   may be specified instead of SDK - because DDK contains SDK headers and libraries necessary for building simple console applications,
#   but also may be specified together with SDK - for building drivers, e.g.:
#     DDK=C:\WinDDK\7600.16385.1
#     DDK=C:\Program Files (x86)\Windows Kits\8.0
#     DDK=C:\Program Files (x86)\Windows Kits\10.0
#
# 6) WDK - path to Windows Development Kit (8.0 or later),
#   may be specified instead of SDK and DDK - newer versions of SDK and DDK (8.0 and later) are combined under the same WDK path, e.g.:
#     WDK=C:\Program Files (x86)\Windows Kits\8.0
#     WDK=C:\Program Files (x86)\Windows Kits\10.0
#
#   Note: SDK/DDK values, if not defined, are will be set to point to WDK.
#   Note: defining SDK is not enough for Visual Studio 2015 and later - it requires WDK (version 10) - for ucrt libraries.
#
#################################################################################################################

# try to autoconfigure:
#  target Windows version, Visual C++ version, paths to compiler, linker, system libraries, headers and tools:
#  - only if they are not defined in project configuration makefile or in command line
#  (variables prefixed with T - are for the tool mode)
#
# WINVER        - minimal Windows version required to run built executables
# {,T}VC_VER    - MSVC++ version, known values see in $(CLEAN_BUILD_DIR)/compilers/msvc/cmn.mk 'MSVC++ versions' table
# {,T}VCCL      - path to cl.exe                (may be in double-quotes, if contains spaces - double-quoted automatically)
# {,T}VCLIB     - path to lib.exe               (must be in double-quotes if contains spaces, may be deduced from VCCL)
# {,T}VCLINK    - path to link.exe              (must be in double-quotes if contains spaces, may be deduced from VCCL)
# {,T}VCINCLUDE - paths to Visual C++ headers   (such as varargs.h,    without quotes, spaces must be replaced with ?)
# {,T}VCLIBPATH - paths to Visual C++ libraries (such as msvcrt.lib,   without quotes, spaces must be replaced with ?)
# {,T}UMINCLUDE - paths to user-mode headers    (such as winbase.h,    without quotes, spaces must be replaced with ?)
# {,T}UMLIBPATH - paths to user-mode libraries  (such as kernel32.lib, without quotes, spaces must be replaced with ?)
# RC            - path to rc.exe                (may be in double-quotes, if contains spaces - double-quoted automatically)
# MC            - path to mc.exe                (may be in double-quotes, if contains spaces - double-quoted automatically)
# MT            - path to mt.exe                (may be in double-quotes, if contains spaces - double-quoted automatically)
#
# example:
#
# WINVER    := WINBLUE
# VC_VER    := 14.0
# VCCL      := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
# VCLIB     := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\lib.exe"
# VCLINK    := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\link.exe"
# VCINCLUDE := C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\VC\include
# VCLIBPATH := C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\VC\lib
# UMINCLUDE := C:\Program?Files?(x86)\Windows?Kits\8.1\Include\um C:\Program?Files?(x86)\Windows?Kits\10\Include\10.0.10240.0\ucrt
# UMLIBPATH := C:\Program?Files?(x86)\Windows?Kits\8.1\Lib\winv6.3\um\x86 C:\Program?Files?(x86)\Windows?Kits\10\Lib\10.0.10240.0\ucrt\x86
# RC        := "C:\Program Files (x86)\Windows Kits\8.1\bin\x86\rc.exe"
# MC        := "C:\Program Files (x86)\Windows Kits\8.1\bin\x86\mc.exe"
# MT        := "C:\Program Files (x86)\Windows Kits\8.1\bin\x86\mt.exe"
#
# note: VCINCLUDE, VCLIBPATH, UMINCLUDE or UMLIBPATH may be defined with empty values in project configuration makefile or in command line

ifeq (,$(filter-out undefined environment,$(origin CONF_NORMALIZE_DIR)))
include $(CLEAN_BUILD_DIR)/compilers/msvc/auto/func.mk
endif

# reset variables - they are may be defined by $(CLEAN_BUILD_DIR)/compilers/msvc/auto/cl.mk
SDK:=
DDK:=
WDK:=
SDK_AUTO:=
DDK_AUTO:=
SDK_VER_AUTO:=
DDK_VER_AUTO:=

ifdef SDK
# SDK=C:/Program?Files/Microsoft?SDKs/Windows/v6.0
override SDK := $(call CONF_NORMALIZE_DIR,$(SDK))
endif

ifdef DDK
# DDK=C:/WinDDK/7600.16385.1
override DDK := $(call CONF_NORMALIZE_DIR,$(DDK))
endif

ifdef WDK
# WDK=C:/Program?Files?(x86)/Windows?Kits/10.0
override WDK := $(call CONF_NORMALIZE_DIR,$(WDK))
endif

ifdef VCCL
# VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
override VCCL := $(call CONF_NORMALIZE_TOOL,$(VCCL))
else
# try to find cl.exe
# note: if WDK is defined, do not define SDK and DDK to point to it yet - to avoid
#  unnecessary lookups for cl.exe in WDK (WDK - 8.0 and later do not contains a compiler)
include $(CLEAN_BUILD_DIR)/compilers/msvc/auto/cl.mk
endif

# OK, now VCCL is defined
ifdef TVCCL
# TVCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
override TVCCL := $(call CONF_NORMALIZE_TOOL,$(TVCCL))
else






# reset {,T}VC_VER, if it's not defined in project configuration makefile or in command line
VC_VER:=
TVC_VER:=

# reset {,T}VCCL, if it's not defined in project configuration makefile or in command line
VCCL:=
TVCCL:=

# if VCCL is defined in project configuration makefile or in command line, check its value
ifdef VCCL
  override VCCL := $(call NORMALIZE_VCCL_PATH,$(VCCL))
else ifdef VC_VER
  $(error VC_VER=$(VC_VER) is defined, but VCCL does not)
endif

# if TVCCL is defined in project configuration makefile or in command line, check its value
ifdef TVCCL
  override TVCCL := $(call NORMALIZE_VCCL_PATH,$(TVCCL))
else ifdef TVC_VER
  $(error TVC_VER=$(TVC_VER) is defined, but TVCCL does not)
endif

# subdirectory of MSVC++ libraries: <empty> or onecore
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_ONECORE:=
TVC_LIB_TYPE_ONECORE:=

# subdirectory of MSVC++ libraries: <empty> or store
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_STORE:=
TVC_LIB_TYPE_STORE:=

# reset variables, if they are not defined in project configuration makefile or in command line
SDK:=
DDK:=
WDK:=
WDK_VER:=

# may auto-define SDK or DDK while autoconfiguration:
#  SDK_AUTO is set only if SDK and WDK were empty before SDK_AUTO was set
#  DDK_AUTO is set only if DDK and WDK were empty before DDK_AUTO was set
SDK_AUTO:=
DDK_AUTO:=

# hints of automatically defined SDK/DDK
#  SDK_VER_AUTO - version of automatically defined SDK, e.g.: v6.0
#  DDK_VER_AUTO - version of automatically defined DDK, e.g.:
#    7600.16385.1 7600.16385.0 6001.18002 6001.18001 6001.18000 6000 3790.1830 3790 2600.1106 2600
SDK_VER_AUTO:=
DDK_VER_AUTO:=

# autoconfigured paths to Visual C++ libraries and headers:
#  {,T}VCLIBPATH_AUTO is set only if {,T}VCLIBPATH was not defined (possibly with empty value) before {,T}VCLIBPATH_AUTO was set
#  {,T}VCINCLUDE_AUTO is set only if {,T}VCINCLUDE was not defined (possibly with empty value) before {,T}VCINCLUDE_AUTO was set
VCLIBPATH_AUTO:=
VCINCLUDE_AUTO:=
TVCLIBPATH_AUTO:=
TVCINCLUDE_AUTO:=

ifdef SDK
# SDK=C:/Program?Files/Microsoft?SDKs/Windows/v6.0
override SDK := $(call CONF_NORMALIZE_DIR,$(SDK))
endif

ifdef DDK
# DDK=C:/WinDDK/7600.16385.1
override DDK := $(call CONF_NORMALIZE_DIR,$(DDK))
endif

ifdef WDK
# WDK=C:/Program?Files?(x86)/Windows?Kits/8.0
override WDK := $(call CONF_NORMALIZE_DIR,$(WDK))
ifdef CB_CHECKING
ifdef SDK
ifdef DDK
override WDK = $(error WDK must not be used if both SDK and DDK are defined)
override WDK_VER = $(error WDK_VER must not be used if both SDK and DDK are defined)
endif
endif
endif
endif

# we need next MSVC++ variables to be defined: VC_VER, VCCL, VCLIBPATH and VCINCLUDE
# (they are may be defined either in project configuration makefile or in command line)
# note: VCLIBPATH or VCINCLUDE may be defined as <empty>, so do not reset them

# first define C++ compiler
ifndef VCCL

include auto/cl.mk

endif # !VCCL









# ok, VCCL is defined, deduce VC_VER from it, but first ensure that cl.exe will run
include $(CLEAN_BUILD_DIR)/compilers/msvc_cl_path.mk

ifndef VC_VER
  VC_VER := $(call CL_GET_VER,$(VCCL))
  $(warning autoconfigured: VC_VER=$(VC_VER))
endif

# define VCLIBPATH_AUTO and VCINCLUDE_AUTO values from $(VCCL)
include $(CLEAN_BUILD_DIR)/compilers/msvc_cl_libs.mk

# reset variables, if they are not defined in project configuration makefile or in command line
VCLIB:=
VCLINK:=

# deduce values of VCLIB and VCLINK from $(VCCL)
ifndef VCLIB
VCLIB := $(call ifaddq,$(subst ?, ,$(addsuffix lib.exe,$(dir $(patsubst "%",%,$(subst $(space),?,$(VCCL)))))))
$(warning autoconfigured: VCLIB=$(VCLIB))
endif

ifndef VCLINK
VCLINK := $(call ifaddq,$(subst ?, ,$(addsuffix link.exe,$(dir $(patsubst "%",%,$(subst $(space),?,$(VCCL)))))))
$(warning autoconfigured: VCLINK=$(VCLINK))
endif

# ----------------- tool mode ------------------

# deduce value of TVCCL from $(VCCL)
ifndef TVCCL

  # paths to cl.exe:
  #  C:\Program Files\Microsoft Visual Studio                                                  VC98\Bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio .NET 2003                                        Vc7\bin\cl.exe
  #  C:\Program Files\Microsoft Visual C++ Toolkit 2003                                        bin\cl.exe
  #  C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2                        Bin\win64\cl.exe           -- do not handle
  #  C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2                        Bin\win64\x86\AMD64\cl.exe -- do not handle
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\x86_amd64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\x86_ia64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\amd64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\ia64\cl.exe
  #  C:\Program Files\Microsoft SDKs\Windows                                                   v6.0\VC\Bin\cl.exe
  #  C:\Program Files\Microsoft SDKs\Windows                                                   v6.0\VC\Bin\x64\cl.exe
  #  C:\WINDDK\3790.1830                                                                       bin\x86\cl.exe
  #  C:\WINDDK\3790.1830                                                                       bin\ia64\cl.exe
  #  C:\WINDDK\3790.1830                                                                       bin\win64\x86\cl.exe
  #  C:\WINDDK\3790.1830                                                                       bin\win64\x86\amd64\cl.exe
  #  C:\WinDDK\6001.18002                                                                      bin\x86\x86\cl.exe
  #  C:\WinDDK\6001.18002                                                                      bin\x86\amd64\cl.exe
  #  C:\WinDDK\6001.18002                                                                      bin\x86\ia64\cl.exe
  #  C:\WinDDK\6001.18002                                                                      bin\ia64\ia64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\x86\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\x64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\arm\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\x64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\x86\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\arm\cl.exe

  # VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
  VCCL_PARENT1 := $(patsubst %/,%,$(dir $(subst \,/,$(patsubst "%",%,$(subst $(space),?,$(VCCL))))))
  VCCL_PARENT2 := $(patsubst %/,%,$(dir $(VCCL_PARENT1)))
  VCCL_PARENT3 := $(patsubst %/,%,$(dir $(VCCL_PARENT2)))
  VCCL_PARENT4 := $(patsubst %/,%,$(dir $(VCCL_PARENT3)))
  VCCL_ENTRY1l := $(call tolower,$(notdir $(VCCL_PARENT1)))
  VCCL_ENTRY2l := $(call tolower,$(notdir $(VCCL_PARENT2)))
  VCCL_ENTRY3l := $(call tolower,$(notdir $(VCCL_PARENT3)))

  ifeq (bin,$(VCCL_ENTRY3l))
    ifneq (,$(filter host%,$(VCCL_ENTRY2l)))
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x64\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\arm\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x64\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
      # VCCL="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\arm\cl.exe"

      TVCCL_AUTO := $(VCCL_PARENT3)/$(call VC_TOOL_PREFIX_2017,$(TCPU))cl.exe

	  VC_TOOL_PREFIX_2017 = Host$(subst x,X,$(TCPU:x86_64=x64))/$(1:x86_64=x64)/


    endif
  endif






# we need next MSVC++ variables: TVCCL and TVCLIBPATH
# (they are may be defined either in project configuration makefile or in command line)
# note: TVCLIBPATH may be defined as <empty>, so do not reset it
ifneq (,$(filter undefined environment,$(origin TVCLIBPATH))$(if $(TVCCL),,1))

  # deduce values of TVCCL and TVCLIBPATH from $(VCCL)
  # note: assume compilers $(TVCCL) and $(VCCL) are from the same Visual Studio installation,
  #  so have the same versions and use common header files
  VCCL_PARENT1 := $(patsubst %\,%,$(dir $(patsubst "%",%,$(subst $(space),?,$(if $(TVCCL),$(TVCCL),$(VCCL))))))

  # reset
  TVCCL_AUTO:=

  ifneq (,$(call is_less_float,14,$(VC_VER)))
    # Visual Studio 2017 or later:
    #  VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
    VCCL_PARENT2 := $(patsubst %\,%,$(dir $(VCCL_PARENT1)))

    # e.g. x86
    # note: if TVCCL is not defined, then assume it will have the same host type as $(VCCL)
    VCCL_HOST := $(patsubst host%,%,$(call tolower,$(notdir $(VCCL_PARENT2))))

    ifndef TVCCL
      #  for VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
      # TVCCL_AUTO=C:\Program?Files\Microsoft?Visual?Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x64\cl.exe
      TVCCL_AUTO := $(VCCL_PARENT2)\$(VCCL_HOST)\cl.exe
    endif

    ifneq (,$(filter undefined environment,$(origin TVCLIBPATH)))
      TVCLIBPATH := $(dir $(patsubst %\,%,$(dir $(VCCL_PARENT2))))lib\$(VCCL_HOST)
      $(warning autoconfigured: TVCLIBPATH=$(TVCLIBPATH))
    endif

  else ifeq (,$(call is_less_float,$(VC_VER),8))
    # Visual Studio 2005 or later:
    #  VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\cl.exe"
    #  VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe"
    #  VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
    #  VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64\cl.exe"
    #  VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64_x86\cl.exe"
    #  VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
    VCCL_ENTRY1l := $(call tolower,$(notdir $(VCCL_PARENT1)))

    ifneq (bin,$(VCCL_ENTRY1l))
      # x64       -> x64
      # amd64     -> amd64
      # amd64_x86 -> amd64
      # x86_amd64 ->
      # note: if TVCCL is not defined, then assume it will have the same host type as $(VCCL)
      VCCL_HOST := $(call VCCL_GET_HOST_2005,$(VCCL_ENTRY1l),$(call VS_SELECT_CPU,$(subst \,/,$(VCCL_PARENT1))))

      ifndef TVCCL
        TVCCL_AUTO := $(dir $(VCCL_PARENT1))$(addsuffix \,$(VCCL_HOST))cl.exe
      endif

      ifneq (,$(filter undefined environment,$(origin TVCLIBPATH)))
        TVCLIBPATH := $(dir $(patsubst %\,%,$(dir $(VCCL_PARENT1))))lib$(addprefix \,$(VCCL_HOST))
        $(warning autoconfigured: TVCLIBPATH=$(TVCLIBPATH))
      endif
    endif

  endif

  # assume $(VCCL) corresponds to $(TCPU)/$(CPU) combination

  ifndef TVCCL
    ifeq ($(CPU),$(TCPU))
      # do not check if $(VCCL) exist
      TVCCL := $(VCCL)
    else ifdef TVCCL_AUTO
      TVCCL := $(wildcard $(subst ?,\ ,$(subst \,/,$(TVCCL_AUTO))))
      ifndef TVCCL
        $(error tool C++ compiler for TCPU=$(TCPU) does not exist: $(call ifaddq,$(subst ?, ,$(TVCCL_AUTO))))
      endif
      TVCCL := $(call ifaddq,$(subst /,\,$(TVCCL)))
    else
      # no cross-compiler support
      $(error TCPU=$(TCPU) do not matches CPU=$(CPU), but cross-compiler is not supported)
    endif
    $(warning autoconfigured: TVCCL=$(TVCCL))
  endif

  ifneq (,$(filter undefined environment,$(origin TVCLIBPATH)))
    ifeq ($(CPU),$(TCPU))
      TVCLIBPATH := $(VCLIBPATH)
    else
      # no cross-compiler support
      $(error TCPU=$(TCPU) do not matches CPU=$(CPU), but cross-compiler is not supported)
    endif
    $(warning autoconfigured: TVCLIBPATH=$(TVCLIBPATH))
  endif

endif

# reset variables, if they are not defined in project configuration makefile or in command line
TVCLIB:=
TVCLINK:=

# deduce values of TVCLIB and TVCLINK from $(TVCCL)
ifndef TVCLIB
TVCLIB := $(call ifaddq,$(subst ?, ,$(addsuffix lib.exe,$(dir $(patsubst "%",%,$(subst $(space),?,$(TVCCL)))))))
$(warning autoconfigured: TVCLIB=$(TVCLIB))
endif

ifndef TVCLINK
TVCLINK := $(call ifaddq,$(subst ?, ,$(addsuffix link.exe,$(dir $(patsubst "%",%,$(subst $(space),?,$(TVCCL)))))))
$(warning autoconfigured: TVCLINK=$(TVCLINK))
endif

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,CONF_NORMALIZE_TOOL CONF_NORMALIZE_DIR GET_PROGRAM_FILES_DIRS VS_CPU VS_CPU64 IS_WIN_64 CONF_FIND_FILE_WHERE CONF_FIND_FILE CONF_FIND_FILE_P \
  MS_REG_QUERY_PATH MS_REG_FIND_FILE_WHERE MS_REG_FIND_FILE MS_REG_FIND_FILE_P \
  MS_REG_SEARCH_X MS_REG_SEARCH_WHERE MS_REG_SEARCH MS_REG_SEARCH_P \
  CONF_SELECT_LATEST1 CONF_SELECT_LATEST VC_TOOL_PREFIX_SDK6 VCCL_2005_PATTERN_GEN_VC VCCL_2005_PATTERN_GEN_VS \
  VC_TOOL_PREFIX_2005 VCCL_GET_LIBS_2005 VCCL_GET_HOST_2005 VC_TOOL_PREFIX_2017 \
  VC_LIB_TYPE_ONECORE VC_LIB_TYPE_STORE VS_2017_SELECT_LATEST_ENTRY \
  VC_VER VCCL VCLIB VCLINK VCLIBPATH VCINCLUDE \
  TVC_VER TVCCL TVCLIB TVCLINK TVCLIBPATH TVCINCLUDE \
  VCCL_PATH_APPEND)

# convert prefix of cl.exe $1 to libraries prefix:
#
#  <none>    -> <none>
#  x86_amd64 -> /amd64
#  x86_arm   -> /arm
#  amd64_x86 -> <none>
#  amd64     -> /amd64
#  amd64_arm -> /arm
#  x64       -> /x64
#
# $1 - cl.exe prefix
# $2 - $(VS_CPU)
VCCL_GET_LIBS_2005 = $(addprefix /,$(filter-out $2,$(lastword $(subst _, ,$1))))

# get host of cl.exe $1:
#
#  <none>    -> <none>
#  x86_amd64 -> <none>
#  x86_arm   -> <none>
#  amd64_x86 -> amd64
#  amd64     -> amd64
#  amd64_arm -> amd64
#  x64       -> x64
#
# $1 - cl.exe prefix
# $2 - $(VS_CPU)
VCCL_GET_HOST_2005 = $(filter-out $2,$(firstword $(subst _, ,$1)))

# CPU-specific paths to libraries
# ---------------------------------------------------------------------
# C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\LIB\msvcrt.lib
# C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\LIB\x64\msvcrt.lib
#
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\{,amd64\,arm\}msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\{,amd64\,arm\}msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\{,amd64\,arm\}msvcrt.lib
#
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\{x86,x64,arm}\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\{x86,x64,arm}\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\{x86,x64,arm}\store\msvcrt.lib

# 7) UMVER - name of the Windows version-specific folder containing user-mode libraries (e.g. kernel32.lib) and headers (e.g. WinBase.h),
#   may be specified explicitly to override one deduced automatically, e.g.:
#     wxp wnet wlh win7 win8 winv6.3 10.0.10240.0 10.0.10586.0 10.0.14393.0 10.0.15063.0 10.0.16299.0
#
#   Note: by default, assuming that SDKs are backward-compatible, the newest SDK is used.
#

# configure paths to system libraries/headers:
# (variables prefixed with T - are for the tool mode)
# {,T}UMLIBPATH - paths to user-mode libraries, spaces must be replaced with ?
# {,T}UMINCLUDE - paths to user-mode headers, spaces must be replaced with ?
ifeq (,$(filter-out undefined environment,$(origin ???)))
include $(dir $(lastword $(MAKEFILE_LIST)))msvc/sdk.mk
endif


# autoconfigure:
#  target Windows version, Visual C++ version, paths to compiler, linker, system libraries, headers and tools:
#  (variables prefixed with T - are for the tool mode)
#
# WINVER        - minimal Windows version required to run built executables
# {,T}VC_VER    - MSVC++ version, known values see in $(CLEAN_BUILD_DIR)/compilers/msvc/cmn.mk 'MSVC++ versions' table
# {,T}VCCL      - path to cl.exe                (may be in double-quotes, if contains spaces - double-quoted automatically)
# {,T}VCLIB     - path to lib.exe               (must be in double-quotes if contains spaces, may be deduced from VCCL)
# {,T}VCLINK    - path to link.exe              (must be in double-quotes if contains spaces, may be deduced from VCCL)
# {,T}VCINCLUDE - paths to Visual C++ headers   (such as varargs.h,    without quotes, spaces must be replaced with ?)
# {,T}VCLIBPATH - paths to Visual C++ libraries (such as msvcrt.lib,   without quotes, spaces must be replaced with ?)
# {,T}UMINCLUDE - paths to user-mode headers    (such as winbase.h,    without quotes, spaces must be replaced with ?)
# {,T}UMLIBPATH - paths to user-mode libraries  (such as kernel32.lib, without quotes, spaces must be replaced with ?)
# RC            - path to rc.exe                (may be in double-quotes, if contains spaces - double-quoted automatically)
# MC            - path to mc.exe                (may be in double-quotes, if contains spaces - double-quoted automatically)
# MT            - path to mt.exe                (may be in double-quotes, if contains spaces - double-quoted automatically)
ifneq (,$(filter undefined environment,$(foreach v,WINVER \
  VC_VER VCCL VCLIB VCLINK VCINCLUDE VCLIBPATH UMINCLUDE UMLIBPATH \
  TVC_VER TVCCL TVCLIB TVCLINK TVCINCLUDE TVCLIBPATH TUMINCLUDE TUMLIBPATH RC MC MT,$(origin $v))))
include $(CLEAN_BUILD_DIR)/compilers/msvc/auto/conf.mk
endif

