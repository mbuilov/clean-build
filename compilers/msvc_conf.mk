#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler auto-configuration (app-level), included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

#################################################################################################################
# input for autoconfiguration:
#
# 1) VS - Visual Studio installation path
#   may be specified if autoconfiguration (based on values of environment variables or registry keys) fails, e.g.:
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
#
# 5) DDK - path to Windows Driver Development Kit,
#   may be specified instead of SDK - because DDK contains SDK headers and libraries necessary for building simple console applications,
#   but may be specified together with SDK - for building drivers, e.g.:
#     DDK=C:\WinDDK\7600.16385.1
#
# 6) WDK - path to Windows Development Kit,
#   may be specified instead of SDK and DDK - newer versions of SDK and DDK (8.0 and later) are combined under the same WDK path, e.g.:
#     WDK=C:\Program Files (x86)\Windows Kits\8.0
#     WDK=C:\Program Files (x86)\Windows Kits\10.0
#
#   Note: SDK/DDK values, if non-empty, are preferred over WDK.
#
# 7) WDK_VER - WDK10 target platform version, e.g. one of: 10.0.10240.0 10.0.10586.0 10.0.14393.0 10.0.15063.0 10.0.16299.0
#   may be specified explicitly if failed to determine it automatically or to override automatically defined value
#
#################################################################################################################

# try to autoconfigure:
#  Visual C++ version, paths to compiler, linker and C/C++ libraries and headers
#  - only if they are not defined in project configuration makefile or in command line
#  (variables prefixed with T - are for the tool mode)
#
# {,T}VC_VER    - MSVC++ version, known values see in $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk
# {,T}VCCL      - path to cl.exe                (may be in double-quotes, if contains spaces - double-quoted automatically)
# {,T}VCLIB     - path to lib.exe               (must be in double-quotes if contains spaces)
# {,T}VCLINK    - path to link.exe              (must be in double-quotes if contains spaces)
# {,T}VCLIBPATH - paths to Visual C++ libraries (without quotes, spaces must be replaced with ?)
# {,T}VCINCLUDE - paths to Visual C++ headers   (without quotes, spaces must be replaced with ?)
#
# example:
#
# VC_VER    := 14.0
# VCCL      := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
# VCLIB     := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\lib.exe"
# VCLINK    := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\link.exe"
# VCLIBPATH := C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\VC\lib
# VCINCLUDE := C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\VC\include
#
# note: VCLIBPATH or VCINCLUDE may be defined with empty values in project configuration makefile or in command line

# normalize path: replace spaces with ?, remove double-quotes, make all slashes backward, remove trailing back-slash, e.g.:
#  "a\b\c d\e\" -> a/b/c?d/e
NORMALIZE_PATH = $(patsubst %/,%,$(subst \,/,$(patsubst "%",%,$(subst $(space),?,$1))))

# convert path to printable form
# a/b/c?d/e -> "a\b\c d\e"
PATH_PRINTABLE = $(call ifaddq,$(subst /,\,$(subst ?, ,$1)))

# get paths to "Program Files" and "Program Files (x86)" directories
# note: ProgramW6432 appear starting with Windows 7
# ------------------------------------------------------------------------
#       | ProgramFiles            ProgramFiles(x86)       ProgramW6432    
# ------|-----------------------------------------------------------------
# win64 | C:\Program Files        C:\Program Files (x86)  C:\Program Files
# wow64 | C:\Program Files (x86)  C:\Program Files (x86)  C:\Program Files
# win32 | C:\Program Files                                                
# ------------------------------------------------------------------------
# result on win64: C:/Program?Files C:/Program?Files?(x86)
# result on wow64: C:/Program?Files?(x86) C:/Program?Files
# result on win32: C:/Program?Files
GET_PROGRAM_FILES_DIRS = $(call uniq,$(foreach \
  v,ProgramFiles ProgramFiles$(open_brace)x86$(close_brace) ProgramW6432,$(if \
  $(filter-out undefined,$(origin $v)),$(subst $(space),?,$(subst \,/,$($v))))))

# base architecture of Visual Studio tools
# note: TCPU likely has this value, but it is possible to have TCPU=x86_64 for VS_CPU=x86, if Visual Studio supports x86_64 tools
# note: VS_CPU value depends on where Visual Studio is installed, e.g., on 64-bit Windows:
#  C:\Program Files\Microsoft Visual Studio 8\VC\bin\cl.exe                 - base     x86_64 compiler for x86_64, VS_CPU should be amd64
#  C:\Program Files (x86)\Microsoft Visual Studio 8\VC\bin\cl.exe           - base     x86    compiler for x86,    VS_CPU should be x86
#  C:\Program Files (x86)\Microsoft Visual Studio 8\VC\bin\amd64\cl.exe     - prefixed x86_64 compiler for x86_64, VS_CPU should be x86
#  C:\Program Files (x86)\Microsoft Visual Studio 8\VC\bin\x86_amd64\cl.exe - prefixed x86    compiler for x86_64, VS_CPU should be x86
VS_CPU   := x86
VS_CPU64 := amd64

# variable ProgramFiles(x86) is defined only under 64-bit Windows
IS_WIN_64 := $(filter-out undefined,$(origin ProgramFiles$(open_brace)x86$(close_brace)))

ifdef IS_WIN_64
# $1 - pattern, like C:/Program?Files?(x86)/A/B/C
VS_SELECT_CPU = $(if $(findstring :/program?files/,$(tolower)),$(VS_CPU64),$(VS_CPU))
else
VS_SELECT_CPU := $(VS_CPU)
endif

# check if file exist and if it is, return path to parent directory of that file
# $1 - path to file, e.g.: C:/Program?Files?(x86)/Microsoft?Visual?Studio?9.0/VC/lib/amd64/msvcrt.lib
# returns: C:\Program?Files?(x86)\Microsoft?Visual?Studio?9.0\VC\lib\amd64
CHECK_FILE_PATH := $(subst /,\,$(patsubst %/,%,$(dir $(subst $(space),?,$(wildcard $(subst ?,\ ,$1))))))

# find file in the paths by pattern, return path where file was found
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program?Files/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_FIND_FILE_WHERE  = $(if $2,$(call VS_FIND_FILE_WHERE1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$1)))
VS_FIND_FILE_WHERE1 = $(if $3,$(firstword $2) $3,$(call VS_FIND_FILE_WHERE,$1,$(wordlist 2,999999,$2)))

# find file in the paths by pattern
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_FIND_FILE  = $(if $2,$(call VS_FIND_FILE1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$1)))
VS_FIND_FILE1 = $(if $3,$3,$(call VS_FIND_FILE,$1,$(wordlist 2,999999,$2)))

# like VS_FIND_FILE, but $1 - name of macro that returns file to find (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# note: macro $1 may use $(firstword $2) - path where the search is done
VS_FIND_FILE_P  = $(if $2,$(call VS_FIND_FILE_P1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$($1))))
VS_FIND_FILE_P1 = $(if $3,$3,$(call VS_FIND_FILE_P,$1,$(wordlist 2,999999,$2)))

# query path value in the registry under "HKLM\SOFTWARE\Microsoft\" or "HKLM\SOFTWARE\Wow6432Node\Microsoft\"
# $1 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $2 - registry key name, e.g.: 14.0 or ProductDir
# $3 - empty or \Wow6432Node
# result: for VC7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/VC/
# result: for VS7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/
# note: result will be with trailing backslash
# note: value of "VisualStudio\6.0\Setup\Microsoft Visual C++\ProductDir" key does not end with slash, e.g:
#  "C:\Program Files (x86)\Microsoft Visual Studio\VC98"
VS_REG_QUERY = $(patsubst %//,%/,$(addsuffix /,$(subst \,/,$(subst ?$2?REG_SZ?,,$(word \
  2,$(subst HKEY_LOCAL_MACHINE\SOFTWARE$3\Microsoft\$1, ,xxx$(subst $(space),?,$(strip $(shell \
  reg query "HKLM\SOFTWARE$3\Microsoft\$1" /v "$2" 2>&1)))))))))

# find file by pattern in the path found in registry
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $3 - registry key name, e.g.: 14.0 or ProductDir
# $4 - if not empty, then also check Wow6432Node (applicable only on Win64), tip: use $(IS_WIN_64)
# result (may be a list): C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_REG_FIND_FILE_WHERE  = $(call VS_REG_FIND_FILE_WHERE1,$1,$(call VS_REG_QUERY,$2,$3),$2,$3,$4)
VS_REG_FIND_FILE_WHERE1 = $(call VS_REG_FIND_FILE_WHERE2,$1,$2,$(if $2,$(wildcard $(subst ?,\ ,$2)$1)),$3,$4,$5)
VS_REG_FIND_FILE_WHERE2 = $(if $3,$2 $3,$(if $6,$(call VS_REG_FIND_FILE_WHERE3,$1,$(call VS_REG_QUERY,$4,$5,\Wow6432Node))))
VS_REG_FIND_FILE_WHERE3 = $(if $2,$(call VS_REG_FIND_FILE_WHERE4,$2,$(wildcard $(subst ?,\ ,$2)$1)))
VS_REG_FIND_FILE_WHERE4 = $(if $2,$1 $2)

