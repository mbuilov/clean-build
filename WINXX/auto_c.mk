#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# run via $(MAKE) A=1 to show autoconf results
ifeq ("$(origin A)","command line")
VAUTO := $A
endif

# 0 -> $(empty)
VAUTO := $(VAUTO:0=)

OSVARIANTS := WINXP WINV WIN7 WIN8 WIN81 WIN10

ifeq ($(filter $(OSVARIANT),$(OSVARIANTS)),)
$(error OSVARIANT undefined or has wrong value, pick on of: $(OSVARIANTS))
endif

# note: WINVER_DEFINES may be defined as empty
ifeq ($(OSVARIANT),WIN10)
WINVER_DEFINES := WINVER=0x0A00 _WIN32_WINNT=0x0A00
else ifeq ($(OSVARIANT),WIN81)
WINVER_DEFINES := WINVER=0x0603 _WIN32_WINNT=0x0603
else ifeq ($(OSVARIANT),WIN8)
WINVER_DEFINES := WINVER=0x0602 _WIN32_WINNT=0x0602
else ifeq ($(OSVARIANT),WIN7)
WINVER_DEFINES := WINVER=0x0601 _WIN32_WINNT=0x0601
else ifeq ($(OSVARIANT),WINV)
WINVER_DEFINES := WINVER=0x0600 _WIN32_WINNT=0x0600
else ifeq ($(OSVARIANT),WINXP)
WINVER_DEFINES := WINVER=0x0501 _WIN32_WINNT=0x0501
else
$(error unable to define WINVER for OSVARIANT = $(OSVARIANT))
endif

ifeq ($(OSVARIANT),WIN10)
SUBSYSTEM_VER := 6.03
else ifeq ($(OSVARIANT),WIN81)
SUBSYSTEM_VER := 6.03
else ifeq ($(OSVARIANT),WIN8)
SUBSYSTEM_VER := 6.02
else ifeq ($(OSVARIANT),WIN7)
SUBSYSTEM_VER := 6.01
else ifeq ($(OSVARIANT),WINV)
SUBSYSTEM_VER := 6.00
else ifeq ($(OSVARIANT),WINXP)
SUBSYSTEM_VER := $(if $(UCPU:%64=),5.01,5.02)
else
$(error unable to define SUBSYSTEM_VER for OSVARIANT = $(OSVARIANT))
endif

AUTOCONF_VARS :=
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

# check that all needed vars are defined, if not - autoconfigure
ifneq ($(words $(foreach x,$(AUTOCONF_VARS),$(if $($x),1))),$(words $(AUTOCONF_VARS)))

# autoconfigure

ifdef VAUTO
$(info try to autoconfigure...)
endif

ifndef VS
$(error VS undefined, example: VS="C:\Program Files (x86)\Microsoft Visual Studio 10.0" or\
 VS="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.10.25017")
endif

ifneq ($(subst \Microsoft Visual Studio ,,$(VS)),$(VS))
# 10.0 -> 10
VS_VER := $(firstword $(subst ., ,$(lastword $(VS))))
else ifneq ($(subst \VC\Tools\MSVC\,,$(VS)),$(VS))
# 14.10.25017 -> 1410
VS_VER := $(subst $(space),,$(wordlist 1,2,$(subst ., ,$(word 2,$(subst \VC\Tools\MSVC\, ,$(subst $(space),?,$(VS)))))))
endif

ifndef VS_VER
$(error VS_VER undefined (expecting 8,9,11,12,14,1410), \
  failed to auto-determine it, likely Visual Studio is installed to non-default location)
endif

ifneq ($(subst \Windows Kits\,,$(WDK)),$(WDK))
WDK_VER := $(firstword $(subst ., ,$(lastword $(subst \, ,$(WDK)))))
endif

GET_WDK_VER = $(if $(WDK_VER),$(WDK_VER),$(error WDK_VER undefined (expecting 7,8,9,10), \
  failed to auto-determine it, likely WDK is installed to non-default location))

# normalize: x x -> x?x
VSN  := $(call unspaces,$(VS))
SDKN := $(call unspaces,$(SDK))
DDKN := $(call unspaces,$(DDK))
WDKN := $(call unspaces,$(WDK))

# APP LEVEL

ifeq ($(call is_less,1000,$(VS_VER)),)

VSLIB  := $(VSN)\VC\lib$(ONECORE)$(addprefix \,$(filter-out x86,$(UCPU:x86_64=amd64)))
VSINC  := $(VSN)\VC\include

VSTLIB := $(VSN)\VC\lib$(addprefix \,$(filter-out x86,$(TCPU:x86_64=amd64)))
VSTINC := $(VSINC)

