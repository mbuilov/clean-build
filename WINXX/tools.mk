#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(MTOP)/defs.mk

OSTYPE := WINDOWS

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

# $1 - prefix
# $2 - list of disks (C: D:)
# $3 - list of files prefixed with $1
nonrelpath1 = $(if $2,$(call nonrelpath1,$1,$(wordlist 2,999999,$2),$(patsubst $1$(firstword $2)%,$(firstword $2)%,$3)),$3)

# add $1 only to non-absolute paths in $2
# note: $1 must end with /
# a/b c:/1 -> xxx/a/b xxx/c:/1 -> xxx/a/b c:/1
nonrelpath = $(if $(findstring :,$2),$(call nonrelpath1,$1,$(sort $(filter %:,$(subst :,: ,$2))),$(addprefix $1,$2)),$(addprefix $1,$2))

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
SED_EXPR = "$(subst %,%%,$1)"
CAT   = type $(ospath)
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

# paths separator, as used in %PATH% environment variable
PATHSEP := ;

# name of environment variable to modify in $(RUN_WITH_DLL_PATH)
DLL_PATH_VAR := PATH

# if %PATH% environment variable was modified for calling a tool, print new %PATH% value in generated batch
# $1 - command to run (with parameters)
# $2 - additional paths to append to $(DLL_PATH_VAR)
# $3 - environment variables to set to run executable, in form VAR=value
show_with_dll_path = $(info setlocal$(if $2,$(newline)set "PATH=$(PATH)")$(foreach \
  v,$3,$(foreach n,$(firstword $(subst =, ,$v)),$(newline)set "$n=$($n)"))$(newline)$1)

# show after executing a command
show_dll_path_end = $(newline)@echo endlocal

# there is no support for embedding dll search path into executables or dlls
NO_RPATH := 1

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DEL_ARGS_LIMIT nonrelpath1 DEL1 DEL DEL_DIR1 DEL_DIR RM1 RM MKDIR SED SED_EXPR \
  CAT ECHO_LINE ECHO1 ECHO EXECIN NUL SUPPRESS_CP_OUTPUT CP TOUCH1 TOUCH DEL_ON_FAIL NO_RPATH)
