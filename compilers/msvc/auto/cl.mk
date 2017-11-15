#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# find and define VCCL - MSVC C/C++ compiler executable, included by $(CLEAN_BUILD_DIR)/compilers/msvc/auto/conf.mk

# note: may also define SDK_AUTO, DDK_AUTO, SDK_VER_AUTO, DDK_VER_AUTO, SDK and DDK

# processor architecture of non-prefixed Visual Studio tools (applicable for pre-Visual Studio 2017)
# note: VS_CPU value depends on where Visual Studio is installed, e.g., on 64-bit Windows:
#  C:\Program Files\Microsoft Visual Studio 8\VC\bin\cl.exe                 - non-prefixed x86_64 compiler for x86_64, VS_CPU=amd64
#  C:\Program Files (x86)\Microsoft Visual Studio 8\VC\bin\cl.exe           - non-prefixed x86    compiler for x86,    VS_CPU=x86
#  C:\Program Files (x86)\Microsoft Visual Studio 8\VC\bin\amd64\cl.exe     - prefixed     x86_64 compiler for x86_64, VS_CPU=x86
#  C:\Program Files (x86)\Microsoft Visual Studio 8\VC\bin\x86_amd64\cl.exe - prefixed     x86    compiler for x86_64, VS_CPU=x86
VS_CPU32 := x86
VS_CPU64 := amd64

ifdef IS_WIN_64
# $1 - pattern, like C:/Program?Files?(x86)/A/B/C
VS_CPU = $(if $(findstring :/program?files/,$(tolower)),$(VS_CPU64),$(VS_CPU32))
else
VS_CPU := $(VS_CPU32)
endif

# for Visual C++ compiler from Windows Server 2003 DDK
# determine MSVC tools prefix for given TOOLCHAIN_CPU/CPU combination, e.g.:
#  C:\WINDDK\3790\bin\x86\cl.exe             - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 13.10.2179 for 80x86
#  C:\WINDDK\3790\bin\ia64\cl.exe            - ???
#  C:\WINDDK\3790\bin\win64\x86\cl.exe       - Microsoft (R) C/C++ Optimizing Compiler Version 13.10.2240.8 for IA-64
#  C:\WINDDK\3790\bin\win64\x86\amd64\cl.exe - Microsoft (R) C/C++ Optimizing Compiler Version 14.00.2207 for AMD64
#
# TOOLCHAIN_CPU\CPU    x86       x86_64        ia64
# ------------------|------------------------------------
#        x86        |  x86/  win64/x86/amd64/  win64/x86/
#        ia64       |   ?          ?           ia64/
#
# $1 - $(TOOLCHAIN_CPU)
# $2 - $(CPU)
CL_TOOL_PREFIX_DDK_3790 = $(if $(filter $1,$2),$1,$(if $(filter %64,$2),win64/)$(1:x86_64=amd64)$(if $(filter x86_64,$2),/amd64))/

# for Visual C++ compiler from Windows Driver Kit 6-7 (Visual C++ 8.0-9.0 of Visual Studio 2005-2008)
# determine MSVC tools prefix for given TOOLCHAIN_CPU/CPU combination, e.g.:
#  C:\WinDDK\6001.18001\bin\x86\x86\cl.exe   - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 14.00.50727.278 for 80x86
#  C:\WinDDK\6001.18001\bin\x86\amd64\cl.exe - Microsoft (R) C/C++ Optimizing Compiler Version 14.00.50727.278 for x64
#  C:\WinDDK\6001.18001\bin\x86\ia64\cl.exe  - Microsoft (R) C/C++ Optimizing Compiler Version 14.00.50727.283 for Itanium
#  C:\WinDDK\6001.18001\bin\ia64\ia64\cl.exe - ????
# $1 - $(TOOLCHAIN_CPU)
# $2 - $(CPU)
CL_TOOL_PREFIX_DDK6 = $(1:x86_64=amd64)/$(2:x86_64=amd64)/