# determine tool prefix $(TCPU)_$1 where
# $1 - target cpu (either $(UCPU) or $(KCPU))
# Note: some prefixes reduced:
#  amd64_amd64 -> amd64
#  x86_x86     -> <none>
VS_TOOL_PREFIX = $(addprefix \,$(filter-out x86_x86,$(subst amd64_amd64,amd64,$(TCPU:x86_64=amd64)_$(1:x86_64=amd64))))

VSLD   := $(call qpath,$(VSN)\VC\bin$(call VS_TOOL_PREFIX,$(UCPU))\link.exe)
VSCL   := $(call qpath,$(VSN)\VC\bin$(call VS_TOOL_PREFIX,$(UCPU))\cl.exe)

VSTLD  := $(call qpath,$(VSN)\VC\bin$(call VS_TOOL_PREFIX,$(TCPU))\link.exe)
VSTCL  := $(call qpath,$(VSN)\VC\bin$(call VS_TOOL_PREFIX,$(TCPU))\cl.exe)

# set path to dlls needed by cl.exe and link.exe to work
ifneq ($(call is_less,$(VS_VER),10),)

ifneq ($(call VS_TOOL_PREFIX,$(UCPU)),\amd64)
# not for \amd64
PATH := $(PATH);$(VS)\VC\bin;$(VS)\Common7\IDE
endif

else ifneq ($(call is_less,$(VS_VER),13),)

ifneq ($(UCPU),$(TCPU))
# for \x86_amd64
PATH := $(PATH);$(VS)\VC\bin
endif

else # Visual Studio 2015

ifneq ($(UCPU),$(TCPU))
# for \amd64_arm
# for \amd64_x86
# for \x86_amd64
# for \x86_arm
PATH := $(PATH);$(VS)\VC\bin$(addprefix \,$(filter-out x86,$(TCPU:x86_64=amd64)))
endif

endif

else # Visual Studio 2017

VSLIB  := $(VSN)\lib$(ONECORE)\$(UCPU:x86_64=x64)
VSINC  := $(VSN)\include

VSTLIB := $(VSN)\lib\$(TCPU:x86_64=x64)
VSTINC := $(VSINC)

