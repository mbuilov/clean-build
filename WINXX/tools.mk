#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(CLEAN_BUILD_DIR)/defs.mk

OSTYPE := WINDOWS

# synchronize make output for parallel builds
MAKEFLAGS += -O

ifneq (,$(filter /cygdrive/%,$(CURDIR)))
$(error cygwin gnu make is used for WINDOWS build - this configuration is not supported, please use native windows tools,\
 for example, under cygwin start build with: /cygdrive/c/tools/gnumake-4.2.1.exe SED=C:/tools/sed.exe <args>)
endif

# Windows programs need at least these variables to be defined in environment
WIN_REQUIRED_VARS := TMP PATHEXT SYSTEMROOT SYSTEMDRIVE COMSPEC

# note: assume variable name cannot contain = character
WIN_EXPORTED := $(filter $(WIN_REQUIRED_VARS:==%),$(join \
  $(addsuffix =,$(call toupper,$(.VARIABLES))),$(.VARIABLES)))

#      if SYSTEMROOT is defined, define SystemRoot = $(value SYSTEMROOT)
# else if SystemRoot is defined, define SYSTEMROOT = $(value SystemRoot)
$(foreach t,TMP PATHEXT SYSTEMROOT COMSPEC,\
  $(if $(filter %=$t,$(WIN_EXPORTED)),\
    $(foreach v,$(filter-out %=$t,$(filter $t=%,$(WIN_EXPORTED))),\
      $(eval override $(lastword $(subst =, ,$v))=$(value $t))\
    )\
  ,\
    $(foreach v,$(firstword $(filter $t=%,$(WIN_EXPORTED))),\
      $(eval $t=$(value $(lastword $(subst =, ,$v))))\
    )\
  )\
)

# export all SYSTEMROOT, SystemRoot, etc.
WIN_EXPORTED := $(sort $(subst =, ,$(WIN_EXPORTED)))
export $(WIN_EXPORTED)

# shell must be cmd.exe, not /bin/sh if build was started under Cygwin
ifneq (cmd.exe,$(notdir $(SHELL)))
ifneq (undefined,$(origin COMSPEC))
override SHELL := $(COMSPEC)
else ifneq (undefined,$(origin SYSTEMROOT))
override SHELL := $(SYSTEMROOT)\System32\cmd.exe
else
$(error unable to determine cmd.exe for the SHELL)
endif
endif

# save exported variables in generated config
# note: SHELL may be overridden just above, save it's new value also
ifdef CONFIG
ifneq (,$(filter conf,$(MAKECMDGOALS)))
conf: override CONFIG_TEXT += $(foreach v,SHELL $(WIN_EXPORTED),$(OVERRIDE_VAR_TEMPLATE))
endif
endif

# strip off Cygwin paths - to use only native windows tools
# for example, sed.exe from Cygwin handles quotes in format string differently than C:/GnuWin32/bin/sed.exe
# note: Cygwin paths may look like: C:\cygwin64\usr\local\bin;C:\cygwin64\bin
# note: assume paths separated with ; and there is no ; inside paths
override PATH := $(subst ?, ,$(subst $(space),;,$(strip $(foreach p,$(subst \
  ;, ,$(subst $(space),?,$(PATH))),$(if $(findstring cygwin,$p),,$p)))))

# print prepared environment in verbose mode
ifdef VERBOSE
$(info setlocal$(newline)FOR /F "delims==" %%V IN ('SET') DO $(foreach \
  x,PATH $(WIN_REQUIRED_VARS) $(PASS_ENV_VARS),IF /I NOT "$x"=="%%V") SET "%%V="$(foreach \
  v,PATH $(filter $(WIN_REQUIRED_VARS),$(WIN_EXPORTED)) $(PASS_ENV_VARS),$(newline)SET "$v=$($v)"))
endif

# maximum command line length
# for Windows 95 and later   - 127 chars;
# for Windows 2000 and later - 2047 chars;
# for Windows XP and later   - 8191 chars (max 31 path arguments of 260 chars length each);
# determine maximum number of arguments passed via command line:
# for Windows XP and later, assuming that maximum length of each argument is 115 chars
DEL_ARGS_LIMIT := 70

# convert slashes
# note: override ospath from $(CLEAN_BUILD_DIR)/defs.mk
ospath = $(subst /,\,$1)

# $1 - prefix
# $2 - list of disks (C: D:)
# $3 - list of files prefixed with $1
nonrelpath1 = $(if $2,$(call nonrelpath1,$1,$(wordlist 2,999999,$2),$(patsubst $1$(firstword $2)%,$(firstword $2)%,$3)),$3)