# for Visual C++ compiler from SDK 6.0 (Visual C++ 8.0 of Visual Studio 2005)
# determine MSVC tools prefix for given CPU
# note: $(TOOLCHAIN_CPU) _must_ match $(CPU)
#
# CPU  |  x86    x86_64
# -----|-------------------------------------
# pref | <none>   x64/
#
# $1 - $(TOOLCHAIN_CPU) or $(CPU)
VC_TOOL_PREFIX_SDK6 = $(addsuffix /,$(filter-out x86,$(1:x86_64=x64)))

# for Visual Studio 2005-2015
# determine MSVC tools prefix for given TOOLCHAIN_CPU/CPU/VS_CPU combination
#
# TOOLCHAIN_CPU\CPU   x86        x86_64      arm
# ------------------|---------------------------------
#       x86         | <none>     x86_amd64/ x86_arm/
#       x86_64      | amd64_x86/ amd64/     amd64_arm/
#
# $1 - $(TOOLCHAIN_CPU)
# $2 - $(CPU)
# $3 - $(VS_CPU)
VC_TOOL_PREFIX_2005 = $(addsuffix /,$(filter-out $3,$(1:x86_64=amd64)$(addprefix _,$(subst x86_64,amd64,$(filter-out $1,$2)))))

# for use with CONF_FIND_FILE_P or MS_REG_SEARCH_P
# $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/VC/ C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/VC/
# result: bin/x86_arm/cl.exe (possible with spaces in result)
VCCL_2005_PATTERN_GEN_VC = bin/$(call VC_TOOL_PREFIX_2005,$(TOOLCHAIN_CPU),$(CPU),$(call VS_CPU,$(firstword $2)))cl.exe

# for use with CONF_FIND_FILE_P or MS_REG_SEARCH_P
# $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/ C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/
# result: VC/bin/x86_arm/cl.exe (possible with spaces in result)
VCCL_2005_PATTERN_GEN_VS = VC/$(VCCL_2005_PATTERN_GEN_VC)

# for Visual Studio 2017
# determine MSVC tools prefix for given TOOLCHAIN_CPU/CPU combination
#
# TOOLCHAIN_CPU\CPU    x86          x86_64        arm
# ------------------|---------------------------------------
#       x86         | HostX86/x86/ HostX86/x64/ HostX86/arm/
#       x86_64      | HostX64/x86/ HostX64/x64/ HostX64/arm/
#
# $1 - $(TOOLCHAIN_CPU)
# $2 - $(CPU)
VC_TOOL_PREFIX_2017 = Host$(subst x,X,$(1:x86_64=x64))/$(2:x86_64=x64)/

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

# take the newest cl.exe among found ones, e.g.:
#  $1=bin/HostX86/x64/cl.exe
#  $2=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
# result: C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
VS_2017_SELECT_LATEST_CL = $(subst ?, ,$(CONF_SELECT_LATEST))

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

ifdef MSVC
# MSVC=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC
override MSVC := $(call CONF_NORMALIZE_DIR,$(MSVC))
endif

ifndef MSVC
ifdef VS
# VS=C:/Program?Files/Microsoft?Visual?Studio?12.0
override VS := $(call CONF_NORMALIZE_DIR,$(VS))
endif
endif

