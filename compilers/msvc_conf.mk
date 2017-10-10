#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler auto-configuration (app-level), included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# try to autoconfigure:
#  Visual C++ version, paths to compiler, linker, system libraries and headers
#  - only if they are not defined in project configuration makefile or in command line
#
# VC_VER    - MSVC++ version, known values see in $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk
# VCCL      - path to cl.exe                (must be in double-quotes if contains spaces)
# VCLIB     - path to lib.exe               (must be in double-quotes if contains spaces)
# VCLINK    - path to link.exe              (must be in double-quotes if contains spaces)
# VCLIBPATH - paths to Visual C++ libraries (spaces must be replaced with ?)
# VCINCLUDE - paths to Visual C++ headers   (spaces must be replaced with ?)
# UMLIBPATH - paths to user-mode libraries  (spaces must be replaced with ?)
# UMINCLUDE - paths to user-mode headers    (spaces must be replaced with ?)
#
# example:
#
# VC_VER    := 14.0
# VCCL      := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
# VCLIB     := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\lib.exe"
# VCLINK    := "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\link.exe"
# VCLIBPATH := C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\VC\lib
# VCINCLUDE := C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\VC\include
# UMLIBPATH := C:\Program?Files?(x86)\Windows?Kits\10\lib\10.0.15063.0\um\x86
# UMINCLUDE := C:\Program?Files?(x86)\Windows?Kits\10\Include\10.0.15063.0\ucrt

#################################################################################################################
# input for autoconfiguration:
#
# 1) WINVARIANT - Windows variant for which to autoconfigure WINVER_DEFINES and SUBSYSTEM_VER
#   by default WINVARIANT=WINXP, other possible values: $(WINVARIANTS)
#
# 2) VS - Visual Studio installation path (without quotes),
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
# 3) MSVC - Visual C++ tools path (without quotes),
#   may be specified instead of VS variable (VS is ignored then), e.g.:
#     MSVC=C:\Program Files\Microsoft Visual Studio\VC98
#     MSVC=C:\Program Files\Microsoft Visual C++ Toolkit 2003
#     MSVC=C:\Program Files\Microsoft Visual Studio .NET 2003\VC7
#     MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC
#     MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC
#     MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503
#
# 4) VCCL - path to Visual C++ compiler cl.exe
#   may be specified instead of VS or MSVC variables (they are ignored then), e.g.:
#     VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio .NET 2003\VC7\bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe
#     VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe
#
# 5) VC_VER - Visual C++ version, e.g: 6.0, 7.0, 7.1, 8.0, 9.0, 10.0, 11.0, 12.0, 14.0, 14.10, 14.11
#   may be specified explicitly if it's not possible to deduce VC_VER automatically
#
#################################################################################################################

# By default, autoconfigure for Windows XP
WINVARIANT := WINXP

# supported Windows variants for autoconfiguration
WINVARIANTS := WINXP WINV WIN7 WIN8 WIN81 WIN10

# WINVER_DEFINES - specifies version of Windows API to compile with
# note: WINVER_DEFINES may be defined as <empty> in project configuration makefile or in command line
ifneq (,$(filter undefined environment,$(origin WINVER_DEFINES)))
ifeq (WIN10,$(WINVARIANT))
WINVER_DEFINES := WINVER=0x0A00 _WIN32_WINNT=0x0A00
else ifeq (WIN81,$(WINVARIANT))
WINVER_DEFINES := WINVER=0x0603 _WIN32_WINNT=0x0603
else ifeq (WIN8,$(WINVARIANT))
WINVER_DEFINES := WINVER=0x0602 _WIN32_WINNT=0x0602
else ifeq (WIN7,$(WINVARIANT))
WINVER_DEFINES := WINVER=0x0601 _WIN32_WINNT=0x0601
else ifeq (WINV,$(WINVARIANT))
WINVER_DEFINES := WINVER=0x0600 _WIN32_WINNT=0x0600
else ifeq (WINXP,$(WINVARIANT))
WINVER_DEFINES := WINVER=0x0501 _WIN32_WINNT=0x0501
else
# WINVER_DEFINES should be defined in project configuration makefile or in command line
$(warning unable to determine WINVER_DEFINES for WINVARIANT=$(WINVARIANT), supported WINVARIANTS=$(WINVARIANTS))
WINVER_DEFINES:=
endif
$(warning autoconfigured: WINVER_DEFINES=$(WINVER_DEFINES))
endif # WINVER_DEFINES

# SUBSYSTEM_VER - minimum Windows version required to run built targets
# note: SUBSYSTEM_VER may be defined as <empty> in project configuration makefile or in command line
ifneq (,$(filter undefined environment,$(origin SUBSYSTEM_VER)))
ifeq (WIN10,$(WINVARIANT))
SUBSYSTEM_VER := 6.03
else ifeq (WIN81,$(WINVARIANT))
SUBSYSTEM_VER := 6.03
else ifeq (WIN8,$(WINVARIANT))
SUBSYSTEM_VER := 6.02
else ifeq (WIN7,$(WINVARIANT))
SUBSYSTEM_VER := 6.01
else ifeq (WINV,$(WINVARIANT))
SUBSYSTEM_VER := 6.00
else ifeq (WINXP,$(WINVARIANT))
SUBSYSTEM_VER := $(if $(CPU:%64=),5.01,5.02)
else
# SUBSYSTEM_VER may be defined in project configuration makefile or in command line
$(warning unable to determine SUBSYSTEM_VER for WINVARIANT=$(WINVARIANT), supported WINVARIANTS=$(WINVARIANTS))
SUBSYSTEM_VER:=
endif
$(warning autoconfigured: SUBSYSTEM_VER=$(SUBSYSTEM_VER))
endif # SUBSYSTEM_VER

# for Visual Studio 2005-2015
# determine MSVC++ tools prefix for given TCPU/CPU combination
#
# TCPU\CPU |  x86        x86_64      arm
# ---------|---------------------------------
# x86      | <none>     x86_amd64/ x86_arm/
# x86_64   | amd64_x86/ amd64/     amd64_arm/
#
# $1 - target CPU
VC_TOOL_PREFIX_2005 = $(addsuffix /,$(filter-out x86_x86,$(subst amd64_amd64,amd64,$(TCPU:x86_64=amd64)_$(1:x86_64=amd64))))
VC_LIB_PREFIX_2005 = $(addprefix \,$(filter-out x86,$(1:x86_64=amd64)))

# for Visual Studio 2017
# determine MSVC++ tools prefix for given TCPU/CPU combination
#
# TCPU\CPU |   x86          x86_64        arm
# ---------|---------------------------------------
# x86      | HostX86/x86/ HostX86/x64/ HostX86/arm/
# x86_64   | HostX64/x86/ HostX64/x64/ HostX64/arm/
#
# $1 - target CPU
VC_TOOL_PREFIX_2017 = Host$(subst x,X,$(TCPU:x86_64=x64))/$(1:x86_64=x64)/
VC_LIB_PREFIX_2017 = \$(1:x86_64=x64)

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

# deduce values of VCLIB and VCLIB from $(VCCL)
VCLIB  = $(call ifaddq,$(subst ?, ,$(addsuffix lib.exe,$(dir $(patsubst "%",%,$(subst $(space),?,$(VCCL)))))))
VCLINK = $(call ifaddq,$(subst ?, ,$(addsuffix link.exe,$(dir $(patsubst "%",%,$(subst $(space),?,$(VCCL)))))))

