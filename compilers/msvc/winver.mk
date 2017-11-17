#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define FORM_WINVER_DEFINES and FORM_SUBSYSTEM_VER macros, included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# NTDDI - Windows device driver interface version
# note: possible values - suffix of NTDDI_... constants listed below, e.g.: NTDDI=WINXPSP3
# note: NTDDI may be overridden in project configuration makefile or in command line
# note: if NTDDI is non-empty, deduce WINVER value from it
NTDDI:=

# WINVER possible values - suffix of next _WIN32_WINNT_... constants
# sdkddkver.h
_WIN32_WINNT_WIN2K        := 0x0500 # Windows 2000
_WIN32_WINNT_WINXP        := 0x0501 # Windows Server 2003, Windows XP
_WIN32_WINNT_WS03         := 0x0502 # Windows Server 2003 SP1, Windows XP SP2
_WIN32_WINNT_WIN6         := 0x0600 # Windows Vista
_WIN32_WINNT_LONGHORN     := 0x0600 # Windows Longhorn (Vista)
_WIN32_WINNT_VISTA        := 0x0600 # Windows Vista
_WIN32_WINNT_WS08         := 0x0600 # Windows Server 2008
_WIN32_WINNT_WIN7         := 0x0601 # Windows 7
_WIN32_WINNT_WIN8         := 0x0602 # Windows 8
_WIN32_WINNT_WINBLUE      := 0x0603 # Windows 8.1
_WIN32_WINNT_WIN10        := 0x0A00 # Windows 10
_WIN32_WINNT_WINTHRESHOLD := 0x0A00 # Windows 10

# NTDDI possible values - suffix of next NTDDI_... constants
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa383745(v=vs.85).aspx
NTDDI_WIN2K        := $(_WIN32_WINNT_WIN2K)0000   # Windows 2000
NTDDI_WINXP        := $(_WIN32_WINNT_WINXP)0000   # Windows XP
NTDDI_WINXPSP1     := $(_WIN32_WINNT_WINXP)0100   # Windows XP SP1
NTDDI_WINXPSP2     := $(_WIN32_WINNT_WINXP)0200   # Windows XP SP2
NTDDI_WINXPSP3     := $(_WIN32_WINNT_WINXP)0300   # Windows XP SP3
NTDDI_WS03         := $(_WIN32_WINNT_WS03)0000    # Windows Server 2003
NTDDI_WS03SP1      := $(_WIN32_WINNT_WS03)0100    # Windows Server 2003 SP1
NTDDI_WS03SP2      := $(_WIN32_WINNT_WS03)0200    # Windows Server 2003 SP2
NTDDI_WIN6         := $(_WIN32_WINNT_WIN6)0000    # Windows Vista
NTDDI_LONGHORN     := $(_WIN32_WINNT_WIN6)0000    # Windows Longhorn (Vista)
NTDDI_VISTA        := $(_WIN32_WINNT_WIN6)0000    # Windows Vista
NTDDI_VISTASP1     := $(_WIN32_WINNT_WIN6)0100    # Windows Vista SP1
NTDDI_WS08         := $(_WIN32_WINNT_WIN6)0100    # Windows Server 2008
NTDDI_WIN7         := $(_WIN32_WINNT_WIN7)0000    # Windows 7
NTDDI_WIN8         := $(_WIN32_WINNT_WIN8)0000    # Windows 8
NTDDI_WINBLUE      := $(_WIN32_WINNT_WINBLUE)0000 # Windows 8.1
NTDDI_WIN10        := $(_WIN32_WINNT_WIN10)0000   # Windows 10
NTDDI_WINTHRESHOLD := $(_WIN32_WINNT_WIN10)0000   # Windows Threshold    version: 1507, build: 10240
NTDDI_WIN10_TH2    := $(_WIN32_WINNT_WIN10)0001   # Windows Threshold 2  version: 1511, build: 10586
NTDDI_WIN10_RS1    := $(_WIN32_WINNT_WIN10)0002   # Windows Redstone     version: 1607, build: 14393
NTDDI_WIN10_RS2    := $(_WIN32_WINNT_WIN10)0003   # Windows Redstone 2   version: 1703, build: 15063
NTDDI_WIN10_RS3    := $(_WIN32_WINNT_WIN10)0004   # Windows Redstone 3   version: 1709, build: 16299
NTDDI_WIN10_RS4    := $(_WIN32_WINNT_WIN10)0005   # Windows Redstone 4   version: 1803, build: 17035

# map NTDDI -> WINVER
# e.g.: WINXPSP3 -> WINXP
NTDDI_GET_WINVER = $(if $(filter \
  WIN10_RS4 WIN10_RS3 WIN10_RS2 WIN10_RS1 WIN10_TH2 WINTHRESHOLD WIN10,$1),WIN10,$(if $(filter \
  WINBLUE,$1),WINBLUE,$(if $(filter \
  WIN8,$1),WIN8,$(if $(filter \
  WIN7,$1),WIN7,$(if $(filter \
  WS08 VISTASP1 VISTA LONGHORN WIN6,$1),WIN6,$(if $(filter \
  WS03SP2 WS03SP1 WS03,$1),WS03,$(if $(filter \
  WINXPSP3 WINXPSP2 WINXPSP1 WINXP,$1),WINXP,WIN2K)))))))

# WINVER - minimal Windows version required to run built executables
# note: possible values - suffix of _WIN32_WINNT_... constants listed above, e.g.: WINVER=WINXP
# note: WINVER may be overridden in project configuration makefile or in command line
ifdef NTDDI
WINVER := $(call NTDDI_GET_WINVER,$(NTDDI))
else
WINVER:=
endif

