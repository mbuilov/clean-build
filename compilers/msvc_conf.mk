#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler auto-configuration (app-level), included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# try to autoconfigure:
#  Visual C++ version, paths to compiler, linker and C/C++ libraries and headers
#  - only if they are not defined in project configuration makefile or in command line
#
# VC_VER    - MSVC++ version, known values see in $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk (or below)
# VCCL      - path to cl.exe                (must be in double-quotes if contains spaces)
# VCLIB     - path to lib.exe               (must be in double-quotes if contains spaces)
# VCLINK    - path to link.exe              (must be in double-quotes if contains spaces)
# VCLIBPATH - paths to Visual C++ libraries (spaces must be replaced with ?)
# VCINCLUDE - paths to Visual C++ headers   (spaces must be replaced with ?)
#
# example:
#
# VC_VER    := 14.0
# VCCL      := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
# VCLIB     := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\lib.exe"
# VCLINK    := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\link.exe"
# VCLIBPATH := C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\VC\lib
# VCINCLUDE := C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\VC\include

#################################################################################################################
# input for autoconfiguration:
#
# 1) VS - Visual Studio installation path (without quotes),
#   may be specified if autoconfiguration based on values of environment variables fails, e.g.:
#     VS=C:\Program Files\Microsoft Visual Studio
#     VS=C:\Program Files\Microsoft Visual Studio .NET 2003
#     VS=C:\Program Files\Microsoft Visual Studio 14.0
#     VS=C:\Program Files\Microsoft Visual Studio\2017
#     VS=C:\Program Files\Microsoft Visual Studio\2017\Enterprise
#
#   Note: if pre-Visual Studio 2017 installation folder has non-default name, it is not possible to
#     deduce Visual C++ version automatically - VC_VER must be specified explicitly, e.g.:
#     VC_VER=14.0
#
# 2) MSVC - Visual C++ tools path (without quotes),
#   may be specified instead of VS variable (VS is ignored then), e.g.:
#     MSVC=C:\Program Files\Microsoft Visual Studio\VC98
#     MSVC=C:\Program Files\Microsoft Visual C++ Toolkit 2003
#     MSVC=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7
#     MSVC=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC
#     MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC
#     MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC
#     MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503
#
# 3) VCCL - path to Visual C++ compiler cl.exe
#   may be specified instead of VS or MSVC variables (they are ignored then), e.g.:
#     VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\bin\cl.exe
#     VCCL=C:\Program Files\Microsoft SDKs\Windows\v6.0\VC\Bin\x64\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe
#
# 4) VC_VER - Visual C++ version, e.g: 6.0 7.0 7.1 8.0 9.0 10.0 11.0 12.0 14.0 14.10 14.11
#   may be specified explicitly if it's not possible to deduce VC_VER automatically
#
#################################################################################################################

