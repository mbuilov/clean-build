#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler tools wrappers, such as mc.exe and rc.exe, included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# note: tools are optional:
#  RC - needed to generate standard version information resource for EXE,DLL,DRV or KDLL
#  MC - used to compile message catalogs when building system service executable
#  MT - used to embed manifest file into EXE or DLL, if compiler supports generation of manifests

# strings to strip off from mc.exe output - $(FINDSTR) regular expression
# note: may be overridden either in project configuration makefile or in command line
MC_STRIP_STRINGS := MC:?Compiling

# wrap mc.exe call to strip-off diagnostic messages
# $1 - mc command with arguments
# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifdef VERBOSE
WRAP_MC = $1 >&2
else
WRAP_MC = $1
endif

ifndef NO_WRAP
ifdef MC_STRIP_STRINGS
WRAP_MC = $(call FILTER_OUTPUT,$1,$(call qpath,$(MC_STRIP_STRINGS),|$(FINDSTR) /VBRC:))
endif
endif

# message compiler
# $1 - generated .rc and .h
# $2 - arguments for mc.exe
# target-specific: TMD
MC_COMPILER = $(call SUP,$(TMD)MC,$1)$(call WRAP_MC,$(MC)$(if $(VERBOSE), -v) $2)

# tools colors
MC_COLOR  := $(GEN_COLOR)
TMC_COLOR := $(GEN_COLOR)

# newer versions of rc.exe (at least 6.1.7600.16385 and later) support /nologo option,
# define this macro if rc.exe is a new one, e.g. RC_SUPPRESS_LOGO := /nologo
ifeq (,$(filter-out undefined environment,$(origin RC_SUPPRESS_LOGO)))

# run rc.exe only if RC is defined
ifneq (,$(filter-out undefined environment,$(origin RC)))

# query /nologo switch of rc.exe
# $1 - "C:\Program Files\Microsoft SDKs\Windows\v6.0A\bin\RC.Exe"
RC_QUERY_NOLOGO = $(filter /nologo,,$(shell $(subst \,/,$1) /?))

# call rc.exe
RC_SUPPRESS_LOGO := $(call RC_QUERY_NOLOGO,$(RC))

# save queried RC_SUPPRESS_LOGO value in generated config
$(call CONFIG_REMEMBER_VARS,RC_SUPPRESS_LOGO)

else # !RC
RC_SUPPRESS_LOGO:=
endif # !RC

endif # !RC_SUPPRESS_LOGO

# strings to strip off from rc.exe output - $(FINDSTR) regular expression
# note: usable if rc.exe does not support /nologo option (RC_SUPPRESS_LOGO is not defined)
# note: may be overridden either in project configuration makefile or in command line
RC_LOGO_STRINGS := Microsoft?(R)?Windows?(R)?Resource?Compiler?Version Copyright?(C)?Microsoft?Corporation.??All?rights?reserved. ^$$

# wrap rc.exe call to strip-off logo messages
# $1 - rc command with arguments
# note: send output to stderr in VERBOSE mode, this is needed for build script generation
ifdef VERBOSE
WRAP_RC = $1 >&2
else
WRAP_RC = $1
endif

ifndef NO_WRAP
ifndef RC_SUPPRESS_LOGO
ifdef RC_LOGO_STRINGS
WRAP_RC = $(call FILTER_OUTPUT,$1,$(call qpath,$(RC_LOGO_STRINGS),|$(FINDSTR) /VBRC:))
endif
endif
endif

# /x - Ignore INCLUDE environment variable
RC_DEFAULT_OPTIONS := $(RC_SUPPRESS_LOGO) /x$(if $(VERBOSE), /v)

# resource compiler
# $1 - target .res
# $2 - source .rc
# $3 - rc compiler options, such as: $(call qpath,$($(TMD)RC_STDINCLUDES),/I)
# target-specific: TMD
RC_COMPILER = $(call SUP,$(TMD)RC,$1)$(call WRAP_RC,$(RC) $(RC_DEFAULT_OPTIONS) $3 /fo$(call ospath,$1 $2))

# tools colors
RC_COLOR  := $(GEN_COLOR)
TRC_COLOR := $(GEN_COLOR)

# MC - message compiler, must be defined to compile message catalogs (for executables that run as service)
# note: MC may be defined in command line, project configuration makefile or
#  autoconfigured in $(CLEAN_BUILD_DIR)/compilers/msvc/auto/conf.mk
# example: MC="C:\Program Files (x86)\Windows Kits\8.1\bin\x86\mc.exe"
ifeq (,$(filter-out undefined environment,$(origin MC)))
MC = $(error MC - path to message compiler mc.exe - is not defined!)
endif

# RC - resource compiler, must be defined to build executables or dlls
# note: RC may be defined in command line, project configuration makefile or
#  autoconfigured in $(CLEAN_BUILD_DIR)/compilers/msvc/auto/conf.mk
# example: RC="C:\Program Files (x86)\Windows Kits\8.1\bin\x86\rc.exe"
ifeq (,$(filter-out undefined environment,$(origin RC)))
RC = $(error RC - path to resource compiler rc.exe - is not defined!)
endif

# MT - manifest tool, must be defined for linker of pre-Visual Studio 2012 (which doesn't support "/MANIFEST:EMBED" option)
# note: MT may be defined in command line, project configuration makefile or
#  autoconfigured in $(CLEAN_BUILD_DIR)/compilers/msvc/auto/conf.mk
# example: MT="C:\Program Files (x86)\Windows Kits\8.1\bin\x86\mt.exe"
ifeq (,$(filter-out undefined environment,$(origin MT)))
MT = $(error MT - path to manifest tool mt.exe - is not defined!)
endif

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,MC_STRIP_STRINGS WRAP_MC MC_COMPILER MC_COLOR TMC_COLOR \
  RC_QUERY_NOLOGO RC_SUPPRESS_LOGO RC_LOGO_STRINGS WRAP_RC \
  RC_DEFAULT_OPTIONS RC_COMPILER RC_COLOR TRC_COLOR MC RC MT)
