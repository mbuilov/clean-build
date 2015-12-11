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
AUTOCONF_VARS += TMC1     # full path in quotes
AUTOCONF_VARS += TRC1     # full path in quotes
AUTOCONF_VARS += MT       # full path in quotes

# check that all needed vars are defined, if not - autoconfigure
ifneq ($(words $(foreach x,$(AUTOCONF_VARS),$($x))),$(words $(AUTOCONF_VARS)))

ifdef VAUTO
$(info some of $(AUTOCONF_VARS) are undefined, try to autoconf:)
endif

# normalize: "x x" -> x?x
# used for paths passed to compilers and tools, but not searched by $(MAKE)
normpath = $(call unspaces,$(subst ",,$1))

VS  := $(call normpath,$(VS))
SDK := $(call normpath,$(SDK))
DDK := $(call normpath,$(DDK))
WDK := $(call normpath,$(WDK))

# autoconf

ifndef VS
$(error VS undefined, example: "C:\Program Files (x86)\Microsoft Visual Studio 10.0")
endif

VSLIB  := $(VS)\VC\lib$(if $(UCPU:%64=),,\amd64)
VSINC  := $(VS)\VC\include
VSLD   := $(call qpath,$(VS)\VC\bin$(if $(UCPU:%64=),,\amd64)\link.exe)
VSCL   := $(call qpath,$(VS)\VC\bin$(if $(UCPU:%64=),,\amd64)\cl.exe)

VSTLIB := $(VS)\VC\lib$(if $(TCPU:%64=),,\amd64)
VSTINC := $(VSINC)
VSTLD  := $(call qpath,$(VS)\VC\bin$(if $(TCPU:%64=),,\amd64)\link.exe)
VSTCL  := $(call qpath,$(VS)\VC\bin$(if $(TCPU:%64=),,\amd64)\cl.exe)

# SDK

ifneq ($(filter WINXP WIN7,$(OSVARIANT)),)

ifndef SDK
$(error SDK undefined, example: "C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A")
endif

UMLIB  := $(SDK)\Lib$(if $(UCPU:%64=),,\x64)
UMINC  := $(SDK)\Include
UMTLIB := $(SDK)\Lib$(if $(TCPU:%64=),,\x64)
UMTINC := $(UMINC)

MC1  := $(call qpath,$(SDK)\bin$(if $(UCPU:%64=),,\x64)\MC.Exe)
RC1  := $(call qpath,$(SDK)\bin$(if $(UCPU:%64=),,\x64)\RC.Exe)
MT1  := $(call qpath,$(SDK)\bin$(if $(UCPU:%64=),,\x64)\MT.Exe)
TMC1 := $(call qpath,$(SDK)\bin$(if $(TCPU:%64=),,\x64)\MC.Exe)
TRC1 := $(call qpath,$(SDK)\bin$(if $(TCPU:%64=),,\x64)\RC.Exe)
TMT1 := $(call qpath,$(SDK)\bin$(if $(TCPU:%64=),,\x64)\MT.Exe)

endif

ifeq ($(OSVARIANT),WIN8)

ifndef SDK
$(error SDK undefined, example: "C:\Program Files (x86)\Windows Kits\8.0")
endif

UMLIB  := $(SDK)\Lib\Win8\um\$(if $(UCPU:%64=),x86,x64)
UMINC  := $(SDK)\Include\um $(SDK)\Include\shared
UMTLIB := $(SDK)\Lib\Win8\um\$(if $(TCPU:%64=),x86,x64)
UMTINC := $(UMINC)

MC1  := $(call qpath,$(SDK)\bin\$(if $(UCPU:%64=),x86,x64)\mc.exe)
RC1  := $(call qpath,$(SDK)\bin\$(if $(UCPU:%64=),x86,x64)\rc.exe)
MT1  := $(call qpath,$(SDK)\bin\$(if $(UCPU:%64=),x86,x64)\mt.exe)
TMC1 := $(call qpath,$(SDK)\bin\$(if $(TCPU:%64=),x86,x64)\mc.exe)
TRC1 := $(call qpath,$(SDK)\bin\$(if $(TCPU:%64=),x86,x64)\rc.exe)
TMT1 := $(call qpath,$(SDK)\bin\$(if $(TCPU:%64=),x86,x64)\mt.exe)

endif

ifeq ($(OSVARIANT),WIN81)

ifndef WDK
$(error WDK undefined, example: "C:\Program Files (x86)\Windows Kits\8.1")
endif

UMLIB  := $(WDK)\Lib\winv6.3\um\$(if $(UCPU:%64=),x86,x64)
UMINC  := $(WDK)\Include\um $(WDK)\Include\shared
UMTLIB := $(WDK)\Lib\winv6.3\um\$(if $(TCPU:%64=),x86,x64)
UMTINC := $(UMINC)

endif

ifeq ($(OSVARIANT),WIN10)

ifndef WDK
$(error WDK undefined, example: "C:\Program Files (x86)\Windows Kits\10")
endif

UMLIB  := $(WDK)\Lib\10.0.10240.0\um\$(if $(UCPU:%64=),x86,x64) $(WDK)\Lib\10.0.10240.0\ucrt\$(if $(UCPU:%64=),x86,x64)
UMINC  := $(WDK)\Include\10.0.10240.0\um $(WDK)\Include\10.0.10240.0\ucrt $(WDK)\Include\10.0.10240.0\shared
UMTLIB := $(WDK)\Lib\10.0.10240.0\um\$(if $(TCPU:%64=),x86,x64) $(WDK)\Lib\10.0.10240.0\ucrt\$(if $(TCPU:%64=),x86,x64)
UMTINC := $(UMINC)

endif

ifneq ($(filter WIN81 WIN10,$(OSVARIANT)),)

MC1  := $(call qpath,$(WDK)\bin\$(if $(UCPU:%64=),x86,x64)\mc.exe)
RC1  := $(call qpath,$(WDK)\bin\$(if $(UCPU:%64=),x86,x64)\rc.exe)
MT1  := $(call qpath,$(WDK)\bin\$(if $(UCPU:%64=),x86,x64)\mt.exe)
TMC1 := $(call qpath,$(WDK)\bin\$(if $(TCPU:%64=),x86,x64)\mc.exe)
TRC1 := $(call qpath,$(WDK)\bin\$(if $(TCPU:%64=),x86,x64)\rc.exe)
TMT1 := $(call qpath,$(WDK)\bin\$(if $(TCPU:%64=),x86,x64)\mt.exe)

endif

# DDK

ifeq ($(OSVARIANT),WINXP)

ifndef DDK
$(error DDK undefined, example: C:\WinDDK\7600.16385.1)
endif

KMLIB := $(DDK)\Lib\wxp\$(if $(KCPU:%64=),i386,amd64)
KMINC := $(DDK)\inc\api $(DDK)\inc\crt $(DDK)\inc\ddk
WKLD  := $(call qpath,$(DDK)\bin\x86\$(if $(KCPU:%64=),x86,amd64)\link.exe)
WKCL  := $(call qpath,$(DDK)\bin\x86\$(if $(KCPU:%64=),x86,amd64)\cl.exe)

INF2CAT  := $(call qpath,$(DDK)\bin\selfsign\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(DDK)\bin\$(if $(KCPU:%64=),x86,amd64)\SignTool.exe)

endif

ifeq ($(OSVARIANT),WIN7)

ifeq ($(strip $(DDK)$(WDK)),)
$(error no DDK nor WDK defined, example: DDK=C:\WinDDK\7600.16385.1 or WDK="C:\Program Files (x86)\Windows Kits\8.1")
endif

ifdef DDK

ifdef WDK
$(error either DDK or WDK must be defined, but not both)
endif

KMLIB := $(DDK)\Lib\win7\$(if $(KCPU:%64=),i386,amd64)
KMINC := $(DDK)\inc\api $(DDK)\inc\crt $(DDK)\inc\ddk
WKLD  := $(call qpath,$(DDK)\bin\x86\$(if $(KCPU:%64=),x86,amd64)\link.exe)
WKCL  := $(call qpath,$(DDK)\bin\x86\$(if $(KCPU:%64=),x86,amd64)\cl.exe)

INF2CAT  := $(call qpath,$(DDK)\bin\selfsign\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(DDK)\bin\$(if $(KCPU:%64=),x86,amd64)\SignTool.exe)

endif

ifdef WDK

ifdef DDK
$(error either DDK or WDK must be defined, but not both)
endif

KMLIB := $(WDK)\Lib\win7\km\$(if $(KCPU:%64=),x86,x64)
KMINC := $(WDK)\Include\km $(WDK)\Include\km\crt $(WDK)\Include\shared
WKLD  := $(call qpath,$(VS)\VC\bin$(if $(KCPU:%64=),,\amd64)\link.exe)
WKCL  := $(call qpath,$(VS)\VC\bin$(if $(KCPU:%64=),,\amd64)\cl.exe)

INF2CAT  := $(call qpath,$(WDK)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDK)\bin\$(if $(KCPU:%64=),x86,x64)\SignTool.exe)

endif

endif

ifneq ($(filter WIN8 WIN81,$(OSVARIANT)),)

ifndef WDK
$(error WDK undefined, example: "C:\Program Files (x86)\Windows Kits\8.1")
endif

KMLIB := $(WDK)\Lib\$(if $(OSVARIANT:WIN81=),win8,winv6.3)\km\$(if $(KCPU:%64=),x86,x64)
KMINC := $(WDK)\Include\km $(WDK)\Include\km\crt $(WDK)\Include\shared
WKLD  := $(call qpath,$(VS)\VC\bin$(if $(KCPU:%64=),,\amd64)\link.exe)
WKCL  := $(call qpath,$(VS)\VC\bin$(if $(KCPU:%64=),,\amd64)\cl.exe)

INF2CAT  := $(call qpath,$(WDK)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDK)\bin\$(if $(KCPU:%64=),x86,x64)\SignTool.exe)

