#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(CLEAN_BUILD_DIR)/defs.mk

OSTYPE := WINDOWS

# synchronize make output for parallel builds
MAKEFLAGS += -O

# shell must be cmd.exe, not /bin/sh if building under cygwin
ifeq (environment,$(origin COMSPEC))
SHELL := $(COMSPEC)
endif

ifneq (,$(filter /cygdrive/%,$(abspath .)))
$(error cygwin gnu make is used for WINDOWS build - this is not supported, please use native tools,\
 for example, under cygwin start build with: /cygdrive/c/tools/gnumake-4.2.1.exe SED=C:/tools/sed.exe <args>)
endif

# Windows needs TEMP, PATHEXT, SYSTEMROOT and COMSPEC variables to be defined in environment of calling executables
export $(foreach v,$(CLEANED_ENV_VARS),$(if $(filter \
  TEMP PATHEXT SYSTEMROOT COMSPEC,$(call toupper,$v)),$v))

# print prepared environment in verbose mode
ifdef VERBOSE
$(info setlocal$(foreach v,$(CLEANED_ENV_VARS),$(if $(filter-out \
  TEMP PATHEXT SYSTEMROOT COMSPEC,$(call toupper,$v)),$(newline)set "$v=")))
endif

# stip off cygwin paths - to use only native windows tools
# for example, sed.exe from cygwin handles format string differently than C:/GnuWin32/bin/sed.exe
override PATH := $(subst ?, ,$(subst $(space),;,$(strip $(foreach p,$(subst \
  ;, ,$(subst $(space),?,$(PATH))),$(if $(word 2,$(subst cygwin, ,$p)),,$p)))))

# maximum command line length
# for Windows 95 and later   - 127 chars;
# for Windows 2000 and later - 2047 chars;
# for Windows XP and later   - 8191 chars (max 31 path arguments of 260 chars length each);
# determine maximum number of arguments passed via command line:
# for Windows XP and later, assuming that maximum length of each argument is 115 chars
DEL_ARGS_LIMIT := 70

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

# delete files $1
DEL = for %%f in ($(ospath)) do if exist %%f del /F /Q %%f

# delete directories $1
# note: DEL_DIR may be not defined for other OSes, use RM in platform-independent code
DEL_DIR = for %%f in ($(ospath)) do if exist %%f rd /S /Q %%f

# delete files and directories
# note: do not need to add $(QUIET) before $(RM)
RM1 = $(QUIET)for %%f in ($(ospath)) do if exist %%f\* (rd /S /Q %%f) else if exist %%f (del /F /Q %%f)
RM  = $(call xcmd,RM1,$1,$(DEL_ARGS_LIMIT),,,,)

# NOTE! there are races in MKDIR - if make spawns two parallel jobs:
#
# if not exist aaa
#                        if not exist aaa/bbb
#                        mkdir aaa/bbb
# mkdir aaa - fail
#
# MKDIR must be called only if destination directory does not exist
# note: MKDIR should create intermediate parent directories of destination directory
MKDIR = mkdir $(ospath)

# stream-editor executable
# note: SED value may be overridden either in command line or in project configuration file, like:
# override SED := C:\tools\gnused.exe
SED := sed.exe

# escape command line argument to pass it to $(SED)
SED_EXPR = "$(subst %,%%,$1)"

# print contents of given file (to stdout, for redirecting it to output file)
CAT = type $(ospath)

# print one line of text (to stdout, for redirecting it to output file)
# note: line will be ended with CRLF
# note: ECHO_LINE may be not defined for other OSes, use ECHO in platform-independent code
ECHO_LINE = echo.$(subst $(open_brace),^$(open_brace),$(subst $(close_brace),^$(close_brace),$(subst \
  %,%%,$(subst <,^<,$(subst >,^>,$(subst |,^|,$(subst &,^&,$(subst ",^",$(subst ^,^^,$1)))))))))

# print lines of text to output file or to stdout
# $1 - lines list, where $(tab) replaced with $$(tab) and $(space) replaced with $$(space)
# $2 - if empty, then echo to stdout
# $3 - text to prepend before command when $6 is non-empty
# $4 - text to prepend before command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# note: ECHO_LINES may be not defined for other OSes, use ECHO in platform-independent code
ECHO_LINES = $(if $6,$3,$4)($(foreach x,$1,($(call \
  ECHO_LINE,$(subst $$(space), ,$(subst $$(tab),$(tab),$x)))) &&) rem.)$(if $2, >$(if $6,>) $2)

# print lines of text (to stdout, for redirecting it to output file)
# note: each line will be ended with CRLF
ECHO = $(if $(findstring $(newline),$1),$(call \
  ECHO_LINES,$(subst $(newline), ,$(subst $(space),$$(space),$(subst $(tab),$$(tab),$1)))),$(ECHO_LINE))

# write lines of text $1 to file $2 by $3 lines at one time
# NOTE: maximum line length cannot exceed command line length (8191 characters)
WRITE = $(call xargs,ECHO_LINES,$(subst $(newline), ,$(subst \
  $(space),$$(space),$(subst $(tab),$$(tab),$1))),$3,$2,$(QUIET),,,$(newline))

# null device for redirecting output into
NUL := NUL

# code for suppressing output of copy command, like
# "        1 file(s) copied."
# "Скопировано файлов:         1."
SUPPRESS_CP_OUTPUT := | findstr /v /c:"        1" & if errorlevel 1 (cmd /c exit 0) else (cmd /c exit 1)

# update modification date of given file(s) or create file(s) if they do not exist
TOUCH = for %%f in ($(ospath)) do if exist %%f (copy /Y /B %%f+,, %%f$(SUPPRESS_CP_OUTPUT)) else (rem. > %%f)

# copy preserving modification date:
# - file(s) $1 to directory $2 or
# - file $1 to file $2
CP = $(if $(word 2,$1),for %%f in ($(ospath)) do copy /Y /B %%f,copy /Y /B $(ospath)) $(call ospath,$2)$(SUPPRESS_CP_OUTPUT)

# execute command $2 in directory $1
EXECIN = pushd $(ospath) && ($2 && popd || (popd & cmd /c exit 1))

# delete target file(s) if failed to build them and exit shell with error code 1
DEL_ON_FAIL = || (($(DEL)) & cmd /c exit 1)

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

# windows terminal do not supports changing output colors
# note: override PRINT_PERCENTS from $(CLEAN_BUILD_DIR)/defs.mk
PRINT_PERCENTS = [$1]

# windows terminal do not supports changing output colors
# note: override COLORIZE from $(CLEAN_BUILD_DIR)/defs.mk
COLORIZE = $1$(padto)$2

# protect variables from modifications in target makefiles
ifdef CLEAN_BUILD_PROTECT_VARS
$(call CLEAN_BUILD_PROTECT_VARS,$(foreach v,$(CLEANED_ENV_VARS),$(if $(filter \
  TEMP PATHEXT SYSTEMROOT COMSPEC,$(call toupper,$v)),$v)) \
  DEL_ARGS_LIMIT nonrelpath1 DEL DEL_DIR RM1 RM MKDIR SED SED_EXPR \
  CAT ECHO_LINE ECHO_LINES ECHO WRITE NUL SUPPRESS_CP_OUTPUT TOUCH CP EXECIN DEL_ON_FAIL NO_RPATH)
endif
