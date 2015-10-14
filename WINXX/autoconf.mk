OSVARIANTS := WINXP WIN7 WIN8 WIN81 WIN10

ifeq ($(filter $(OSVARIANT),$(OSVARIANTS)),)
$(error OSVARIANT undefined or has wrong value, pick on of: $(OSVARIANTS))
endif

NEEDED_TOOLS :=
NEEDED_TOOLS += VSLIB  # spaces must be replaced with ?
NEEDED_TOOLS += VSINC  # spaces must be replaced with ?
NEEDED_TOOLS += VSLD   # full path in quotes
NEEDED_TOOLS += VSCL   # full path in quotes
NEEDED_TOOLS += UMLIB  # spaces must be replaced with ?
NEEDED_TOOLS += UMINC  # spaces must be replaced with ?
NEEDED_TOOLS += VSTLIB # spaces must be replaced with ?
NEEDED_TOOLS += VSTINC # spaces must be replaced with ?
NEEDED_TOOLS += VSTLD  # full path in quotes
NEEDED_TOOLS += VSTCL  # full path in quotes
NEEDED_TOOLS += UMTLIB # spaces must be replaced with ?
NEEDED_TOOLS += UMTINC # spaces must be replaced with ?
NEEDED_TOOLS += KMLIB  # spaces must be replaced with ?
NEEDED_TOOLS += KMINC  # spaces must be replaced with ?
NEEDED_TOOLS += WKLD   # full path in quotes
NEEDED_TOOLS += WKCL   # full path in quotes
NEEDED_TOOLS += MC1    # full path in quotes
NEEDED_TOOLS += RC1    # full path in quotes
NEEDED_TOOLS += TMC1   # full path in quotes
NEEDED_TOOLS += TRC1   # full path in quotes
NEEDED_TOOLS += MT     # full path in quotes

ifneq ($(words $(foreach x,$(NEEDED_TOOLS),$($x))),$(words $(NEEDED_TOOLS)))

ifdef VAUTO
$(info some of $(NEEDED_TOOLS) is undefined, try to autoconf:)
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

VSLIB  := $(VS)\VC\lib$(if $(filter %64,$(UCPU)),\amd64)
VSINC  := $(VS)\VC\include
VSLD   := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(UCPU)),\amd64)\link.exe)
VSCL   := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(UCPU)),\amd64)\cl.exe)

VSTLIB := $(VS)\VC\lib$(if $(filter %64,$(TCPU)),\amd64)
VSTINC := $(VSINC)
VSTLD  := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(TCPU)),\amd64)\link.exe)
VSTCL  := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(TCPU)),\amd64)\cl.exe)

# SDK

ifneq ($(filter WINXP WIN7,$(OSVARIANT)),)

ifndef SDK
$(error SDK undefined, example: "C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A")
endif

UMLIB  := $(SDK)\Lib$(if $(filter %64,$(UCPU)),\x64)
UMINC  := $(SDK)\Include
UMTLIB := $(SDK)\Lib$(if $(filter %64,$(TCPU)),\x64)
UMTINC := $(UMINC)

MC1  := $(call qpath,$(SDK)\bin$(if $(filter %64,$(UCPU)),\x64)\MC.Exe)
RC1  := $(call qpath,$(SDK)\bin$(if $(filter %64,$(UCPU)),\x64)\RC.Exe)
MT1  := $(call qpath,$(SDK)\bin$(if $(filter %64,$(UCPU)),\x64)\MT.Exe)
TMC1 := $(call qpath,$(SDK)\bin$(if $(filter %64,$(TCPU)),\x64)\MC.Exe)
TRC1 := $(call qpath,$(SDK)\bin$(if $(filter %64,$(TCPU)),\x64)\RC.Exe)
TMT1 := $(call qpath,$(SDK)\bin$(if $(filter %64,$(TCPU)),\x64)\MT.Exe)

endif

ifeq ($(OSVARIANT),WIN8)

ifndef SDK
$(error SDK undefined, example: "C:\Program Files (x86)\Windows Kits\8.0")
endif

