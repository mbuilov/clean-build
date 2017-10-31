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
#   Note: if pre-Visual Studio 2017 installation folder has non-default name, it is not possible to
#     deduce Visual C++ version automatically - VC_VER must be specified explicitly, e.g.:
#     VC_VER=14.0 or VC_VER=vs2015
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
# 3) VCCL - path to Visual C++ compiler cl.exe (may be in double-quotes, if contains spaces - double-quoted automatically)
#   may be specified instead of VS or MSVC variables (they are ignored then), e.g.:
#     VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\cl.exe
#     VCCL=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe
#
# 4) VC_VER - Visual C++ version, e.g. one of: 6.0 7.0 7.1 8.0 9.0 10.0 11.0 12.0 14.0 14.10 14.11
#   or by Visual Studio version, one of: vs2002 vs2003 vs2005 vs2008 vs2010 vs2012 vs2013 vs2015
#   may be specified explicitly if it's not possible to deduce VC_VER automatically or to override automatically deduced value
#
# 5) SDK - path to Windows Software Development Kit,
#   may be specified explicitly if failed to determine it automatically or to override automatically defined value, e.g.:
#     SDK=C:\Program Files\Microsoft SDKs\Windows\v6.0
#
# 6) DDK - path to Windows Driver Development Kit,
#   may be specified instead of SDK, because DDK contains SDK headers and libraries necessary for building simple console
#   applications, also DDK may include C++ compilers, e.g.:
#     DDK=C:\WinDDK\7600.16385.1
#
# 7) WDK - path to Windows Development Kit,
#   may be specified instead of SDK and DDK - newer versions of SDK and DDK (8.0 and later) are combined under the same WDK path, e.g.:
#     WDK=C:\Program Files (x86)\Windows Kits\8.0
#
# 8) SDK_VER/DDK_VER/WDK_VER - SDK/DDK/WDK versions,
#   may be specified explicitly if failed to determine them automatically or to override automatically defined values, e.g. one of:
#     SDK_VER=7.1 10.0.10240.0
#     DDK_VER=2600 2600.1106 3790 3790.1830 6000 6001.18000 6001.18001 6001.18002 7600.16385.0 7600.16385.1 7.0.0 7.1.0 8.0 8.1 10.0.10240.0
#     WDK_VER=10.0.16299.0
#
#################################################################################################################

# try to autoconfigure:
#  Visual C++ version, paths to compiler, linker and C/C++ libraries and headers
#  - only if they are not defined in project configuration makefile or in command line
#  (variables prefixed with T - are for the tool mode)
#
# {,T}VC_VER    - MSVC++ version, known values see in $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk (or below)
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

# normalize path: replace spaces with ?, remove double-quotes, make all slashes backward, add trailing back-slash, e.g.:
#  "a\b\c d\e" -> a/b/c?d/e/
NOMALIZE_PATH = $(patsubst %//,%/,$(addsuffix /,$(subst \,/,$(patsubst "%",%,$(subst $(space),?,$1)))))

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

# query path value in the registry
# $1 - registry key sub path, e.g.: VisualStudio\SxS\VC7 or VisualStudio\SxS\VS7 or VisualStudio\6.0\Setup\Microsoft Visual C++
# $2 - registry key name, e.g.: 14.0 or ProductDir
# $3 - empty or \Wow6432Node
# result: for VC7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/VC/
# result: for VS7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/
# note: result will be with trailing backslash
# note: value of "VisualStudio\6.0\Setup\Microsoft Visual C++\ProductDir" key does not with slash, e.g:
#  "C:\Program Files (x86)\Microsoft Visual Studio\VC98"
VS_REG_QUERY = $(patsubst %//,%/,$(addsuffix /,$(subst \,/,$(subst ?$2?REG_SZ?,,$(lastword \
  $(subst HKEY_LOCAL_MACHINE\SOFTWARE$3\Microsoft\$1, ,$(subst $(space),?,$(strip $(shell \
  reg query "HKLM\SOFTWARE$3\Microsoft\$1" /v "$2" 2>NUL)))))))))

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

# for Visual C++ compiler from WDK 6-7 (Visual C++ 8.0-9.0 of Visual Studio 2005-2008)
# determine MSVC++ tools prefix for given TCPU/CPU combination, e.g.:
#  C:\WinDDK\6001.18001\bin\x86\x86\cl.exe   - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 14.00.50727.278 for 80x86
#  C:\WinDDK\6001.18001\bin\x86\amd64\cl.exe - Microsoft (R) C/C++ Optimizing Compiler Version 14.00.50727.278 for x64
#  C:\WinDDK\6001.18001\bin\x86\ia64\cl.exe  - Microsoft (R) C/C++ Optimizing Compiler Version 14.00.50727.283 for Itanium
#  C:\WinDDK\6001.18001\bin\ia64\ia64\cl.exe - ????
# $1 - $(CPU)
CL_TOOL_PREFIX_WDK6 = $(TCPU:x86_64=amd64)/$(1:x86_64=amd64)/

# path prefix of msvcrt.lib
#  C:\WinDDK\6001.18001\lib\crt\{i386,amd64,ia64}\msvcrt.lib
# $1 - $(CPU)
#  x86    -> /crt/i386
#  x86_64 -> /crt/amd64
#  ia64   -> /crt/ia64
VC_LIB_PREFIX_WDK6 = crt/$(patsubst x86,i386,$(1:x86_64=amd64))/

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
#  x86_amd64 -> \amd64
#  x86_arm   -> \arm
#  amd64_x86 -> <none>
#  amd64     -> \amd64
#  amd64_arm -> \arm
#  x64       -> \x64
# $1 - cl.exe prefix
# $2 - $(VS_CPU)
VCCL_GET_LIBS_2005 = $(addprefix \,$(filter-out $2,$(lastword $(subst _, ,$1))))

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