# reset VC_VER, if it's not defined in project configuration makefile or in command line
VC_VER:=

# subdirectory of MSVC++ libraries: <empty> or onecore
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_ONECORE:=

# subdirectory of MSVC++ libraries: <empty> or store
# note: for Visual Studio 14.0 and later
VC_LIB_TYPE_STORE:=

# we need next MSVC++ variables
# (they are may be defined either in project configuration makefile or in command line)
# note: VCLIBPATH or VCINCLUDE may be defined as <empty>
ifneq (,$(filter undefined environment,$(foreach v,VCLIBPATH VCINCLUDE,$(origin $v)))$(if $(VCCL),,1)$(if $(VC_VER),,2))

# reset variables, if they are not defined in project configuration makefile or in command line
VS:=
MSVC:=
VCLIBPATH:=
VCINCLUDE:=

#  VS may be defined as                                   compiler path
# -----------------------------------------------------|------------------------
#  C:\Program Files\Microsoft Visual Studio            |  \VC98\Bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio .NET       |  \VC7\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio .NET 2003  |  \VC7\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 8          |  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 9.0        |  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 10.0       |  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 11.0       |  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 12.0       |  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 14.0       |  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio\2017       |  \Community\VC\Tools\MSVC\14.10.25017\bin\HostX86\x86\cl.exe
#  C:\Program Files\Microsoft Visual Studio\2017       |  \Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe

# CPU-specific paths to compiler
# ---------------------------------------------------------------------
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64_arm\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\amd64_x86\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe
# C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_arm\cl.exe
#
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\arm\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x64\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\arm\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x64\cl.exe
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe

# CPU-specific paths to libraries
# ---------------------------------------------------------------------
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\amd64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\amd64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\onecore\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\amd64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio 14.0\VC\lib\store\msvcrt.lib
#
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x86\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x86\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\arm\store\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\store\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x86\store\msvcrt.lib

# find file in the paths
# $1 - file to find, e.g. VC/bin/cl.exe
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
# result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_FIND_FILE = $(if $2,$(call VS_FIND_FILE1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))$1)))
VS_FIND_FILE1 = $(if $3,$3,$(call VS_FIND_FILE,$1,$(wordlist 2,999999,$2)))

# there may be more than one compiler found - take the newer one, e.g.
#  $1=C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#     C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
#  $2=bin/HostX86/x64/cl.exe
VS_2017_SELECT_LATEST_CL = $(subst ?, ,$(addsuffix $(patsubst vc_tools_msvc_%,%,$(lastword \
  $(sort $(filter vc_tools_msvc_%,$(subst /, ,$(subst /vc/tools/msvc/,/vc_tools_msvc_,$(tolower)))))))/$2,$(dir \
  $(firstword $(subst /$2, ,$(subst $(space),?,$1))))))

ifndef VCCL
ifndef MSVC
ifndef VS

  # Check for toolkit of Visual Studio 2003
  # VCToolkitInstallDir=C:\Program Files\Microsoft Visual C++ Toolkit 2003
  ifneq (undefined,$(origin VCToolkitInstallDir))
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
  #  VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 12.0\
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

  # try to extract Visual Studio installation paths from values of VS*COMNTOOLS variables,
  #  e.g. VS140COMNTOOLS=C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools\
  #   or  VS150COMNTOOLS=C:\Program Files\Microsoft Visual Studio\2017\Community\Common7\Tools\
  # note: return sorted values, starting from the greatest tools version
  VS_COMN_VERS := $(call reverse,$(call sort_numbers,$(patsubst VS%COMNTOOLS,%,$(filter VS%COMNTOOLS,$(.VARIABLES)))))

  ifdef VS_COMN_VERS

    # note: result will look like:
    #  C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
    VS_COMNS := $(subst \,/,$(dir $(patsubst %\,%,$(dir $(patsubst %\,%,$(foreach \
      v,$(VS_COMN_VERS),$(subst $(space),?,$(VS$vCOMNTOOLS))))))))

    ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),150))
      # select appropriate compiler for the $(CPU)
      VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

      # try to find Visual Studio 2017 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
      # C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
      VCCL := $(call VS_2017_SELECT_LATEST_CL,$(call \
        VS_FIND_FILE,VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(VS_COMNS)),$(VCCL_2017_PREFIXED))
    endif

    ifndef VCCL
      ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),80))
        # try to find Visual Studio 2005 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
        # C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
        # C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
        VCCL := $(call VS_FIND_FILE,VC/bin/$(call VC_TOOL_PREFIX_2005,$(CPU))cl.exe,$(VS_COMNS))
      endif

      ifndef VCCL
        ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),70))
          # try to find Visual Studio .NET 2003 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
          # C:/Program Files/Microsoft Visual Studio .NET 2003/VC7/bin\cl.exe
          VCCL := $(call VS_FIND_FILE,VC7/bin/cl.exe,$(VS_COMNS))
        endif

        ifndef VCCL
          # try to find Visual Studio 6.0 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
          # C:/Program Files/Microsoft Visual Studio/VC98/Bin/cl.exe
          VCCL := $(call VS_FIND_FILE,VC98/Bin/cl.exe,$(VS_COMNS))
        endif
      endif
    endif

    ifdef VCCL
      VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))
      $(warning autoconfigured: VCCL=$(VCCL))
    endif

  endif
endif
endif
endif

ifndef VCCL
ifndef MSVC
ifndef VS
  $(error unable to find C++ complier, please specify either VS, MSVC or VCCL, e.g.:$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio 14.0$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio\2017$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio\2017\Community$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\VC98$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe)
endif
endif
endif

ifndef VCCL
ifndef MSVC

# VS=C:\Program Files\Microsoft Visual Studio
# VS=C:\Program Files\Microsoft Visual Studio .NET 2003
# VS=C:\Program Files\Microsoft Visual Studio 14.0
# VS=C:\Program Files\Microsoft Visual Studio\2017
# VS=C:\Program Files\Microsoft Visual Studio\2017\Enterprise
# VS path must use forward slashes, there must be no trailing slash
VS_PARENT0 := $(patsubst %\,%,$(subst /,\,$(subst $(space),?,$(VS))))
VS_ENTRY0l := $(call tolower,$(notdir $(VS_PARENT0)))

# define MSVC
ifeq (vc98,$(MSVC_ENTRY0l))
  # MSVC=C:\PROG~FBU\MICR~2ZC\VC98
  # MSVC=C:\Program Files\Microsoft Visual Studio\VC98
  VCCL := $(call ifaddq,$(MSVC)\Bin\cl.exe)

else ifeq (microsoft?visual?c++?toolkit?2003,$(MSVC_ENTRY0l))




# 1) check if compiler is specified - define VC_VER, VCLIBPATH and VCINCLUDE from it
ifdef VCCL

# VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
# VCCL="C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe"
# VCCL="C:\Program Files\Microsoft Visual Studio .NET\VC7\bin\cl.exe"
# VCCL="C:\Program Files\Microsoft Visual Studio .NET 2003\VC7\bin\cl.exe"
# VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
# VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
# VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
VCCL_PARENT1 := $(patsubst %\,%,$(dir $(patsubst "%",%,$(subst $(space),?,$(VCCL)))))
VCCL_PARENT2 := $(patsubst %\,%,$(dir $(VCCL_PARENT1)))

