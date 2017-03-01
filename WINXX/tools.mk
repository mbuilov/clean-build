#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(MTOP)/defs.mk

# synchronize make output for parallel builds
MAKEFLAGS += -O

# shell must be cmd.exe, not /bin/sh if building under cygwin
SHELL := $(COMSPEC)

ifneq ($(filter /cygdrive/%,$(TOP)),)
$(error building with cygwin tools is not supported, please use native tools,\
 for example: /cygdrive/c/tools/gnumake-4.2.1.exe SED=C:/tools/sed.exe <args>)
endif

# stip off cygwin paths - to use only native windows tools
# for example, sed.exe from cygwin handles format string differently than C:/GnuWin32/bin/sed.exe
PATH := $(subst ?, ,$(subst $(space),;,$(strip $(foreach p,$(subst \
  ;, ,$(subst $(space),?,$(PATH))),$(if $(word 2,$(subst cygwin, ,$p)),,$p)))))

# max command line length
# for Windows 95 and later    - 127 chars;
# for Windows 2000 and later  - 2047 chars;
# for Windows XP and later    - 8191 chars (max 31 path arguments of 260 chars length each);
# maximum number of args passed via command line
ifndef DEL_ARGS_LIMIT
# for Windows XP and later, assuming that maximum length of each arg is 80 chars
DEL_ARGS_LIMIT := 100
endif

# don't colorize output
TERM_NO_COLOR := 1

# convert slashes
# NOTE: no spaces allowed in paths the $(MAKE) works with
ospath = $(subst /,\,$1)

# absolute paths contain ':', for example c:/agent
# NOTE: assume there are no spaces and ':' in the path to sources
isrelpath = $(if $(word 2,$(subst :, ,$1)),,1)

# delete one file
DEL1 = if exist $1 del /F /Q $1
DEL  = $(call DEL1,$(ospath))

# delete directory
DEL_DIR1 = if exist $1\* rd /S /Q $1
DEL_DIR  = $(call DEL_DIR1,$(ospath))

# delete files and directories
RM1 = $(if $(VERBOSE),,@)for %%f in ($(ospath)) do if exist %%f\* (rd /S /Q %%f) else if exist %%f (del /F /Q %%f)
RM  = $(call xcmd,RM1,$1,$(DEL_ARGS_LIMIT))

# NOTE! there are races in MKDIR - if make spawns two parallel jobs:
# if not exist aaa
#                        if not exist aaa/bbb
#                        mkdir aaa/bbb
# mkdir aaa - fail
#MKDIR1 = if not exist $1 mkdir $1
# assume MKDIR is called only if directory does not exist
MKDIR = mkdir $(ospath)

SED  ?= sed.exe
SED  := $(SED) -b
SED_EXPR = "$(subst %,%%,$1)"
CAT   = type $(ospath)
open_brace:=(
close_brace:=)
ECHO_LINE = echo$(if $1, $(subst $(open_brace),^$(open_brace),$(subst $(close_brace),^$(close_brace),$(subst \
             %,%%,$(subst <,^<,$(subst >,^>,$(subst |,^|,$(subst &,^&,$(subst ",^",$(subst ^,^^,$1))))))))),.)
ECHO1 = $(if $(word 2,$1),($(foreach x,$1,($(call ECHO_LINE,$(subst $$(newline),,$(subst $$(space), ,$(subst \
         $$(tab),$(tab),$x))))) &&) rem.),$(call ECHO_LINE,$(subst $$(space), ,$(subst $$(tab),$(tab),$1))))
ECHO  = $(call ECHO1,$(subst $(newline),$$(newline) ,$(subst $(space),$$(space),$(subst $(tab),$$(tab),$1))))
NUL  := NUL
SUPPRESS_CP_OUTPUT := | findstr /v /c:"        1" & if errorlevel 1 (cmd /c exit 0) else (cmd /c exit 1)
CP    = copy /Y /B $(ospath) $(call ospath,$2)$(SUPPRESS_CP_OUTPUT)
TOUCH1 = if not exist $1 (rem. > $1) else (copy /B $1+,, $1$(SUPPRESS_CP_OUTPUT))
TOUCH = $(call TOUCH1,$(ospath))

# execute command $2 in directory $1
EXECIN = pushd $(ospath) && ($2 && popd || (popd & cmd /c exit 1))

# delete target if failed to build it and exit shell with error code 1
DEL_ON_FAIL = || ($(foreach x,$1,($(call DEL,$x)) &) cmd /c exit 1)

# suffix of built tool executables
TOOL_SUFFIX := .exe

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DEL_ARGS_LIMIT DEL1 DEL DEL_DIR1 DEL_DIR RM1 RM MKDIR SED SED_EXPR \
  CAT open_brace close_brace ECHO_LINE ECHO1 ECHO EXECIN NUL SUPPRESS_CP_OUTPUT CP TOUCH1 TOUCH DEL_ON_FAIL TOOL_SUFFIX)