# reset VCCL, if it's not defined in project configuration makefile or in command line
ifneq (,$(filter undefined environment,$(origin VCCL)))
VCCL:=
else
  # VCCL path must use forward slashes
  override VCCL := $(subst /,\,$(VCCL))
  ifneq (,$(findstring $(space),$(VCCL)))
    # if $(VCCL) contains a space, it must be in double quotes
    ifeq ($(subst $(space),?,$(VCCL)),$(patsubst "%",%,$(subst $(space),?,$(VCCL))))
    override VCCL := "$(VCCL)"
    endif
  endif
endif

# reset VC_VER, if it's not defined in project configuration makefile or in command line
ifneq (,$(filter undefined environment,$(origin VC_VER)))
VC_VER:=
else ifneq (,$(findstring vs,$(VC_VER)))
  # map vs2015 -> 14, according VS... values defined in $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk
  override VC_VER := $(foreach v,$(subst vs,VS,$(VC_VER)),$(if $(filter undefined environment,$(origin $v)),$(error \
    unknown VC_VER=$(VC_VER), please use one of: vs2002 vs2003 vs2005 vs2008 vs2010 vs2012 vs2013 vs2015),$($v)))
endif

# subdirectory of MSVC++ libraries: <empty> or onecore
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_ONECORE:=

# subdirectory of MSVC++ libraries: <empty> or store
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_STORE:=

# we need next MSVC++ variables to be defined: VC_VER, VCCL, VCLIBPATH and VCINCLUDE
# (they are may be defined either in project configuration makefile or in command line)
# note: VCLIBPATH or VCINCLUDE may be defined as <empty>, so do not reset them
ifneq (,$(filter undefined environment,$(foreach v,VCLIBPATH VCINCLUDE,$(origin $v)))$(if $(VCCL),,1)$(if $(VC_VER),,2))

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
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\arm\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x64\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\arm\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x64\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe

# CPU-specific paths to libraries
# ---------------------------------------------------------------------
# C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\LIB\msvcrt.lib
# C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\LIB\x64\msvcrt.lib
#
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\amd64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\amd64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\amd64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\arm\msvcrt.lib
#
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x86\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x86\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x86\store\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\store\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\arm\store\msvcrt.lib

# there may be more than one file found - take the newer one, e.g.
#  $1=bin/HostX86/x64/cl.exe
#  $2=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
# result: C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
VS_2017_SELECT_LATEST1 = $(patsubst %,$2%$1,$(lastword $(sort $(subst $1?$2, ,$(patsubst %,$1?%?$2,$(subst $(space),?,$3))))))
VS_2017_SELECT_LATEST  = $(call VS_2017_SELECT_LATEST1,$1,$(firstword $2),$(wordlist 2,999999,$2))

# take the newer one found cl.exe, e.g.:
#  $1=bin/HostX86/x64/cl.exe
#  $2=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
# result: C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
VS_2017_SELECT_LATEST_ENTRY = $(subst ?, ,$(VS_2017_SELECT_LATEST))

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