ifeq (bin,$(call tolower,$(notdir $(VCCL_PARENT1))))
  # VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
  # VCCL="C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe"
  # VCCL="C:\Program Files\Microsoft Visual Studio .NET\VC7\bin\cl.exe"
  # VCCL="C:\Program Files\Microsoft Visual Studio .NET 2003\VC7\bin\cl.exe"
  # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"

  ifndef VC_VER
    VCCL_ENTRY2l := $(call tolower,$(notdir $(VCCL_PARENT2)))

    ifeq (vc98,$(VCCL_ENTRY2l))
      # VCCL="C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe"
      VC_VER := 6.0

    else ifeq (microsoft?visual?c++?toolkit?2003,$(VCCL_ENTRY2l))
      # VCCL="C:\Program Files\Microsoft Visual C++ Toolkit 2003\bin\cl.exe"
      VC_VER := 7.1

    else ifeq (vc7,$(VCCL_ENTRY2l))
      # VCCL="C:\Program Files\Microsoft Visual Studio .NET\VC7\bin\cl.exe"
      # VCCL="C:\Program Files\Microsoft Visual Studio .NET 2003\VC7\bin\cl.exe"
      VCCL_ENTRY3l := $(call tolower,$(notdir $(patsubst %\,%,$(dir $(VCCL_PARENT2)))))

      ifeq (microsoft?visual?studio?.net?2003,$(VCCL_ENTRY3l))
        VC_VER := 7.1
      else ifeq (microsoft?visual?studio?.net,$(VCCL_ENTRY3l))
        VC_VER := 7.0
      endif

    else ifeq (vc,$(VCCL_ENTRY2l))
      # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
      VCCL_ENTRY3l := $(call tolower,$(notdir $(patsubst %\,%,$(dir $(VCCL_PARENT2)))))

      ifneq (,$(filter microsoft?visual?studio?%,$(VCCL_ENTRY3l)))
        VC_VER := $(lastword $(subst ?, ,$(VCCL_ENTRY3l)))
      endif

    endif # vc

    ifdef VC_VER
      $(warning autoconfigured: VC_VER=$(VC_VER))
    endif

  endif # !VC_VER

  ifndef VCLIBPATH
    VCLIBPATH := $(VCCL_PARENT2)\lib
    $(warning autoconfigured: VCLIBPATH=$(VCLIBPATH))
  endif

  ifndef VCINCLUDE
    VCINCLUDE := $(VCCL_PARENT2)\include
    $(warning autoconfigured: VCINCLUDE=$(VCINCLUDE))
  endif

else
  # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
  # VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
  VCCL_PARENT3 := $(patsubst %\,%,$(dir $(VCCL_PARENT2)))

  ifeq (bin,$(call tolower,$(notdir $(VCCL_PARENT2))))
    # VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"

    # check that CPU and TCPU values match the compiler
    ifneq ($(call VC_TOOL_PREFIX_2005,$(CPU)),$(call tolower,$(notdir $(VCCL_PARENT1)))/)
      $(warning combination of TCPU=$(TCPU) and CPU=$(CPU) does not match selected compiler VCCL=$(VCCL))
    endif

    ifndef VC_VER

      ifeq (vc,$(call tolower,$(notdir $(VCCL_PARENT3))))
        VCCL_ENTRY4l := $(call tolower,$(notdir $(patsubst %\,%,$(dir $(VCCL_PARENT3)))))

        ifneq (,$(filter microsoft?visual?studio?%,$(VCCL_ENTRY4l)))
          VC_VER := $(lastword $(subst ?, ,$(VCCL_ENTRY4l)))
        endif

      endif # vc

      ifdef VC_VER
        $(warning autoconfigured: VC_VER=$(VC_VER))
      endif

    endif # !VC_VER

    ifndef VCLIBPATH
      VCLIBPATH := $(VCCL_PARENT3)\lib$(VC_LIB_TYPE_ONECORE:%=\%)$(VC_LIB_TYPE_STORE:%=\%)$(call VC_LIB_PREFIX_2005,$(CPU))
      $(warning autoconfigured: VCLIBPATH=$(VCLIBPATH))
    endif

    ifndef VCINCLUDE
      VCINCLUDE := $(VCCL_PARENT3)\include
      $(warning autoconfigured: VCINCLUDE=$(VCINCLUDE))
    endif

  else ifeq (bin,$(call tolower,$(notdir $(VCCL_PARENT3))))
    # VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"

    # check that CPU and TCPU values match the compiler
    ifneq ($(call VC_TOOL_PREFIX_2017,$(CPU)),$(call tolower,$(notdir $(VCCL_PARENT2)))/)
      $(warning combination of TCPU=$(TCPU) and CPU=$(CPU) does not match selected compiler VCCL=$(VCCL))
    endif

    VCCL_PARENT4 := $(patsubst %\,%,$(dir $(VCCL_PARENT3)))

    ifndef VC_VER

      ifneq (,$(filter %\vc\tools\msvc\,$(call tolower,$(dir $(VCCL_PARENT4)))))
        VC_VER := $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(notdir $(VCCL_PARENT4)))))
      endif

      ifdef VC_VER
        $(warning autoconfigured: VC_VER=$(VC_VER))
      endif

    endif # !VC_VER

    ifndef VCLIBPATH
      # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\msvcrt.lib
      # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\store\msvcrt.lib
      # C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x64\msvcrt.lib
      VCLIBPATH := $(VCCL_PARENT4)\lib$(VC_LIB_TYPE_ONECORE:%=\%)$(call VC_LIB_PREFIX_2017,$(CPU))$(VC_LIB_TYPE_STORE:%=\%)
      $(warning autoconfigured: VCLIBPATH=$(VCLIBPATH))
    endif

    ifndef VCINCLUDE
      VCINCLUDE := $(VCCL_PARENT4)\include
      $(warning autoconfigured: VCINCLUDE=$(VCINCLUDE))
    endif

  else
    $(error unable to autoconfigure for VCCL=$(VCCL))
  endif
endif

ifndef VC_VER
$(error unable to determine Visual C++ version for VCCL=$(VCCL), please specify it explicitly, e.g. VC_VER=14.1)
endif

else # !VCCL

# 2) try to define VCCL from MSVC

# if MSVC is not defined, try to define it from the environment, but only if VS is not defined 
ifndef MSVC
ifndef VS

  # Check for toolkit of Visual Studio 2003
  # VCToolkitInstallDir=C:\Program Files\Microsoft Visual C++ Toolkit 2003
  ifneq (undefined,$(origin VCToolkitInstallDir))
    MSVC := $(VCToolkitInstallDir)

  # for Visual Studio 6.0, vcvars32.bat defines MSVCDir, e.g.:
  # MSVCDir=C:\PROG~FBU\MICR~2ZC\VC98
  else ifneq (undefined,$(origin MSVCDir))
    MSVC := $(MSVCDir)

  endif
endif
endif

ifdef MSVC

# MSVC path must use forward slashes, there must be no trailing slash
override MSVC := $(subst ?,$(space),$(patsubst %\,%,$(subst /,\,$(subst $(space),?,$(MSVC)))))

# MSVC=C:\PROG~FBU\MICR~2ZC\VC98
# MSVC=C:\Program Files\Microsoft Visual Studio\VC98
# MSVC=C:\Program Files\Microsoft Visual C++ Toolkit 2003
# MSVC=C:\Program Files\Microsoft Visual Studio .NET 2003\VC7
# MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC
# MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC
# MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503
MSVC_PARENT0 := $(subst $(space),?,$(MSVC))
MSVC_ENTRY0l := $(call tolower,$(notdir $(MSVC_PARENT0)))

