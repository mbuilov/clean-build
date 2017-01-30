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

OSVARIANTS ?= WINXP WINV WIN7 WIN8 WIN81 WIN10

ifeq ($(filter $(OSVARIANT),$(OSVARIANTS)),)
$(error OSVARIANT undefined or has wrong value, pick on of: $(OSVARIANTS))
endif

# note: WINVER_DEFINES may be defined as empty
ifeq (undefined,$(origin WINVER_DEFINES))
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
endif

ifndef SUBSYSTEM_VER
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
$(error VS undefined, example: VS="C:\Program Files (x86)\Microsoft Visual Studio 10.0")
endif

ifneq ($(subst \Microsoft Visual Studio ,,$(VS)),$(VS))
VS_VER  := $(firstword $(subst ., ,$(lastword $(VS))))
endif

ifndef VS_VER
$(error VS_VER undefined (expecting 8,9,11,12,14), \
  failed to auto-determine it, likely Visual Studio was installed to non-default location)
endif

ifneq ($(subst \Windows Kits\,,$(WDK)),$(WDK))
WDK_VER := $(firstword $(subst ., ,$(lastword $(subst \, ,$(WDK)))))
endif

GET_WDK_VER = $(if $(WDK_VER),$(WDK_VER),$(error WDK_VER undefined (expecting 7,8,9,10), \
  failed to auto-determine it, likely WDK was installed to non-default location))

# normalize: "x x" -> x?x
# used for paths passed to compilers and tools, but not searched by $(MAKE)
normpath = $(call unspaces,$(subst "",,$1))

VSN  := $(call normpath,$(VS))
SDKN := $(call normpath,$(SDK))
DDKN := $(call normpath,$(DDK))
WDKN := $(call normpath,$(WDK))

VSLIB  := $(VSN)\VC\lib$(if $(UCPU:%64=),,\amd64)
VSINC  := $(VSN)\VC\include

VSTLIB := $(VSN)\VC\lib$(if $(TCPU:%64=),,\amd64)
VSTINC := $(VSINC)

ifneq ($(call is_less,$(VS_VER),10),)

VSLD   := cd /d $(call qpath,$(VSN)\Common7\IDE) && $(call qpath,$(VSN)\VC\bin$(if $(UCPU:%64=),,\amd64)\link.exe)
VSCL   := cd /d $(call qpath,$(VSN)\Common7\IDE) && $(call qpath,$(VSN)\VC\bin$(if $(UCPU:%64=),,\amd64)\cl.exe)

VSTLD  := cd /d $(call qpath,$(VSN)\Common7\IDE) && $(call qpath,$(VSN)\VC\bin$(if $(TCPU:%64=),,\amd64)\link.exe)
VSTCL  := cd /d $(call qpath,$(VSN)\Common7\IDE) && $(call qpath,$(VSN)\VC\bin$(if $(TCPU:%64=),,\amd64)\cl.exe)

else # $(VS_VER) >= 10

VSLD   := $(call qpath,$(VSN)\VC\bin$(if $(UCPU:%64=),,\amd64)\link.exe)
VSCL   := $(call qpath,$(VSN)\VC\bin$(if $(UCPU:%64=),,\amd64)\cl.exe)

VSTLD  := $(call qpath,$(VSN)\VC\bin$(if $(TCPU:%64=),,\amd64)\link.exe)
VSTCL  := $(call qpath,$(VSN)\VC\bin$(if $(TCPU:%64=),,\amd64)\cl.exe)

endif # $(VS_VER) >= 10

# APP LEVEL

ifeq ($(strip $(SDK)$(WDK)),)
$(error no SDK nor WDK defined, example:\
 SDK="C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A" or WDK="C:\Program Files (x86)\Windows Kits\8.1")
endif

ifdef SDK

ifdef WDK
$(error either SDK or WDK must be defined, but not both)
endif

ifneq ($(call is_less,12,$(GET_VS_VER)),)
$(error too new Visual Studio version $(lastword $(VS)) to build with SDK, please use WDK)
endif

UMLIB  := $(SDKN)\Lib$(if $(UCPU:%64=),,\x64)
UMINC  := $(SDKN)\Include
UMTLIB := $(SDKN)\Lib$(if $(TCPU:%64=),,\x64)
UMTINC := $(UMINC)

MC1  := $(call qpath,$(SDKN)\bin$(if $(UCPU:%64=),,\x64)\MC.Exe)
RC1  := $(call qpath,$(SDKN)\bin$(if $(UCPU:%64=),,\x64)\RC.Exe)
MT1  := $(call qpath,$(SDKN)\bin$(if $(UCPU:%64=),,\x64)\MT.Exe)
TMC1 := $(call qpath,$(SDKN)\bin$(if $(TCPU:%64=),,\x64)\MC.Exe)
TRC1 := $(call qpath,$(SDKN)\bin$(if $(TCPU:%64=),,\x64)\RC.Exe)
TMT1 := $(call qpath,$(SDKN)\bin$(if $(TCPU:%64=),,\x64)\MT.Exe)

endif # SDK

ifdef WDK

ifdef SDK
$(error either SDK or WDK must be defined, but not both)
endif