ifndef VCCL
ifndef MSVC
ifndef VS

  # define VCCL and, optionally, VC_VER from values of VS*COMNTOOLS environment variables (may be set by the vcvars32.bat)

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
        VS_FIND_FILE_WHERE,VC/Tools/MSVC/$(VC_VER)*/$(VCCL_2017_PREFIXED),$(VS_COMNS_2017)))

      ifndef VCCL
        # filter-out Visual Studio 2017 or later
        VS_COMN_VERS := $(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,150),$v))
      endif

      # if VCCL is defined, extract VC_VER from it below
    endif
  endif

  ifndef VCCL
    ifdef VS_COMN_VERS
      # define VC_VER at end of this section

      ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),80))
        # Visual Studio 2005 or later

        # search cl.exe in the paths of VS*COMNTOOLS
        # $1 - MSVC versions, e.g. 140,120,110,100,90,80
        # result: 140 C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
        VS_COMN_FIND_CL_2005 = $(if $1,$(call VS_COMN_FIND_CL_20051,$1,$(call \
          VS_STRIP_COMN,$(subst $(space),?,$(VS$(firstword $1)COMNTOOLS)))))

        # $1 - MSVC versions, e.g. 140,120,110,100,90,80
        # $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/
        VS_COMN_FIND_CL_20051 = $(call VS_COMN_FIND_CL_20052,$1,$(wildcard $(subst ?,\ ,$2)VC/bin/$(call \
          VC_TOOL_PREFIX_2005,$(CPU),$(call VS_SELECT_CPU,$2))cl.exe))

        # $1 - MSVC versions, e.g. 140,120,110,100,90,80
        # $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/VC/bin/x86_arm/cl.exe
        VS_COMN_FIND_CL_20052 = $(if $2,$(firstword $1) $2,$(call VS_COMN_FIND_CL_2005,$(wordlist 2,999999,$1)))

        # select appropriate compiler for the $(CPU), e.g.:
        #  VC/bin/x86_arm/cl.exe
        VCCL := $(call VS_COMN_FIND_CL_2005,$(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,80),,$v)))

        ifndef VCCL
          # filter-out Visual Studio 2005 or later
          VS_COMN_VERS := $(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,80),$v))
        endif
      endif

      ifndef VCCL
        ifdef VS_COMN_VERS

          # search cl.exe in the paths of VS*COMNTOOLS
          # $1 - MSVC versions, e.g. 71,70,60
          # $2 - Vc7/bin/cl.exe or VC98/Bin/cl.exe
          # result: 140 C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
          VS_COMN_FIND_CL = $(if $1,$(call VS_COMN_FIND_CL1,$1,$2,$(wildcard \
            $(subst ?,\ ,$(call VS_STRIP_COMN,$(subst $(space),?,$(VS$(firstword $1)COMNTOOLS))))$2)))

          # $1 - MSVC versions, e.g. 71,70,60
          # $2 - Vc7/bin/cl.exe or VC98/Bin/cl.exe
          # $3 - C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
          VS_COMN_FIND_CL1 = $(if $3,$(firstword $1) $3,$(call VS_COMN_FIND_CL,$(wordlist 2,999999,$1),$2))

          ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),70))
            # Visual Studio .NET or later

            ifeq ($(VS_CPU)_$(VS_CPU),$(TCPU)_$(CPU))
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

            ifeq ($(VS_CPU)_$(VS_CPU),$(TCPU)_$(CPU))
              VCCL := $(call VS_COMN_FIND_CL,$(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,60),,$v)),VC98/Bin/cl.exe)
            endif

            ifndef VCCL
              # filter-out Visual Studio 6.0 or later
              VS_COMN_VERS := $(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,60),$v))
            endif
          endif
        endif
      endif

      # define VC_VER at end of this section
      ifdef VCCL
        ifndef VC_VER
          VC_VER := $(firstword $(VCCL))
          $(warning autoconfigured: VC_VER=$(VC_VER))
        endif
        VCCL := $(wordlist 2,999999,$(VCCL))
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

  # check registry and standard places in Program Files - to define VCCL and, optionally, VC_VER

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
    VS_REG_SEARCH_WHERE,Tools/MSVC/$(VC_VER)*/$(VCCL_2017_PREFIXED),$(call VCCL_REG_KEYS_VC,15.0)))

  ifndef VCCL
    # look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
    VCCL := $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(call \
      VS_REG_SEARCH_WHERE,VC/Tools/MSVC/$(VC_VER)*/$(VCCL_2017_PREFIXED),$(call VCCL_REG_KEYS_VS,15.0)))
  endif

  ifndef VCCL
    # check standard places
    # e.g.: C:/Program?Files/ C:/Program?Files?(x86)/
    PROGRAM_FILES_PLACES := $(addsuffix /,$(GET_PROGRAM_FILES_DIRS))

    # look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
    VCCL := $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(call \
      VS_FIND_FILE_WHERE,Microsoft Visual Studio/*/*/VC/Tools/MSVC/$(VC_VER)*/$(VCCL_2017_PREFIXED),$(PROGRAM_FILES_PLACES)))
  endif

  # if VCCL is defined, deduce VC_VER from it below

  ifndef VCCL
    # define VC_VER at end of this section

    # versions of Visual C++ starting with Visual Studio 2005
    VCCL_2005_VERSIONS := 14.0 12.0 11.0 10.0 9.0 8.0

    # $1 - 14.0 12.0 11.0 10.0 9.0 8.0
    # result: 14.0 C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
    VS_SEARCH_2005  = $(if $1,$(call VS_SEARCH_20051,$1,$(call \
      VS_REG_SEARCH_P,VCCL_2005_PATTERN_GEN_VC,$(call VCCL_REG_KEYS_VC,$(firstword $1)))))

    # look in Visual Studio installation paths
    VS_SEARCH_20051 = $(if $2,$(firstword $1) $2,$(call VS_SEARCH_20052,$1,$(call \
      VS_REG_SEARCH_P,VCCL_2005_PATTERN_GEN_VS,$(call VCCL_REG_KEYS_VS,$(firstword $1)))))

    # check standard places
    VS_SEARCH_20052 = $(if $2,$(firstword $1) $2,$(call VS_SEARCH_20053,$1,$(call \
      VS_FIND_FILE_P,VCCL_2005_PATTERN_GEN_VS,$(addsuffix \
      Microsoft?Visual?Studio?$(subst 8.0,8,$(firstword $1))/,$(PROGRAM_FILES_PLACES)))))

    # recursion
    VS_SEARCH_20053 = $(if $2,$(firstword $1) $2,$(call VS_SEARCH_2005,$(wordlist 2,999999,$1)))

    # result: 14.0 C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
    VCCL := $(call VS_SEARCH_2005,$(VCCL_2005_VERSIONS))

    ifndef VCCL
      # check for C++ compiler bundled in WDK7.1
      WDK_71_REG_PATH := KitSetup\configured-kits\{B4285279-1846-49B4-B8FD-B9EAF0FF17DA}\{68656B6B-555E-5459-5E5D-6363635E5F61}

      # look for:
      #  C:\WinDDK\7600.16385.1\bin\x86\x86\cl.exe   - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 15.00.30729.207 for 80x86
      #  C:\WinDDK\7600.16385.1\bin\x86\amd64\cl.exe - Microsoft (R) C/C++ Optimizing Compiler Version 15.00.30729.207 for x64
      #  C:\WinDDK\7600.16385.1\bin\x86\ia64\cl.exe  - Microsoft (R) C/C++ Optimizing Compiler Version 15.00.30729.207 for Itanium
      VCCL := $(call VS_REG_FIND_FILE,bin/$(call CL_TOOL_PREFIX_WDK6,$(CPU))cl.exe,$(WDK_71_REG_PATH),setup-install-location,$(IS_WIN_64))

      ifndef VCCL
        ifdef WDK
          ifeq (7.1,$(WDK_VER))