UMLIB  := $(SDK)\Lib\Win8\um\$(if $(filter %64,$(UCPU)),x64,x86)
UMINC  := $(SDK)\Include\um $(SDK)\Include\shared
UMTLIB := $(SDK)\Lib\Win8\um\$(if $(filter %64,$(TCPU)),x64,x86)
UMTINC := $(UMINC)

MC1  := $(call qpath,$(SDK)\bin\$(if $(filter %64,$(UCPU)),x64,x86)\mc.exe)
RC1  := $(call qpath,$(SDK)\bin\$(if $(filter %64,$(UCPU)),x64,x86)\rc.exe)
MT1  := $(call qpath,$(SDK)\bin\$(if $(filter %64,$(UCPU)),x64,x86)\mt.exe)
TMC1 := $(call qpath,$(SDK)\bin\$(if $(filter %64,$(TCPU)),x64,x86)\mc.exe)
TRC1 := $(call qpath,$(SDK)\bin\$(if $(filter %64,$(TCPU)),x64,x86)\rc.exe)
TMT1 := $(call qpath,$(SDK)\bin\$(if $(filter %64,$(TCPU)),x64,x86)\mt.exe)

endif

ifeq ($(OSVARIANT),WIN81)

ifndef WDK
$(error WDK undefined, example: "C:\Program Files (x86)\Windows Kits\8.1")
endif

UMLIB  := $(WDK)\Lib\winv6.3\um\$(if $(filter %64,$(UCPU)),x64,x86)
UMINC  := $(WDK)\Include\um $(WDK)\Include\shared
UMTLIB := $(WDK)\Lib\winv6.3\um\$(if $(filter %64,$(TCPU)),x64,x86)
UMTINC := $(UMINC)

endif

ifeq ($(OSVARIANT),WIN10)

ifndef WDK
$(error WDK undefined, example: "C:\Program Files (x86)\Windows Kits\10")
endif

UMLIB  := $(WDK)\Lib\10.0.10240.0\um\$(if $(filter %64,$(UCPU)),x64,x86) $(WDK)\Lib\10.0.10240.0\ucrt\$(if $(filter %64,$(UCPU)),x64,x86)
UMINC  := $(WDK)\Include\10.0.10240.0\um $(WDK)\Include\10.0.10240.0\ucrt $(WDK)\Include\10.0.10240.0\shared
UMTLIB := $(WDK)\Lib\10.0.10240.0\um\$(if $(filter %64,$(TCPU)),x64,x86) $(WDK)\Lib\10.0.10240.0\ucrt\$(if $(filter %64,$(TCPU)),x64,x86)
UMTINC := $(UMINC)

endif

ifneq ($(filter WIN81 WIN10,$(OSVARIANT)),)

MC1  := $(call qpath,$(WDK)\bin\$(if $(filter %64,$(UCPU)),x64,x86)\mc.exe)
RC1  := $(call qpath,$(WDK)\bin\$(if $(filter %64,$(UCPU)),x64,x86)\rc.exe)
MT1  := $(call qpath,$(WDK)\bin\$(if $(filter %64,$(UCPU)),x64,x86)\mt.exe)
TMC1 := $(call qpath,$(WDK)\bin\$(if $(filter %64,$(TCPU)),x64,x86)\mc.exe)
TRC1 := $(call qpath,$(WDK)\bin\$(if $(filter %64,$(TCPU)),x64,x86)\rc.exe)
TMT1 := $(call qpath,$(WDK)\bin\$(if $(filter %64,$(TCPU)),x64,x86)\mt.exe)

endif

# DDK

ifeq ($(OSVARIANT),WINXP)

ifndef DDK
$(error DDK undefined, example: C:\WinDDK\7600.16385.1)
endif

KMLIB := $(DDK)\Lib\wxp\$(if $(filter %64,$(KCPU)),amd64,i386)
KMINC := $(DDK)\inc\api $(DDK)\inc\crt $(DDK)\inc\ddk
WKLD  := $(call qpath,$(DDK)\bin\x86\$(if $(filter %64,$(KCPU)),amd64,x86)\link.exe)
WKCL  := $(call qpath,$(DDK)\bin\x86\$(if $(filter %64,$(KCPU)),amd64,x86)\cl.exe)