ifndef WDK_TARGET
$(error WDK_TARGET undefined, check contents of "$(WDK)\Lib", example: "win7, win8, winv6.3, 10.0.10240.0")
endif

ifneq ($(call is_less,$(GET_WDK_VER),8),)

$(error too new WDK for building APP-level, use SDK instead)

else ifneq ($(call is_less,$(WDK_VER),10),)

UMLIB  := $(WDKN)\Lib\$(WDK_TARGET)\um\$(if $(UCPU:%64=),x86,x64)
UMINC  := $(WDKN)\Include
UMINC  := $(UMINC)\um $(UMINC)\shared
UMTLIB := $(WDKN)\Lib\$(WDK_TARGET)\um\$(if $(TCPU:%64=),x86,x64)
UMTINC := $(UMINC)

else # WDK10

UMLIB  := $(WDKN)\Lib\$(WDK_TARGET)\um\$(if $(UCPU:%64=),x86,x64) $(WDKN)\Lib\$(WDK_TARGET)\ucrt\$(if $(UCPU:%64=),x86,x64)
UMINC  := $(WDKN)\Include\$(WDK_TARGET)
UMINC  := $(UMINC)\um $(UMINC)\ucrt $(UMINC)\shared
UMTLIB := $(WDKN)\Lib\$(WDK_TARGET)\um\$(if $(TCPU:%64=),x86,x64) $(WDKN)\Lib\$(WDK_TARGET)\ucrt\$(if $(TCPU:%64=),x86,x64)
UMTINC := $(UMINC)

endif # WDK10

MC1  := $(call qpath,$(WDKN)\bin\$(if $(UCPU:%64=),x86,x64)\mc.exe)
RC1  := $(call qpath,$(WDKN)\bin\$(if $(UCPU:%64=),x86,x64)\rc.exe)
MT1  := $(call qpath,$(WDKN)\bin\$(if $(UCPU:%64=),x86,x64)\mt.exe)
TMC1 := $(call qpath,$(WDKN)\bin\$(if $(TCPU:%64=),x86,x64)\mc.exe)
TRC1 := $(call qpath,$(WDKN)\bin\$(if $(TCPU:%64=),x86,x64)\rc.exe)
TMT1 := $(call qpath,$(WDKN)\bin\$(if $(TCPU:%64=),x86,x64)\mt.exe)
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

ifneq ($(call is_less,12,$(GET_VS_VER)),)
$(error too new Visual Studio version $(lastword $(VS)) to build with DDK, please use WDK)
endif

DDK_TARGET := $(if $(filter WINXP,$(OSVARIANT)),wxp,win7)

KMLIB := $(DDKN)\Lib\$(DDK_TARGET)\$(if $(KCPU:%64=),i386,amd64)
KMINC := $(DDKN)\inc\api $(DDKN)\inc\crt $(DDKN)\inc\ddk

WKLD  := $(call qpath,$(DDKN)\bin\x86\$(if $(KCPU:%64=),x86,amd64)\link.exe)
WKCL  := $(call qpath,$(DDKN)\bin\x86\$(if $(KCPU:%64=),x86,amd64)\cl.exe)

INF2CAT  := $(call qpath,$(DDKN)\bin\selfsign\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(DDKN)\bin\$(if $(KCPU:%64=),x86,amd64)\SignTool.exe)

endif # DDK

ifdef WDK

ifdef DDK
$(error either DDK or WDK must be defined, but not both)
endif

ifndef WDK_TARGET
$(error WDK_TARGET undefined, check contents of "$(WDK)\Lib", example: "win7, win8, winv6.3, 10.0.10240.0")
endif

ifneq ($(filter win%,$(WDK_TARGET)),)
ifneq ($(call is_less,12,$(GET_VS_VER)),)
$(error too new Visual Studio version $(lastword $(VS)) to build with WDK_TARGET=$(WDK_TARGET), please select different WDK_TARGET)
endif
endif

KMLIB := $(WDKN)\Lib\$(WDK_TARGET)\km\$(if $(KCPU:%64=),x86,x64)
KMINC := $(WDKN)\Include$(if $(call is_less,$(GET_WDK_VER),10),,\$(WDK_TARGET))
KMINC := $(KMINC)\km $(KMINC)\km\crt $(KMINC)\shared

WKLD  := $(call qpath,$(VSN)\VC\bin$(if $(KCPU:%64=),,\amd64)\link.exe)
WKCL  := $(call qpath,$(VSN)\VC\bin$(if $(KCPU:%64=),,\amd64)\cl.exe)

INF2CAT  := $(call qpath,$(WDKN)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDKN)\bin\$(if $(KCPU:%64=),x86,x64)\SignTool.exe)

endif # WDK

endif # autoconf

# print autoconfigured vars
ifdef VAUTO
$(foreach x,$(AUTOCONF_VARS),$(info $x=$($x)))
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,VAUTO OSVARIANTS WINVER_DEFINES \
  SUBSYSTEM_VER AUTOCONF_VARS $(AUTOCONF_VARS) normpath VS VSN SDK SDKN DDK DDKN WDK WDKN)