# same as VS_REG_FIND_FILE_WHERE, but do not return path where file was found
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_REG_FIND_FILE = $(wordlist 2,999999,$(VS_REG_FIND_FILE_WHERE))

# like VS_REG_FIND_FILE, but $1 - name of macro that returns file to find (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# note: macro $1 may use $2 - path where the search is done
VS_REG_FIND_FILE_P  = $(call VS_REG_FIND_FILE_P1,$1,$(call VS_REG_QUERY,$2,$3),$2,$3,$4)
VS_REG_FIND_FILE_P1 = $(call VS_REG_FIND_FILE_P2,$1,$(if $2,$(wildcard $(subst ?,\ ,$2)$($1))),$3,$4,$5)
VS_REG_FIND_FILE_P2 = $(if $2,$2,$(if $5,$(call VS_REG_FIND_FILE_P3,$1,$(call VS_REG_QUERY,$3,$4,\Wow6432Node))))
VS_REG_FIND_FILE_P3 = $(if $2,$(wildcard $(subst ?,\ ,$2)$($1)))

# find file by pattern in the paths found in registry
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# $3 - VS_REG_FIND_FILE_WHERE, VS_REG_FIND_FILE or VS_REG_FIND_FILE_P
VS_REG_SEARCH_X  = $(if $2,$(call VS_REG_SEARCH_X1,$1,$2,$3,$(subst ?, ,$(firstword $2))))
VS_REG_SEARCH_X1 = $(call VS_REG_SEARCH_X2,$1,$2,$3,$(call $3,$1,$(firstword $4),$(lastword $4),$(IS_WIN_64)))
VS_REG_SEARCH_X2 = $(if $4,$4,$(call VS_REG_SEARCH_X,$1,$(wordlist 2,999999,$2),$3))

# find file by pattern in the paths found in registry
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - registry key sub paths and corresponding key names, e.g. VisualStudio\14.0\Setup\VC?ProductDir VisualStudio\SxS\VC7?14.0
# result (may be a list): C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/ C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_REG_SEARCH_WHERE = $(call VS_REG_SEARCH_X,$1,$2,VS_REG_FIND_FILE_WHERE)

# same as VS_REG_SEARCH_WHERE, but do not return path where file was found
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_REG_SEARCH = $(call VS_REG_SEARCH_X,$1,$2,VS_REG_FIND_FILE)

# like VS_REG_SEARCH, but $1 - name of macro that returns file to find (VCCL_2005_PATTERN_GEN_VC or VCCL_2005_PATTERN_GEN_VS)
# note: macro $1 may use $2 - path where the search is done
VS_REG_SEARCH_P = $(call VS_REG_SEARCH_X,$1,$2,VS_REG_FIND_FILE_P)

# there may be more than one file found - take the newer one, e.g.:
#  $1=bin/HostX86/x64/cl.exe
#  $2=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
# result: C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
VS_SELECT_LATEST1 = $(patsubst %,$2%$1,$(lastword $(sort $(subst $1?$2, ,$(patsubst %,$1?%?$2,$(subst $(space),?,$3))))))
VS_SELECT_LATEST  = $(call VS_SELECT_LATEST1,$1,$(firstword $2),$(wordlist 2,999999,$2))

# for Visual C++ compiler from Windows Server 2003 DDK
# determine MSVC++ tools prefix for given TCPU/CPU combination, e.g.:
#  C:\WINDDK\3790\bin\x86\cl.exe             - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 13.10.2179 for 80x86
#  C:\WINDDK\3790\bin\ia64\cl.exe            - ???
#  C:\WINDDK\3790\bin\win64\x86\cl.exe       - Microsoft (R) C/C++ Optimizing Compiler Version 13.10.2240.8 for IA-64
#  C:\WINDDK\3790\bin\win64\x86\amd64\cl.exe - Microsoft (R) C/C++ Optimizing Compiler Version 14.00.2207 for AMD64
#
# TCPU\CPU |  x86       x86_64        ia64
# ---------|---------------------------------
# x86      |  x86  win64/x86/amd64  win64/x86
# ia64     |   ?          ?           ia64
#
# $1 - $(CPU)
CL_TOOL_PREFIX_DDK_3790 = $(if $(filter $1,$(TCPU)),$1,$(if $(filter %64,$1),win64/)$(TCPU:x86_64=amd64)/$(if $(filter x86_64,$1),amd64/))

# for Visual C++ compiler from Windows Driver Kit 6-7 (Visual C++ 8.0-9.0 of Visual Studio 2005-2008)
# determine MSVC++ tools prefix for given TCPU/CPU combination, e.g.:
#  C:\WinDDK\6001.18001\bin\x86\x86\cl.exe   - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 14.00.50727.278 for 80x86
#  C:\WinDDK\6001.18001\bin\x86\amd64\cl.exe - Microsoft (R) C/C++ Optimizing Compiler Version 14.00.50727.278 for x64
#  C:\WinDDK\6001.18001\bin\x86\ia64\cl.exe  - Microsoft (R) C/C++ Optimizing Compiler Version 14.00.50727.283 for Itanium
#  C:\WinDDK\6001.18001\bin\ia64\ia64\cl.exe - ????
# $1 - $(CPU)
CL_TOOL_PREFIX_DDK6 = $(TCPU:x86_64=amd64)/$(1:x86_64=amd64)/

# for Visual C++ compiler from SDK 6.0 (Visual C++ 8.0 of Visual Studio 2005)
# determine MSVC++ tools prefix for given CPU
# note: $(TCPU) _must_ match $(CPU)
#
# CPU  |  x86    x86_64
# -----|-------------------------------------
# pref | <none>   x64/
#
VC_TOOL_PREFIX_SDK6 := $(addsuffix /,$(filter-out x86,$(TCPU:x86_64=x64)))

# for use with VS_FIND_FILE_P or VS_REG_SEARCH_P
# $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/VC/ C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/VC/
# result: bin/x86_arm/cl.exe (possible with spaces in result)
VCCL_2005_PATTERN_GEN_VC = bin/$(call VC_TOOL_PREFIX_2005,$(CPU),$(call VS_SELECT_CPU,$(firstword $2)))cl.exe

# for use with VS_FIND_FILE_P or VS_REG_SEARCH_P
# $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/ C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/
# result: VC/bin/x86_arm/cl.exe (possible with spaces in result)
VCCL_2005_PATTERN_GEN_VS = VC/bin/$(call VC_TOOL_PREFIX_2005,$(CPU),$(call VS_SELECT_CPU,$(firstword $2)))cl.exe

# for Visual Studio 2005-2015
# determine MSVC++ tools prefix for given TCPU/CPU combination
#
# TCPU\CPU |  x86        x86_64      arm
# ---------|---------------------------------
# x86      | <none>     x86_amd64/ x86_arm/
# x86_64   | amd64_x86/ amd64/     amd64_arm/
#
# $1 - $(CPU)
# $2 - $(VS_CPU)
VC_TOOL_PREFIX_2005 = $(addsuffix /,$(filter-out \
  $2,$(TCPU:x86_64=amd64)$(addprefix _,$(subst x86_64,amd64,$(filter-out $(TCPU),$1)))))

# convert prefix of cl.exe $1 to libraries prefix:
#  <none>    -> <none>
#  x86_amd64 -> /amd64
#  x86_arm   -> /arm
#  amd64_x86 -> <none>
#  amd64     -> /amd64
#  amd64_arm -> /arm
#  x64       -> /x64
# $1 - cl.exe prefix
# $2 - $(VS_CPU)
VCCL_GET_LIBS_2005 = $(addprefix /,$(filter-out $2,$(lastword $(subst _, ,$1))))

# get host of cl.exe $1:
#  <none>    -> <none>
#  x86_amd64 -> <none>
#  x86_arm   -> <none>
#  amd64_x86 -> amd64
#  amd64     -> amd64
#  amd64_arm -> amd64
#  x64       -> x64
# $1 - cl.exe prefix
# $2 - $(VS_CPU)
VCCL_GET_HOST_2005 = $(filter-out $2,$(firstword $(subst _, ,$1)))

# for Visual Studio 2017
# determine MSVC++ tools prefix for given TCPU/CPU combination
#
# TCPU\CPU |   x86          x86_64        arm
# ---------|---------------------------------------
# x86      | HostX86/x86/ HostX86/x64/ HostX86/arm/
# x86_64   | HostX64/x86/ HostX64/x64/ HostX64/arm/
#
# $1 - $(CPU)
VC_TOOL_PREFIX_2017 = Host$(subst x,X,$(TCPU:x86_64=x64))/$(1:x86_64=x64)/