# https://msdn.microsoft.com/en-us/library/windows/hardware/hh965708(v=vs.120).aspx/html
SUBSYSTEM_VER_WIN2K := 5.00 # Windows 2000
SUBSYSTEM_VER_WINXP := 5.01 # Windows XP
SUBSYSTEM_VER_WS03  := 5.02 # Windows Server 2003
SUBSYSTEM_VER_VISTA := 6.00 # Windows Vista
SUBSYSTEM_VER_WS08  := 6.01 # Windows Server 2008
SUBSYSTEM_VER_WIN7  := 6.01 # Windows 7
SUBSYSTEM_VER_WIN8  := 6.02 # Windows 8

# map WINVER -> SUBSYSTEM version name
WINVER_GET_SUBSYSTEM = $(if $(filter \
  WINTHRESHOLD WIN10 WINBLUE WIN8,$1),WIN8,$(if $(filter \
  WIN7 WS08,$1),WS08,$(if $(filter \
  VISTA LONGHORN WIN6,$1),VISTA,$(if $(filter \
  WS03,$1),WS03,$(if $(filter \
  WINXP,$1,)WINXP,WIN2K)))))

# WINVER_DEFINES - specifies version of Windows API to compile with
# note: if NTDDI_VERSION is defined, _WIN32_WINNT must also be defined
FORM_WINVER_DEFINES = $(if $(NTDDI),NTDDI_VERSION=$(NTDDI_$(NTDDI)) )_WIN32_WINNT=$(_WIN32_WINNT_$(WINVER))

# SUBSYSTEM_VER - minimum Windows version required to run built targets
FORM_SUBSYSTEM_VER = $(SUBSYSTEM_VER_$(call WINVER_GET_SUBSYSTEM,$(WINVER)))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,NTDDI \
  _WIN32_WINNT_WIN2K _WIN32_WINNT_WINXP _WIN32_WINNT_WS03 _WIN32_WINNT_WIN6 _WIN32_WINNT_LONGHORN _WIN32_WINNT_VISTA \
  _WIN32_WINNT_WS08 _WIN32_WINNT_WIN7 _WIN32_WINNT_WIN8 _WIN32_WINNT_WINBLUE _WIN32_WINNT_WIN10 _WIN32_WINNT_WINTHRESHOLD \
  NTDDI_WIN2K NTDDI_WINXP NTDDI_WINXPSP1 NTDDI_WINXPSP2 NTDDI_WINXPSP3 \
  NTDDI_WS03 NTDDI_WS03SP1 NTDDI_WS03SP2 NTDDI_WIN6 NTDDI_LONGHORN NTDDI_VISTA NTDDI_VISTASP1 NTDDI_WS08 NTDDI_WIN7 NTDDI_WIN8 \
  NTDDI_WINBLUE NTDDI_WIN10 NTDDI_WINTHRESHOLD NTDDI_WIN10_TH2 NTDDI_WIN10_RS1 NTDDI_WIN10_RS2 NTDDI_WIN10_RS3 NTDDI_WIN10_RS4 \
  NTDDI_GET_WINVER WINVER \
  SUBSYSTEM_VER_WIN2K SUBSYSTEM_VER_WINXP SUBSYSTEM_VER_WS03 SUBSYSTEM_VER_VISTA \
  SUBSYSTEM_VER_WS08 SUBSYSTEM_VER_WIN7 SUBSYSTEM_VER_WIN8 \
  WINVER_GET_SUBSYSTEM FORM_WINVER_DEFINES FORM_SUBSYSTEM_VER)

### by default, configure for Windows XP if target arch is x86 and for Windows XP SP2 if target arch is x86_64
##WINVER := $(if $(CPU:%64=),WINXP,WS03)
#
## WINVER_DEFINES - specifies version of Windows API to compile with
## note: WINVER_DEFINES may be defined as <empty> in project configuration makefile or in command line
#ifeq (,$(filter-out undefined environment,$(origin WINVER_DEFINES)))
#ifdef NTDDI
## note: if NTDDI_VERSION is defined, _WIN32_WINNT must also be defined
#WINVER_DEFINES := NTDDI_VERSION=$(NTDDI_$(NTDDI)) _WIN32_WINNT=$(_WIN32_WINNT_$(WINVER))
#else
#WINVER_DEFINES := _WIN32_WINNT=$(_WIN32_WINNT_$(WINVER))
#endif
#endif
#
## SUBSYSTEM_VER - minimum Windows version required to run built targets
## note: SUBSYSTEM_VER may be defined as <empty> in project configuration makefile or in command line
#ifeq (,$(filter-out undefined environment,$(origin SUBSYSTEM_VER)))
#SUBSYSTEM_VER := $(SUBSYSTEM_VER_$(call WINVER_GET_SUBSYSTEM,$(WINVER)))
#endif

# map WINVER -> Windows version-specific folder name
#WINVER_GET_FOLDER = $(if $(filter \
#  WINTHRESHOLD WIN10,$1),10.0.*,$(if $(filter \
#  WINBLUE,$1),winv6.3,$(if $(filter \
#  WIN8,$1),win8,$(if $(filter \
#  WIN7,$1),win7,$(if $(filter \
#  WS08 VISTA LONGHORN WIN6,$1),wlh,$(if $(filter \
#  WS03,$1),wnet,$(if $(filter \
#  WINXP,$1),wxp,$(if $(filter \
#  WIN2K,$1),w2k,$(error unknown WINVER: $1)))))))))