ifndef MSVC
ifndef VS
  # try to define VCCL from values of VS*COMNTOOLS environment variables (that are may be set by the vcvars32.bat)

  # extract Visual Studio installation paths from values of VS*COMNTOOLS variables,
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
      VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(TOOLCHAIN_CPU),$(CPU))cl.exe

      # try to find Visual Studio 2017 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
      #  C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
      VCCL := $(call VS_2017_SELECT_LATEST_CL,$(VCCL_2017_PREFIXED),$(call \
        CONF_FIND_FILE_WHERE,VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(VS_COMNS_2017)))

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
          VC_TOOL_PREFIX_2005,$(TOOLCHAIN_CPU),$(CPU),$(call VS_CPU,$2))cl.exe))

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
      # result: C:/Program Files/Microsoft Visual Studio .NET 2003/Vc7/bin/cl.exe
      VS_COMN_FIND_CL = $(if $1,$(call VS_COMN_FIND_CL1,$1,$2,$(wildcard \
        $(subst ?,\ ,$(call VS_STRIP_COMN,$(subst $(space),?,$(VS$(firstword $1)COMNTOOLS))))$2)))

      # $1 - MSVC versions, e.g. 71,70,60
      # $2 - Vc7/bin/cl.exe or VC98/Bin/cl.exe
      # $3 - C:/Program Files/Microsoft Visual Studio .NET 2003/Vc7/bin/cl.exe
      VS_COMN_FIND_CL1 = $(if $3,$3,$(call VS_COMN_FIND_CL,$(wordlist 2,999999,$1),$2))

      ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),70))
        # Visual Studio .NET or later

        # may compile only for x86 on x86
        ifeq ($(CPU) $(VS_CPU32),$(TOOLCHAIN_CPU) $(CPU))
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

        ifeq ($(CPU) $(VS_CPU32),$(TOOLCHAIN_CPU) $(CPU))
          VCCL := $(call VS_COMN_FIND_CL,$(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,60),,$v)),VC98/Bin/cl.exe)
        endif

        ifndef VCCL
          # filter-out Visual Studio 6.0 or later
          VS_COMN_VERS := $(foreach v,$(VS_COMN_VERS),$(if $(call is_less,$v,60),$v))
        endif

      endif
    endif
  endif

endif # !VS
endif # !MSVC