# find file in the paths by pattern
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe, may be with spaces)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe


VS_FIND_FILE  = $(if $2,$(call VS_FIND_FILE1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$1)))

            VCCL := $(call VS_FIND_FILE,Microsoft Visual Studio/*/*/VC/Tools/MSVC/$(VC_VER)*/$(VCCL_2017_PREFIXED),$(subst \,/,$(subst $(space),?,$(WDK))))
          endif
        endif
      endif

      ifdef VCCL
        # compiler from WDK7.1 has the version 15.00.30729.207 (corresponds to Visual Studio 2008)
        VCCL := 9.0 $(VCCL)
      endif
    endif

    ifndef VCCL
      # cross compiler is not supported, but may compile x86_64 on x86_64 or x86 on x86
      ifeq ($(CPU),$(TCPU))

        # check for Visual C++ compiler bundled in SDK6.0

        # look for C:/Program Files/Microsoft SDKs/Windows/v6.0/VC/Bin/x64/cl.exe
        VCCL := $(call VS_REG_FIND_FILE,VC/Bin/$(VC_TOOL_PREFIX_SDK6)cl.exe,Microsoft SDKs\Windows\v6.0,InstallationFolder)

        ifndef VCCL
          # look in Program Files
          VCCL := $(call VS_FIND_FILE,VC/Bin/$(VC_TOOL_PREFIX_SDK6)cl.exe,$(addsuffix \
            Microsoft?SDKs/Windows/v6.0/,$(PROGRAM_FILES_PLACES)))
        endif

        ifdef VCCL
          # compiler from SDK6.0 is the same as in Visual Studio 2005
          VCCL := 8.0 $(VCCL)
        endif

        ifndef VCCL
          # cross compiler is not supported, may compile only x86 on x86
          ifeq ($(VS_CPU),$(CPU))

            # search Visual C++ .NET 2003 compiler
            VCCL := $(call VS_REG_SEARCH,bin/cl.exe,$(call VCCL_REG_KEYS_VC,7.1))

            ifndef VCCL
              VCCL := $(call VS_REG_SEARCH,Vc7/bin/cl.exe,$(call VCCL_REG_KEYS_VS,7.1))
            endif

            ifndef VCCL
              # look in Program Files
              VCCL := $(call VS_FIND_FILE,Vc7/bin/cl.exe,$(addsuffix \
                Microsoft?Visual?Studio?.NET?2003/,$(PROGRAM_FILES_PLACES)))
            endif

            ifdef VCCL
              VCCL := 7.1 $(VCCL)
            endif

            ifndef VCCL
              # look in Program Files for Visual C++ compiler of Microsoft Visual C++ Toolkit 2003
              VCCL := $(call VS_FIND_FILE,bin/cl.exe,$(addsuffix \
                Microsoft?Visual?C++?Toolkit?2003/,$(PROGRAM_FILES_PLACES)))

              ifdef VCCL
                VCCL := 7.1 $(VCCL)
              endif
            endif

            ifndef VCCL
              # search Visual C++ .NET compiler
              VCCL := $(call VS_REG_SEARCH,bin/cl.exe,$(call VCCL_REG_KEYS_VC,7.0))

              ifndef VCCL
                VCCL := $(call VS_REG_SEARCH,Vc7/bin/cl.exe,$(call VCCL_REG_KEYS_VS,7.0))
              endif

              ifndef VCCL
                # look in Program Files
                VCCL := $(call VS_FIND_FILE,Vc7/bin/cl.exe,$(addsuffix \
                  Microsoft?Visual?Studio?.NET/,$(PROGRAM_FILES_PLACES)))
              endif

              ifdef VCCL
                VCCL := 7.0 $(VCCL)
              endif
            endif

            ifndef VCCL
              # search Visual 6.0 compiler
              VCCL := $(call VS_REG_FIND_FILE,Bin/cl.exe,VisualStudio\6.0\Setup\Microsoft Visual C++,ProductDir,$(IS_WIN_64))

              ifndef VCCL
                VCCL := $(call VS_REG_FIND_FILE,VC98/Bin/cl.exe,VisualStudio\6.0\Setup\Microsoft Visual Studio,ProductDir,$(IS_WIN_64))
              endif

              ifndef VCCL
                # look in Program Files
                VCCL := $(call VS_FIND_FILE,VC98/Bin/cl.exe,$(addsuffix \
                  Microsoft?Visual?Studio/,$(PROGRAM_FILES_PLACES)))
              endif

              ifdef VCCL
                VCCL := 6.0 $(VCCL)
              endif
            endif

          endif # ifeq ($(VS_CPU),$(CPU))
        endif

      endif # ifeq ($(CPU),$(TCPU))
    endif

    # define VC_VER at end of this section
    ifdef VCCL
      ifndef VC_VER
        VC_VER := $(firstword $(VCCL))
        $(warning autoconfigured: VC_VER=$(VC_VER))
      endif
      VCCL := $(wordlist 2,999999,$(VCCL))
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
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe)
endif
endif
endif