# reset VC_VER, if it's not defined in project configuration makefile or in command line
VC_VER:=

# reset VCCL, if it's not defined in project configuration makefile or in command line
VCCL:=

# if VCCL is defined in project configuration makefile or in command line, check its value
ifdef VCCL
  # VCCL path must use forward slashes
  override VCCL := $(subst /,\,$(VCCL))
  ifneq (,$(findstring $(space),$(VCCL)))
    # if $(VCCL) contains a space, it must be in double quotes
    ifeq ($(subst $(space),?,$(VCCL)),$(patsubst "%",%,$(subst $(space),?,$(VCCL))))
      override VCCL := "$(VCCL)"
    endif
  endif
else ifdef VC_VER
  $(error VC_VER=$(VC_VER) is defined, but VCCL does not)
endif

# subdirectory of MSVC++ libraries: <empty> or onecore
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_ONECORE:=

# subdirectory of MSVC++ libraries: <empty> or store
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_STORE:=

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

# autoconfigured paths to Visual C++ libraries and headers:
#  VCLIBPATH_AUTO is set only if VCLIBPATH was not defined (possibly with empty value) before VCLIBPATH_AUTO was set
#  VCINCLUDE_AUTO is set only if VCINCLUDE was not defined (possibly with empty value) before VCINCLUDE_AUTO was set
VCLIBPATH_AUTO:=
VCINCLUDE_AUTO:=

ifdef SDK
# SDK=C:/Program?Files/Microsoft?SDKs/Windows/v6.0
override SDK := $(call NORMALIZE_PATH,$(SDK))
endif

ifdef DDK
# DDK=C:/WinDDK/7600.16385.1
override DDK := $(call NORMALIZE_PATH,$(DDK))
endif

ifdef WDK
# WDK=C:/Program?Files?(x86)/Windows?Kits/8.0
override WDK := $(call NORMALIZE_PATH,$(WDK))
ifdef MCHECK
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
ifndef VCCL

# reset variables, if they are not defined in project configuration makefile or in command line
VS:=
MSVC:=

# VS may be defined as                                 compiler path
# ---------------------------------------------------|-----------------------
# C:\Program Files\Microsoft Visual Studio           | \VC98\Bin\CL.EXE
# C:\Program Files\Microsoft Visual Studio .NET      | \Vc7\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio .NET 2003 | \Vc7\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio 8         | \VC\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio 9.0       | \VC\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio 10.0      | \VC\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio 11.0      | \VC\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio 12.0      | \VC\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0      | \VC\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017      | \Community\VC\Tools\MSVC\14.10.25017\bin\HostX86\x86\cl.exe

# CPU-specific paths to compiler
# ---------------------------------------------------------------------
# C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\cl.exe
# C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe
#
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_arm\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64_x86\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64_arm\cl.exe
#
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\{HostX86,HostX64}\{x86,x64,arm}\cl.exe

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

# take the newer one found cl.exe, e.g.:
#  $1=bin/HostX86/x64/cl.exe
#  $2=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
# result: C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
VS_2017_SELECT_LATEST_ENTRY = $(subst ?, ,$(VS_SELECT_LATEST))

ifndef VCCL
ifndef MSVC
ifndef VS

  # VCToolsInstallDir is normally set by the vcvars32.bat, e.g.:
  #  VCToolsInstallDir=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\
  # note: likely with trailing slash
  ifneq (undefined,$(origin VCToolsInstallDir))
    MSVC := $(VCToolsInstallDir)

  # VCINSTALLDIR is normally set by the vcvars32.bat, e.g.:
  #  VCINSTALLDIR=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\
  # note: likely with trailing slash
  else ifneq (undefined,$(origin VCINSTALLDIR))
    MSVC := $(VCINSTALLDIR)

  # Check for toolkit of Visual Studio 2003
  # VCToolkitInstallDir=C:\Program Files\Microsoft Visual C++ Toolkit 2003
  else ifneq (undefined,$(origin VCToolkitInstallDir))
    MSVC := $(VCToolkitInstallDir)

  # for Visual Studio 6.0, vcvars32.bat defines MSVCDir, e.g.:
  # MSVCDir=C:\PROG~FBU\MICR~2ZC\VC98
  else ifneq (undefined,$(origin MSVCDir))
    MSVC := $(MSVCDir)

  endif
endif
endif
endif

ifndef VCCL
ifndef MSVC
ifndef VS

  # VSINSTALLDIR is normally set by the vcvars32.bat, e.g.:
  #  VSINSTALLDIR=C:\Program Files\Microsoft Visual Studio 12.0\
  #  VSINSTALLDIR=C:\Program Files\Microsoft Visual Studio\2017\Community\
  # note: likely with trailing slash
  ifneq (undefined,$(origin VSINSTALLDIR))
    VS := $(VSINSTALLDIR)

  endif
endif
endif
endif

ifdef MSVC
# MSVC=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC
override MSVC := $(call NORMALIZE_PATH,$(MSVC))
endif

ifndef MSVC
ifdef VS
# VS=C:/Program?Files/Microsoft?Visual?Studio?12.0
override VS := $(call NORMALIZE_PATH,$(VS))
endif
endif

ifndef VCCL
ifndef MSVC
ifndef VS
  # define VCCL from values of VS*COMNTOOLS environment variables (that may be set by the vcvars32.bat)

  # try to extract Visual Studio installation paths from values of VS*COMNTOOLS variables,
  #  e.g. VS140COMNTOOLS=C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools\
  #   or  VS150COMNTOOLS=C:\Program Files\Microsoft Visual Studio\2017\Community\Common7\Tools\
  # note: return sorted values, starting from the greatest tools version
  VS_COMN_VERS := $(call reverse,$(call sort_numbers,$(patsubst VS%COMNTOOLS,%,$(filter VS%COMNTOOLS,$(.VARIABLES)))))

  ifdef VS_COMN_VERS

    # C:\Program?Files\Microsoft?Visual?Studio\2017\Community\Common7\Tools\ -> C:/Program?Files/Microsoft?Visual?Studio/2017/Community/
    VS_STRIP_COMN = $(subst \,/,$(dir $(patsubst %\,%,$(dir $(patsubst %\,%,$1)))))

    ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),150))
      # Visual Studio 2017 or later

      # note: result will look like:
      #  C:/Program?Files/Microsoft?Visual?Studio/2017/Community/
      VS_COMNS_2017 := $(call VS_STRIP_COMN,$(foreach v,$(VS_COMN_VERS),$(if \
        $(call is_less,$v,150),,$(subst $(space),?,$(VS$vCOMNTOOLS)))))

      # select appropriate compiler for the $(CPU)
      VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

      # try to find Visual Studio 2017 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
      #  C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
      VCCL := $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(call \
        VS_FIND_FILE_WHERE,VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(VS_COMNS_2017)))

      ifndef VCCL
        # filter-out Visual Studio 2017 or later
        VS_COMN_VERS := $(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,150),$v))
      endif

    endif
  endif

  ifndef VCCL
    ifdef VS_COMN_VERS
      ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),80))
        # Visual Studio 2005 or later

        # search cl.exe in the paths of VS*COMNTOOLS
        # $1 - MSVC versions, e.g. 140,120,110,100,90,80
        # result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
        VS_COMN_FIND_CL_2005 = $(if $1,$(call VS_COMN_FIND_CL_20051,$1,$(call \
          VS_STRIP_COMN,$(subst $(space),?,$(VS$(firstword $1)COMNTOOLS)))))

        # $1 - MSVC versions, e.g. 140,120,110,100,90,80
        # $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/
        VS_COMN_FIND_CL_20051 = $(call VS_COMN_FIND_CL_20052,$1,$(wildcard $(subst ?,\ ,$2)VC/bin/$(call \
          VC_TOOL_PREFIX_2005,$(CPU),$(call VS_SELECT_CPU,$2))cl.exe))

        # $1 - MSVC versions, e.g. 140,120,110,100,90,80
        # $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/VC/bin/x86_arm/cl.exe
        VS_COMN_FIND_CL_20052 = $(if $2,$2,$(call VS_COMN_FIND_CL_2005,$(wordlist 2,999999,$1)))

        # select appropriate compiler for the $(CPU), e.g.:
        # C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
        VCCL := $(call VS_COMN_FIND_CL_2005,$(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,80),,$v)))

        ifndef VCCL
          # filter-out Visual Studio 2005 or later
          VS_COMN_VERS := $(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,80),$v))
        endif

      endif
    endif
  endif

  ifndef VCCL
    ifdef VS_COMN_VERS

      # search cl.exe in the paths of VS*COMNTOOLS
      # $1 - MSVC versions, e.g. 71,70,60
      # $2 - Vc7/bin/cl.exe or VC98/Bin/cl.exe
      # result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
      VS_COMN_FIND_CL = $(if $1,$(call VS_COMN_FIND_CL1,$1,$2,$(wildcard \
        $(subst ?,\ ,$(call VS_STRIP_COMN,$(subst $(space),?,$(VS$(firstword $1)COMNTOOLS))))$2)))

      # $1 - MSVC versions, e.g. 71,70,60
      # $2 - Vc7/bin/cl.exe or VC98/Bin/cl.exe
      # $3 - C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
      VS_COMN_FIND_CL1 = $(if $3,$3,$(call VS_COMN_FIND_CL,$(wordlist 2,999999,$1),$2))

      ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),70))
        # Visual Studio .NET or later

        # may compile only for x86 on x86
        ifeq ($(CPU) $(VS_CPU),$(TCPU) $(CPU))
          VCCL := $(call VS_COMN_FIND_CL,$(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,70),,$v)),Vc7/bin/cl.exe)
        endif

        ifndef VCCL
          # filter-out Visual Studio .NET or later
          VS_COMN_VERS := $(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,70),$v))
        endif
      endif

    endif
  endif

  ifndef VCCL
    ifdef VS_COMN_VERS
      ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),60))
        # Visual Studio 6.0 or later

        ifeq ($(CPU) $(VS_CPU),$(TCPU) $(CPU))
          VCCL := $(call VS_COMN_FIND_CL,$(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,60),,$v)),VC98/Bin/cl.exe)
        endif

        ifndef VCCL
          # filter-out Visual Studio 6.0 or later
          VS_COMN_VERS := $(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,60),$v))
        endif

      endif
    endif
  endif

  ifdef VCCL
    # C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
    # "C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe"
    VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))
    $(warning autoconfigured: VCCL=$(VCCL))
  endif