ifndef VCCL
ifndef MSVC
ifndef VS
  # check registry and standard places in Program Files - to define VCCL

  # get registry keys of Visual C++ installation paths for MS_REG_SEARCH
  # $1 - Visual Studio version, e.g.: 7.0 7.1 8.0 9.0 10.0 11.0 12.0 14.0 15.0
  # note: for Visual Studio 2005 and later - check VCExpress key
  VCCL_REG_KEYS_VC = VisualStudio\$1\Setup\VC?ProductDir $(if $(call \
    is_less_float,$1,8.0),,VCExpress\$1\Setup\VC?ProductDir) VisualStudio\SxS\VC7?$1

  # get registry keys of Visual Studio installation paths for MS_REG_SEARCH
  VCCL_REG_KEYS_VS = VisualStudio\$1\Setup\VS?ProductDir $(if $(call \
    is_less_float,$1,8.0),,VCExpress\$1\Setup\VS?ProductDir) VisualStudio\SxS\VS7?$1

  # select appropriate compiler for the $(CPU)
  VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(TOOLCHAIN_CPU),$(CPU))cl.exe

  # look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
  VCCL := $(call VS_2017_SELECT_LATEST_CL,$(VCCL_2017_PREFIXED),$(call \
    MS_REG_SEARCH_WHERE,Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(call VCCL_REG_KEYS_VC,15.0)))

  ifndef VCCL
    # look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
    VCCL := $(call VS_2017_SELECT_LATEST_CL,$(VCCL_2017_PREFIXED),$(call \
      MS_REG_SEARCH_WHERE,VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(call VCCL_REG_KEYS_VS,15.0)))
  endif

  ifndef VCCL
    # check standard places
    # e.g.: C:/Program?Files/ C:/Program?Files?(x86)/
    PROGRAM_FILES_PLACES := $(addsuffix /,$(GET_PROGRAM_FILES_DIRS))

    # look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
    VCCL := $(call VS_2017_SELECT_LATEST_CL,$(VCCL_2017_PREFIXED),$(call \
      CONF_FIND_FILE_WHERE,Microsoft Visual Studio/*/*/VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(PROGRAM_FILES_PLACES)))
  endif

  ifndef VCCL
    # versions of Visual C++ starting with Visual Studio 2005
    VCCL_2005_VERSIONS := 14.0 12.0 11.0 10.0 9.0 8.0

    # $1 - 14.0 12.0 11.0 10.0 9.0 8.0
    # result: 14.0 C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
    VS_SEARCH_2005  = $(if $1,$(call VS_SEARCH_20051,$1,$(call \
      MS_REG_SEARCH_P,VCCL_2005_PATTERN_GEN_VC,$(call VCCL_REG_KEYS_VC,$(firstword $1)))))

    # look in Visual Studio installation paths
    VS_SEARCH_20051 = $(if $2,$2,$(call VS_SEARCH_20052,$1,$(call \
      MS_REG_SEARCH_P,VCCL_2005_PATTERN_GEN_VS,$(call VCCL_REG_KEYS_VS,$(firstword $1)))))

    # check standard places
    # note: for Visual Studio 2005 registry key ends with 8.0, but directory in Program Files ends with just 8
    VS_SEARCH_20052 = $(if $2,$2,$(call VS_SEARCH_20053,$1,$(call \
      CONF_FIND_FILE_P,VCCL_2005_PATTERN_GEN_VS,$(addsuffix \
      Microsoft?Visual?Studio?$(subst 8.0,8,$(firstword $1))/,$(PROGRAM_FILES_PLACES)))))

    # recursion
    VS_SEARCH_20053 = $(if $2,$2,$(call VS_SEARCH_2005,$(wordlist 2,999999,$1)))

    # result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
    VCCL := $(call VS_SEARCH_2005,$(VCCL_2005_VERSIONS))
  endif

  ifndef VCCL
    # check for C++ compiler bundled in Windows Driver Kit 7.1.0 or 7.0.0
    CL_DDK6 := bin/$(call CL_TOOL_PREFIX_DDK6,$(TOOLCHAIN_CPU),$(CPU))cl.exe

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
      VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK6),$(DDK_71_REG_PATH),setup-install-location,$(IS_WIN_64))
      ifdef VCCL
        DDK_VER_AUTO := 7600.16385.1
      else
        VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK6),$(DDK_70_REG_PATH),setup-install-location,$(IS_WIN_64))
        ifdef VCCL
          DDK_VER_AUTO := 7600.16385.0
        endif
      endif

      ifdef VCCL
        # e.g.: C:/my?ddks/WinDDK/7600.16385.1
        DDK_AUTO := $(patsubst %/$(CL_DDK6),%,$(subst $(space),?,$(VCCL)))
      endif

    endif
  endif

  ifndef VCCL
    # cross compiler is not supported by SDK6.0, but may compile x86_64 on x86_64 or x86 on x86
    ifeq ($(CPU),$(TOOLCHAIN_CPU))

      # check for Visual C++ compiler bundled in SDK6.0
      CL_SDK6 := VC/Bin/$(call VC_TOOL_PREFIX_SDK6,$(CPU))cl.exe

      # look for C:/Program Files/Microsoft SDKs/Windows/v6.0/VC/Bin/x64/cl.exe - Microsoft Compiler Version 14.00.50727.762 for x64
      ifdef SDK
        VCCL := $(wildcard $(subst ?,\ ,$(SDK))/$(CL_SDK6))

      else ifndef WDK # WDK may be used instead of SDK, but WDK comes without bundled compiler

        # look for C:/Program Files/Microsoft SDKs/Windows/v6.0/VC/Bin/x64/cl.exe - Microsoft Compiler Version 14.00.50727.762 for x64
        VCCL := $(call MS_REG_FIND_FILE,$(CL_SDK6),Microsoft SDKs\Windows\v6.0,InstallationFolder)

        ifndef VCCL
          # look in Program Files
          VCCL := $(call CONF_FIND_FILE,$(CL_SDK6),$(addsuffix Microsoft?SDKs/Windows/v6.0/,$(PROGRAM_FILES_PLACES)))
        endif

        ifdef VCCL
          # e.g.: C:/Program?Files/Microsoft?SDKs/Windows/v6.0
          SDK_AUTO := $(patsubst %/$(CL_SDK6),%,$(subst $(space),?,$(VCCL)))
          SDK_VER_AUTO := v6.0
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
      VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK6),$(DDK_62_REG_PATH),setup-install-location,$(IS_WIN_64))
      ifdef VCCL
        DDK_VER_AUTO := 6001.18002
      else
        # check registry for Windows Driver Kit – Server 2008 (x86, x64, ia64)   6001.18001  April 1, 2008
        VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK6),WINDDK\6001.18001\Setup,BUILD,$(IS_WIN_64))
        ifdef VCCL
          DDK_VER_AUTO := 6001.18001
        else
          # check registry for Windows Driver Kit – Server 2008 (x86, x64, ia64)  6001.18000  Jan 2008
          VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK6),WINDDK\6001.18000\Setup,BUILD,$(IS_WIN_64))
          ifdef VCCL
            DDK_VER_AUTO := 6001.18000
          else
            # check registry for Windows Driver Kit for Windows Vista 6000 November 29, 2006
            VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK6),WINDDK\6000\Setup,BUILD,$(IS_WIN_64))
            ifdef VCCL
              DDK_VER_AUTO := 6000
            endif
          endif
        endif
      endif

      ifdef VCCL
        # e.g.: C:/my?ddks/WinDDK/6001.18002
        DDK_AUTO := $(patsubst %/$(CL_DDK6),%,$(subst $(space),?,$(VCCL)))
      endif

    endif
  endif

  ifndef VCCL
    # cross compiler is not supported by Visual Studio .NET 2003, may compile only x86 on x86
    ifeq ($(CPU) $(VS_CPU32),$(TOOLCHAIN_CPU) $(CPU))

      # search Visual C++ .NET 2003 compiler
      VCCL := $(call MS_REG_SEARCH,bin/cl.exe,$(call VCCL_REG_KEYS_VC,7.1))

      ifndef VCCL
        VCCL := $(call MS_REG_SEARCH,Vc7/bin/cl.exe,$(call VCCL_REG_KEYS_VS,7.1))
      endif

      ifndef VCCL
        # look in Program Files
        VCCL := $(call CONF_FIND_FILE,Vc7/bin/cl.exe,$(addsuffix Microsoft?Visual?Studio?.NET?2003/,$(PROGRAM_FILES_PLACES)))
      endif

    endif
  endif

  ifndef VCCL
    # check for C++ compiler bundled in Windows Server 2003 SP1 DDK
    # check for C++ compiler bundled in Windows Server 2003 DDK 3790
    CL_DDK_3790 := bin/$(call CL_TOOL_PREFIX_DDK_3790,$(TOOLCHAIN_CPU),$(CPU))cl.exe

    # look for:
    #  C:\WINDDK\3790.1830\bin\x86\cl.exe - Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 13.10.4035 for 80x86
    ifdef DDK
      VCCL := $(wildcard $(subst ?,\ ,$(DDK))/$(CL_DDK_3790))

    else ifndef WDK # WDK may be used instead of DDK, but WDK comes without bundled compiler

      # check registry for Windows Server 2003 SP1 DDK
      # e.g.: C:/my ddks/WinDDK/3790.1830/bin/x86/cl.exe
      VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK_3790),WINDDK\3790.1830,LFNDirectory,$(IS_WIN_64))
      ifdef VCCL
        DDK_VER_AUTO := 3790.1830
      else
        # check registry for Windows Server 2003 DDK 3790
        VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK_3790),WINDDK\3790,LFNDirectory,$(IS_WIN_64))
        ifdef VCCL
          DDK_VER_AUTO := 3790
        endif
      endif

      ifdef VCCL
        # e.g.: C:/my?ddks/WinDDK/3790.1830
        DDK_AUTO := $(patsubst %/$(CL_DDK_3790),%,$(subst $(space),?,$(VCCL)))
      endif

    endif
  endif

  ifndef VCCL
    # cross compiler is not supported, may compile only x86 on x86
    ifeq ($(CPU) $(VS_CPU32),$(TOOLCHAIN_CPU) $(CPU))

      # look in Program Files for Visual C++ compiler of Microsoft Visual C++ Toolkit 2003
      VCCL := $(call CONF_FIND_FILE,bin/cl.exe,$(addsuffix Microsoft?Visual?C++?Toolkit?2003/,$(PROGRAM_FILES_PLACES)))

    endif
  endif

  ifndef VCCL
    # cross compiler is not supported, may compile only x86 on x86
    ifeq ($(CPU) $(VS_CPU32),$(TOOLCHAIN_CPU) $(CPU))

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
        VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK_2600),WINDDK\2600.1106,LFNDirectory,$(IS_WIN_64))
        ifdef VCCL
          DDK_VER_AUTO := 2600.1106
        else
          # check registry for DDK for Windows XP
          VCCL := $(call MS_REG_FIND_FILE,$(CL_DDK_2600),WINDDK\2600,LFNDirectory,$(IS_WIN_64))
          ifdef VCCL
            DDK_VER_AUTO := 2600
          endif
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
    ifeq ($(CPU) $(VS_CPU32),$(TOOLCHAIN_CPU) $(CPU))

      # search Visual C++ .NET compiler
      VCCL := $(call MS_REG_SEARCH,bin/cl.exe,$(call VCCL_REG_KEYS_VC,7.0))

      ifndef VCCL
        VCCL := $(call MS_REG_SEARCH,Vc7/bin/cl.exe,$(call VCCL_REG_KEYS_VS,7.0))
      endif

      ifndef VCCL
        # look in Program Files
        VCCL := $(call CONF_FIND_FILE,Vc7/bin/cl.exe,$(addsuffix Microsoft?Visual?Studio?.NET/,$(PROGRAM_FILES_PLACES)))
      endif

      ifndef VCCL
        # search Visual 6.0 compiler
        VCCL := $(call MS_REG_FIND_FILE,Bin/cl.exe,VisualStudio\6.0\Setup\Microsoft Visual C++,ProductDir,$(IS_WIN_64))

        ifndef VCCL
          VCCL := $(call MS_REG_FIND_FILE,VC98/Bin/cl.exe,VisualStudio\6.0\Setup\Microsoft Visual Studio,ProductDir,$(IS_WIN_64))
        endif

        ifndef VCCL
          # look in Program Files
          VCCL := $(call CONF_FIND_FILE,VC98/Bin/cl.exe,$(addsuffix Microsoft?Visual?Studio/,$(PROGRAM_FILES_PLACES)))
        endif
      endif

    endif
  endif