ifndef VCCL
ifndef MSVC

  # define VCCL and, optionally, VC_VER from $(VS)

  # get Visual Studio folder name, e.g.:
  #  VS_PATH=C:/Program?Files/Microsoft?Visual?Studio?14.0
  #  VS_NAME=microsoft?visual?studio?14.0
  #  VS_WILD=C:/Program\ Files/Microsoft\ Visual\ Studio\ 14.0/
  # note: $(VS) could be without trailing slash
  VS_PATH := $(patsubst %/,%,$(subst \,/,$(subst $(space),?,$(VS))))
  VS_NAME := $(call tolower,$(notdir $(VS_PATH)))
  VS_WILD := $(subst ?,\ ,$(VS_PATH))/

  ifeq (microsoft?visual?studio?.net,$(VS_NAME))
    VC_VER_AUTO := 7.0
    ifeq ($(VS_CPU)_$(VS_CPU),$(TCPU)_$(CPU))
      VCCL := $(wildcard $(VS_WILD)Vc7/bin/cl.exe)
    endif

  else ifeq (microsoft?visual?studio?.net?2003,$(VS_NAME))
    VC_VER_AUTO := 7.1
    ifeq ($(VS_CPU)_$(VS_CPU),$(TCPU)_$(CPU))
      VCCL := $(wildcard $(VS_WILD)Vc7/bin/cl.exe)
    endif

  else ifneq (,$(filter microsoft?visual?studio?%,$(VS_NAME)))
    VC_VER_AUTO := $(lastword $(subst ?, ,$(VS_NAME)))
    VCCL := $(wildcard $(VS_WILD)VC/bin/$(call VC_TOOL_PREFIX_2005,$(CPU),$(call VS_SELECT_CPU,$(VS_PATH)))cl.exe)

  else ifneq (,$(wildcard $(VS_WILD)VC98/.)
    VC_VER_AUTO := 6.0
    ifeq ($(VS_CPU)_$(VS_CPU),$(TCPU)_$(CPU))
      VCCL := $(wildcard $(VS_WILD)VC98/bin/cl.exe)
    endif

  else
    # assume Visual Studio 2017 or later

    # select appropriate compiler for the $(CPU)
    VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

    # e.g. VCCL=C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX64/x86/cl.exe
    VCCL := $(call VS_DEDUCE_VCCL,$(wildcard $(VS_WILD)*/VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED)))

    # if there are multiple Visual Studio editions, select which have the latest compiler,
    #  or may be VS specified with Visual Studio edition type?
    # $1 - C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX64/x86/cl.exe
    VS_DEDUCE_VCCL = $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(VS_PATH)/ $(if \
      $1,$1,$(wildcard $(VS_WILD)VC/Tools/MSVC/$(VC_VER)*/$(VCCL_2017_PREFIXED))))

    # if VCCL is defined, extract VC_VER from it below
    VC_VER_AUTO:=
  endif

  ifndef VCCL
    $(error unable to autoconfigure for TCPU/CPU=$(TCPU)/$(CPU) on VS_CPU/VS_CPU64=$(VS_CPU)/$(VS_CPU64) with VS=$(VS),\
please specify either MSVC or VCCL, e.g.:$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\VC98$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual C++ Toolkit 2003$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe)
  endif

  ifndef VC_VER
    ifdef VC_VER_AUTO
      VC_VER := $(VC_VER_AUTO)
      $(warning autoconfigured: VC_VER=$(VC_VER))
    endif
  endif

  # C:\Program?Files\Microsoft?Visual?Studio?14.0\VC\bin\cl.exe
  # "C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
  VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))
  $(warning autoconfigured: VCCL=$(VCCL))

endif # !MSVC
endif # !VCCL

