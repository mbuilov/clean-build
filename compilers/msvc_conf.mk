#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler auto-configuration (app-level), included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# try to autoconfigure paths to compiler/linker and system libraries/headers
#  - if they are not defined in project configuration makefile or in command line
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
# VC_VER    := 14
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
#   by default WINXP, other possible values: $(WINVARIANTS)
#
# 2) VS - Visual Studio installation path,
#  may be specified if autoconfiguration based of value(s) of VS*COMNTOOLS variable(s) fails,
#  for example: C:\Program Files (x86)\Microsoft Visual Studio 14.0
#
#  Note: if pre-2017 Visual Studio installation folder has non-default name, it is not possible
#   to deduce Visual C++ version automatically - VC_VER must be specified explicitly
#
#  Note: for post-Visual Studio 2017, VS variable may be specified with Visual Studio edition type,
#   e.g.: VS=C:\Program Files\Microsoft Visual Studio\2017\Enterprise
#
#  Note: for post-Visual Studio 2017, instead of VS variable, it may be defined MSVC - path to Visual C++,
#   e.g. MSVC=C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC
#
# 3) VC_VER - Visual C++ version, known values are: 6.0, 7.0, 7.1, 8.0, 9.0, 10.0, 11.0, 12.0, 14.0, 14.10, 14.11
#  may be specified explicitly if autoconfiguration fails
#
#################################################################################################################

# By default, autoconfigure for Windows XP
WINVARIANT := WINXP

# supported Windows variants for autoconfiguration
WINVARIANTS := WINXP WINV WIN7 WIN8 WIN81 WIN10

# reset variables, if they are not defined in project configuration makefile or in command line
VC_VER:=
VS:=
MSVC:=

# WINVER_DEFINES - specifies version of Windows API to compile with
ifeq (,$(filter override command,$(origin WINVER_DEFINES)))

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
ifeq (,$(filter override command,$(origin SUBSYSTEM_VER)))

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

# we need next MSVC++ variables
# (they are may be defined either in project configuration makefile or in command line)
ifneq (6,$(words $(foreach v,VC_VER VCCL VCLIB VCLINK VCLIBPATH VCINCLUDE,$(filter override command,$(origin $v)))))

# prepare VS value for $(wildcard) function
VS_WILD := $(subst $(space),\ ,$(subst \,/,$(VS)))

# try to determine MSVC based on VS value,
#  assuming VS=C:\Program Files\Microsoft Visual Studio\2017
# or may be VS=C:\Program Files\Microsoft Visual Studio\2017\Community
#        or VS=C:\Program Files\Microsoft Visual Studio\2017\Enterprise
#        or VS=C:\Program Files\Microsoft Visual Studio\2017\Whatever...
VS_DEDUCE_MSVC1 = $(if $1,$1,$(subst /,\,$(wildcard $(VS_WILD)/VC/Tools/MSVC)))
VS_DEDUCE_MSVC = $(call VS_DEDUCE_MSVC1,$(subst /,\,$(wildcard $(VS_WILD)/*/VC/Tools/MSVC)))

# first, determine Visual C++ version
ifndef VC_VER

# for post-Visual Studio 2017, MSVC variable may be defined - path to Visual C++
# if it's not defined, try to deduce it
ifndef MSVC

# check if VS variable (Visual Studio installation path) is defined, likely in command line:
#    VS = C:\Program Files\Microsoft Visual Studio 14.0
# or VS = C:\Program Files\Microsoft Visual Studio\2017
# or VS = C:\Program Files\Microsoft Visual Studio\2017\Enterprise
ifdef VS

#                 VS may be defined as                     compiler path
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
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\arm\store\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\arm\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\onecore\x86\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x64\store\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x86\msvcrt.lib
# C:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.11.25503\lib\x86\store\msvcrt.lib

ifneq (,$(findstring \Microsoft Visual Studio\,$(VS)\))
# Visual Studio 6.0
VC_VER := 6
else ifneq (,$(findstring \Microsoft Visual Studio .NET 2003,$(VS)))
# Visual Studio 2003
VC_VER := 7.1
else ifneq (,$(findstring \Microsoft Visual Studio .NET,$(VS)))
# Visual Studio 2002
VC_VER := 7
else ifneq (,$(findstring \Microsoft Visual Studio ,$(VS)))
# Visual Studio 2005-2015
VC_VER := $(firstword $(subst ., ,$(lastword $(VS))))
else # >= 2017?
MSVC := $(VS_DEDUCE_MSVC)
endif # >= 2017?

# extract VC_VER from $(MSVC) path later...
ifndef MSVC
ifndef VC_VER
$(error unable to determine Visual C++ version VC_VER for VS=$(VS), please specify it manually, e.g. VC_VER=14.1)
endif
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






### subdirectory of MSVC++ libraries: <empty> or onecore
##VC_LIB_TYPE_ONECORE:=
##
### subdirectory of MSVC++ libraries: <empty> or store
##VC_LIB_TYPE_STORE:=


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