endif

ifneq ($(filter WIN10,$(OSVARIANT)),)

ifndef WDK
$(error WDK undefined, example: "C:\Program Files (x86)\Windows Kits\10")
endif

KMLIB := $(WDK)\Lib\10.0.10240.0\km\$(if $(KCPU:%64=),x86,x64)
KMINC := $(WDK)\Include\10.0.10240.0\km $(WDK)\Include\10.0.10240.0\km\crt $(WDK)\Include\10.0.10240.0\shared
WKLD  := $(call qpath,$(VS)\VC\bin$(if $(KCPU:%64=),,\amd64)\link.exe)
WKCL  := $(call qpath,$(VS)\VC\bin$(if $(KCPU:%64=),,\amd64)\cl.exe)

INF2CAT  := $(call qpath,$(WDK)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDK)\bin\$(if $(KCPU:%64=),x86,x64)\SignTool.exe)

endif

endif # !NO_AUTOCONF

# print autoconfigured vars
ifdef VAUTO
$(foreach x,$(AUTOCONF_VARS),$(info $x=$($x)))
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_APPEND_PROTECTED_VARS,VAUTO OSVARIANTS WINVER_DEFINES \
  SUBSYSTEM_VER AUTOCONF_VARS $(AUTOCONF_VARS) normpath VS SDK DDK WDK)