# get paths to "Program Files" and "Program Files (x86)" directories
# result: C:/Program?Files C:/Program?Files?(x86)
GET_PROGRAM_FILES_DIRS = $(call uniq,$(foreach \
  v,ProgramW6432 ProgramFiles ProgramFiles$(open_brace)x86$(close_brace),$(if \
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

# for Visual C++ compiler from SDK 6.0 (Visual C++ 8.0 of Visual Studio 2005)
# determine MSVC++ tools prefix for given CPU
# note: $(TCPU) _must_ match $(CPU)
#
# CPU  |  x86    x86_64
# -----|-------------------------------------
# pref | <none>   x64/
#
VC_TOOL_PREFIX_SDK6 := $(addsuffix /,$(filter-out x86,$(TCPU:x86_64=x64)))

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
VC_VER:=

# subdirectory of MSVC++ libraries: <empty> or onecore
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_ONECORE:=

# subdirectory of MSVC++ libraries: <empty> or store
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_STORE:=

# we need next MSVC++ variables: VC_VER, VCCL, VCLIBPATH and VCINCLUDE
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

# find file in the paths by static pattern
# $1 - file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_FIND_FILE = $(if $2,$(call VS_FIND_FILE1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$1)))
VS_FIND_FILE1 = $(if $3,$3,$(call VS_FIND_FILE,$1,$(wordlist 2,999999,$2)))

# find file in the paths by pattern dependent on the path where the search is done
# $1 - name of macro that returns file to find, e.g.: VC/bin/cl.exe (possibly be a mask, like: VC/Tools/MSVC/*/bin/HostX86/x86/cl.exe)
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result (may be a list): C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
# note: macro $1 may use $(firstword $2) - path where the search is done
VS_FIND_FILE_P = $(if $2,$(call VS_FIND_FILE_P1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$($1))))
VS_FIND_FILE_P1 = $(if $3,$3,$(call VS_FIND_FILE_P,$1,$(wordlist 2,999999,$2)))

# there may be more than one compiler found - take the newer one, e.g.
#  $1=C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Enterprise/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
#  $2=bin/HostX86/x64/cl.exe
# result: C:/Program Files/Microsoft Visual Studio/2017/Enterprise/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
VS_2017_SELECT_LATEST_CL = $(subst ?, ,$(patsubst ?%,%$2,$(filter %/$(patsubst vc_tools_msvc_%,%,$(lastword $(sort $(filter \
  vc_tools_msvc_%,$(subst /, ,$(subst /vc/tools/msvc/,/vc_tools_msvc_,$(tolower)))))))/,$(subst $2, ,?$(subst $(space),?,$1)))))

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
      VCCL := $(call VS_2017_SELECT_LATEST_CL,$(call \
        VS_FIND_FILE,VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(VS_COMNS_2017)),$(VCCL_2017_PREFIXED))

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

  # at last, check registry - to define VCCL

  # query path to Visual Studio in registry
  # $1 - sub key, e.g. VC7 or VS7
  # $2 - parameter name, e.g.: 14.0
  # result: for VC7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/VC/
  # result: for VS7 - C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/
  # note: assume with trailing backslash
  VS_REG_QUERY = $(subst \,/,$(subst ?$2?REG_SZ?,,$(call VS_REG_QUERY_WOW6432,$1,$2,$(lastword \
    $(subst HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\VisualStudio\SxS\$1, ,$(subst \
    $(space),?,$(strip $(shell reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\SxS\$1" /v "$2" 2>NUL))))))))

  # check Wow6432Node (on Win64)
  # $1 - sub key, e.g. VC7 or VS7
  # $2 - parameter name, e.g.: 14.0
  # $3 - result of reg query
  VS_REG_QUERY_WOW6432 = $(if $3,$3,$(if $(IS_WIN_64),$(lastword \
    $(subst HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\$1, ,$(subst \
    $(space),?,$(strip $(shell reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\$1" /v "$2" 2>NUL)))))))

  # select appropriate compiler for the $(CPU)
  VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

  VCCL := $(call VS_SEARCH_CL1,$(call VS_2017_SELECT_LATEST_CL,$(call \
    VS_FIND_FILE,Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(call VS_REG_QUERY,VC7,15.0)),$(VCCL_2017_PREFIXED)))

  # $1 - result of $(VS_2017_SELECT_LATEST_CL)
  VS_SEARCH_CL1 = $(if $1,$1,$(call VS_SEARCH_CL2,$(call VS_2017_SELECT_LATEST_CL,$(call \
    VS_FIND_FILE,VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(call VS_REG_QUERY,VCS,15.0)),$(VCCL_2017_PREFIXED))))

  # $1 - result of $(VS_2017_SELECT_LATEST_CL)
  VS_SEARCH_CL2 = $(if $1,$1,$(call VS_SEARCH_CL3,$(call VS_SEARCH_CL_2005,8.0 9.0 10.0 11.0 12.0 14.0)))

  VS_SEARCH_CL3 = $(if $1,$1,$(call VS_SEARCH_CL4,$(call VS_SEARCH_CL_DOT_NET,7.0 7.1)))



  # check "Program Files" and "Program Files (x86)" directories
  VCCL := $(call VS_SEARCH_CL,$(addsuffix /,$(GET_PROGRAM_FILES_DIRS)))

  # find cl.exe, checking the latest Visual Studio versions first
  # $1 - C:/Program?Files/ C:/Program?Files?(x86)/
  # first look for C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
  VS_SEARCH_CL = $(call VS_SEARCH_CL1,$1,$(call VS_2017_SELECT_LATEST_CL,$(call \
    VS_FIND_FILE,Microsoft\ Visual\ Studio/*/*/VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$1),$(VCCL_2017_PREFIXED)))

  # $1 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $2 - result of $(VS_2017_SELECT_LATEST_CL)
  VS_SEARCH_CL1 = $(if $2,$2,$(call VS_SEARCH_CL2,$1,$(call VS_REG_QUERY,VC7,15.0)))

  # $1 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $2 - result of $(call VS_REG_QUERY,VC7,15.0), e.g.: C:\Program?Files?(x86)\Microsoft?Visual?Studio\2017\Community\VC\
  # note: assume with trailing slash
  VS_SEARCH_CL2 = $(call VS_SEARCH_CL3,$1,$(if $2,$(call VS_2017_SELECT_LATEST_CL,$(call \
    VS_FIND_FILE,Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(subst \,/,$2)),$(VCCL_2017_PREFIXED))))

  # $1 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $2 - result of $(VS_2017_SELECT_LATEST_CL)
  VS_SEARCH_CL3 = $(if $2,$2,$(call VS_SEARCH_CL4,$1,$(call VS_REG_QUERY,VS7,15.0)))

  # $1 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $2 - result of $(call VS_REG_QUERY,VS7,15.0), e.g.: C:\Program?Files?(x86)\Microsoft?Visual?Studio\2017\Community\
  # note: assume with trailing slash
  VS_SEARCH_CL4 = $(call VS_SEARCH_CL5,$1,$(if $2,$(call VS_2017_SELECT_LATEST_CL,$(call \
    VS_FIND_FILE,VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(subst \,/,$2)),$(VCCL_2017_PREFIXED))))

  # $1 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $2 - result of $(VS_2017_SELECT_LATEST_CL)
  VS_SEARCH_CL5 = $(if $2,$2,$(VS_SEARCH_OLD_CL))

  # get list of Visual Studio versions
  # $1 - C:/Program?Files/ C:/Program?Files?(x86)/
  # result: .NET .NET?2003 8 9.0 10.0 11.0 12.0 14.0
  VS_FIND_VERSIONS = $(patsubst %/.,%,$(foreach d,$1,$(subst ?$dMicrosoft?Visual?Studio?, ,?$(subst \
    $(space),?,$(wildcard $(subst ?,\ ,$d)Microsoft\ Visual\ Studio\ */.)))))

  # filter and sort versions of Visual Studio 2005-2015
  # $1 - .NET .NET?2003 8 9.0 10.0 11.0 12.0 14.0
  # result: 14.0 12.0 11.0 10.0 9.0 8
  VS_SORT_VERSIONS_2005 = $(addsuffix .0,$(call reverse,$(call sort_numbers,$(subst \
    .0,,$(filter 14.0 12.0 11.0 10.0 9.0,$1))))) $(filter 8,$1)

  # search cl.exe, checking the latest Visual Studio version directories first
  # $1 - C:/Program?Files/ C:/Program?Files?(x86)/
  # result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
  VS_SEARCH_OLD_CL = $(call VS_SEARCH_OLD_CL1,$(VS_FIND_VERSIONS),$1)

  # $2 - C:/Program?Files/Microsoft?Visual?Studio?14.0/ C:/Program?Files?(x86)/Microsoft?Visual?Studio?14.0/
  # result: VC/bin/x86_arm/cl.exe
  VCCL_2005_PATTERN_GEN = VC/bin/$(call VC_TOOL_PREFIX_2005,$(CPU),$(call VS_SELECT_CPU,$(firstword $2)))cl.exe

  # search C++ compiler of Visual Studio 2005-2015
  # $1 - .NET .NET?2003 8 9.0 10.0 11.0 12.0 14.0
  # $2 - C:/Program?Files/ C:/Program?Files?(x86)/
  VS_SEARCH_OLD_CL1 = $(call VS_SEARCH_OLD_CL2,$1,$2,$(call \
    VS_FIND_FILE_P,VCCL_2005_PATTERN_GEN,$(foreach v,$(VS_SORT_VERSIONS_2005),$(addsuffix Microsoft?Visual?Studio?$v/,$2))))

  # check for Visual C++ compiler bundled in SDK6.0
  # $1 - .NET .NET?2003 8 9.0 10.0 11.0 12.0 14.0
  # $2 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $3 - result of $(VS_FIND_FILE_P)
  VS_SEARCH_OLD_CL2 = $(if $3,$3,$(if \
    $(filter $(CPU),$(TCPU)),$(call VS_SEARCH_OLD_CL3,$1,$2,$(call \
    VS_FIND_FILE,VC/Bin/$(VC_TOOL_PREFIX_SDK6)cl.exe,$(addsuffix Microsoft?SDKs/Windows/v6.0/,$2)))))

  # search Visual C++ .NET 2003 compiler
  # $1 - .NET .NET?2003 8 9.0 10.0 11.0 12.0 14.0
  # $2 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $3 - result of $(VS_FIND_FILE)
  VS_SEARCH_OLD_CL3 = $(if $3,$3,$(if \
    $(filter $(VS_CPU),$(CPU)),$(call VS_SEARCH_OLD_CL4,$1,$2,$(if $(filter .NET?2003,$1),$(call \
    VS_FIND_FILE,Vc7/bin/cl.exe,$(addsuffix Microsoft?Visual?Studio?.NET?2003/,$2))))))

  # check for Visual C++ compiler of Microsoft Visual C++ Toolkit 2003
  # $1 - .NET .NET?2003 8 9.0 10.0 11.0 12.0 14.0
  # $2 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $3 - result of $(VS_FIND_FILE)
  VS_SEARCH_OLD_CL4 = $(if $3,$3,$(call VS_SEARCH_OLD_CL5,$1,$2,$(call \
    VS_FIND_FILE,bin/cl.exe,$(addsuffix Microsoft?Visual?C++?Toolkit?2003/,$2))))

  # search Visual C++ .NET compiler
  # $1 - .NET .NET?2003 8 9.0 10.0 11.0 12.0 14.0
  # $2 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $3 - result of $(VS_FIND_FILE)
  VS_SEARCH_OLD_CL5 = $(if $3,$3,$(call VS_SEARCH_OLD_CL6,$2,$(if $(filter .NET,$1),$(call \
    VS_FIND_FILE,Vc7/bin/cl.exe,$(addsuffix Microsoft?Visual?Studio?.NET/,$2)))))

  # at last, check for Visual C++ 6.0 compiler
  # $1 - C:/Program?Files/ C:/Program?Files?(x86)/
  # $2 - result of $(VS_FIND_FILE)
  VS_SEARCH_OLD_CL6 = $(if $2,$2,$(call \
    VS_FIND_FILE,VC98/Bin/cl.exe,$(addsuffix Microsoft?Visual?Studio/,$1)))

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
    VS_DEDUCE_VCCL = $(call VS_2017_SELECT_LATEST_CL,$(if $1,$1,$(wildcard \
      $(VS_WILD)VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED))),$(VCCL_2017_PREFIXED))

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
      VCCL := $(call VS_2017_SELECT_LATEST_CL,$(wildcard $(MSVC_WILD)Tools/MSVC/*/$(VCCL_2017_PREFIXED)),$(VCCL_2017_PREFIXED))

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

# by default, allow adjusting PATH environment variable
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
$(call SET_GLOBAL,GET_PROGRAM_FILES_DIRS VS_CPU VS_CPU64 IS_WIN_64 \
  VC_VER VCCL VC_LIB_TYPE_ONECORE VC_LIB_TYPE_STORE VCLIBPATH VCINCLUDE VCLIB VCLINK TVCCL TVCLIBPATH TVCLIB TVCLINK \
  VCCL_PATH_APPEND)