# define VCCL
ifeq (vc98,$(MSVC_ENTRY0l))
  # MSVC=C:\PROG~FBU\MICR~2ZC\VC98
  # MSVC=C:\Program Files\Microsoft Visual Studio\VC98
  VCCL := $(call ifaddq,$(MSVC)\Bin\cl.exe)

else ifeq (microsoft?visual?c++?toolkit?2003,$(MSVC_ENTRY0l))
  # MSVC=C:\Program Files\Microsoft Visual C++ Toolkit 2003
  VCCL := $(call ifaddq,$(MSVC)\bin\cl.exe)

else ifeq (vc7,$(MSVC_ENTRY0l))
  # MSVC=C:\Program Files\Microsoft Visual Studio .NET\VC7
  # MSVC=C:\Program Files\Microsoft Visual Studio .NET 2003\VC7
  VCCL := $(call ifaddq,$(MSVC)\bin\cl.exe)

else ifeq (vc,$(MSVC_ENTRY0l))
  # MSVC=C:\Program Files\Microsoft Visual Studio 14.0\VC

  # select appropriate compiler for the $(CPU)
  VCCL := $(call ifaddq,$(MSVC)\bin\$(subst /,\,$(call VC_TOOL_PREFIX_2005,$(CPU)))cl.exe)

else ifneq (,$(filter %\vc\tools\msvc,$(call tolower,$(MSVC_PARENT0))))
  # MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC

  # select appropriate compiler for the $(CPU)
  VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

  # find cl.exe and choose the newest one
  VCCL := $(call VS_2017_SELECT_LATEST_CL,$(wildcard \
    $(subst $(space),\ ,$(subst \,/,$(MSVC)))/*/$(VCCL_2017_PREFIXED)),$(VCCL_2017_PREFIXED))

  ifndef VCCL
    $(error C++ compiler $(subst /,\,$(VCCL_2017_PREFIXED)) for TCPU/CPU combination $(TCPU)/$(CPU) was not found in $(MSVC))
  endif

  VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))

else ifneq (,$(filter %\vc\tools\msvc\,$(call tolower,$(dir $(MSVC_PARENT0)))))
  # MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503

  # select appropriate compiler for the $(CPU)
  VCCL := $(call ifaddq,$(MSVC)\bin\$(subst /,\,$(VC_TOOL_PREFIX_2017,$(CPU)))cl.exe)

else
  $(error unable to autoconfigure for MSVC=$(MSVC))

endif # vc

$(warning autoconfigured: VCCL=$(VCCL))

else # !MSVC

# 3) try to define MSVC or VCCL from VS

# if VS is not defined, try to define it from the environment
ifndef VS

  # VSINSTALLDIR is normally set by the vcvars32.bat, e.g.:
  #  VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 12.0\
  # note: likely with trailing slash
  ifneq (undefined,$(origin VSINSTALLDIR))
    VS := $(VSINSTALLDIR)

  else
    # try to extract Visual Studio installation paths from values of VS*COMNTOOLS variables,
    #  e.g. VS140COMNTOOLS=C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools\
    #   or  VS150COMNTOOLS=C:\Program Files\Microsoft Visual Studio\2017\Community\Common7\Tools\
    # note: return sorted values, starting from the greatest tools version
    VS_COMN_VERS := $(call reverse,$(call sort_numbers,$(patsubst VS%COMNTOOLS,%,$(filter VS%COMNTOOLS,$(.VARIABLES)))))

    ifdef VS_COMN_VERS

      # note: result will look like:
      #  C:/Program?Files/Microsoft?Visual?Studio/2017/Community/ C:/Program?Files/Microsoft?Visual?Studio?14.0/
      VS_COMNS := $(subst \,/,$(dir $(patsubst %\,%,$(dir $(patsubst %\,%,$(foreach \
        v,$(VS_COMN_VERS),$(subst $(space),?,$(VS$vCOMNTOOLS))))))))

      ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),150))
        # select appropriate compiler for the $(CPU)
        VCCL_2017_PREFIXED := bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe

        # try to find Visual Studio 2017 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
        # C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
        VCCL := $(call VS_2017_SELECT_LATEST_CL,$(call \
	      VS_FIND_FILE,VC/Tools/MSVC/*/$(VCCL_2017_PREFIXED),$(VS_COMNS)),$(VCCL_2017_PREFIXED))
      endif

      ifndef VCCL
        ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),80))
          # select appropriate compiler for the $(CPU), e.g.:
          # VCCL_2005_PREFIXED := x86_arm/cl.exe
          # VCCL_2005_PREFIXED := cl.exe
          VCCL_2005_PREFIXED := $(call VC_TOOL_PREFIX_2005,$(CPU))cl.exe

          # try to find Visual Studio 2005 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
          # C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
          # C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
          VCCL := $(call VS_FIND_FILE,VC/bin/$(VCCL_2005_PREFIXED),$(VS_COMNS))
        endif

        ifndef VCCL
          ifeq (,$(call is_less,$(firstword $(VS_COMN_VERS)),70))
            # try to find Visual Studio .NET 2003 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
            # C:/Program Files/Microsoft Visual Studio .NET 2003/VC7/bin\cl.exe
            VCCL := $(call VS_FIND_FILE,VC7/bin/cl.exe,$(VS_COMNS))
          endif

          ifndef VCCL
            # try to find Visual Studio 6.0 cl.exe in the paths of VS*COMNTOOLS variables, e.g.:
            # C:/Program Files/Microsoft Visual Studio/VC98/Bin/cl.exe
            VCCL := $(call VS_FIND_FILE,VC7/bin/cl.exe,$(VS_COMNS))
          endif
        endif
      endif

    endif # VS_COMN_VERS
  endif

  ifndef VS
  ifndef VCCL
  $(error please specify Visual Studio installation path, e.g. VS=C:\Program Files\Microsoft Visual Studio 14.0)
  endif
  endif

endif










MSVC := $(VCCL_PARENT2)
VS   := $(VCCL_PARENT3)
else
VCCL_PARENT4 := $(patsubst %\,%,$(dir $(VCCL_PARENT3)))
ifneq (,$(filter bin biN bIn bIN Bin BiN BIn BIN,$(notdir $(VCCL_PARENT2))))
# VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
# MSVC=C:\Program?Files\Microsoft?Visual?Studio?14.0\VC
# VS=C:\Program?Files\Microsoft?Visual?Studio?14.0
MSVC := $(VCCL_PARENT3)
VS   := $(VCCL_PARENT4)
else ifneq (,$(filter bin biN bIn bIN Bin BiN BIn BIN,$(notdir $(VCCL_PARENT3))))
# VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
# MSVC=C:\Program?Files\Microsoft?Visual?Studio\2017\Community\VC\Tools\MSVC\14.11.25503
# VS=C:\Program?Files\Microsoft?Visual?Studio\2017\Community
MSVC := $(VCCL_PARENT4)
VS   := $(patsubst %\VC\Tools\MSVC\,%,$(dir $(VCCL_PARENT4)))
else
$(error bad path to Visual C++ compiler cl.exe: VCCL=$(VCCL))
endif
endif

endif # VCCL


# check environment variables to define MSVC
ifndef MSVC

# Check for toolkit of Visual Studio 2003
ifneq (undefined,$(origin VCToolkitInstallDir))
MSVC := $(VCToolkitInstallDir)
VC_VER_HINT := 7.1

