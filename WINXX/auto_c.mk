#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# run via $(MAKE) A=1 to show autoconf results
ifeq (command line,$(origin A))
VAUTO := $(A:0=)
else
VAUTO:=
endif

# supported target windows variants
WINVARIANTS := WINXP WINV WIN7 WIN8 WIN81 WIN10

# default target variant - must be defined either in command line
# or in project configuration file before including this file, via:
# WINVARIANT := WIN7
WINVARIANT:=

# WINVARIANT should be non-recursive (simple)
override WINVARIANT := $(WINVARIANT)

ifndef WINVARIANT
$(error WINVARIANT undefined, please pick on of: $(WINVARIANTS))
endif

ifeq (,$(filter $(WINVARIANT),$(WINVARIANTS)))
$(error unknown WINVARIANT=$(WINVARIANT), please pick on of: $(WINVARIANTS))
endif

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
WINVER_DEFINES:=
ifndef WINVER_DEFINES
$(error unable to define WINVER_DEFINES for WINVARIANT = $(WINVARIANT))
endif
endif

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
SUBSYSTEM_VER:=
ifndef SUBSYSTEM_VER
$(error unable to define SUBSYSTEM_VER for WINVARIANT = $(WINVARIANT))
endif
endif

# option for parallel builds, starting from Visual Studio 2013
# empty by default
FORCE_SYNC_PDB:=
FORCE_SYNC_PDB_KERN:=

# SUPPRESS_RC_LOGO may be defined as /nologo, but not all versions of rc.exe support this switch
SUPPRESS_RC_LOGO:=

# variables that must be defined:
AUTOCONF_VARS:=
AUTOCONF_VARS += VSLIB    # spaces must be replaced with ?
AUTOCONF_VARS += VSINC    # spaces must be replaced with ?
AUTOCONF_VARS += VSLD     # full path in quotes
AUTOCONF_VARS += VSCL     # full path in quotes
AUTOCONF_VARS += UMLIB    # spaces must be replaced with ?
AUTOCONF_VARS += UMINC    # spaces must be replaced with ?
AUTOCONF_VARS += VSTLIB   # spaces must be replaced with ?
AUTOCONF_VARS += VSTINC   # spaces must be replaced with ?
AUTOCONF_VARS += VSTLD    # full path in quotes
AUTOCONF_VARS += VSTCL    # full path in quotes
AUTOCONF_VARS += UMTLIB   # spaces must be replaced with ?
AUTOCONF_VARS += UMTINC   # spaces must be replaced with ?
AUTOCONF_VARS += KMLIB    # spaces must be replaced with ?
AUTOCONF_VARS += KMINC    # spaces must be replaced with ?
AUTOCONF_VARS += WKLD     # full path in quotes
AUTOCONF_VARS += WKCL     # full path in quotes
AUTOCONF_VARS += INF2CAT  # full path in quotes
AUTOCONF_VARS += SIGNTOOL # full path in quotes
AUTOCONF_VARS += MC1      # full path in quotes
AUTOCONF_VARS += RC1      # full path in quotes
AUTOCONF_VARS += MT1      # full path in quotes
AUTOCONF_VARS += TMC1     # full path in quotes
AUTOCONF_VARS += TRC1     # full path in quotes
AUTOCONF_VARS += TMT1     # full path in quotes

# autoconfigure by default
NO_AUTOCONF:=

# check that all needed vars are defined, if not - autoconfigure
ifeq (,$(NO_AUTOCONF))

# autoconfigure

ifdef VAUTO
$(info try to autoconfigure...)
endif

# VS - path to Visual Studio - must be defined either in command line
# or in project configuration file before including this file, via:
# VS:=C:\Program Files (x86)\Microsoft Visual Studio 10.0
VS:=

ifeq (,$(VS))
$(error VS undefined, example: VS:="C:\Program Files (x86)\Microsoft Visual Studio 10.0" or\
 VS:="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017")
endif

# Visual Studio version
# Visual Studio 97          = 5
# Visual Studio 6.0         = 6
# Visual Studio .NET (2002) = 7
# Visual Studio .NET 2003   = 7
# Visual Studio 2005        = 8     c:\Program Files\Microsoft Visual Studio 8
# Visual Studio 2008        = 9     c:\Program Files\Microsoft Visual Studio 9.0
# Visual Studio 2010        = 10
# Visual Studio 2012        = 11    c:\Program Files\Microsoft Visual Studio 11.0
# Visual Studio 2013        = 12    c:\Program Files\Microsoft Visual Studio 12.0
# Visual Studio 2015        = 14    c:\Program Files\Microsoft Visual Studio 14.0
# Visual Studio 2017        = 1410  c:\Program Files\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017

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