endif
endif
endif

ifndef VCCL
ifndef MSVC
ifndef VS
  # check registry and standard places in Program Files - to define VCCL

  # get registry keys of Visual C++ installation paths for VS_REG_SEARCH
  # $1 - Visual Studio version, e.g.: 7.0 7.1 8.0 9.0 10.0 11.0 12.0 14.0 15.0
  # note: for Visual Studio 2005 and later - check VCExpress key
  VCCL_REG_KEYS_VC = VisualStudio\$1\Setup\VC?ProductDir $(if $(call \
    is_less_float,$1,8.0),,VCExpress\$1\Setup\VC?ProductDir) VisualStudio\SxS\VC7?$1

  # get registry keys of Visual Studio installation paths for VS_REG_SEARCH
  VCCL_REG_KEYS_VS = VisualStudio\$1\Setup\VS?ProductDir $(if $(call \
    is_less_float,$1,8.0),,VCExpress\$1\Setup\VS?ProductDir) VisualStudio\SxS\VS7?$1

  # select appropriate compiler for the $(CPU)
  VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

  # look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
  VCCL := $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(call \
    VS_REG_SEARCH_WHERE,Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(call VCCL_REG_KEYS_VC,15.0)))

  ifndef VCCL
    # look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
    VCCL := $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(call \
      VS_REG_SEARCH_WHERE,VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(call VCCL_REG_KEYS_VS,15.0)))
  endif

  ifndef VCCL
    # check standard places
    # e.g.: C:/Program?Files/ C:/Program?Files?(x86)/
    PROGRAM_FILES_PLACES := $(addsuffix /,$(GET_PROGRAM_FILES_DIRS))

    # look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
    VCCL := $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(call \
      VS_FIND_FILE_WHERE,Microsoft Visual Studio/*/*/VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(PROGRAM_FILES_PLACES)))
  endif

  ifndef VCCL
    # versions of Visual C++ starting with Visual Studio 2005
    VCCL_2005_VERSIONS := 14.0 12.0 11.0 10.0 9.0 8.0

    # $1 - 14.0 12.0 11.0 10.0 9.0 8.0
    # result: 14.0 C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
    VS_SEARCH_2005  = $(if $1,$(call VS_SEARCH_20051,$1,$(call \
      VS_REG_SEARCH_P,VCCL_2005_PATTERN_GEN_VC,$(call VCCL_REG_KEYS_VC,$(firstword $1)))))

    # look in Visual Studio installation paths
    VS_SEARCH_20051 = $(if $2,$2,$(call VS_SEARCH_20052,$1,$(call \
      VS_REG_SEARCH_P,VCCL_2005_PATTERN_GEN_VS,$(call VCCL_REG_KEYS_VS,$(firstword $1)))))

    # check standard places
    VS_SEARCH_20052 = $(if $2,$2,$(call VS_SEARCH_20053,$1,$(call \
      VS_FIND_FILE_P,VCCL_2005_PATTERN_GEN_VS,$(addsuffix \
      Microsoft?Visual?Studio?$(subst 8.0,8,$(firstword $1))/,$(PROGRAM_FILES_PLACES)))))

    # recursion
    VS_SEARCH_20053 = $(if $2,$2,$(call VS_SEARCH_2005,$(wordlist 2,999999,$1)))

    # result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
    VCCL := $(call VS_SEARCH_2005,$(VCCL_2005_VERSIONS))
  endif

  ifndef VCCL
    # check for C++ compiler bundled in Windows Driver Kit 7.1.0 or 7.0.0
    CL_DDK6 := bin/$(call CL_TOOL_PREFIX_DDK6,$(CPU))cl.exe

    # look for:
    #  C:\WinDDK\7600.16385.1\bin\x86\x86\cl.exe   - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 15.00.30729.207 for 80x86
    #  C:\WinDDK\7600.16385.1\bin\x86\amd64\cl.exe - Microsoft (R) C/C++ Optimizing Compiler Version 15.00.30729.207 for x64
    #  C:\WinDDK\7600.16385.1\bin\x86\ia64\cl.exe  - Microsoft (R) C/C++ Optimizing Compiler Version 15.00.30729.207 for Itanium
    ifdef DDK
      VCCL := $(wildcard $(subst ?,\ ,$(DDK))/$(CL_DDK6))

    else ifndef WDK # WDK may be used instead of DDK, but WDK comes without bundled compiler

      # check registry for Windows Driver Kit 7.1.0 or 7.0.0
      DDK_71_REG_PATH := KitSetup\configured-kits\{B4285279-1846-49B4-B8FD-B9EAF0FF17DA}\{68656B6B-555E-5459-5E5D-6363635E5F61}
      DDK_70_REG_PATH := KitSetup\configured-kits\{B4285279-1846-49B4-B8FD-B9EAF0FF17DA}\{676E6B70-5659-5459-5B5F-6063635E5F61}

      # e.g.: C:/my ddks/WinDDK/7600.16385.1/bin/x86/x86/cl.exe
      VCCL := $(call VS_REG_FIND_FILE,$(CL_DDK6),$(DDK_71_REG_PATH),setup-install-location,$(IS_WIN_64))
      ifndef VCCL
        VCCL := $(call VS_REG_FIND_FILE,$(CL_DDK6),$(DDK_70_REG_PATH),setup-install-location,$(IS_WIN_64))
      endif

      ifdef VCCL
        # e.g.: C:/my?ddks/WinDDK/7600.16385.1
        DDK_AUTO := $(patsubst %/$(CL_DDK6),%,$(subst $(space),?,$(VCCL)))
      endif

    endif
  endif

  ifndef VCCL
    # cross compiler is not supported by SDK6.0, but may compile x86_64 on x86_64 or x86 on x86
    ifeq ($(CPU),$(TCPU))

      # check for Visual C++ compiler bundled in SDK6.0
      CL_SDK6 := VC/Bin/$(VC_TOOL_PREFIX_SDK6)cl.exe

      # look for C:/Program Files/Microsoft SDKs/Windows/v6.0/VC/Bin/x64/cl.exe - Microsoft Compiler Version 14.00.50727.762 for x64
      ifdef SDK
        VCCL := $(wildcard $(subst ?,\ ,$(SDK))/$(CL_SDK6))

      else ifndef WDK # WDK may be used instead of SDK, but WDK comes without bundled compiler

        # look for C:/Program Files/Microsoft SDKs/Windows/v6.0/VC/Bin/x64/cl.exe - Microsoft Compiler Version 14.00.50727.762 for x64
        VCCL := $(call VS_REG_FIND_FILE,$(CL_SDK6),Microsoft SDKs\Windows\v6.0,InstallationFolder)

        ifndef VCCL
          # look in Program Files
          VCCL := $(call VS_FIND_FILE,$(CL_SDK6),$(addsuffix Microsoft?SDKs/Windows/v6.0/,$(PROGRAM_FILES_PLACES)))
        endif

        ifdef VCCL
          # e.g.: C:/Program?Files/Microsoft?SDKs/Windows/v6.0
          SDK_AUTO := $(patsubst %/$(CL_SDK6),%,$(subst $(space),?,$(VCCL)))
        endif

      endif
    endif
  endif

  ifndef VCCL
    # check for C++ compiler bundled in Windows Driver Kit – Server 2008 Release SP1 (x86, x64, i64) 6001.18002 December 8, 2008
    # check for C++ compiler bundled in Windows Driver Kit – Server 2008 (x86, x64, ia64) 6001.18001 April 1, 2008

    # look for:
    #  C:\WinDDK\6001.18002\bin\x86\x86\cl.exe - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 14.00.50727.278 for 80x86
    ifdef DDK
      # already checked

    else ifndef WDK # WDK may be used instead of DDK, but WDK comes without bundled compiler

      # check registry for Windows Driver Kit – Server 2008 Release SP1 (x86, x64, i64) 6001.18002  December 8, 2008
      DDK_62_REG_PATH := KitSetup\configured-kits\{B4285279-1846-49B4-B8FD-B9EAF0FF17DA}\{515A5454-555D-5459-5B5D-616264656660}

      # e.g.: C:/my ddks/WinDDK/6001.18002/bin/x86/x86/cl.exe
      VCCL := $(call VS_REG_FIND_FILE,$(CL_DDK6),$(DDK_62_REG_PATH),setup-install-location,$(IS_WIN_64))
      ifndef VCCL
        # check registry for Windows Driver Kit – Server 2008 (x86, x64, ia64)   6001.18001  April 1, 2008
        VCCL := $(call VS_REG_FIND_FILE,$(CL_DDK6),WINDDK\6001.18001\Setup,BUILD,$(IS_WIN_64))
      endif

      ifdef VCCL
        # e.g.: C:/my?ddks/WinDDK/6001.18002
        DDK_AUTO := $(patsubst %/$(CL_DDK6),%,$(subst $(space),?,$(VCCL)))
      endif

    endif
  endif

  ifndef VCCL
    # cross compiler is not supported by Visual Studio .NET 2003, may compile only x86 on x86
    ifeq ($(CPU) $(VS_CPU),$(TCPU) $(CPU))

      # search Visual C++ .NET 2003 compiler
      VCCL := $(call VS_REG_SEARCH,bin/cl.exe,$(call VCCL_REG_KEYS_VC,7.1))

      ifndef VCCL
        VCCL := $(call VS_REG_SEARCH,Vc7/bin/cl.exe,$(call VCCL_REG_KEYS_VS,7.1))
      endif

      ifndef VCCL
        # look in Program Files
        VCCL := $(call VS_FIND_FILE,Vc7/bin/cl.exe,$(addsuffix Microsoft?Visual?Studio?.NET?2003/,$(PROGRAM_FILES_PLACES)))
      endif

    endif
  endif

  ifndef VCCL
    # check for C++ compiler bundled in Windows Server 2003 SP1 DDK
    # check for C++ compiler bundled in Windows Server 2003 DDK 3790
    CL_DDK_3790 := bin/$(call CL_TOOL_PREFIX_DDK_3790,$(CPU))cl.exe

    # look for:
    #  C:\WINDDK\3790.1830\bin\x86\cl.exe - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 13.10.4035 for 80x86
    ifdef DDK
      VCCL := $(wildcard $(subst ?,\ ,$(DDK))/$(CL_DDK_3790))

    else ifndef WDK # WDK may be used instead of DDK, but WDK comes without bundled compiler

      # check registry for Windows Server 2003 SP1 DDK
      # e.g.: C:/my ddks/WinDDK/3790.1830/bin/x86/cl.exe
      VCCL := $(call VS_REG_FIND_FILE,$(CL_DDK_3790),WINDDK\3790.1830,LFNDirectory,$(IS_WIN_64))
      ifndef VCCL
        # check registry for Windows Server 2003 DDK 3790
        VCCL := $(call VS_REG_FIND_FILE,$(CL_DDK_3790),WINDDK\3790,LFNDirectory,$(IS_WIN_64))
      endif

      ifdef VCCL
        # e.g.: C:/my?ddks/WinDDK/3790.1830
        DDK_AUTO := $(patsubst %/$(CL_DDK_3790),%,$(subst $(space),?,$(VCCL)))
      endif

    endif
  endif

  ifndef VCCL
    # cross compiler is not supported, may compile only x86 on x86
    ifeq ($(CPU) $(VS_CPU),$(TCPU) $(CPU))

      # look in Program Files for Visual C++ compiler of Microsoft Visual C++ Toolkit 2003
      VCCL := $(call VS_FIND_FILE,bin/cl.exe,$(addsuffix Microsoft?Visual?C++?Toolkit?2003/,$(PROGRAM_FILES_PLACES)))

    endif
  endif

  ifndef VCCL
    # cross compiler is not supported, may compile only x86 on x86
    ifeq ($(CPU) $(VS_CPU),$(TCPU) $(CPU))

      # check for C++ compiler bundled in Windows XP SP1 DDK 2600.1106
      # check for C++ compiler bundled in DDK for Windows XP
      CL_DDK_2600 := bin/$(CPU:x86_64=amd64)/cl.exe

      # look for:
      #  C:\WINDDK\2600.1106\bin\x86\cl.exe - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 13.00.9176 for 80x86
      ifdef DDK
        VCCL := $(wildcard $(subst ?,\ ,$(DDK))/$(CL_DDK_2600))

      else ifndef WDK # WDK may be used instead of DDK, but WDK comes without bundled compiler

        # check registry for Windows XP SP1 DDK 2600.1106
        # e.g.: C:/my ddks/WinDDK/2600.1106/bin/x86/cl.exe
        VCCL := $(call VS_REG_FIND_FILE,$(CL_DDK_2600),WINDDK\2600.1106,LFNDirectory,$(IS_WIN_64))
        ifndef VCCL
          # check registry for DDK for Windows XP
          VCCL := $(call VS_REG_FIND_FILE,$(CL_DDK_2600),WINDDK\2600,LFNDirectory,$(IS_WIN_64))
        endif

        ifdef VCCL
          # e.g.: C:/my?ddks/WinDDK/2600.1106
          DDK_AUTO := $(patsubst %/$(CL_DDK_2600),%,$(subst $(space),?,$(VCCL)))
        endif

      endif
    endif
  endif

  ifndef VCCL
    # cross compiler is not supported, may compile only x86 on x86
    ifeq ($(CPU) $(VS_CPU),$(TCPU) $(CPU))

      # search Visual C++ .NET compiler
      VCCL := $(call VS_REG_SEARCH,bin/cl.exe,$(call VCCL_REG_KEYS_VC,7.0))

      ifndef VCCL
        VCCL := $(call VS_REG_SEARCH,Vc7/bin/cl.exe,$(call VCCL_REG_KEYS_VS,7.0))
      endif

      ifndef VCCL
        # look in Program Files
        VCCL := $(call VS_FIND_FILE,Vc7/bin/cl.exe,$(addsuffix Microsoft?Visual?Studio?.NET/,$(PROGRAM_FILES_PLACES)))
      endif

      ifndef VCCL
        # search Visual 6.0 compiler
        VCCL := $(call VS_REG_FIND_FILE,Bin/cl.exe,VisualStudio\6.0\Setup\Microsoft Visual C++,ProductDir,$(IS_WIN_64))

        ifndef VCCL
          VCCL := $(call VS_REG_FIND_FILE,VC98/Bin/cl.exe,VisualStudio\6.0\Setup\Microsoft Visual Studio,ProductDir,$(IS_WIN_64))
        endif

        ifndef VCCL
          # look in Program Files
          VCCL := $(call VS_FIND_FILE,VC98/Bin/cl.exe,$(addsuffix Microsoft?Visual?Studio/,$(PROGRAM_FILES_PLACES)))
        endif
      endif

    endif
  endif

  ifdef SDK_AUTO
    # e.g.: C:/Program?Files/Microsoft?SDKs/Windows/v6.0
    # note: VCCL is defined now
    SDK := $(SDK_AUTO)
    $(warning autoconfigured: SDK=$(SDK))
  endif

  ifdef DDK_AUTO
    # e.g.: C:/my?ddks/WinDDK/6001.18002
    # note: VCCL is defined now
    DDK := $(DDK_AUTO)
    $(warning autoconfigured: DDK=$(DDK))
  endif

  ifdef VCCL
    # C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
    # "C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe"
    VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))
    $(warning autoconfigured: VCCL=$(VCCL))
  endif