# add $1 only to non-absolute paths in $2
# note: $1 must end with /
# a/b c:/1 -> xxx/a/b xxx/c:/1 -> xxx/a/b c:/1
# note: override nonrelpath from $(CLEAN_BUILD_DIR)/defs.mk
nonrelpath = $(if $(findstring :,$2),$(call nonrelpath1,$1,$(sort $(filter %:,$(subst :,: ,$2))),$(addprefix $1,$2)),$(addprefix $1,$2))

# delete files $1
DEL = for %%f in ($(ospath)) do if exist %%f del /F/Q %%f

# delete directories $1
# note: DEL_DIR may be not defined for other OSes, use RM in platform-independent code
DEL_DIR = for %%f in ($(ospath)) do if exist %%f rd /S/Q %%f

# delete files and directories
# note: do not need to add $(QUIET) before $(RM)
RM1 = $(QUIET)for %%f in ($(ospath)) do if exist %%f\* (rd /S/Q %%f) else if exist %%f (del /F/Q %%f)
RM  = $(call xcmd,RM1,$1,$(DEL_ARGS_LIMIT),,,,)

# NOTE! there are races in MKDIR - if make spawns two parallel jobs:
#
# if not exist aaa
#                        if not exist aaa/bbb
#                        mkdir aaa/bbb
# mkdir aaa - fail
#
# MKDIR must be called only if destination directory does not exist
# note: MKDIR must create intermediate parent directories of destination directory
MKDIR = mkdir $(ospath)

# compare content of two text files: $1 and $2
# return an error if they are differ
CMP = FC /T $(call ospath,$1 $2)

# escape program argument to pass it via shell: 1 " 2 -> "1 "" 2"
SHELL_ESCAPE = "$(subst ","",$(subst \",\\",$(subst %,%%,$1)))"

# escape special characters in unquoted argument of echo or set command
UNQUOTED_ESCAPE = $(subst $(open_brace),^$(open_brace),$(subst $(close_brace),^$(close_brace),$(subst \
  %,%%,$(subst <,^<,$(subst >,^>,$(subst |,^|,$(subst &,^&,$(subst ",^",$(subst ^,^^,$1)))))))))

# stream-editor executable
# note: SED value may be overridden either in command line or in project configuration makefile, like:
# SED := C:\tools\gnused.exe
SED := sed.exe

# escape command line argument to pass it to $(SED)
SED_EXPR = $(SHELL_ESCAPE)

# print contents of given file (to stdout, for redirecting it to output file)
CAT = type $(ospath)

# print one line of text (to stdout, for redirecting it to output file)
# note: line will be ended with CRLF
# NOTE: ECHO_LINE may be not defined for other OSes, use ECHO in platform-independent code
# NOTE: echoed line length must not exceed maximum command line length (8191 characters)
ECHO_LINE = echo.$(UNQUOTED_ESCAPE)

# print lines of text to output file or to stdout
# $1 - lines list, where $(tab) replaced with $$(tab) and $(space) replaced with $$(space), must be non-empty
# $2 - if empty, then echo to stdout
# $3 - text to prepend before command when $6 is non-empty
# $4 - text to prepend before command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# NOTE: ECHO_LINES may be not defined for other OSes, use ECHO in platform-independent code
# NOTE: total text length must not exceed maximum command line length (8191 characters)
ECHO_LINES = $(if $6,$3,$4)($(foreach x,$1,$(eval ECHO_LINES_:=$(subst \
  $(comment),$$(comment),$x))($(call ECHO_LINE,$(ECHO_LINES_))) &&) rem.)$(if $2, >$(if $6,>) $2)

# print lines of text (to stdout, for redirecting it to output file)
# note: each line will be ended with CRLF
# NOTE: total text length must not exceed maximum command line length (8191 characters)
ECHO = $(if $(findstring $(newline),$1),$(call ECHO_LINES,$(subst $(newline),$$(empty) ,$(subst \
  $(tab),$$(tab),$(subst $(space),$$(space),$(subst $$,$$$$,$1))))),$(ECHO_LINE))

# write lines of text $1 to file $2 by $3 lines at one time
# NOTE: echoed at one time text length must not exceed maximum command line length (8191 characters)
WRITE = $(call xargs,ECHO_LINES,$(subst $(newline),$$(empty) ,$(subst \
  $(tab),$$(tab),$(subst $(space),$$(space),$(subst $$,$$$$,$1)))),$3,$2,$(QUIET),,,$(newline))