# for Visual Studio 6.0, vcvars32.bat defines MSVCDir, e.g.:
# MSVCDir=C:\PROG~FBU\MICR~2ZC\VC98
else ifneq (undefined,$(origin MSVCDir))
MSVC := $(MSVCDir)
VC_VER_HINT := 6.0

endif
endif # !MSVC

# it is possible to deduce VS variable from MSVC value
ifdef MSVC

# MSVC=C:\PROG~FBU\MICR~2ZC\VC98
# MSVC=C:\Program Files\Microsoft Visual Studio\VC98
# MSVC=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC
# MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC
# MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503
MSVC_PARENT1 := $(patsubst %\,%,$(dir $(MSVC)))

ifneq (,$(filter VC98 vC98 Vc98 vc98 VC7 vC7 Vc7 vc7,$(notdir $(MSVC))))
VS := $(MSVC_PARENT1)
else ifneq (,$(filter VC7 vC7 Vc7 vc7,$(notdir $(MSVC))))
VS := $(MSVC_PARENT1)







# we need VS variable only if MSVC is not defined
ifndef MSVC

ifndef VS

# for Visual Studio 6.0, vcvars32.bat defines MSDevDir, e.g.:
# MSDevDir=C:\PROG~FBU\MICR~2ZC
ifneq (undefined,$(origin MSDevDir))
VS := $(MSDevDir)
VC_VER_HINT := 6.0

# VSINSTALLDIR is normally set by the vcvars32.bat, e.g. VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 12.0\
# note: likely with trailing slash
else ifneq (undefined,$(origin VSINSTALLDIR))
VS := $(VSINSTALLDIR)

endif
endif # !VS

ifndef VS

# try to extract Visual Studio installation paths from values of VS*COMNTOOLS variables,
#  e.g. VS140COMNTOOLS=C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools\
#   or  VS150COMNTOOLS=C:\Program Files\Microsoft Visual Studio\2017\Community\Common7\Tools\
# note: return sorted values, starting from the greatest tools version
# note: result will look like: C:/Program?Files/Microsoft?Visual?Studio/2017/Community C:/Program?Files/Microsoft?Visual?Studio?14.0
VS_COMNS := $(subst \,/,$(patsubst %\Common7\Tools\,%,$(foreach v,$(call reverse,$(call sort_numbers,$(patsubst \
  VS%COMNTOOLS,%,$(filter VS%COMNTOOLS,$(.VARIABLES))))),$(subst $(space),?,$(VS$vCOMNTOOLS)))))

# find file in the paths
# $1 - file to find, e.g. VC/bin/cl.exe
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community C:/Program?Files/Microsoft?Visual?Studio?14.0
# result: C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/cl.exe
VS_FIND_FILE = $(if $2,$(call VS_FIND_FILE1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))/$1)))
VS_FIND_FILE1 = $(if $3,$3,$(call VS_FIND_FILE,$1,$(wordlist 2,999999,$2)))

# try to find Visual Studio 2017 cl.exe in the paths of VS*COMNTOOLS variables,
# e.g. C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x86/cl.exe
VCCL_2017_PREFIXED := /bin/$(call VC_TOOL_PREFIX_2017,$(CPU))cl.exe
VCCL := $(call VS_FIND_FILE,VC/Tools/MSVC/*$(VCCL_2017_PREFIXED),$(VS_COMNS))

ifdef VCCL

# there may be more than one compiler found - take the latest one, e.g.
#  VCCL=C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.10.25017/bin/HostX86/x64/cl.exe \
#       C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.11.25503/bin/HostX86/x64/cl.exe
VCCL_2017_VER := $(patsubst VC_Tools_MSVC_%,%,$(lastword $(sort $(filter \
  VC_Tools_MSVC_%,$(subst /, ,$(subst /VC/Tools/MSVC/,/VC_Tools_MSVC_,$(VCCL)))))))

# ?aaa/14.10.25017/bin/HostX86/x64/cl.exe?bbb/14.11.25503/bin/HostX86/x64/cl.exe -> ?aaa/14.10.25017 ?bbb/14.11.25503
VCCL := $(call ifaddq,$(subst /,\,$(subst ?, ,$(patsubst ?%,%,$(filter %/VC/Tools/MSVC/$(VCCL_2017_VER),?$(subst \
  $(VCCL_2017_PREFIXED), ,$(subst $(space),?,$(VCCL))))))$(VCCL_2017_PREFIXED)))

$(warning autoconfigured: VCCL=$(VCCL))

# also define Visual C++ version
ifndef VC_VER
VC_VER := $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(VCCL_2017_VER))))
$(warning autoconfigured: VC_VER=$(VC_VER))
endif

else # !VCCL

# try to find Visual Studio 2005 and later cl.exe in the paths of VS*COMNTOOLS variables
# e.g. C:/Program Files/Microsoft Visual Studio 14.0/VC/bin/x86_arm/cl.exe
VCCL_2005_PREFIXED := $(call VC_TOOL_PREFIX_2005,$(CPU))cl.exe
VCCL := $(call VS_FIND_FILE,VC/bin/$(VCCL_2005_PREFIXED),$(VS_COMNS))

ifdef VCCL

# VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_arm\cl.exe"
VCCL := $(call ifaddq,$(subst /,\,$(VCCL)))

$(warning autoconfigured: VCCL=$(VCCL))

endif
endif # !VCCL
endif # !VS
endif # !MSVC
endif # !VCCL



$(error unable to find C++ complier, please specify either VS, MSVC or VCCL, e.g.:$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio$(newline)$(if \
,)VS=C:\Program Files (x86)\Microsoft Visual Studio 14.0$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio\2017$(newline)$(if \
,)VS=C:\Program Files\Microsoft Visual Studio\2017\Community$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\VC98$(newline)$(if \
,)MSVC=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC$(newline)$(if \
,)MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\VC98\Bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe$(newline)$(if \
,)VCCL=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe)





# 1) it is possible to deduce VS or MSVC value from value of VCCL
ifdef VCCL

# VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
# VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
# VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
VCCL_PARENT1 := $(patsubst %\,%,$(dir $(patsubst "%",%,$(subst $(space),?,$(VCCL)))))
VCCL_PARENT2 := $(patsubst %\,%,$(dir $(VCCL_PARENT1)))
VCCL_PARENT3 := $(patsubst %\,%,$(dir $(VCCL_PARENT2)))

ifneq (,$(filter bin biN bIn bIN Bin BiN BIn BIN,$(notdir $(VCCL_PARENT1))))
# VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
VS := $(subst ?, ,$(VCCL_PARENT3))
else
VCCL_PARENT4 := $(patsubst %\,%,$(dir $(VCCL_PARENT3)))
ifneq (,$(filter bin biN bIn bIN Bin BiN BIn BIN,$(notdir $(VCCL_PARENT2))))
# VCCL="C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\x86_amd64\cl.exe"
VS := $(subst ?, ,$(VCCL_PARENT4))
else ifneq (,$(filter bin biN bIn bIN Bin BiN BIn BIN,$(notdir $(VCCL_PARENT3))))
# VCCL="C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX64\x86\cl.exe"
MSVC := $(subst ?, ,$(VCCL_PARENT4))
else
$(error bad path to cl.exe (Visual C++ compiler): VCCL=$(VCCL))
endif
endif

else # !VCCL

# 2) VSINSTALLDIR is normally set by the vcvars32.bat, e.g. VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 12.0\
# note: likely with trailing slash
VS := $(VSINSTALLDIR)




VCCL_2017 := $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(patsubst VC_Tools_MSVC_%,%,$(lastword $(sort $(filter VC_Tools_MSVC_%,$(subst \, ,$(subst VC\Tools\MSVC\,VC_Tools_MSVC_,$(VCCL_2017))))))))))

VC_VER := $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(subst MSVC_,,$(lastword $(sort $(filter \
  MSVC_%,$(subst /, ,$(subst MSVC/,MSVC_,$(wildcard $(subst $(space),\ ,$(subst \,/,$(MSVC)))/*))))))))))

endif






endif

endif # !VS
endif # !MSVC




else
endif
endif

# prepare VS value for $(wildcard) function
VS_WILD := $(subst $(space),\ ,$(subst \,/,$(VS)))

# try to deduce MSVC value based on VS value (for post-Visual Studio 2017),
#  assuming VS=C:\Program Files\Microsoft Visual Studio\2017
# or may be VS=C:\Program Files\Microsoft Visual Studio\2017\Community
#        or VS=C:\Program Files\Microsoft Visual Studio\2017\Enterprise
#        or VS=C:\Program Files\Microsoft Visual Studio\2017\Whatever...

# if there are multiple Visual Studio editions, select the first one
# or may be VS specified with Visual Studio edition type?
VS_DEDUCE_MSVC = $(subst /,\,$(subst //,/,$(call VS_DEDUCE_MSVC1,$(wildcard $(VS_WILD)/*/VC/Tools/MSVC))))
VS_DEDUCE_MSVC1 = $(if $1,$(subst ?, ,$(addsuffix /VC/Tools/MSVC,$(firstword \
  $(subst /VC/Tools/MSVC, ,$(subst $(space),?,$1))))),$(wildcard $(VS_WILD)/VC/Tools/MSVC))