endif
endif
endif

ifndef VCCL
ifndef MSVC
ifndef VS
  $(error unable to find C++ compiler for TCPU/CPU=$(TCPU)/$(CPU) on VS_CPU/VS_CPU64=$(VS_CPU)/$(VS_CPU64),\
please specify either VS, MSVC or VCCL, e.g.:$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio 14.0$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio\2017$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio\2017\Community$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\VC98$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual C++ Toolkit 2003$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe$(newline)$(if \
,)VCCL=C:\WINDDK\3790\bin\x86\cl.exe$(newline)$(if \
,)VCCL=C:\WinDDK\7600.16385.1\bin\x86\amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe)
endif
endif
endif

ifndef VCCL
ifndef MSVC
  # define VCCL from $(VS)

  # get Visual Studio folder name, e.g.:
  #  VS=C:/Program?Files/Microsoft?Visual?Studio?14.0
  #  VS_WILD=C:/Program\ Files/Microsoft\ Visual\ Studio\ 14.0/
  VS_WILD := $(subst ?,\ ,$(VS))/

  # try Visual Studio 2017 or later

  # select appropriate compiler for the $(CPU)
  VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

  # e.g. VCCL=C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX64/x86/cl.exe
  VCCL := $(call VS_DEDUCE_VCCL,$(wildcard $(VS_WILD)*/VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED)))

  # if there are multiple Visual Studio editions, select which have the latest compiler,
  #  or may be VS specified with Visual Studio edition type?
  # $1 - C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX64/x86/cl.exe
  VS_DEDUCE_VCCL = $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(VS)/ $(if \
    $1,$1,$(wildcard $(VS_WILD)VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED))))

  ifndef VCCL
    # may be Visual Studio 2005-2015?
    VCCL := $(wildcard $(VS_WILD)VC/bin/$(call VC_TOOL_PREFIX_2005,$(CPU),$(call VS_SELECT_CPU,$(VS)))cl.exe)
  endif

  ifndef VCCL
    # cross-compiler is not supported
    ifeq ($(CPU) $(VS_CPU),$(TCPU) $(CPU))

      # may be Visual Studio 2002-2003?
      VCCL := $(wildcard $(VS_WILD)Vc7/bin/cl.exe)

      ifndef VCCL
        # may be Visual Studio 6.0?
        VCCL := $(wildcard $(VS_WILD)VC98/bin/cl.exe)
      endif

    endif
  endif

  ifndef VCCL
    $(error unable to find C++ compiler for TCPU/CPU=$(TCPU)/$(CPU) on VS_CPU/VS_CPU64=$(VS_CPU)/$(VS_CPU64) with VS=$(call \
  PATH_PRINTABLE,$(VS)), please specify either MSVC or VCCL, e.g.:$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\VC98$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual C++ Toolkit 2003$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe$(newline)$(if \
,)VCCL=C:\WINDDK\3790\bin\x86\cl.exe$(newline)$(if \
,)VCCL=C:\WinDDK\7600.16385.1\bin\x86\amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe)
  endif

  # C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
  # "C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
  VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))
  $(warning autoconfigured: VCCL=$(VCCL))

