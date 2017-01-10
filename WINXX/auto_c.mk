#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPLv2+, see COPYING
#----------------------------------------------------------------------------------

# run via $(MAKE) A=1 to show autoconf results
ifeq ("$(origin A)","command line")
VAUTO := $A
endif

# 0 -> $(empty)
VAUTO := $(VAUTO:0=)

OSVARIANTS ?= WINXP WIN7 WIN8 WIN81 WIN10

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
AVALUES := $(words $(foreach x,$(AUTOCONF_VARS),$(if $($x),1)))
ifneq ($(AVALUES),$(words $(AUTOCONF_VARS)))

ifneq ($(AVALUES),0)
$(foreach x,$(AUTOCONF_VARS),$(if $($x),,$(error \
  $x is undefined, either define it or undefine $(strip $(foreach x,$(AUTOCONF_VARS),$(if $($x),$x))) variable(s) to autoconfigure)))
endif

# autoconf

ifdef VAUTO
$(info try to autoconfigure...)
endif

ifndef VS
$(error VS undefined, example: VS="C:\Program Files (x86)\Microsoft Visual Studio 10.0")
endif

# normalize: "x x" -> x?x
# used for paths passed to compilers and tools, but not searched by $(MAKE)
normpath = $(call unspaces,$(subst ",,$1))

VSN  := $(call normpath,$(VS))
SDKN := $(call normpath,$(SDK))
DDKN := $(call normpath,$(DDK))
WDKN := $(call normpath,$(WDK))

VSLIB  := $(VSN)\VC\lib$(if $(UCPU:%64=),,\amd64)
VSINC  := $(VSN)\VC\include
VSLD   := $(call qpath,$(VSN)\VC\bin$(if $(UCPU:%64=),,\amd64)\link.exe)
VSCL   := $(call qpath,$(VSN)\VC\bin$(if $(UCPU:%64=),,\amd64)\cl.exe)

VSTLIB := $(VSN)\VC\lib$(if $(TCPU:%64=),,\amd64)
VSTINC := $(VSINC)
VSTLD  := $(call qpath,$(VSN)\VC\bin$(if $(TCPU:%64=),,\amd64)\link.exe)
VSTCL  := $(call qpath,$(VSN)\VC\bin$(if $(TCPU:%64=),,\amd64)\cl.exe)

# SDK

ifneq ($(filter WINXP WIN7,$(OSVARIANT)),)

VS_VER  := $(firstword $(subst ., ,$(lastword $(VS))))
VS_VERx := $(subst 0,x,$(subst 1,x,$(subst 2,x,$(subst 3,x,$(subst 4,x,$(subst \
  5,x,$(subst 6,x,$(subst 7,x,$(subst 8,x,$(subst 9,x,$(VS_VER)))))))))))

ifneq ($(if $(filter-out x,$(lastword $(sort x $(VS_VERx)))),$(filter-out \
  xx,$(lastword $(sort xx $(VS_VERx))))$(filter-out 12,$(lastword $(sort 12 $(VS_VER))))),)
$(error too new Visual Studio version $(lastword $(VS)) - may build targets for WINXP or WIN7 only with Visual Studio 12.0 or older)
endif

ifndef SDK
$(error SDK undefined, example: SDK="C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A")
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

endif # WINXP, WIN7

ifneq ($(filter WIN8 WIN81 WIN10,$(OSVARIANT)),)

ifndef WDK
$(error WDK undefined, example: WDK="C:\Program Files (x86)\Windows Kits\8.0")
endif

ifndef WDK_VER
$(error WDK_VER undefined, example: "Win8, winv6.3, 10.0.10240.0")
endif

ifneq ($(filter WIN8 WIN81,$(OSVARIANT)),)

UMLIB  := $(WDKN)\Lib\$(WDK_VER)\um\$(if $(UCPU:%64=),x86,x64)
UMINC  := $(WDKN)\Include\um $(WDKN)\Include\shared
UMTLIB := $(WDKN)\Lib\$(WDK_VER)\um\$(if $(TCPU:%64=),x86,x64)
UMTINC := $(UMINC)

else # WIN10

UMLIB  := $(WDKN)\Lib\$(WDK_VER)\um\$(if $(UCPU:%64=),x86,x64) $(WDKN)\Lib\$(WDK_VER)\ucrt\$(if $(UCPU:%64=),x86,x64)
UMINC  := $(WDKN)\Include\$(WDK_VER)\um $(WDKN)\Include\$(WDK_VER)\ucrt $(WDKN)\Include\$(WDK_VER)\shared
UMTLIB := $(WDKN)\Lib\$(WDK_VER)\um\$(if $(TCPU:%64=),x86,x64) $(WDKN)\Lib\$(WDK_VER)\ucrt\$(if $(TCPU:%64=),x86,x64)
UMTINC := $(UMINC)

endif # WIN10

MC1  := $(call qpath,$(WDKN)\bin\$(if $(UCPU:%64=),x86,x64)\mc.exe)
RC1  := $(call qpath,$(WDKN)\bin\$(if $(UCPU:%64=),x86,x64)\rc.exe)
MT1  := $(call qpath,$(WDKN)\bin\$(if $(UCPU:%64=),x86,x64)\mt.exe)
TMC1 := $(call qpath,$(WDKN)\bin\$(if $(TCPU:%64=),x86,x64)\mc.exe)
TRC1 := $(call qpath,$(WDKN)\bin\$(if $(TCPU:%64=),x86,x64)\rc.exe)
TMT1 := $(call qpath,$(WDKN)\bin\$(if $(TCPU:%64=),x86,x64)\mt.exe)

endif # WIN8, WIN81, WIN10

# DDK

ifeq ($(OSVARIANT),WINXP)

ifndef DDK
$(error DDK undefined, example: DDK=C:\WinDDK\7600.16385.1)
endif

KMLIB := $(DDKN)\Lib\wxp\$(if $(KCPU:%64=),i386,amd64)
KMINC := $(DDKN)\inc\api $(DDKN)\inc\crt $(DDKN)\inc\ddk
WKLD  := $(call qpath,$(DDKN)\bin\x86\$(if $(KCPU:%64=),x86,amd64)\link.exe)
WKCL  := $(call qpath,$(DDKN)\bin\x86\$(if $(KCPU:%64=),x86,amd64)\cl.exe)

INF2CAT  := $(call qpath,$(DDKN)\bin\selfsign\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(DDKN)\bin\$(if $(KCPU:%64=),x86,amd64)\SignTool.exe)

endif # WINXP

ifeq ($(OSVARIANT),WIN7)

ifeq ($(strip $(DDK)$(WDK)),)
$(error no DDK nor WDK defined, example: DDK=C:\WinDDK\7600.16385.1 or WDK="C:\Program Files (x86)\Windows Kits\8.1")
endif

ifdef DDK

ifdef WDK
$(error either DDK or WDK must be defined, but not both)
endif

KMLIB := $(DDKN)\Lib\win7\$(if $(KCPU:%64=),i386,amd64)
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

KMLIB := $(WDKN)\Lib\win7\km\$(if $(KCPU:%64=),x86,x64)
KMINC := $(WDKN)\Include\km $(WDKN)\Include\km\crt $(WDKN)\Include\shared
WKLD  := $(call qpath,$(VSN)\VC\bin$(if $(KCPU:%64=),,\amd64)\link.exe)
WKCL  := $(call qpath,$(VSN)\VC\bin$(if $(KCPU:%64=),,\amd64)\cl.exe)

INF2CAT  := $(call qpath,$(WDKN)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDKN)\bin\$(if $(KCPU:%64=),x86,x64)\SignTool.exe)

endif # WDK

endif # WIN7

ifneq ($(filter WIN8 WIN81 WIN10,$(OSVARIANT)),)

ifndef WDK
$(error WDK undefined, example: WDK="C:\Program Files (x86)\Windows Kits\8.1")
endif

ifndef WDK_VER
$(error WDK_VER undefined, example: "Win8, winv6.3, 10.0.10240.0")
endif

ifneq ($(filter WIN8 WIN81,$(OSVARIANT)),)

KMLIB := $(WDKN)\Lib\$(WDK_VER)\km\$(if $(KCPU:%64=),x86,x64)
KMINC := $(WDKN)\Include\km $(WDKN)\Include\km\crt $(WDKN)\Include\shared

else # WIN10

KMLIB := $(WDKN)\Lib\$(WDK_VER)\km\$(if $(KCPU:%64=),x86,x64)
KMINC := $(WDKN)\Include\$(WDK_VER)\km $(WDKN)\Include\$(WDK_VER)\km\crt $(WDKN)\Include\$(WDK_VER)\shared

endif # WIN10

WKLD  := $(call qpath,$(VSN)\VC\bin$(if $(KCPU:%64=),,\amd64)\link.exe)
WKCL  := $(call qpath,$(VSN)\VC\bin$(if $(KCPU:%64=),,\amd64)\cl.exe)

INF2CAT  := $(call qpath,$(WDKN)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDKN)\bin\$(if $(KCPU:%64=),x86,x64)\SignTool.exe)

endif # WIN8, WIN81, WIN10

endif # autoconf

# print autoconfigured vars
ifdef VAUTO
$(foreach x,$(AUTOCONF_VARS),$(info $x=$($x)))
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,VAUTO OSVARIANTS WINVER_DEFINES \
  SUBSYSTEM_VER AUTOCONF_VARS $(AUTOCONF_VARS) normpath VS VSN SDK SDKN DDK DDKN WDK WDKN)