VSLD   := $(call qpath,$(VSN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(UCPU:x86_64=x64)\link.exe)
VSCL   := $(call qpath,$(VSN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(UCPU:x86_64=x64)\cl.exe)

VSTLD  := $(call qpath,$(VSN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(TCPU:x86_64=x64)\link.exe)
VSTCL  := $(call qpath,$(VSN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(TCPU:x86_64=x64)\cl.exe)

# set path to dlls needed by cl.exe and link.exe to work
ifneq ($(UCPU),$(TCPU))
# for HostX64/x86
# for HostX86/x64
PATH := $(PATH);$(VS)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(TCPU:x86_64=x64)
endif

endif

# PATH variable may have changed, print it to generated batch file
$(if $(VERBOSE),$(info setlocal$(newline)set "PATH=$(PATH)"))

# option for parallel builds, starting from Visual Studio 2013
ifneq ($(call is_less,11,$(VS_VER)),)
FORCE_SYNC_PDB := /FS
endif

ifeq ($(strip $(SDK)$(WDK)),)
$(error no SDK nor WDK defined, example:\
 SDK="C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A" or WDK="C:\Program Files (x86)\Windows Kits\8.1")
endif

ifdef SDK

ifdef WDK
$(error either SDK or WDK must be defined, but not both)
endif

ifneq ($(call is_less,12,$(VS_VER)),)
$(error too new Visual Studio version $(lastword $(subst \, ,$(VS))) to build with SDK, please use WDK)
endif

UMLIB  := $(SDKN)\Lib$(addprefix \,$(filter-out x86,$(UCPU:x86_64=x64)))
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

ifndef WDK_TARGET
$(error WDK_TARGET undefined, check contents of "$(WDK)\Lib", example: "win7, win8, winv6.3, 10.0.10240.0")
endif

ifneq ($(call is_less,$(GET_WDK_VER),8),)

$(error unsuitable WDK version $(GET_WDK_VER) for building APP-level, use SDK instead)

else ifneq ($(call is_less,$(WDK_VER),10),)

UMLIB  := $(WDKN)\Lib\$(WDK_TARGET)\um\$(UCPU:x86_64=x64)
UMINC  := $(WDKN)\Include
UMINC  := $(UMINC)\um $(UMINC)\shared
UMTLIB := $(WDKN)\Lib\$(WDK_TARGET)\um\$(TCPU:x86_64=x64)
UMTINC := $(UMINC)

else # WDK10

UMLIB  := $(WDKN)\Lib\$(WDK_TARGET)\um\$(UCPU:x86_64=x64) $(WDKN)\Lib\$(WDK_TARGET)\ucrt\$(UCPU:x86_64=x64)
UMINC  := $(WDKN)\Include\$(WDK_TARGET)
UMINC  := $(UMINC)\um $(UMINC)\ucrt $(UMINC)\shared
UMTLIB := $(WDKN)\Lib\$(WDK_TARGET)\um\$(TCPU:x86_64=x64) $(WDKN)\Lib\$(WDK_TARGET)\ucrt\$(TCPU:x86_64=x64)
UMTINC := $(UMINC)

endif # WDK10

TMC1 := $(call qpath,$(WDKN)\bin\$(TCPU:x86_64=x64)\mc.exe)
TRC1 := $(call qpath,$(WDKN)\bin\$(TCPU:x86_64=x64)\rc.exe)
TMT1 := $(call qpath,$(WDKN)\bin\$(TCPU:x86_64=x64)\mt.exe)
MC1  := $(TMC1)
RC1  := $(TRC1)
MT1  := $(TMT1)
SUPPRESS_RC_LOGO := /nologo

endif # WDK

# KERNEL LEVEL

ifeq ($(strip $(DDK)$(WDK)),)
$(error no DDK nor WDK defined, example: DDK=C:\WinDDK\7600.16385.1 or WDK="C:\Program Files (x86)\Windows Kits\8.1")
endif

ifdef DDK

ifdef WDK
$(error either DDK or WDK must be defined, but not both)
endif

ifneq ($(call is_less,12,$(VS_VER)),)
$(error too new Visual Studio version $(lastword $(subst \, ,$(VS))) to build with DDK, please use WDK)
endif

DDK_TARGET := $(if $(filter WINXP,$(OSVARIANT)),wxp,win7)

KMLIB := $(DDKN)\Lib\$(DDK_TARGET)\$(if $(KCPU:x86_64=),$(KCPU:x86=i386),amd64)
KMINC := $(DDKN)\inc\api $(DDKN)\inc\crt $(DDKN)\inc\ddk

WKLD  := $(call qpath,$(DDKN)\bin\x86\$(KCPU:x86_64=amd64)\link.exe)
WKCL  := $(call qpath,$(DDKN)\bin\x86\$(KCPU:x86_64=amd64)\cl.exe)

INF2CAT  := $(call qpath,$(DDKN)\bin\selfsign\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(DDKN)\bin\$(KCPU:x86_64=amd64)\SignTool.exe)

endif # DDK

ifdef WDK

ifdef DDK
$(error either DDK or WDK must be defined, but not both)
endif

WDK_KTARGET := $(WDK_TARGET)

ifndef WDK_KTARGET
$(error WDK_KTARGET undefined, check contents of "$(WDK)\Lib", example: "win7, win8, winv6.3, 10.0.10240.0")
endif

ifneq ($(filter win%,$(WDK_KTARGET)),)
ifneq ($(call is_less,12,$(VS_VER)),)
$(error too new Visual Studio version $(lastword \
  $(subst \, ,$(VS))) to build with WDK_KTARGET=$(WDK_KTARGET), please select different WDK_KTARGET)
endif
endif

KMLIB := $(WDKN)\Lib\$(WDK_KTARGET)\km\$(KCPU:x86_64=x64)
KMINC := $(WDKN)\Include$(if $(call is_less,$(GET_WDK_VER),10),,\$(WDK_KTARGET))
KMINC := $(KMINC)\km $(KMINC)\km\crt $(KMINC)\shared

ifeq ($(call is_less,1000,$(VS_VER)),)

WKLD  := $(call qpath,$(VSN)\VC\bin$(call VS_TOOL_PREFIX,$(KCPU))\link.exe)
WKCL  := $(call qpath,$(VSN)\VC\bin$(call VS_TOOL_PREFIX,$(KCPU))\cl.exe)

else # Visual Studio 2017

WKLD  := $(call qpath,$(VSN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(KCPU:x86_64=x64)\link.exe)
WKCL  := $(call qpath,$(VSN)\bin\Host$(patsubst x%,X%,$(TCPU:x86_64=x64))\$(KCPU:x86_64=x64)\cl.exe)

endif

INF2CAT  := $(call qpath,$(WDKN)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDKN)\bin\$(TCPU:x86_64=x64)\SignTool.exe)

endif # WDK

endif # autoconf

# print autoconfigured vars
ifdef VAUTO
$(foreach x,$(AUTOCONF_VARS),$(info $x=$($x)))
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,VAUTO OSVARIANTS WINVER_DEFINES SUBSYSTEM_VER AUTOCONF_VARS $(AUTOCONF_VARS) \
  VS_VER WDK_VER GET_WDK_VER ONECORE FORCE_SYNC_PDB VS_TOOL_PREFIX VS VSN SDK SDKN DDK DDKN WDK WDKN)