ifndef VCCL
  # define VCCL and, optionally, VC_VER from $(MSVC)

  # MSVC path must use forward slashes, there must be no trailing slash, e.g.:
  #  MSVC_PATH=C:/Program?Files/Microsoft?Visual?Studio?14.0/VC
  #  MSVC_NAME=vc
  #  MSVC_WILD=C:/Program\ Files/Microsoft\ Visual\ Studio\ 14.0/VC/
  # note: $(MSVC) could be without trailing slash
  MSVC_PATH := $(patsubst %/,%,$(subst \,/,$(subst $(space),?,$(MSVC))))
  MSVC_NAME := $(call tolower,$(notdir $(MSVC_PATH)))
  MSVC_WILD := $(subst ?,\ ,$(MSVC_PATH))/

  # reset
  VC_VER_AUTO:=

  ifeq (vc98,$(MSVC_NAME))
    # MSVC=C:\Program Files\Microsoft Visual Studio\VC98
    VC_VER_AUTO := 6.0
    ifeq ($(VS_CPU)_$(VS_CPU),$(TCPU)_$(CPU))
      VCCL := $(wildcard $(MSVC_WILD)Bin/cl.exe)
    endif

  else ifeq (microsoft?visual?c++?toolkit?2003,$(MSVC_NAME))
    # MSVC=C:\Program Files\Microsoft Visual C++ Toolkit 2003
    VC_VER_AUTO := 7.1
    ifeq ($(VS_CPU)_$(VS_CPU),$(TCPU)_$(CPU))
      VCCL := $(wildcard $(MSVC_WILD)bin/cl.exe)
    endif

  else ifeq (vc7,$(MSVC_NAME))
    # MSVC=C:\Program Files\Microsoft Visual Studio .NET\Vc7
    # MSVC=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7
    ifndef VC_VER
      VS_NAME := $(call tolower,$(notdir $(patsubst %/,%,$(dir $(MSVC_PATH)))))
      ifeq (microsoft?visual?studio?.net,$(VS_NAME))
        VC_VER_AUTO := 7.0
      else ifeq (microsoft?visual?studio?.net?2003,$(VS_NAME))
        VC_VER_AUTO := 7.1
      else
        $(error unable to determine Visual C++ version for MSVC=$(MSVC), please specify it explicitly, e.g. VC_VER=7.1)
      endif
    endif
    ifeq ($(VS_CPU)_$(VS_CPU),$(TCPU)_$(CPU))
      VCCL := $(wildcard $(MSVC_WILD)bin/cl.exe)
    endif

  else ifeq (vc,$(MSVC_NAME))
    # MSVC=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC
    # MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC
    # MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC
    VS_NAME := $(call tolower,$(notdir $(patsubst %/,%,$(dir $(MSVC_PATH)))))

    ifeq (v6.0,$(VS_NAME))
      # MSVC=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC
      VC_VER_AUTO := 8.0
      ifeq ($(CPU),$(TCPU))
        # select appropriate compiler for the $(CPU)
        VCCL := $(wildcard $(MSVC_WILD)Bin/$(VC_TOOL_PREFIX_SDK6)cl.exe)
      endif

    else ifeq (,$(wildcard $(MSVC_WILD)Tools/MSVC/.))
      # MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC

      ifndef VC_VER
        ifneq (,$(filter microsoft?visual?studio?%,$(VS_NAME)))
          VC_VER_AUTO := $(lastword $(subst ?, ,$(VS_NAME)))
        else
          $(error unable to determine Visual C++ version for MSVC=$(MSVC), please specify it explicitly, e.g. VC_VER=14.0)
        endif
      endif
      # select appropriate compiler for the $(CPU)
      VCCL := $(wildcard $(MSVC_WILD)bin/$(call VC_TOOL_PREFIX_2005,$(CPU),$(call VS_SELECT_CPU,$(MSVC_PATH)))cl.exe)

    else
      # MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC

      # select appropriate compiler for the $(CPU)
      VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

      # find cl.exe and choose the newest one
      VCCL := $(call VS_2017_SELECT_LATEST_ENTRY,$(VCCL_2017_PREFIXED),$(MSVC_PATH)/ $(wildcard \
        $(MSVC_WILD)Tools/MSVC/$(VC_VER)*/$(VCCL_2017_PREFIXED)))

      # extract VC_VER from VCCL below
    endif

  else ifneq (,$(filter %/vc/tools/msvc/,$(call tolower,$(dir $(MSVC_PATH)))))
    # MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503

    # select appropriate compiler for the $(CPU)
    VCCL := $(wildcard $(MSVC_WILD)bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe)

    # extract VC_VER from VCCL below
  endif

  ifndef VCCL
    $(error unable to autoconfigure for TCPU/CPU=$(TCPU)/$(CPU) on VS_CPU/VS_CPU64=$(VS_CPU)/$(VS_CPU64) with MSVC=$(MSVC),\
please specify VCCL, e.g.:$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe)
  endif

  ifndef VC_VER
    ifdef VC_VER_AUTO
      VC_VER := $(VC_VER_AUTO)
      $(warning autoconfigured: VC_VER=$(VC_VER))
    endif
  endif

  # C:\Program?Files\Microsoft?Visual?Studio?14.0\VC\bin\cl.exe
  # "C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
  VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))
  $(warning autoconfigured: VCCL=$(VCCL))

endif # !VCCL

# ok, VCCL is defined, VC_VER - possibly defined also
# deduce VC_VER, VCLIBPATH and VCINCLUDE values from $(VCCL)