# base path to Visual Studio C headers/libraries
ifneq (,$(call is_less,$(VS_VER),1410))
# < Visual Studio 2017
VCN := $(VS)\VC
else
# >= Visual Studio 2017
VCN := $(VS)
endif

# WDK - path to Windows Development Kit
# DDK - path to Driver Development Kit
# SDK - path to Software Development Kit
# - if any of these variables is needed, it may be defined either in command line
# or in project configuration file before including this file, via:
# WDK:=C:\Program Files (x86)\Windows Kits\8.1
# DDK:=C:\WinDDK\7600.16385.1
# SDK:=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A
WDK:=
DDK:=
SDK:=

# ensure that next variables are non-recursive (simple)
override WDK := $(WDK)
override DDK := $(DDK)
override SDK := $(SDK)

# Windows Kit version
ifneq (,$(findstring \Windows Kits\,$(WDK)))
WDK_VER := $(firstword $(subst ., ,$(lastword $(subst \, ,$(WDK)))))
else
WDK_VER:=
endif

# check WDK_VER only when needed
GET_WDK_VER = $(if $(WDK_VER),$(WDK_VER),$(if $(WDK),$(error WDK_VER undefined (expecting 7,8,9,10), \
  failed to auto-determine it, likely WDK is installed to non-default location),$(error \
  WDK undefined, example: WDK:="C:\Program Files (x86)\Windows Kits\8.1")))

# normalize: x x -> x?x
VCN  := $(call unspaces,$(VCN))
WDKN := $(call unspaces,$(WDK))
DDKN := $(call unspaces,$(DDK))
SDKN := $(call unspaces,$(SDK))

# empty by default
ONECORE:=

# APP LEVEL

ifeq (,$(call is_less,1000,$(VS_VER)))
# < Visual Studio 2017

VSLIB  := $(VCN)\lib$(ONECORE)$(addprefix \,$(filter-out x86,$(CPU:x86_64=amd64)))
VSINC  := $(VCN)\include

VSTLIB := $(VCN)\lib$(addprefix \,$(filter-out x86,$(TCPU:x86_64=amd64)))
VSTINC := $(VSINC)

# determine tool prefix $(TCPU)_$1 where
# $1 - target cpu (either $(CPU) or $(KCPU))
# Note: some prefixes reduced:
#  amd64_amd64 -> amd64
#  x86_x86     -> <none>
VS_TOOL_PREFIX = $(addprefix \,$(filter-out x86_x86,$(subst amd64_amd64,amd64,$(TCPU:x86_64=amd64)_$(1:x86_64=amd64))))

VSLD   := $(call qpath,$(VCN)\bin$(call VS_TOOL_PREFIX,$(CPU))\link.exe)
VSCL   := $(call qpath,$(VCN)\bin$(call VS_TOOL_PREFIX,$(CPU))\cl.exe)

VSTLD  := $(call qpath,$(VCN)\bin$(call VS_TOOL_PREFIX,$(TCPU))\link.exe)
VSTCL  := $(call qpath,$(VCN)\bin$(call VS_TOOL_PREFIX,$(TCPU))\cl.exe)

# set path to dlls needed by cl.exe and link.exe to work
ifneq (,$(call is_less,$(VS_VER),10))
# <= Visual Studio 2008

ifneq (\amd64,$(call VS_TOOL_PREFIX,$(CPU)))
# not for \amd64
override PATH := $(VS)\Common7\IDE;$(VS)\VC\bin;$(PATH)
endif

else ifneq (,$(call is_less,$(VS_VER),13))
# <= Visual Studio 2013

ifneq ($(CPU),$(TCPU))
# for \x86_amd64
override PATH := $(VS)\VC\bin;$(PATH)
endif

else # Visual Studio 2015

ifneq ($(CPU),$(TCPU))
# for \amd64_arm
# for \amd64_x86
# for \x86_amd64
# for \x86_arm
override PATH := $(VS)\VC\bin$(addprefix \,$(filter-out x86,$(TCPU:x86_64=amd64)));$(PATH)
endif

endif # Visual Studio 2015

else # Visual Studio 2017

VSLIB  := $(VCN)\lib$(ONECORE)\$(CPU:x86_64=x64)
VSINC  := $(VCN)\include

VSTLIB := $(VCN)\lib\$(TCPU:x86_64=x64)
VSTINC := $(VSINC)

