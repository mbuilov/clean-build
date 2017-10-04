#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler auto-configuration (app-level), included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# paths to compiler/linker and system libraries/headers - if not defined in project
#  configuration makefile or in command line, try to autoconfigure
#
# VC_VER    - MSVC++ version, known values see in $(CLEAN_BUILD_DIR)/compilers/msvc_cmn.mk
# VCCL      - path to cl.exe, must be in double-quotes if contains spaces
# VCLIB     - path to lib.exe, must be in double-quotes if contains spaces
# VCLINK    - path to link.exe, must be in double-quotes if contains spaces
# VCLIBPATH - paths to Visual C++ libraries, spaces must be replaced with ?
# VCINCLUDE - paths to Visual C++ headers, spaces must be replaced with ?
# UMLIBPATH - paths to user-mode libraries, spaces must be replaced with ?
# UMINCLUDE - paths to user-mode headers, spaces must be replaced with ?
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
#

# Windows variant to autoconfigure for 
WINVARIANT := WINXP

# supported Windows variants for autoconfiguration
WINVARIANTS := WINXP WINV WIN7 WIN8 WIN81 WIN10

# version of Windows API to compile with
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
$(warning unable to auto-determine WINVER_DEFINES for WINVARIANT = $(WINVARIANT), supported WINVARIANTS = $(WINVARIANTS))
WINVER_DEFINES:=
endif

$(warning autoconfigured: WINVER_DEFINES = $(WINVER_DEFINES))
endif # WINVER_DEFINES

# minimum Windows version required to run built targets
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
$(warning unable to auto-determine SUBSYSTEM_VER for WINVARIANT = $(WINVARIANT))
SUBSYSTEM_VER:=
endif

$(warning autoconfigured: SUBSYSTEM_VER = $(SUBSYSTEM_VER))
endif # SUBSYSTEM_VER

# we need next MSVC++ variables to be defined (either in project configuration makefile or in command line)
ifneq (6,$(words $(foreach v,VC_VER VCCL VCLIB VCLINK VCLIBPATH VCINCLUDE,$(filter override command,$(origin $v)))))

# first, check if VS variable is defined - Visual Studio installation path
ifneq (,$(filter override command,$(origin VS)))

# VS may be defined as:
# ------------------------------------------------------------------------------
#  C:\Program Files\Microsoft Visual Studio            #  \VC98\Bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio .NET       #  \VC7\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio .NET 2003  #  \VC7\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 8          #  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 9.0        #  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 10.0       #  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 11.0       #  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 12.0       #  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio 14.0       #  \VC\bin\cl.exe
#  C:\Program Files\Microsoft Visual Studio\2017       #  \Community\VC\Tools\MSVC\14.10.25017\bin\HostX86\x86\cl.exe
#  C:\Program Files\Microsoft Visual Studio\2017       #  \Community\VC\Tools\MSVC\14.11.25503\bin\HostX86\x86\cl.exe

# prepare VS value for $(wildcard) function
VS_WILD := $(subst $(space),\ ,$(subst \,/,$(VS)))

# if file exists under Visual Studio directory, return path to it (in double quotes, if path contains spaces needed)
# otherwise, return empty string
# $1 - file to check, e.g. VC98/Bin/cl.exe
VS_IS_FILE_EXISTS1 = $(if $1,$2,$(warning file $2 does not exists))
VS_IS_FILE_EXISTS = $(call VS_IS_FILE_EXISTS1,$(wildcard $(VS_WILD)/$1),$(call ifaddq,$(VS)\$(subst /,\,$1)))

# if directory exists under Visual Studio directory, return path to it (with spaces replaced with ?)
# otherwise, return empty string
# $1 - directory to check, e.g. VC98/Lib
VS_IS_DIR_EXISTS1 = $(if $1,$2,$(warning directory $2 does not exists))
VS_IS_DIR_EXISTS = $(call VS_IS_DIR_EXISTS1,$(wildcard $(VS_WILD)/$1/.),$(subst $(space),?,$(VS)\$(subst /,\,$1)))

# try to define paths to the tools (cl.exe, lib.exe or link.exe) and Visual C++ libraries and headers
# $1 - VC++ directory, e.g. VC98, VC7 or VC
define VC_FIND_PATHS
ifeq (,$(filter override command,$(origin VCCL)))
VCCL := $(call VS_IS_FILE_EXISTS,$1/bin/cl.exe)
endif
ifeq (,$(filter override command,$(origin VCLIB)))
VCLIB := $(call VS_IS_FILE_EXISTS,$1/bin/lib.exe)
endif
ifeq (,$(filter override command,$(origin VCLINK)))
VCLINK := $(call VS_IS_FILE_EXISTS,$1/bin/link.exe)
endif
ifeq (,$(filter override command,$(origin VCLIBPATH)))
VCLIBPATH := $(call VS_IS_DIR_EXISTS,$1/lib)
endif
ifeq (,$(filter override command,$(origin VCINCLUDE)))
VCINCLUDE := $(call VS_IS_DIR_EXISTS,$1/include)
endif
endef

ifneq (,$(findstring \Microsoft Visual Studio\,$(VS)\))

# looks like Visual Studio 6.0
VC_VER := 6
$(eval $(call VC_FIND_PATHS,VC98))

else ifneq (,$(findstring \Microsoft Visual Studio .NET 2003,$(VS)))

# Visual Studio 2003
VC_VER := 7.1
$(eval $(call VC_FIND_PATHS,VC7))

else ifneq (,$(findstring \Microsoft Visual Studio .NET,$(VS)))

# Visual Studio 2002
VC_VER := 7
$(eval $(call VC_FIND_PATHS,VC7))

else ifneq (,$(findstring \Microsoft Visual Studio ,$(VS)))

# Visual Studio 8/9.0/10.0/11.0/12.0/14.0
VC_VER := $(firstword $(subst ., ,$(lastword $(VS))))
$(eval $(call VC_FIND_PATHS,VC))


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