ifneq (123,$(if \
  $(VC_VER),1)$(if \
  $(filter undefined environment,$(origin VCLIBPATH)),,2)$(if \
  $(filter undefined environment,$(origin VCINCLUDE)),,3))

  # VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
  VCCL_PARENT1 := $(patsubst %\,%,$(dir $(patsubst "%",%,$(subst $(space),?,$(VCCL)))))
  VCCL_PARENT2 := $(patsubst %\,%,$(dir $(VCCL_PARENT1)))

  # e.g. bin or x64 or amd64_x86
  VCCL_ENTRY1l := $(call tolower,$(notdir $(VCCL_PARENT1)))

  ifeq (bin,$(VCCL_ENTRY1l))
    # VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio .NET\Vc7\bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"

    ifndef VC_VER
      VCCL_PARENT2l := $(call tolower,$(VCCL_PARENT2))
      VCCL_ENTRY2l := $(notdir $(VCCL_PARENT2l))

      ifeq (vc98,$(VCCL_ENTRY2l))
        # VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
        VC_VER := 6.0

      else ifeq (microsoft?visual?c++?toolkit?2003,$(VCCL_ENTRY2l))
        # VCCL="C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe"
        VC_VER := 7.1

      else ifeq (vc7,$(VCCL_ENTRY2l))
        # VCCL="C:\Program Files\Microsoft Visual Studio .NET\Vc7\bin\cl.exe"
        # VCCL="C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\cl.exe"
        VCCL_ENTRY3l := $(notdir $(patsubst %\,%,$(dir $(VCCL_PARENT2l))))

        ifeq (microsoft?visual?studio?.net?2003,$(VCCL_ENTRY3l))
          VC_VER := 7.1
        else ifeq (microsoft?visual?studio?.net,$(VCCL_ENTRY3l))
          VC_VER := 7.0
        endif

      else ifeq (vc,$(VCCL_ENTRY2l))
        # VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\cl.exe"
        # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
        VCCL_ENTRY3l := $(notdir $(patsubst %\,%,$(dir $(VCCL_PARENT2l))))

        ifeq (v6.0,$(VCCL_ENTRY3l))
          VC_VER := 8.0
        else ifneq (,$(filter microsoft?visual?studio?%,$(VCCL_ENTRY3l)))
          VC_VER := $(lastword $(subst ?, ,$(VCCL_ENTRY3l)))
        endif

      endif

      ifdef VC_VER
        $(warning autoconfigured: VC_VER=$(VC_VER))
      endif
    endif

    ifneq (,$(filter undefined environment,$(origin VCLIBPATH)))
      VCLIBPATH := $(VCCL_PARENT2)\lib
      $(warning autoconfigured: VCLIBPATH=$(VCLIBPATH))
    endif

    ifneq (,$(filter undefined environment,$(origin VCINCLUDE)))
      VCINCLUDE := $(VCCL_PARENT2)\include
      $(warning autoconfigured: VCINCLUDE=$(VCINCLUDE))
    endif

  else
    # VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
    # VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
    VCCL_PARENT3 := $(patsubst %\,%,$(dir $(VCCL_PARENT2)))

    ifeq (bin,$(call tolower,$(notdir $(VCCL_PARENT2))))
      # VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe"
      # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"

      ifndef VC_VER
        ifeq (vc,$(call tolower,$(notdir $(VCCL_PARENT3))))
          VCCL_ENTRY4l := $(call tolower,$(notdir $(patsubst %\,%,$(dir $(VCCL_PARENT3)))))

          ifeq (v6.0,$(VCCL_ENTRY4l))
            VC_VER := 8.0
          ifneq (,$(filter microsoft?visual?studio?%,$(VCCL_ENTRY4l)))
            VC_VER := $(lastword $(subst ?, ,$(VCCL_ENTRY4l)))
          endif
        endif

        ifdef VC_VER
          $(warning autoconfigured: VC_VER=$(VC_VER))
        endif
      endif

      ifneq (,$(filter undefined environment,$(origin VCLIBPATH)))
        # C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\LIB\x64\msvcrt.lib
        # C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\arm\msvcrt.lib
        # C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\msvcrt.lib
        # C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\amd64\msvcrt.lib
        VCLIBPATH := $(VCCL_PARENT3)\lib$(VC_LIB_TYPE_ONECORE:%=\%)$(VC_LIB_TYPE_STORE:%=\%)$(call \
          VCCL_GET_LIBS_2005,$(VCCL_ENTRY1l),$(call VS_SELECT_CPU,$(subst \,/,$(VCCL_PARENT3))))
        $(warning autoconfigured: VCLIBPATH=$(VCLIBPATH))
      endif

      ifneq (,$(filter undefined environment,$(origin VCINCLUDE)))
        VCINCLUDE := $(VCCL_PARENT3)\include
        $(warning autoconfigured: VCINCLUDE=$(VCINCLUDE))
      endif

    else ifeq (bin,$(call tolower,$(notdir $(VCCL_PARENT3))))
      # VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"

      VCCL_PARENT4 := $(patsubst %\,%,$(dir $(VCCL_PARENT3)))

      ifndef VC_VER
        ifneq (,$(filter %\vc\tools\msvc\,$(call tolower,$(dir $(VCCL_PARENT4)))))
          VC_VER := $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(notdir $(VCCL_PARENT4)))))
        endif

        ifdef VC_VER
          $(warning autoconfigured: VC_VER=$(VC_VER))
        endif
      endif

      ifneq (,$(filter undefined environment,$(origin VCLIBPATH)))
        # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\msvcrt.lib
        # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\store\msvcrt.lib
        # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x64\msvcrt.lib
        VCLIBPATH := $(VCCL_PARENT4)\lib$(VC_LIB_TYPE_ONECORE:%=\%)\$(VCCL_ENTRY1l)$(VC_LIB_TYPE_STORE:%=\%)
        $(warning autoconfigured: VCLIBPATH=$(VCLIBPATH))
      endif

      ifneq (,$(filter undefined environment,$(origin VCINCLUDE)))
        VCINCLUDE := $(VCCL_PARENT4)\include
        $(warning autoconfigured: VCINCLUDE=$(VCINCLUDE))
      endif

    else
      $(error unable to autoconfigure for VCCL=$(VCCL), please specify VC_VER, VCLIBPATH and VCINCLUDE explicitly, e.g.:$(newline)$(if \
,)VC_VER=14.1$(newline)$(if \
,)VCLIBPATH=C:\Program?Files\Microsoft?Visual?Studio?14.0\VC\lib$(newline)$(if \
,)VCINCLUDE=C:\Program?Files\Microsoft?Visual?Studio?14.0\VC\include)

    endif
  endif

  ifndef VC_VER
    $(error unable to determine Visual C++ version for VCCL=$(VCCL), please specify it explicitly, e.g. VC_VER=14.1)
  endif

endif # 123

endif # autoconfig

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
ifneq (,$(filter undefined environment,$(origin TVCCL)))
TVCCL:=
else
  # TVCCL path must use forward slashes
  override TVCCL := $(subst /,\,$(TVCCL))
  ifneq (,$(findstring $(space),$(TVCCL)))
    # if $(TVCCL) contains a space, it must be in double quotes
    ifeq ($(subst $(space),?,$(TVCCL)),$(patsubst "%",%,$(subst $(space),?,$(TVCCL))))
    override TVCCL := "$(TVCCL)"
    endif
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

# --------------------- runtime paths --------------------

# by default, allow adjusting PATH environment variable so cl.exe may find needed dlls
DO_NOT_ADJUST_PATH:=

ifndef DO_NOT_ADJUST_PATH

# remember if environment variable PATH was changed
VCCL_PATH_APPEND:=

# adjust environment variable PATH so cl.exe, lib.exe and link.exe will find their dlls
VCCL_PARENT1 := $(patsubst %\,%,$(dir $(patsubst "%",%,$(subst $(space),?,$(VCCL)))))
VCCL_ENTRY1l := $(call tolower,$(notdir $(VCCL_PARENT1)))