endif # !MSVC
endif # !VCCL

ifndef VCCL
  # define VCCL from $(MSVC)

  # MSVC path must use forward slashes, there must be no trailing slash, e.g.:
  #  MSVC=C:/Program?Files/Microsoft?Visual?Studio?14.0/VC
  #  MSVC_WILD=C:/Program\ Files/Microsoft\ Visual\ Studio\ 14.0/VC/
  MSVC_WILD := $(subst ?,\ ,$(MSVC))/

  ifneq (,$(filter %/vc/tools/msvc/,$(call tolower,$(dir $(MSVC)))))
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC/Tools/MSVC/14.11.25503

    # select appropriate compiler for the $(CPU)
    VCCL := $(wildcard $(MSVC_WILD)bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe)

  else ifeq (vc,$(call tolower,$(notdir $(MSVC))))
    # MSVC=C:/Program?Files/Microsoft?SDKs/Windows/v6.0/VC
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio?14.0/VC
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC
    MSVC_PARENT := $(patsubst %/,%,$(dir $(MSVC)))

    ifeq (v6.0,$(call tolower,$(notdir $(MSVC_PARENT))))
      # MSVC=C:/Program?Files/Microsoft?SDKs/Windows/v6.0/VC
      ifeq ($(CPU),$(TCPU))
        # select appropriate compiler for the $(CPU)
        VCCL := $(wildcard $(MSVC_WILD)Bin/$(VC_TOOL_PREFIX_SDK6)cl.exe)
      endif

      ifdef VCCL
      ifndef SDK
      ifndef WDK
        # e.g.: C:/Program?Files/Microsoft?SDKs/Windows/v6.0
        SDK_AUTO := $(MSVC_PARENT)
      endif
      endif
      endif

    else
      # MSVC=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC

      # select appropriate compiler for the $(CPU)
      VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

      # find cl.exe and choose the newest one
      VCCL := $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(MSVC)/ $(wildcard \
        $(MSVC_WILD)Tools/MSVC/*/$(VCCL_2017_PREFIXED)))

      ifndef VCCL
        # MSVC=C:/Program?Files/Microsoft?Visual?Studio?14.0/VC

        # select appropriate compiler for the $(CPU)
        VCCL := $(wildcard $(MSVC_WILD)bin/$(call VC_TOOL_PREFIX_2005,$(CPU),$(call VS_SELECT_CPU,$(MSVC)))cl.exe)
      endif
    endif

  else ifeq ($(CPU) $(VS_CPU),$(TCPU) $(CPU))
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio/VC98
    # MSVC=C:/Program?Files/Microsoft?Visual?C++?Toolkit?2003
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio?.NET/Vc7
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio?.NET?2003/Vc7
    VCCL := $(wildcard $(MSVC_WILD)bin/cl.exe)
  endif

  ifndef VCCL
    $(error unable to find C++ compiler for TCPU/CPU=$(TCPU)/$(CPU) on VS_CPU/VS_CPU64=$(VS_CPU)/$(VS_CPU64) with MSVC=$(call \
  PATH_PRINTABLE,$(MSVC)), please specify VCCL, e.g.:$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe$(newline)$(if \
,)VCCL=C:\WINDDK\3790\bin\x86\cl.exe$(newline)$(if \
,)VCCL=C:\WinDDK\7600.16385.1\bin\x86\amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe)
  endif

  ifdef SDK_AUTO
    # e.g.: C:/Program?Files/Microsoft?SDKs/Windows/v6.0
    # note: VCCL is defined now
    SDK := $(SDK_AUTO)
    $(warning autoconfigured: SDK=$(SDK))
  endif

  # C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
  # "C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
  VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))
  $(warning autoconfigured: VCCL=$(VCCL))

endif # define VCCL from $(MSVC)

endif # !VCCL

# ok, VCCL is defined,
# deduce VC_VER, VCLIBPATH and VCINCLUDE values from $(VCCL)

# by default, allow adjusting environment variable PATH so cl.exe may find needed dlls
CL_DO_NOT_ADJUST_PATH:=

ifndef CL_DO_NOT_ADJUST_PATH

  # remember if environment variable PATH was changed
  VCCL_PATH_APPEND:=

  # compilers that need additional paths:
  #  C:\Program Files\Microsoft Visual Studio                                                  VC98\Bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio .NET 2003                                        Vc7\bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\x86_amd64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\x86_ia64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\amd64\cl.exe
  #  C:\Program Files\Microsoft Visual Studio 8                                                VC\bin\ia64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\x86\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\x64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX86\arm\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\x64\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\x86\cl.exe
  #  C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503   bin\HostX64\arm\cl.exe

  # adjust environment variable PATH so cl.exe, lib.exe and link.exe will find their dlls
  VCCL_PARENT1 := $(patsubst %\,%,$(dir $(patsubst "%",%,$(subst $(space),?,$(VCCL)))))
  VCCL_PARENT2 := $(patsubst %\,%,$(dir $(VCCL_PARENT1)))
  VCCL_PARENT3 := $(patsubst %\,%,$(dir $(VCCL_PARENT2)))
  VCCL_ENTRY1l := $(call tolower,$(notdir $(VCCL_PARENT1)))
  VCCL_ENTRY2l := $(call tolower,$(notdir $(VCCL_PARENT2)))
  VCCL_ENTRY3l := $(call tolower,$(notdir $(VCCL_PARENT3)))

  ifneq (,$(filter host%,$(VCCL_ENTRY2l)))
    # Visual Studio 2017 or later:
    #  VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"

    VCCL_HOST := $(patsubst host%,%,$(VCCL_ENTRY2l))

    # if cross-compiling, add path to host dlls
    ifneq ($(VCCL_HOST),$(VCCL_ENTRY1l))
      VCCL_PATH_APPEND := $(VCCL_PARENT2)\$(VCCL_HOST)
    endif

  else ifeq (vc bin,$(VCCL_ENTRY2l) $(VCCL_ENTRY1l))
    # Visual Studio 2005-2015:
    #  VCCL="C:\Program Files\Microsoft Visual Studio 8\VC\bin\cl.exe"
    #  VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\cl.exe"

    #  add path to $(VS)\Common7\IDE if compiling on x86 host
    COMMON7_IDE_PATH := $(VCCL_PARENT3)\Common7\IDE

    # note: Visual Studio 2013 does not contain mspdb120.dll in $(VS)\Common7\IDE directory
    ifneq (,$(wildcard $(subst ?,\ ,$(subst \,/,$(COMMON7_IDE_PATH)))/mspdb*0.dll))
      VCCL_PATH_APPEND := $(COMMON7_IDE_PATH)
    endif

  else ifeq (vc7 bin,$(VCCL_ENTRY2l) $(VCCL_ENTRY1l))
    # for Visual Studio 2002-2003
    VCCL_PATH_APPEND := $(VCCL_PARENT3)\Common7\IDE

  else ifeq (vc98 bin,$(VCCL_ENTRY2l) $(VCCL_ENTRY1l))
    # for Visual Studio 6.0
    VCCL_PATH_APPEND := $(VCCL_PARENT3)\Common\MSDev98\Bin

  else ifeq (vc bin,$(VCCL_ENTRY3l) $(VCCL_ENTRY2l))
    # Visual Studio 2005-2015:
    #  VCCL="C:\Program Files\Microsoft Visual Studio 8\VC\bin\x86_amd64\cl.exe"
    #  VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe"

    # x64       -> VCCL_HOST_PREF=\x64   VC_LIBS_PREF=\x64
    # amd64     -> VCCL_HOST_PREF=\amd64 VC_LIBS_PREF=\amd64
    # amd64_x86 -> VCCL_HOST_PREF=\amd64 VC_LIBS_PREF=
    # x86_amd64 -> VCCL_HOST_PREF=       VC_LIBS_PREF=\amd64
    VCCL_CPU       := $(call VS_SELECT_CPU,$(subst \,/,$(VCCL_PARENT1)))
    VCCL_HOST_PREF := $(addprefix \,$(call VCCL_GET_HOST_2005,$(VCCL_ENTRY1l),$(VCCL_CPU)))
    VC_LIBS_PREF   := $(call VCCL_GET_LIBS_2005,$(VCCL_ENTRY1l),$(VCCL_CPU))

    # if cross-compiling, add path to host dlls
    # note: some dlls are may be in $(VS)\Common7\IDE
    ifneq ($(VCCL_HOST_PREF),$(VC_LIBS_PREF))
      VCCL_PATH_APPEND := $(VCCL_PARENT2)$(VCCL_HOST_PREF)
    endif

    ifndef VCCL_HOST_PREF
      # add path to $(VS)\Common7\IDE if compiling on $(VS_CPU) host
      # note: needed only for Visual Studio 2012 and before

      # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
      COMMON7_IDE_PATH := $(dir $(VCCL_PARENT3))Common7\IDE

      ifneq (,$(wildcard $(subst ?,\ ,$(subst \,/,$(COMMON7_IDE_PATH)))/mspdb*0.dll))
        VCCL_PATH_APPEND := $(COMMON7_IDE_PATH)
      endif
    endif

  endif

  ifdef VCCL_PATH_APPEND
    override PATH := $(PATH);$(subst ?, ,$(VCCL_PATH_APPEND))
  endif

  # PATH was adjusted, do not adjust it if read PATH variable from generated project configuration makefile
  CL_DO_NOT_ADJUST_PATH := 1

endif # !CL_DO_NOT_ADJUST_PATH

ifndef VC_VER
  # Оптимизирующий 32-разрядный компилятор Microsoft (R) C/C++ версии 15.00.30729.01 для 80x86   ->  15 00
  CL_VER := $(wordlist 1,2,$(subst ., ,$(lastword $(foreach v,$(filter \
    0% 1% 2% 3% 4% 5% 6% 7% 8% 9%,$(shell $(subst \,/,$(VCCL)) 2>&1)),$(if $(word 3,$(subst ., ,$v)),$v)))))

  ifndef CL_VER
    $(error unable to determine version of VCCL=$(VCCL))
  endif

  # map 12 00 -> 6.00
  VC_VER := $(foreach m,$(firstword $(CL_VER)),$(if $(filter undefined environment,$(origin MSC_VER_$m)),$(error \
    unknown VCCL=$(VCCL) compiler major version number: $m),$(MSC_VER_$m).$(lastword $(CL_VER))))

  $(warning autoconfigured: VC_VER=$(VC_VER))
endif

# define VCLIBPATH_AUTO and VCINCLUDE_AUTO
ifneq (,$(filter undefined environment,$(origin VCLIBPATH) $(origin VCINCLUDE)))

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

      ifneq (,$(filter undefined environment,$(origin VCLIBPATH)))
        # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\msvcrt.lib
        # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\store\msvcrt.lib
        # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x64\msvcrt.lib
        MSVCRTLIB_PATH := $(VCCL_PARENT4)/lib$(VC_LIB_TYPE_ONECORE:%=/%)/$(VCCL_ENTRY1l)$(VC_LIB_TYPE_STORE:%=/%)/msvcrt.lib
        VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH))

        ifndef VCLIBPATH_AUTO
          $(error unable to autoconfigure VCLIBPATH for VCCL=$(VCCL): file does not exist:$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH))$(if \
            ,)$(newline)please specify VCLIBPATH explicitly, e.g.:$(if \
            ,)$(newline)VCLIBPATH=$(subst /,\,$(VCCL_PARENT4))\lib\$(CPU:x86_64=x64))
        endif
      endif

      ifneq (,$(filter undefined environment,$(origin VCINCLUDE)))
        # C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\include\varargs.h
        VARARGS_H_PATH := $(VCCL_PARENT4)/include/varargs.h
        VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH))

        ifndef VCINCLUDE_AUTO
          $(error unable to autoconfigure VCINCLUDE for VCCL=$(VCCL): file does not exist:$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH))$(if \
            ,)$(newline)please specify VCINCLUDE explicitly, e.g.:$(if \
            ,)$(newline)VCINCLUDE=$(subst /,\,$(VCCL_PARENT4))\include)
        endif
      endif

    endif
  endif

  ifeq (bin,$(VCCL_ENTRY1l))
    # VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio .NET\Vc7\bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"

    ifneq (,$(filter undefined environment,$(origin VCLIBPATH)))
      MSVCRTLIB_PATH := $(VCCL_PARENT2)/lib/msvcrt.lib
      VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH))

      ifndef VCLIBPATH_AUTO
        $(error unable to autoconfigure VCLIBPATH for VCCL=$(VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH))$(if \
          ,)$(newline)please specify VCLIBPATH explicitly, e.g.:$(if \
          ,)$(newline)VCLIBPATH=$(subst /,\,$(VCCL_PARENT2))\lib)
      endif
    endif

    ifneq (,$(filter undefined environment,$(origin VCINCLUDE)))
      VARARGS_H_PATH := $(VCCL_PARENT2)/include/varargs.h
      VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH))

      ifndef VCINCLUDE_AUTO
        $(error unable to autoconfigure VCINCLUDE for VCCL=$(VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH))$(if \
          ,)$(newline)please specify VCINCLUDE explicitly, e.g.:$(if \
          ,)$(newline)VCINCLUDE=$(subst /,\,$(VCCL_PARENT2))\include)
      endif
    endif

  endif

  ifeq (vc bin,$(VCCL_ENTRY3l) $(VCCL_ENTRY2l))
    # VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"

    ifneq (,$(filter undefined environment,$(origin VCLIBPATH)))
      # C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\LIB\x64\msvcrt.lib
      # C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\arm\msvcrt.lib
      # C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\msvcrt.lib
      # C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\amd64\msvcrt.lib
      MSVCRTLIB_PATH := $(VCCL_PARENT3)/lib$(VC_LIB_TYPE_ONECORE:%=/%)$(VC_LIB_TYPE_STORE:%=/%)$(call \
        VCCL_GET_LIBS_2005,$(VCCL_ENTRY1l),$(call VS_SELECT_CPU,$(VCCL_PARENT3)))/msvcrt.lib
      VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH))

      ifndef VCLIBPATH_AUTO
        $(error unable to autoconfigure VCLIBPATH for VCCL=$(VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH))$(if \
          ,)$(newline)please specify VCLIBPATH explicitly, e.g.:$(if \
          ,)$(newline)VCLIBPATH=$(subst /,\,$(VCCL_PARENT3))\lib\$(CPU:x86_64=amd64))
      endif
    endif

    ifneq (,$(filter undefined environment,$(origin VCINCLUDE)))
      # C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\INCLUDE\varargs.h
      # C:\Program Files\Microsoft Visual Studio 14.0\VC\include\varargs.h
      VARARGS_H_PATH := $(VCCL_PARENT3)/include/varargs.h
      VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH))

      ifndef VCINCLUDE_AUTO
        $(error unable to autoconfigure VCINCLUDE for VCCL=$(VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH))$(if \
          ,)$(newline)please specify VCINCLUDE explicitly, e.g.:$(if \
          ,)$(newline)VCINCLUDE=$(subst /,\,$(VCCL_PARENT3))\include)
      endif
    endif

  endif

  ifeq (bin,$(VCCL_ENTRY3l)
    ifeq (,$(filter win64 host%,$(VCCL_ENTRY2l)))
      # VCCL="C:\WinDDK\6001.18002\bin\x86\x86\cl.exe"
      # VCCL="C:\WinDDK\6001.18002\bin\x86\amd64\cl.exe"
      # VCCL="C:\WinDDK\6001.18002\bin\x86\ia64\cl.exe"
      # VCCL="C:\WinDDK\6001.18002\bin\ia64\ia64\cl.exe"

      ifneq (,$(filter undefined environment,$(origin VCLIBPATH)))
        # C:\WinDDK\6001.18001\lib\crt\{i386,amd64,ia64}\msvcrt.lib
        MSVCRTLIB_PATH := $(VCCL_PARENT4)/lib/crt/$(patsubst x86,i386,$(CPU:x86_64=amd64))/msvcrt.lib
        VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH))

        ifndef VCLIBPATH_AUTO
          $(error unable to autoconfigure VCLIBPATH for VCCL=$(VCCL): file does not exist:$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH))$(if \
            ,)$(newline)please specify VCLIBPATH explicitly, e.g.:$(if \
            ,)$(newline)VCLIBPATH=$(subst /,\,$(VCCL_PARENT4))\lib\crt\$(patsubst x86,i386,$(CPU:x86_64=amd64)))
        endif
      endif

    ifneq (,$(filter undefined environment,$(origin VCINCLUDE)))
      # C:\WinDDK\6001.18001\inc\crt\varargs.h
      VARARGS_H_PATH := $(VCCL_PARENT4)/inc/crt/varargs.h
      VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH))

      ifndef VCINCLUDE_AUTO
        $(error unable to autoconfigure VCINCLUDE for VCCL=$(VCCL): file does not exist:$(if \
          ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH))$(if \
          ,)$(newline)please specify VCINCLUDE explicitly, e.g.:$(if \
          ,)$(newline)VCINCLUDE=$(subst /,\,$(VCCL_PARENT4))\inc\crt)
      endif
    endif

  endif

  ifndef VCLIBPATH_AUTO
  ifndef VCINCLUDE_AUTO
    # VCCL="C:\WINDDK\3790.1830\bin\x86\cl.exe"
    # VCCL="C:\WINDDK\3790.1830\bin\ia64\cl.exe"
    # VCCL="C:\WINDDK\3790.1830\bin\win64\x86\cl.exe"
    # VCCL="C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Bin\win64\x86\AMD64\cl.exe"
    # VCCL="C:\WINDDK\3790.1830\bin\win64\x86\amd64\cl.exe"

    ifeq (bin,$(VCCL_ENTRY2l))
      VCCL_PARENTx := $(VCCL_PARENT3)
    else ifeq (bin,$(VCCL_ENTRY3l))
      VCCL_PARENTx := $(VCCL_PARENT4)
    else
      VCCL_PARENTx := $(patsubst %/,%,$(dir $(VCCL_PARENT4)))
    endif

    ifneq (,$(filter undefined environment,$(origin VCLIBPATH)))
      # C:\WINDDK\3790.1830\lib\crt\{i386,amd64,ia64}\msvcrt.lib
      MSVCRTLIB_PATH1 := $(VCCL_PARENTx)/lib/crt/$(patsubst x86,i386,$(CPU:x86_64=amd64))/msvcrt.lib
      VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH1))

      ifndef VCLIBPATH_AUTO
        # C:\WINDDK\2600\lib\wxp\{i386,ia64}\msvcrt.lib
        # C:\WINDDK\2600.1106\lib\wxp\{i386,ia64}\msvcrt.lib
        # C:\WINDDK\3790\lib\wxp\{i386,ia64}\msvcrt.lib
        # C:\WINDDK\3790\lib\wnet\{i386,amd64,ia64}\msvcrt.lib
        MSVCRTLIB_PATH2 := $(VCCL_PARENTx)/lib/$(call \
          WIN_NAME_FROM_WINVARIANT,$(WINVARIANT))/$(patsubst x86,i386,$(CPU:x86_64=amd64))/msvcrt.lib
        VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH2))

        ifndef VCLIBPATH_AUTO
          # C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Lib\{AMD64,IA64}\msvcrt.Lib
          MSVCRTLIB_PATH3 := $(VCCL_PARENTx)/lib/$(CPU:x86_64=amd64)/msvcrt.lib
          VCLIBPATH_AUTO := $(call CHECK_FILE_PATH,$(MSVCRTLIB_PATH3))

          ifndef VCLIBPATH_AUTO
            $(error unable to autoconfigure VCLIBPATH for VCCL=$(VCCL): files do not exist:$(if \
              ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH1))$(if \
              ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH2))$(if \
              ,)$(newline)$(call PATH_PRINTABLE,$(MSVCRTLIB_PATH3))$(if \
              ,)$(newline)please specify VCLIBPATH explicitly, e.g.:$(if \
              ,)$(newline)VCLIBPATH=$(subst /,\,$(VCCL_PARENTx))\lib\crt\$(patsubst x86,i386,$(CPU:x86_64=amd64)))
          endif
        endif
      endif
    endif

    ifneq (,$(filter undefined environment,$(origin VCINCLUDE)))
      # C:\WINDDK\3790.1830\inc\crt\varargs.h
      VARARGS_H_PATH1 := $(VCCL_PARENTx)/inc/crt/varargs.h
      VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH1))

      ifndef VCINCLUDE_AUTO
        # C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\Include\crt\varargs.h
        VARARGS_H_PATH2 := $(VCCL_PARENTx)/Include/crt/varargs.h
        VCINCLUDE_AUTO := $(call CHECK_FILE_PATH,$(VARARGS_H_PATH2))

        ifndef VCINCLUDE_AUTO
          $(error unable to autoconfigure VCINCLUDE for VCCL=$(VCCL): files do not exist:$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH1))$(if \
            ,)$(newline)$(call PATH_PRINTABLE,$(VARARGS_H_PATH2))$(if \
            ,)$(newline)please specify VCINCLUDE explicitly, e.g.:$(if \
            ,)$(newline)VCINCLUDE=$(subst /,\,$(VCCL_PARENTx))\inc\crt)
        endif
      endif
    endif

  endif
  endif

endif # define VCLIBPATH_AUTO and VCINCLUDE_AUTO

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

# reset TVCCL, if it's not defined in project configuration makefile or in command line
TVCCL:=

# if TVCCL is defined in project configuration makefile or in command line, check its value
ifdef TVCCL
  # TVCCL path must use forward slashes
  override TVCCL := $(subst /,\,$(TVCCL))
  ifneq (,$(findstring $(space),$(TVCCL)))
    # if $(TVCCL) contains a space, it must be in double quotes
    ifeq ($(subst $(space),?,$(TVCCL)),$(patsubst "%",%,$(subst $(space),?,$(TVCCL))))
      override TVCCL := "$(TVCCL)"
    endif
  endif
else ifdef TVC_VER
  $(error TVC_VER=$(TVC_VER) is defined, but TVCCL does not)
endif

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
$(call SET_GLOBAL,NORMALIZE_PATH GET_PROGRAM_FILES_DIRS VS_CPU VS_CPU64 IS_WIN_64 VS_FIND_FILE_WHERE VS_FIND_FILE VS_FIND_FILE_P \
  VS_REG_QUERY VS_REG_FIND_FILE_WHERE VS_REG_FIND_FILE VS_REG_FIND_FILE_P \
  VS_REG_SEARCH_X VS_REG_SEARCH_WHERE VS_REG_SEARCH VS_REG_SEARCH_P \
  VS_SELECT_LATEST1 VS_SELECT_LATEST VC_TOOL_PREFIX_SDK6 VCCL_2005_PATTERN_GEN_VC VCCL_2005_PATTERN_GEN_VS \
  VC_TOOL_PREFIX_2005 VCCL_GET_LIBS_2005 VCCL_GET_HOST_2005 VC_TOOL_PREFIX_2017 \
  VC_LIB_TYPE_ONECORE VC_LIB_TYPE_STORE VS_2017_SELECT_LATEST_ENTRY \
  VC_VER VCCL VCLIB VCLINK VCLIBPATH VCINCLUDE \
  TVC_VER TVCCL TVCLIB TVCLINK TVCLIBPATH TVCINCLUDE \
  VCCL_PATH_APPEND)