# first, determine Visual C++ version
ifndef VC_VER

# if MSVC is not defined, try to deduce it
ifndef MSVC

# check if VS variable (Visual Studio installation path) is defined, likely in command line:
#    VS = C:\Program Files\Microsoft Visual Studio 14.0
# or VS = C:\Program Files\Microsoft Visual Studio\2017
# or VS = C:\Program Files\Microsoft Visual Studio\2017\Enterprise
ifdef VS

# note: $(VS) may have trailing slash
ifneq (,$(findstring \Microsoft Visual Studio\\,$(VS)\\))
# Visual Studio 6.0
VC_VER := 6
else ifneq (,$(findstring \Microsoft Visual Studio .NET 2003,$(VS))
# Visual Studio 2003
VC_VER := 7.1
else ifneq (,$(findstring \Microsoft Visual Studio .NET,$(VS)))
# Visual Studio 2002
VC_VER := 7
else ifneq (,$(findstring \Microsoft Visual Studio ,$(VS)))
# Visual Studio 2005-2015
VC_VER := $(firstword $(subst ., ,$(lastword $(VS))))
else
# >= Visual Studio 2017 or may be Visual Studio is installed to non-default location
MSVC := $(VS_DEDUCE_MSVC)
# if MSVC is defined, extract VC_VER value from it later
ifndef MSVC
$(error failed to determine Visual C++ version for VS=$(VS), please specify it explicitly, e.g. VC_VER=14.0)
endif
endif

else # !VS

# check values of VS*COMNTOOLS environment variables
VS_COMNS := $(VS_GET_COMNS)

ifdef VS_COMNS

VCCL:=



# find file in paths
# $1 - file to find, e.g. VC/bin/cl.exe
# $2 - paths to look in, e.g. C:/Program?Files/Microsoft?Visual?Studio/2017/Community C:/Program?Files/Microsoft?Visual?Studio?14.0
# result: "C:\Program Files\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
VS_FIND_FILE = $(if $2,$(call VS_FIND_FILE1,$1,$2,$(wildcard $(subst ?,\ ,$(firstword $2))/$1)))




# check if file exists
# $1 - path to the file, e.g. C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/bin/cl.exe
# $2 - list of paths to check, e.g. C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\Common7\Tools\
# $3 - next macro to expand with tail of list $2
IS_FILE_EXISTS = $(if $(wildcard $(subst $(space),\ ,$1)),$(call ifaddq,$(ospath)),$(call $3,$(wordlist 2,999999,$2)))

# find cl.exe in $(VS_COMNS) paths
FIND_CL_EXE1 = $(call IS_FILE_EXISTS,$1\\VC98\Bin\cl.exe

FIND_CL_EXE = $(if $1,$(call \
  IS_FILE_EXISTS,$(subst ?, ,$(firstword $1)\VC\bin\cl.exe)),$1,$0))












# for post-Visual Studio 2017, we need MSVC variable - path to Visual C++
# if it's not defined, try to deduce it
ifndef MSVC

# check if VS variable (Visual Studio installation path) is defined, likely in command line:
#    VS = C:\Program Files\Microsoft Visual Studio 14.0
# or VS = C:\Program Files\Microsoft Visual Studio\2017
# or VS = C:\Program Files\Microsoft Visual Studio\2017\Enterprise
ifdef VS










ifdef MSVC
# assume MSVC = C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC
#           for C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503
#               C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017
# select the latest: VC_VER = 14.11
VC_VER := $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(subst MSVC_,,$(lastword $(sort $(filter \
  MSVC_%,$(subst /, ,$(subst MSVC/,MSVC_,$(wildcard $(subst $(space),\ ,$(subst \,/,$(MSVC)))/*))))))))))
ifndef VC_VER
$(error unable to determine Visual C++ version VC_VER for MSVC=$(MSVC), please specify it manually, e.g. VC_VER=14.1)
endif
endif # MSVC

endif # >= 2017

ifndef VC_VER

$(warning autoconfigured: VC_VER=$(VC_VER))

# check if MSVC variable is defined - path to Visual C++ (for post-Visual Studio 2017)
ifdef MSVC

# assume MSVC = C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC
#           for C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503
#               C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017
# select the latest: VC_VER = 14.11
VC_VER := $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(subst MSVC_,,$(lastword $(sort $(filter \
  MSVC_%,$(subst /, ,$(subst MSVC/,MSVC_,$(wildcard $(subst $(space),\ ,$(subst \,/,$(MSVC)))/*))))))))))
ifndef VC_VER
$(error unable to determine Visual C++ version VC_VER for MSVC=$(MSVC), please specify it manually, e.g. VC_VER=14.1)
endif

else # !VS

# check if VS*COMNTOOLS variable(s) are defined,
#  e.g. VS140COMNTOOLS=C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools\
#   or  VS150COMNTOOLS=C:\Program Files\Microsoft Visual Studio\2017\Community\Common7\Tools\
# note: check paths, starting from the greatest version
# note: result will look like: C:\Program?Files\Microsoft?Visual?Studio\2017\Community C:\Program?Files\Microsoft?Visual?Studio?14.0
VS_COMNS := $(foreach v,$(call reverse,$(call sort_numbers,$(patsubst \
  VS%COMNTOOLS,%,$(filter VS%COMNTOOLS,$(.VARIABLES))))),$(subst $(space),?,$(VS$vCOMNTOOLS:\Common7\Tools\=)))

# check if file exists
# $1 - path to the file, e.g. C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/bin/cl.exe
# $2 - list of paths to check, e.g. C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\Common7\Tools\
# $3 - next macro to expand with tail of list $2
IS_FILE_EXISTS = $(if $(wildcard $(subst $(space),\ ,$1)),$(call ifaddq,$(ospath)),$(call $3,$(wordlist 2,999999,$2)))



# check if file exists
# $1 - path to the file, e.g. C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/bin/cl.exe
# $2 - list of paths to check, e.g. C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\Common7\Tools\
# $3 - next macro to expand with tail of list $2
IS_FILE_EXISTS = $(if $(wildcard $(subst $(space),\ ,$1)),$(call ifaddq,$(ospath)),$(call $3,$(wordlist 2,999999,$2)))

# find cl.exe in $(VS_COMNS) paths
FIND_CL_EXE = $(if $1,$(call IS_FILE_EXISTS,$(subst ?, ,$(abspath $(firstword $1)..\..\VC\bin\cl.exe)),$1,$0))

# result is empty or something like "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
FOUND_CL_EXE := $(call FIND_CL_EXE,$(VS_COMNS))

VS := $(if $(FOUND_CL_EXE),
ifdef FOUND_CL_EXE

yyy = $(if $(wildcard $(subst $(space),\ ,$1)),$(call ifaddq,$(ospath)),
xxx = $(call yyy,$(subst ?, ,$(abspath $(subst $(space),?,$(VS$1COMNTOOLS))..\..\VC\bin\cl.exe)))


xxx = $(if $(wildcard $(subst \,/,$(subst $(space),\ ,$(VS$(lastword $1)COMNTOOLS)))../../VC/bin/cl.exe),$(VS$(lastword $1)COMNTOOLS)

$(foreach v,$(call reverse,$(call sort_numbers,$(patsubst VS%COMNTOOLS,%,$(filter VS%COMNTOOLS,$(.VARIABLES))))),$(if \
  $(wildcard $(subst \,/,$(subst $(space),\ ,$(VS$vCOMNTOOLS)))../../VC/bin/cl.exe),

   C:/Program\ Files\ (x86)/Microsoft\ Visual\ Studio\ 14.0/Common7/Tools//../../vc/bin/cl.exe







# if file exists under Visual Studio directory, return path to it (in double quotes, if path contains spaces)
# otherwise, return empty string
# $1 - file to check, e.g. VC98/Bin/cl.exe
VS_IS_FILE_EXISTS1 = $(if $1,$2,$(error file does not exist: $2))
VS_IS_FILE_EXISTS = $(call VS_IS_FILE_EXISTS1,$(wildcard $(VS_WILD)/$1),$(call ifaddq,$(VS)\$(subst /,\,$1)))

# if directory exists under Visual Studio directory, return path to it (with spaces replaced with ?)
# otherwise, return empty string
# $1 - directory to check, e.g. VC98/Lib
VS_IS_DIR_EXISTS1 = $(if $1,$2,$(error directory does not exist: $2))
VS_IS_DIR_EXISTS = $(call VS_IS_DIR_EXISTS1,$(wildcard $(VS_WILD)/$1/.),$(subst $(space),?,$(VS)\$(subst /,\,$1)))

# try to define paths to Visual C++ tools (cl.exe, lib.exe or link.exe), libraries and headers
# $1 - prefix of variables VCCL, VCLIB, VCLINK and VCLIBPATH: empty or T
# $2 - relative path to cl.exe, lib.exe and link.exe,     e.g. VC/bin
# $3 - relative path to lib and include directories,      e.g. VC
# $4 - target CPU specific subdirectory of lib directory, e.g. /onecore/amd64
define VC_FIND_PATHS
ifeq (,$(filter override command,$(origin $1VCCL)))
$1VCCL := $(call VS_IS_FILE_EXISTS,$2/cl.exe)
endif
ifeq (,$(filter override command,$(origin $1VCLIB)))
$1VCLIB := $(call VS_IS_FILE_EXISTS,$2/lib.exe)
endif
ifeq (,$(filter override command,$(origin $1VCLINK)))
$1VCLINK := $(call VS_IS_FILE_EXISTS,$2/link.exe)
endif
ifeq (,$(filter override command,$(origin $1VCLIBPATH)))
$1VCLIBPATH := $(call VS_IS_DIR_EXISTS,$3/lib$4)
endif
ifeq (,$1$(filter override command,$(origin VCINCLUDE)))
VCINCLUDE := $(call VS_IS_DIR_EXISTS,$3/include)
endif
endef

ifneq (,$(findstring \Microsoft Visual Studio\,$(VS)\))

# Visual Studio 6.0
VC_VER := 6
$(eval $(call VC_FIND_PATHS,,VC98/bin,VC98))

# for the tool mode
TVCCL      := $(VCCL)
TVCLIB     := $(VCLIB)
TVCLINK    := $(VCLINK)
TVCLIBPATH := $(VCLIBPATH)

else ifneq (,$(findstring \Microsoft Visual Studio .NET 2003,$(VS)))

# Visual Studio 2003
VC_VER := 7.1
$(eval $(call VC_FIND_PATHS,,VC7/bin,VC7))

# for the tool mode
TVCCL      := $(VCCL)
TVCLIB     := $(VCLIB)
TVCLINK    := $(VCLINK)
TVCLIBPATH := $(VCLIBPATH)

else ifneq (,$(findstring \Microsoft Visual Studio .NET,$(VS)))

# Visual Studio 2002
VC_VER := 7
$(eval $(call VC_FIND_PATHS,,VC7/bin,VC7))

# for the tool mode
TVCCL      := $(VCCL)
TVCLIB     := $(VCLIB)
TVCLINK    := $(VCLINK)
TVCLIBPATH := $(VCLIBPATH)

else ifneq (,$(findstring \Microsoft Visual Studio ,$(VS)))

# Visual Studio 2005-2015
VC_VER := $(firstword $(subst ., ,$(lastword $(VS))))

# determine tool prefix for TCPU/CPU combination
#
# $1 - target CPU, e.g. x86, x86_64 or arm
#
# TCPU\CPU |   x86       x86_64      arm
# ---------|----------------------------------
# x86      |  <none>     /x86_amd64 /x86_arm
# x86_64   |  /amd64_x86 /amd64     /amd64_arm
#
VS_TOOL_PREFIX = $(addprefix /,$(filter-out x86_x86,$(subst amd64_amd64,amd64,$(TCPU:x86_64=amd64)_$(1:x86_64=amd64))))

$(eval $(call VC_FIND_PATHS,,VC/bin$(call VS_TOOL_PREFIX,$(CPU)),VC,$(VC_LIB_STORE:%=/%)$(VC_LIB_ONECORE:%=/%)$(addprefix \
  /,$(filter-out x86,$(CPU:x86_64=amd64)))))

# for the tool mode
$(eval $(call VC_FIND_PATHS,T,VC/bin$(call VS_TOOL_PREFIX,$(TCPU)),VC,$(addprefix \
  /,$(filter-out x86,$(TCPU:x86_64=amd64)))))

else # assume VS = C:\Program Files\Microsoft Visual Studio\2017

ifndef VS_MSVC
# if VS_MSVC is not defined, try to determine it
# note: VS_MSVC may be defined as C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC
VS_MSVC := $(subst /,\,$(wildcard $(VS_WILD)/*/VC/Tools/MSVC))
endif

ifndef VS_MSVC
# may be VS = C:\Program Files\Microsoft Visual Studio\2017\Community
# or     VS = C:\Program Files\Microsoft Visual Studio\2017\Enterprise
# or     VS = C:\Program Files\Microsoft Visual Studio\2017\Whatever...
VS_MSVC := $(subst /,\,$(wildcard $(VS_WILD)/VC/Tools/MSVC))
endif

ifdef VS_MSVC
# assume VS_MSVC = C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC
#              for C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503
#                  C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017
# select the latest: VC_VER = 14.11
VC_VER := $(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(subst MSVC_,,$(lastword $(sort $(filter \
  MSVC_%,$(subst /, ,$(subst MSVC/,MSVC_,$(wildcard $(subst $(space),\ ,$(subst \,/,$(VS_MSVC)))/*))))))))))
endif # VS_MSVC

ifndef VC_VER
ifdef VS_MSVC
$(error unable to determine Visual C++ version VC_VER for VS_MSVC=$(VS_MSVC), please specify it manually, e.g. VC_VER=14.1)
else
$(error unable to determine Visual C++ version VC_VER for VS=$(VS), please specify it manually, e.g. VC_VER=14.1)
endif
endif

endif









VS_SVC_WILD := $(subst $(space),\ ,$(wildcard $(VS_WILD)/*/VC/Tools/MSVC))

MSVC_WILD := $(subst $(space),\ ,$(wildcard $(VS_WILD)/*/VC/Tools/MSVC))

ifeq (,$(MSVC_WILD))
$(error unable to find VC\Tools\MSVC subdirectory under VS = $(VS))

$(VS_WILD)/*/VC/Tools/MSVC


# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\arm\msvcrt.lib
Enterprise


ifneq (,$(findstring \VC\Tools\MSVC\,$(VS)))

# 14.10.25017 -> 1410
VC_VER := $(subst $(space),,$(wordlist 1,2,$(subst ., ,$(word 2,$(subst \VC\Tools\MSVC\, ,$(subst $(space),?,$(VS)))))))






ifneq (,$(findstring \Microsoft Visual Studio ,$(VS)))
# 10.0 -> 10
VS_VER := $(firstword $(subst ., ,$(lastword $(VS))))
else ifneq (,$(findstring \VC\Tools\MSVC\,$(VS)))
# 14.10.25017 -> 1410
VS_VER := $(subst $(space),,$(wordlist 1,2,$(subst ., ,$(word 2,$(subst \VC\Tools\MSVC\, ,$(subst $(space),?,$(VS)))))))
else
VS_VER:=
endif

ifeq (,$(VS_VER))
$(error VS_VER undefined (expecting 8,9,11,12,14,1410), \
  failed to auto-determine it, likely Visual Studio is installed to non-default location)
endif

endif

endif

# VS - Visual Studio installation path
ifeq (,$(filter override command,$(origin VS)))

# check if VS*COMNTOOLS variable(s) are defined, e.g. VS140COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools
# note: result will look like C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\Common7\Tools\
# note: check paths, starting from the greatest version
VS_COMNS := $(foreach v,$(call reverse,$(call sort_numbers,$(patsubst \
  VS%COMNTOOLS,%,$(filter VS%COMNTOOLS,$(.VARIABLES))))),$(subst $(space),?,$(VS$vCOMNTOOLS)))

# check if file exists
# $1 - path to the file, e.g. C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/bin/cl.exe
# $2 - list of paths to check, e.g. C:\Program?Files?(x86)\Microsoft?Visual?Studio?14.0\Common7\Tools\
# $3 - next macro to expand with tail of list $2
IS_FILE_EXISTS = $(if $(wildcard $(subst $(space),\ ,$1)),$(call ifaddq,$(ospath)),$(call $3,$(wordlist 2,999999,$2)))

# find cl.exe in $(VS_COMNS) paths
FIND_CL_EXE = $(if $1,$(call IS_FILE_EXISTS,$(subst ?, ,$(abspath $(firstword $1)..\..\VC\bin\cl.exe)),$1,$0))

# result is empty or something like "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\cl.exe"
FOUND_CL_EXE := $(call FIND_CL_EXE,$(VS_COMNS))

VS := $(if $(FOUND_CL_EXE),
ifdef FOUND_CL_EXE

yyy = $(if $(wildcard $(subst $(space),\ ,$1)),$(call ifaddq,$(ospath)),
xxx = $(call yyy,$(subst ?, ,$(abspath $(subst $(space),?,$(VS$1COMNTOOLS))..\..\VC\bin\cl.exe)))


xxx = $(if $(wildcard $(subst \,/,$(subst $(space),\ ,$(VS$(lastword $1)COMNTOOLS)))../../VC/bin/cl.exe),$(VS$(lastword $1)COMNTOOLS)

$(foreach v,$(call reverse,$(call sort_numbers,$(patsubst VS%COMNTOOLS,%,$(filter VS%COMNTOOLS,$(.VARIABLES))))),$(if \
  $(wildcard $(subst \,/,$(subst $(space),\ ,$(VS$vCOMNTOOLS)))../../VC/bin/cl.exe),

   C:/Program\ Files\ (x86)/Microsoft\ Visual\ Studio\ 14.0/Common7/Tools//../../vc/bin/cl.exe


VS_INTALL_PATHS:=
ADD_VS_INST_PATH1 = $(eval VS_INTALL_PATHS += $$1)
ADD_VS_INST_PATH = $(call ADD_VS_INST_PATH1,$(subst $(space),\ ,$(subst \,/,$1)))

VS90COMNTOOLS

$(call ADD_VS_INST_PATH,Microsoft Visual Studio\2017\Community\VC\Tools\MSVC)
$(call ADD_VS_INST_PATH,

VS_INTALL_PATHS += Microsoft Visual Studio\2017\Community\VC\Tools\MSVC

ifneq (,$(wildcard C:/Microsoft\ Visual\ Studio/2017/Community/VC/Tools/MSVC

ifneq (,$(wildcard C:/Program\ Files\ (x86)/Microsoft\ Visual\ Studio\ 14.0/.

# VS:=C:\Program Files (x86)\Microsoft Visual Studio 10.0

#  6       1200   Visual Studio 6.0   Microsoft Visual Studio\VC98\Bin\cl.exe
#  7       1300   Visual Studio 2002  Microsoft Visual Studio .NET\VC7\bin\cl.exe
#  7.1     1310   Visual Studio 2003  Microsoft Visual Studio .NET 2003\VC7\bin\cl.exe
#  8       1400   Visual Studio 2005  Microsoft Visual Studio 8\VC\bin\cl.exe
#  9       1500   Visual Studio 2008  Microsoft Visual Studio 9.0\VC\bin\cl.exe
#  10      1600   Visual Studio 2010  Microsoft Visual Studio 10.0\VC\bin\cl.exe
#  11      1700   Visual Studio 2012  Microsoft Visual Studio 11.0\VC\bin\cl.exe
#  12      1800   Visual Studio 2013  Microsoft Visual Studio 12.0\VC\bin\cl.exe
#  14      1900   Visual Studio 2015  Microsoft Visual Studio 14.0\VC\bin\cl.exe
#  14.1    1910   Visual Studio 2017  Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017\bin\HostX86\x86\cl.exe
#  14.11   1911   Visual Studio 2017  Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe

c:\Program Files (x86)\Microsoft Visual Studio 14.0

P := C:/Program\ Files\ (x86)/Microsoft\ Visual\ Studio\ 14.0/.

VS := $(wildcard 

ifeq (,$(VS))
$(error VS undefined, example: VS:="C:\Program Files (x86)\Microsoft Visual Studio 10.0" or\
 VS:="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017")
endif