ifneq (,$(call is_less_float,14,$(VC_VER)))
  # Visual Studio 2017 or later:
  #  VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"

  VCCL_PARENT2 := $(patsubst %\,%,$(dir $(VCCL_PARENT1)))
  VCCL_HOST := $(patsubst host%,%,$(call tolower,$(notdir $(VCCL_PARENT2))))

  # if cross-compiling, add path to host dlls
  ifneq ($(VCCL_HOST),$(VCCL_ENTRY1l))
    VCCL_PATH_APPEND := $(VCCL_PARENT2)\$(VCCL_HOST)
  endif

else ifeq (,$(call is_less_float,$(VC_VER),8))
  # Visual Studio 2005 or later:
  #  VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\cl.exe"
  #  VCCL="C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe"
  #  VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
  #  VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64\cl.exe"
  #  VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64_x86\cl.exe"
  #  VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"

  ifneq (bin,$(VCCL_ENTRY1l))
    # x64       -> VCCL_HOST_PREF=\x64   VC_LIBS_PREF=\x64
    # amd64     -> VCCL_HOST_PREF=\amd64 VC_LIBS_PREF=\amd64
    # amd64_x86 -> VCCL_HOST_PREF=\amd64 VC_LIBS_PREF=
    # x86_amd64 -> VCCL_HOST_PREF=       VC_LIBS_PREF=\amd64
    VCCL_CPU       := $(call VS_SELECT_CPU,$(subst \,/,$(VCCL_PARENT1)))
    VCCL_HOST_PREF := $(addprefix \,$(call VCCL_GET_HOST_2005,$(VCCL_ENTRY1l),$(VCCL_CPU)))
    VC_LIBS_PREF   := $(call VCCL_GET_LIBS_2005,$(VCCL_ENTRY1l),$(VCCL_CPU))

    # e.g. C:\Program Files\Microsoft Visual Studio 14.0\VC\bin
    VCCL_PARENT2 := $(patsubst %\,%,$(dir $(VCCL_PARENT1)))

    # if cross-compiling, add path to host dlls
    # note: some dlls are may be in $(VS)\Common7\IDE
    ifneq ($(VCCL_HOST_PREF),$(VC_LIBS_PREF))
      VCCL_PATH_APPEND := $(VCCL_PARENT2)$(VCCL_HOST_PREF)
    endif

    ifndef VCCL_HOST_PREF
      # for Visual Studio 2012 and before:
      #  add path to $(VS)\Common7\IDE if compiling on $(VS_CPU) host
      ifeq (,$(call is_less_float,11,$(VC_VER)))

        # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
        COMMON7_IDE_PATH := $(dir $(patsubst %\,%,$(dir $(VCCL_PARENT2))))Common7\IDE

        ifneq (,$(wildcard $(subst ?,\ ,$(subst \,/,$(COMMON7_IDE_PATH)))\.))
          VCCL_PATH_APPEND := $(COMMON7_IDE_PATH)
        endif
      endif
    endif
  endif

endif

ifeq (bin,$(VCCL_ENTRY1l))

  # for Visual Studio .NET ... Visual Studio 2012:
  #  add path to $(VS)\Common7\IDE if compiling on x86 host
  ifeq (,$(call is_less_float,$(VC_VER),7))
    ifeq (,$(call is_less_float,11,$(VC_VER)))

      # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
      COMMON7_IDE_PATH := $(dir $(patsubst %\,%,$(dir $(VCCL_PARENT1))))Common7\IDE

      ifneq (,$(wildcard $(subst ?,\ ,$(subst \,/,$(COMMON7_IDE_PATH)))\.))
        VCCL_PATH_APPEND := $(COMMON7_IDE_PATH)
      endif
    endif

  else
    # for Visual Studio 6.0:
    #  add path to $(VS)\Common\MSDev98\Bin

    # VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe
    VCCL_PATH_APPEND := $(dir $(patsubst %\,%,$(dir $(VCCL_PARENT1))))Common\MSDev98\Bin
  endif

endif

ifdef VCCL_PATH_APPEND
override PATH := $(PATH);$(subst ?, ,$(VCCL_PATH_APPEND))
# if PATH variable was changed, print it to generated batch file
ifdef VERBOSE
$(info SET "PATH=$(PATH)")
endif
endif

endif # !DO_NOT_ADJUST_PATH

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,GET_PROGRAM_FILES_DIRS VS_CPU VS_CPU64 IS_WIN_64 VS_FIND_FILE_WHERE VS_FIND_FILE VS_FIND_FILE_P VS_REG_QUERY \
  VS_REG_FIND_FILE_WHERE VS_REG_FIND_FILE VS_REG_FIND_FILE_P VS_REG_SEARCH_X VS_REG_SEARCH_WHERE VS_REG_SEARCH VS_REG_SEARCH_P \
  VCCL_2005_PATTERN_GEN_VC VCCL_2005_PATTERN_GEN_VS VC_TOOL_PREFIX_SDK6 \
  VC_TOOL_PREFIX_2005 VCCL_GET_LIBS_2005 VCCL_GET_HOST_2005 VC_TOOL_PREFIX_2017 \
  VC_VER VCCL VC_LIB_TYPE_ONECORE VC_LIB_TYPE_STORE VS_2017_SELECT_LATEST1 VS_2017_SELECT_LATEST VS_2017_SELECT_LATEST_ENTRY \
  VCLIBPATH VCINCLUDE VCLIB VCLINK TVCCL TVCLIBPATH TVCLIB TVCLINK \
  VCCL_PATH_APPEND)