endif
endif
endif

ifndef VCCL
ifndef MSVC
ifndef VS
  $(error unable to find C++ compiler for TOOLCHAIN_CPU/CPU=$(TOOLCHAIN_CPU)/$(CPU),\
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

  # check for Visual Studio 2017 or later

  # select appropriate compiler for the $(CPU)
  VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(TOOLCHAIN_CPU),$(CPU))cl.exe

  # if there are multiple Visual Studio editions, select which have the latest compiler,
  #  or may be VS specified with Visual Studio edition type?
  # $1 - C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX64/x86/cl.exe
  VS_DEDUCE_VCCL = $(call VS_2017_SELECT_LATEST_CL,$(VCCL_2017_PREFIXED),$(VS)/ $(if \
    $1,$1,$(wildcard $(VS_WILD)VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED))))

  # e.g. VCCL=C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX64/x86/cl.exe
  VCCL := $(call VS_DEDUCE_VCCL,$(wildcard $(VS_WILD)*/VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED)))

  ifndef VCCL
    # may be Visual Studio 2005-2015?
    VCCL := $(wildcard $(VS_WILD)VC/bin/$(call VC_TOOL_PREFIX_2005,$(TOOLCHAIN_CPU),$(CPU),$(call VS_CPU,$(VS)))cl.exe)
  endif

  ifndef VCCL
    # cross-compiler is not supported
    ifeq ($(CPU) $(VS_CPU32),$(TOOLCHAIN_CPU) $(CPU))

      # may be Visual Studio 2002-2003?
      VCCL := $(wildcard $(VS_WILD)Vc7/bin/cl.exe)

      ifndef VCCL
        # may be Visual Studio 6.0?
        VCCL := $(wildcard $(VS_WILD)VC98/bin/cl.exe)
      endif

    endif
  endif

  ifndef VCCL
    $(error unable to find C++ compiler for TOOLCHAIN_CPU/CPU=$(TOOLCHAIN_CPU)/$(CPU) with VS=$(call \
  CONF_PATH_PRINTABLE,$(VS)), please specify either MSVC or VCCL, e.g.:$(newline)$(if \
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
    VCCL := $(wildcard $(MSVC_WILD)bin/$(call VC_TOOL_PREFIX_2017,$(TOOLCHAIN_CPU),$(CPU))cl.exe)

  else ifeq (vc,$(call tolower,$(notdir $(MSVC))))
    # MSVC=C:/Program?Files/Microsoft?SDKs/Windows/v6.0/VC
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio?14.0/VC
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC
    MSVC_PARENT := $(patsubst %/,%,$(dir $(MSVC)))

    ifeq (v6.0,$(call tolower,$(notdir $(MSVC_PARENT))))
      # MSVC=C:/Program?Files/Microsoft?SDKs/Windows/v6.0/VC
      ifeq ($(CPU),$(TOOLCHAIN_CPU))
        # select appropriate compiler for the $(CPU)
        VCCL := $(wildcard $(MSVC_WILD)Bin/$(call VC_TOOL_PREFIX_SDK6,$(CPU))cl.exe)
      endif

      ifdef VCCL
      ifndef SDK
      ifndef WDK
        # e.g.: C:/Program?Files/Microsoft?SDKs/Windows/v6.0
        SDK_AUTO := $(MSVC_PARENT)
        SDK_VER_AUTO := v6.0
      endif
      endif
      endif

    else
      # MSVC=C:/Program?Files/Microsoft?Visual?Studio/2017/Community/VC

      # select appropriate compiler for the $(CPU)
      VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(TOOLCHAIN_CPU),$(CPU))cl.exe

      # find cl.exe and choose the newest one
      VCCL := $(call VS_2017_SELECT_LATEST_CL,$(VCCL_2017_PREFIXED),$(MSVC)/ $(wildcard \
        $(MSVC_WILD)Tools/MSVC/*/$(VCCL_2017_PREFIXED)))

      ifndef VCCL
        # MSVC=C:/Program?Files/Microsoft?Visual?Studio?14.0/VC

        # select appropriate compiler for the $(CPU)
        VCCL := $(wildcard $(MSVC_WILD)bin/$(call VC_TOOL_PREFIX_2005,$(TOOLCHAIN_CPU),$(CPU),$(call VS_CPU,$(MSVC)))cl.exe)
      endif
    endif

  else ifeq ($(CPU) $(VS_CPU32),$(TOOLCHAIN_CPU) $(CPU))
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio/VC98
    # MSVC=C:/Program?Files/Microsoft?Visual?C++?Toolkit?2003
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio?.NET/Vc7
    # MSVC=C:/Program?Files/Microsoft?Visual?Studio?.NET?2003/Vc7
    VCCL := $(wildcard $(MSVC_WILD)bin/cl.exe)
  endif

  ifndef VCCL
    $(error unable to find C++ compiler for TOOLCHAIN_CPU/CPU=$(TOOLCHAIN_CPU)/$(CPU) with MSVC=$(call \
  CONF_PATH_PRINTABLE,$(MSVC)), please specify VCCL, e.g.:$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe$(newline)$(if \
,)VCCL=C:\WINDDK\3790\bin\x86\cl.exe$(newline)$(if \
,)VCCL=C:\WinDDK\7600.16385.1\bin\x86\amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe)
  endif

endif # !VCCL

ifdef SDK_AUTO
# e.g.: C:/Program?Files/Microsoft?SDKs/Windows/v6.0
SDK := $(SDK_AUTO)
$(warning autoconfigured: SDK=$(SDK))
endif

ifdef DDK_AUTO
# e.g.: C:/my?ddks/WinDDK/6001.18002
DDK := $(DDK_AUTO)
$(warning autoconfigured: DDK=$(DDK))
endif

# C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
# "C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe"
VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))
$(warning autoconfigured: VCCL=$(VCCL))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,VS_CPU32 VS_CPU64 VS_CPU CL_TOOL_PREFIX_DDK_3790 CL_TOOL_PREFIX_DDK6 VC_TOOL_PREFIX_SDK6 \
  VC_TOOL_PREFIX_2005 VCCL_2005_PATTERN_GEN_VC VCCL_2005_PATTERN_GEN_VS VC_TOOL_PREFIX_2017 VS MSVC \
  VS_2017_SELECT_LATEST_CL DDK_71_REG_PATH DDK_70_REG_PATH DDK_62_REG_PATH)