INF2CAT  := $(call qpath,$(DDK)\bin\selfsign\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(DDK)\bin\$(if $(filter %64,$(KCPU)),amd64,x86)\SignTool.exe)

endif

ifeq ($(OSVARIANT),WIN7)

ifeq ($(strip $(DDK)$(WDK)),)
$(error no DDK nor WDK defined, example: DDK=C:\WinDDK\7600.16385.1 or WDK="C:\Program Files (x86)\Windows Kits\8.1")
endif

ifdef DDK

ifdef WDK
$(error either DDK or WDK must be defined, but not both)
endif

KMLIB := $(DDK)\Lib\win7\$(if $(filter %64,$(KCPU)),amd64,i386)
KMINC := $(DDK)\inc\api $(DDK)\inc\crt $(DDK)\inc\ddk
WKLD  := $(call qpath,$(DDK)\bin\x86\$(if $(filter %64,$(KCPU)),amd64,x86)\link.exe)
WKCL  := $(call qpath,$(DDK)\bin\x86\$(if $(filter %64,$(KCPU)),amd64,x86)\cl.exe)

INF2CAT  := $(call qpath,$(DDK)\bin\selfsign\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(DDK)\bin\$(if $(filter %64,$(KCPU)),amd64,x86)\SignTool.exe)

endif

ifdef WDK

ifdef DDK
$(error either DDK or WDK must be defined, but not both)
endif

KMLIB := $(WDK)\Lib\win7\km\$(if $(filter %64,$(KCPU)),x64,x86)
KMINC := $(WDK)\Include\km $(WDK)\Include\km\crt $(WDK)\Include\shared
WKLD  := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(KCPU)),\amd64)\link.exe)
WKCL  := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(KCPU)),\amd64)\cl.exe)

INF2CAT  := $(call qpath,$(WDK)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDK)\bin\$(if $(filter %64,$(KCPU)),x64,x86)\SignTool.exe)

endif

endif

ifneq ($(filter WIN8 WIN81,$(OSVARIANT)),)

ifndef WDK
$(error WDK undefined, example: "C:\Program Files (x86)\Windows Kits\8.1")
endif

KMLIB := $(WDK)\Lib\$(if $(filter WIN81,$(OSVARIANT)),winv6.3,win8)\km\$(if $(filter %64,$(KCPU)),x64,x86)
KMINC := $(WDK)\Include\km $(WDK)\Include\km\crt $(WDK)\Include\shared
WKLD  := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(KCPU)),\amd64)\link.exe)
WKCL  := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(KCPU)),\amd64)\cl.exe)

INF2CAT  := $(call qpath,$(WDK)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDK)\bin\$(if $(filter %64,$(KCPU)),x64,x86)\SignTool.exe)

endif

ifneq ($(filter WIN10,$(OSVARIANT)),)

ifndef WDK
$(error WDK undefined, example: "C:\Program Files (x86)\Windows Kits\10")
endif

KMLIB := $(WDK)\Lib\10.0.10240.0\km\$(if $(filter %64,$(KCPU)),x64,x86)
KMINC := $(WDK)\Include\10.0.10240.0\km $(WDK)\Include\10.0.10240.0\km\crt $(WDK)\Include\10.0.10240.0\shared
WKLD  := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(KCPU)),\amd64)\link.exe)
WKCL  := $(call qpath,$(VS)\VC\bin$(if $(filter %64,$(KCPU)),\amd64)\cl.exe)

INF2CAT  := $(call qpath,$(WDK)\bin\x86\Inf2Cat.exe)
SIGNTOOL := $(call qpath,$(WDK)\bin\$(if $(filter %64,$(KCPU)),x64,x86)\SignTool.exe)

endif

endif # !NO_AUTOCONF

ifdef VAUTO
$(foreach x,$(NEEDED_TOOLS),$(info $x=$($x)))
endif