# null device for redirecting output into
NUL := NUL

# code for suppressing output of copy command, like
# "        1 file(s) copied."
# "Скопировано файлов:         1."
SUPPRESS_CP_OUTPUT := | findstr /VC:"        1" & if errorlevel 1 (cmd /c exit 0) else (cmd /c exit 1)
SUPPRESS_MV_OUTPUT := | findstr /VC:"        1" & if errorlevel 1 (cmd /c exit 0) else (cmd /c exit 1)

# copy preserving modification date:
# - file(s) $1 to directory $2 or
# - file $1 to file $2
CP = $(if $(word 2,$1),for %%f in ($(ospath)) do copy /Y /B %%f,copy /Y /B $(ospath)) $(call ospath,$2)$(SUPPRESS_CP_OUTPUT)

# move preserving modification date:
# - file(s) $1 to directory $2 or
# - file $1 to file $2
MV = $(if $(word 2,$1),for %%f in ($(ospath)) do move /Y %%f,move /Y $(ospath)) $(call ospath,$2)$(SUPPRESS_MV_OUTPUT)

# update modification date of given file(s) or create file(s) if they do not exist
TOUCH = for %%f in ($(ospath)) do if exist %%f (copy /Y /B %%f+,, %%f$(SUPPRESS_CP_OUTPUT)) else (rem. > %%f)

# execute command $2 in directory $1
EXECIN = pushd $(ospath) && ($2 && popd || (popd & cmd /c exit 1))

# delete target file(s) if failed to build them and exit shell with error code 1
DEL_ON_FAIL = || (($(DEL)) & cmd /c exit 1)

# suffix of built tool executables
# note: override TOOL_SUFFIX from $(CLEAN_BUILD_DIR)/defs.mk
TOOL_SUFFIX := .exe

# paths separator, as used in %PATH% environment variable
# note: override PATHSEP from $(CLEAN_BUILD_DIR)/defs.mk
PATHSEP := ;

# name of environment variable to modify in $(RUN_TOOL)
# note: override DLL_PATH_VAR from $(CLEAN_BUILD_DIR)/defs.mk
DLL_PATH_VAR := PATH

# if %PATH% environment variable was modified for calling a tool, print new %PATH% value in generated batch
# $1 - tool to execute (with parameters)
# $2 - additional path(s) separated by $(PATHSEP) to append to $(DLL_PATH_VAR)
# $3 - list of names of variables to set in environment (export) for running an executable
# note: override show_tool_vars from $(CLEAN_BUILD_DIR)/defs.mk
show_tool_vars = $(info setlocal$(foreach v,$(if $2,PATH) $3,$(newline)set $v=$(call UNQUOTED_ESCAPE,$($v)))$(newline)$1)

# show after executing a command
# note: override show_tool_vars_end from $(CLEAN_BUILD_DIR)/defs.mk
show_tool_vars_end = $(newline)@echo endlocal

# there is no support for embedding dll search path into executables or dlls
NO_RPATH := 1

# windows terminal do not supports ANSI color escape sequences
# note: override PRINT_PERCENTS from $(CLEAN_BUILD_DIR)/defs.mk
ifeq (,$(filter ansi-colors,$(.FEATURES)))
PRINT_PERCENTS = [$1]
endif

# windows terminal do not supports ANSI color escape sequences
# note: override COLORIZE from $(CLEAN_BUILD_DIR)/defs.mk
ifeq (,$(filter ansi-colors,$(.FEATURES)))
COLORIZE = $1$(padto)$2
endif

# filter command's output through pipe, then send it to stderr
# $1 - command
# $2 - pipe expression for filtering stdout, must be non-empty, for example: |findstr /BC:ABC
FILTER_OUTPUT = (($1 2>&1 && echo OK>&2)$2)3>&2 2>&1 1>&3|findstr /BC:OK>NUL

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,WIN_REQUIRED_VARS WIN_EXPORTED $(sort $(WIN_REQUIRED_VARS) $(WIN_EXPORTED)) \
  PATH DEL_ARGS_LIMIT nonrelpath1 DEL DEL_DIR RM1 RM MKDIR CMP SHELL_ESCAPE UNQUOTED_ESCAPE SED SED_EXPR \
  CAT ECHO_LINE ECHO_LINES ECHO WRITE NUL SUPPRESS_CP_OUTPUT SUPPRESS_MV_OUTPUT CP MV TOUCH EXECIN DEL_ON_FAIL NO_RPATH FILTER_OUTPUT)