VSLD   := $(call qpath,$(VCN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(CPU:x86_64=x64)\link.exe)
VSCL   := $(call qpath,$(VCN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(CPU:x86_64=x64)\cl.exe)

VSTLD  := $(call qpath,$(VCN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(TCPU:x86_64=x64)\link.exe)
VSTCL  := $(call qpath,$(VCN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(TCPU:x86_64=x64)\cl.exe)

# set path to dlls needed by cl.exe and link.exe to work
ifneq ($(CPU),$(TCPU))
# for HostX64/x86
# for HostX86/x64
override PATH := $(VS)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(TCPU:x86_64=x64);$(PATH)
endif

endif # Visual Studio 2017

# PATH variable may have changed, print it to generated batch file
$(if $(VERBOSE),$(info SET "PATH=$(PATH)"))

# option for parallel builds, starting from Visual Studio 2013
ifneq (,$(call is_less,11,$(VS_VER)))
FORCE_SYNC_PDB := /FS
endif

ifeq (,$(strip $(SDK)$(WDK)))
$(error no SDK nor WDK defined, example:\
 SDK:="C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A" or WDK:="C:\Program Files (x86)\Windows Kits\8.1")
endif

ifdef SDK

ifdef WDK
$(error either SDK or WDK must be defined, but not both)
endif

ifneq (,$(call is_less,12,$(VS_VER)))
$(error too new Visual Studio version $(lastword $(subst \, ,$(VS))) to build with SDK, please use WDK)
endif

UMLIB  := $(SDKN)\Lib$(addprefix \,$(filter-out x86,$(CPU:x86_64=x64)))
UMINC  := $(SDKN)\Include
UMTLIB := $(SDKN)\Lib$(addprefix \,$(filter-out x86,$(TCPU:x86_64=x64)))
UMTINC := $(UMINC)

TMC1 := $(call qpath,$(SDKN)\bin$(addprefix \,$(filter-out x86,$(TCPU:x86_64=x64)))\MC.Exe)
TRC1 := $(call qpath,$(SDKN)\bin$(addprefix \,$(filter-out x86,$(TCPU:x86_64=x64)))\RC.Exe)
TMT1 := $(call qpath,$(SDKN)\bin$(addprefix \,$(filter-out x86,$(TCPU:x86_64=x64)))\MT.Exe)
MC1  := $(TMC1)
RC1  := $(TRC1)
MT1  := $(TMT1)

endif # SDK

ifdef WDK

ifdef SDK
$(error either SDK or WDK must be defined, but not both)
endif

# WDK target OS version - must be defined either in command line
# or in project configuration file before including this file, via:
# WDK_TARGET := win7
WDK_TARGET:=

ifeq (,$(WDK_TARGET))
$(error WDK_TARGET undefined, check contents of "$(WDK)\Lib", example: win7, win8, winv6.3, 10.0.10240.0)
endif

ifneq (,$(call is_less,$(GET_WDK_VER),8))

$(error unsuitable WDK version $(GET_WDK_VER) for building APP-level, use SDK instead)

else ifneq (,$(call is_less,$(WDK_VER),10))

UMLIB  := $(WDKN)\Lib\$(WDK_TARGET)\um\$(CPU:x86_64=x64)
UMINC  := $(WDKN)\Include
UMINC  := $(UMINC)\um $(UMINC)\shared
UMTLIB := $(WDKN)\Lib\$(WDK_TARGET)\um\$(TCPU:x86_64=x64)
UMTINC := $(UMINC)

else # WDK10

UMLIB  := $(WDKN)\Lib\$(WDK_TARGET)\um\$(CPU:x86_64=x64) $(WDKN)\Lib\$(WDK_TARGET)\ucrt\$(CPU:x86_64=x64)
UMINC  := $(WDKN)\Include\$(WDK_TARGET)
UMINC  := $(UMINC)\um $(UMINC)\ucrt $(UMINC)\shared
UMTLIB := $(WDKN)\Lib\$(WDK_TARGET)\um\$(TCPU:x86_64=x64) $(WDKN)\Lib\$(WDK_TARGET)\ucrt\$(TCPU:x86_64=x64)
UMTINC := $(UMINC)

endif # WDK10

# for WDK 10.0.15063.0 and later
ifeq (,$(call is_less,$(WDK_VER),10)$(call is_less,$(word 3,$(subst ., ,$(WDK_TARGET))),15063))

TMC1 := $(call qpath,$(WDKN)\bin\$(WDK_TARGET)\$(TCPU:x86_64=x64)\mc.exe)
TRC1 := $(call qpath,$(WDKN)\bin\$(WDK_TARGET)\$(TCPU:x86_64=x64)\rc.exe)
TMT1 := $(call qpath,$(WDKN)\bin\$(WDK_TARGET)\$(TCPU:x86_64=x64)\mt.exe)

else # !WDK 10.0.15063.0

TMC1 := $(call qpath,$(WDKN)\bin\$(TCPU:x86_64=x64)\mc.exe)
TRC1 := $(call qpath,$(WDKN)\bin\$(TCPU:x86_64=x64)\rc.exe)
TMT1 := $(call qpath,$(WDKN)\bin\$(TCPU:x86_64=x64)\mt.exe)

endif # !WDK 10.0.15063.0

MC1  := $(TMC1)
RC1  := $(TRC1)
MT1  := $(TMT1)
SUPPRESS_RC_LOGO := /nologo

endif # WDK

ifdef DRIVERS_SUPPORT

# KERNEL LEVEL

ifeq (,$(strip $(DDK)$(WDK)))
$(error no DDK nor WDK defined, example: DDK:="C:\WinDDK\7600.16385.1" or DDK:="C:\WDK71"\
 or WDK:="C:\Program Files (x86)\Windows Kits\8.1")
endif

ifdef DDK

ifdef WDK
$(error either DDK or WDK must be defined, but not both)
endif

ifneq (,$(call is_less,12,$(VS_VER)))
$(error too new Visual Studio version $(lastword $(subst \, ,$(VS))) to build with DDK, please use WDK)
endif

# target OS version
DDK_TARGET := $(if $(filter WINXP,$(WINVARIANT)),wxp,win7)

KMLIB := $(DDKN)\Lib\$(DDK_TARGET)\$(if $(KCPU:x86_64=),$(KCPU:x86=i386),amd64)
KMINC := $(DDKN)\inc\api $(DDKN)\inc\ddk $(DDKN)\inc\crt

WKLD  := $(call qpath,$(DDKN)\bin\x86\$(KCPU:x86_64=amd64)\link.exe)
WKCL  := $(call qpath,$(DDKN)\bin\x86\$(KCPU:x86_64=amd64)\cl.exe)

INF2CAT  := $(call qpath,$(DDKN)\bin\selfsign\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(DDKN)\bin\$(KCPU:x86_64=amd64)\SignTool.exe)

endif # DDK

ifdef WDK

ifdef DDK
$(error either DDK or WDK must be defined, but not both)
endif

# target kernel version - must be defined either in command line
# or in project configuration file before including this file, via:
# WDK_KTARGET := 10.0.10240.0
WDK_KTARGET:=

ifeq (,$(WDK_KTARGET))
$(error WDK_KTARGET undefined, check contents of "$(WDK)\Lib", example: win7, win8, winv6.3, 10.0.10240.0)
endif

ifneq (,$(filter win%,$(WDK_KTARGET)))
ifneq (,$(call is_less,12,$(VS_VER)))
$(error too new Visual Studio version $(lastword \
  $(subst \, ,$(VS))) to build with WDK_KTARGET=$(WDK_KTARGET), please select different WDK_KTARGET)
endif
endif

KMLIB := $(WDKN)\Lib\$(WDK_KTARGET)\km\$(KCPU:x86_64=x64)
KMINC := $(WDKN)\Include$(if $(call is_less,$(GET_WDK_VER),10),,\$(WDK_KTARGET))
KMINC := $(KMINC)\km $(KMINC)\km\crt $(KMINC)\shared

ifeq (,$(call is_less,1000,$(VS_VER)))

WKLD  := $(call qpath,$(VCN)\bin$(call VS_TOOL_PREFIX,$(KCPU))\link.exe)
WKCL  := $(call qpath,$(VCN)\bin$(call VS_TOOL_PREFIX,$(KCPU))\cl.exe)

else # Visual Studio 2017

WKLD  := $(call qpath,$(VCN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(KCPU:x86_64=x64)\link.exe)
WKCL  := $(call qpath,$(VCN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(KCPU:x86_64=x64)\cl.exe)

endif # Visual Studio 2017

INF2CAT  := $(call qpath,$(WDKN)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDKN)\bin\$(TCPU:x86_64=x64)\SignTool.exe)

# option for parallel builds, starting from Visual Studio 2013
ifneq (,$(call is_less,11,$(VS_VER)))
FORCE_SYNC_PDB_KERN := /FS
endif

endif # WDK

endif # DRIVERS_SUPPORT

endif # autoconf

# print autoconfigured vars
ifdef VAUTO
$(foreach x,$(AUTOCONF_VARS),$(info $x $(if $(findstring simple,$(flavor $x)),:)= $(value $x)))
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,VAUTO WINVARIANTS WINVARIANT WINVER_DEFINES \
  SUBSYSTEM_VER AUTOCONF_VARS $(AUTOCONF_VARS) NO_AUTOCONF VS_TOOL_PREFIX WDK_TARGET DDK_TARGET WDK_KTARGET \
  VS_VER WDK_VER GET_WDK_VER FORCE_SYNC_PDB FORCE_SYNC_PDB_KERN SUPPRESS_RC_LOGO VS WDK DDK SDK VCN WDKN DDKN SDKN ONECORE PATH)
