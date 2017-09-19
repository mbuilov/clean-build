#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler tools, such as mc.exe and rc.exe, included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# paths to rc.exe and mc.exe should be defined in project configuration makefile
MC = $(error MC is not defined - path to mc.exe, should be in double-quotes if contains spaces)
RC = $(error RC is not defined - path to rc.exe, should be in double-quotes if contains spaces)

# strings to strip off from mc.exe output (findstr regular expression)
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
WRAP_MC = $(call FILTER_OUTPUT,$1,$(call qpath,$(MC_STRIP_STRINGS),|findstr /VBRC:))
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

# newer versions of rc.exe support /nologo option,
# define this macro if rc.exe is a new one, e.g. RC_SUPPRESS_LOGO := /nologo
RC_SUPPRESS_LOGO:=

# strings to strip off from rc.exe output (findstr regular expression)
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
WRAP_RC = $(call FILTER_OUTPUT,$1,$(call qpath,$(RC_LOGO_STRINGS),|findstr /VBRC:))
endif
endif
endif

# standard include paths - to include <winver.h>
# target-specific: TMD
RC_COMPILER_INCLUDES = $($(TMD)VSINCLUDE) $($(TMD)UMINCLUDE)

# resource compiler
# $1 - target .res
# $2 - source .rc
# $3 - rc compiler options
# target-specific: TMD
RC_COMPILER = $(call SUP,$(TMD)RC,$1)$(call WRAP_RC,$(RC) $(RC_SUPPRESS_LOGO)$(if \
  $(VERBOSE), /v) $3 $(call qpath,$(RC_COMPILER_INCLUDES),/I) /fo$(call ospath,$1 $2))

# tools colors
RC_COLOR  := $(GEN_COLOR)
TRC_COLOR := $(GEN_COLOR)

# Manifest Tool
MT = $(error MT is not defined - path to mt.exe, should be in double-quotes if contains spaces)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,MC RC MC_STRIP_STRINGS WRAP_MC MC_COMPILER MC_COLOR TMC_COLOR \
  RC_SUPPRESS_LOGO RC_LOGO_STRINGS WRAP_RC RC_COMPILER_INCLUDES RC_COMPILER RC_COLOR TRC_COLOR MT)
